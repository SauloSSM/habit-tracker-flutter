const { readFileSync } = require('node:fs');
const { before, after, beforeEach, test } = require('node:test');
const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const { doc, getDoc, getDocs, collection, query, where, setDoc, updateDoc, deleteDoc, writeBatch, serverTimestamp } = require('firebase/firestore');

let env;
before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-habit-tracker',
    firestore: { rules: readFileSync('firestore.rules', 'utf8') },
  });
});
after(async () => { await env?.cleanup(); });
beforeEach(async () => { await env.clearFirestore(); });
const dbFor = uid => env.authenticatedContext(uid, { email: `${uid}@teste.com` }).firestore();
function pair(db, id = 'habit', uid = 'a') {
  const batch = writeBatch(db);
  batch.set(doc(db, 'habitos', id), {
    uid, title: 'Ler', description: '', weekdays: [1, 3], createdDay: '2026-11-18',
    checkins: [], createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
  });
  batch.set(doc(db, 'realizacoes', id), {
    uid, habitId: id, datas: [], createdDay: '2026-11-18',
    createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
  });
  return batch.commit();
}
test('owner creates a pair and queries both collections by UID', async () => {
  const db = dbFor('a');
  await assertSucceeds(getDoc(doc(db, 'habitos', 'new-id')));
  await assertSucceeds(pair(db));
  for (const name of ['habitos', 'realizacoes']) {
    const result = await assertSucceeds(getDocs(query(collection(db, name), where('uid', '==', 'a'))));
    if (result.size !== 1) throw Error('Missing document');
    await assertFails(getDocs(collection(db, name)));
  }
});
test('anonymous users and other UIDs cannot read or modify owner data', async () => {
  await pair(dbFor('a'));
  for (const db of [dbFor('b'), env.unauthenticatedContext().firestore()]) {
    for (const name of ['habitos', 'realizacoes']) {
      await assertFails(getDoc(doc(db, name, 'habit')));
      await assertFails(updateDoc(doc(db, name, 'habit'), { uid: 'b' }));
      await assertFails(deleteDoc(doc(db, name, 'habit')));
    }
    await assertFails(pair(db, 'forged', 'a'));
  }
});
test('check-ins require atomic equality; metadata edits preserve history', async () => {
  const db = dbFor('a');
  await pair(db);
  await assertFails(updateDoc(doc(db, 'habitos', 'habit'), { checkins: ['2026-11-18'], updatedAt: serverTimestamp() }));
  await assertFails(updateDoc(doc(db, 'realizacoes', 'habit'), { datas: ['2026-11-18'], updatedAt: serverTimestamp() }));
  const batch = writeBatch(db);
  batch.update(doc(db, 'habitos', 'habit'), { checkins: ['2026-11-18'], updatedAt: serverTimestamp() });
  batch.update(doc(db, 'realizacoes', 'habit'), { datas: ['2026-11-18'], updatedAt: serverTimestamp() });
  await assertSucceeds(batch.commit());
  await assertSucceeds(updateDoc(doc(db, 'habitos', 'habit'), { title: 'Ler mais', updatedAt: serverTimestamp() }));
  await assertFails(updateDoc(doc(db, 'habitos', 'habit'), { uid: 'b', updatedAt: serverTimestamp() }));
});
test('deletion requires both documents and cannot leave orphan history', async () => {
  const db = dbFor('a');
  await pair(db);
  await assertFails(deleteDoc(doc(db, 'habitos', 'habit')));
  await assertFails(deleteDoc(doc(db, 'realizacoes', 'habit')));
  const batch = writeBatch(db);
  batch.delete(doc(db, 'habitos', 'habit'));
  batch.delete(doc(db, 'realizacoes', 'habit'));
  await assertSucceeds(batch.commit());
});
test('profile ownership, required fields, timestamps and schema are enforced', async () => {
  const db = dbFor('a');
  const profile = { uid: 'a', nome: 'Pessoa', telefone: '11999999999', email: 'a@teste.com', createdAt: serverTimestamp(), updatedAt: serverTimestamp() };
  await assertFails(setDoc(doc(db, 'usuarios', 'a'), { ...profile, senha: 'never-store' }));
  await assertFails(setDoc(doc(db, 'usuarios', 'b'), profile));
  await assertSucceeds(setDoc(doc(db, 'usuarios', 'a'), profile));
  await assertSucceeds(updateDoc(doc(db, 'usuarios', 'a'), { nome: 'Outro nome', updatedAt: serverTimestamp() }));
  await assertFails(getDoc(doc(dbFor('b'), 'usuarios', 'a')));
  await assertFails(updateDoc(doc(db, 'usuarios', 'a'), { createdAt: serverTimestamp(), updatedAt: serverTimestamp() }));
});
test('invalid habit frequency and extra fields are rejected', async () => {
  const db = dbFor('a');
  await pair(db);
  for (const fields of [{ weekdays: [] }, { weekdays: [8] }, { weekdays: [1, 1] }, { title: '' }, { description: 'x'.repeat(301) }, { unexpected: true }]) {
    await assertFails(updateDoc(doc(db, 'habitos', 'habit'), { ...fields, updatedAt: serverTimestamp() }));
  }
});
test('malformed dates and replacement of entire check-in history are rejected', async () => {
  const db = dbFor('a');
  await pair(db);
  for (const dates of [['not-a-date'], [123], ['2026-11-17', '2026-11-18']]) {
    const batch = writeBatch(db);
    batch.update(doc(db, 'habitos', 'habit'), { checkins: dates, updatedAt: serverTimestamp() });
    batch.update(doc(db, 'realizacoes', 'habit'), { datas: dates, updatedAt: serverTimestamp() });
    await assertFails(batch.commit());
  }
});
