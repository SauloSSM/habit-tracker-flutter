# HabitTracker — Parte 2

Projeto acadêmico em Flutter, Dart e Material 3: hábitos e progresso com gentileza. A Parte 2 mantém as telas, o tema, o logotipo e as rotas da Parte 1 e integra Firebase Authentication e Cloud Firestore, sem backend próprio.

Implementação na branch `parte-2-firebase`; o histórico da Parte 1 permanece em `main`. Os arquivos Firebase e as alterações de dependências encontrados no início foram aproveitados. `AUDITORIA_FINAL.md` registra a Parte 1, não valida esta integração.

## Requisitos da Parte 2

| Requisito | Implementação | Código |
| --- | --- | --- |
| RF001 | Login por e-mail/senha, logout, restauração de sessão, erros em português e solicitação real de recuperação pelo SDK Firebase | `main.dart`, `AuthNotifier`, `FirebaseAuthRepository`, telas de login/recuperação |
| RF002 | Cadastro Auth com nome, telefone e e-mail; documento `usuarios/{uid}` com UID e datas do servidor; edição de nome | `FirebaseAuthRepository.register`, `_profile`, `updateName` |
| RF003 | CRUD e check-ins no Firestore, feedback de gravação, documentos com mais de cinco campos e isolamento por UID | `HabitsNotifier`, `FirestoreHabitsRepository`, `firestore.rules` |
| RF004 | Dois fluxos distintos de snapshots: `habitos` e `realizacoes`; cada tela usa explicitamente `StreamBuilder<List<Habit>>` e `ListView.builder` | `habits_list_screen.dart`, `habit_history_screen.dart`, `watchHabits`, `watchRealizations` |

Os números acima são os requisitos da Parte 2; a numeração da auditoria antiga corresponde à Parte 1.

## Configuração Firebase necessária

`lib/firebase_options.dart` já foi gerado por `flutterfire configure --platforms=web` para o projeto **habit-tracker-flutter-81c6c**. Ele é utilizado na inicialização e foi preservado. Isso registra o aplicativo Web; não comprova que os serviços abaixo estejam habilitados. Não foi feita inspeção autenticada nem alteração no Firebase Console nesta implementação.

No Console do projeto:

1. Em **Authentication → Sign-in method**, habilitar **Email/Password** e salvar. O login por link de e-mail não é necessário.
2. Em **Authentication → Settings → Authorized domains**, conferir o domínio de execução. Para desenvolvimento, adicionar `localhost` se ausente; para hospedagem futura, adicionar o domínio efetivamente utilizado. Não há URL de publicação criada por esta entrega.
3. Em **Firestore Database**, criar o banco **(default)**, edição Standard, escolhendo conscientemente a região. Começar em modo produção. Não usar regras públicas de modo teste.
4. Após executar os testes abaixo, publicar o conteúdo exato de `firestore.rules` na aba **Rules** do Firestore. Alternativamente, com Firebase CLI autenticado e projeto conferido, executar manualmente:

   ```sh
   firebase deploy --only firestore:rules --project habit-tracker-flutter-81c6c
   ```

   Esse comando publica somente regras. **Não foi executado nesta entrega.** O `firebase.json` aponta para `firestore.rules`, mantém o registro FlutterFire e configura os emuladores locais.
5. Em **Authentication → Templates → Password reset**, conferir remetente e texto em português. Criar uma conta de teste com um e-mail acessível, solicitar recuperação, conferir spam e abrir o link recebido. O método usa `sendPasswordResetEmail`; a entrega real depende do serviço e do provedor de e-mail.

Referências oficiais: [autenticação por senha em Flutter](https://firebase.google.com/docs/auth/flutter/password-auth), [regras e autenticação](https://firebase.google.com/docs/firestore/security/get-started) e [transações e escritas atômicas](https://firebase.google.com/docs/firestore/manage-data/transactions).

As opções Web identificam o aplicativo; a autorização dos dados depende de Authentication e das regras, não de esconder a API key. Não adicionar chaves privadas ou contas de serviço ao app.

## Executar

Ambiente local: Flutter **3.47.7**, Dart **3.13.5**. Dependências fixadas em `pubspec.lock`.

```sh
flutter pub get
flutter run -d chrome --web-port 7357
```

Alternativa: `flutter run -d web-server --web-port 7357`, abrindo o endereço realmente informado pelo Flutter. O SDK local ignorado pelo Git está em `.tools/flutter`; no PowerShell pode-se usar `.\.tools\flutter\bin\flutter.bat` e `.\.tools\flutter\bin\dart.bat`.

Não há conta demonstrativa em produção: cadastrar uma conta real. A sessão é administrada pelo Firebase Authentication. Inicialização aguarda o primeiro estado de autenticação antes de escolher a rota. Falha de inicialização oferece **Tentar novamente**.

## Arquitetura e navegação

- `AuthNotifier` e `HabitsNotifier` continuam como `ChangeNotifier` com provider. Os modelos `AppUser` e `Habit` foram reaproveitados; `AppUser` também comporta telefone.
- `AuthRepository` permanece como contrato; `FirebaseAuthRepository` implementa Auth e perfil no Firestore. Senhas são entregues somente ao SDK Authentication, nunca ao Firestore ou ao armazenamento local.
- `HabitsRepository` é o contrato de persistência; `FirestoreHabitsRepository` é usado por `main.dart`. As implementações demonstrativas/locais continuam disponíveis exclusivamente para regressão da Parte 1 e não são selecionadas na execução normal.
- `HabitsNotifier` assina as duas consultas por UID e distribui os eventos aos `StreamBuilder`. As consultas usam `where('uid', isEqualTo: uid)` e `snapshots`; a ordenação ocorre em memória, sem índice composto adicional.
- Ao trocar usuário, os dados são limpos, as assinaturas anteriores são canceladas e respostas de gerações antigas são descartadas. Os builders também recebem uma chave por UID.
- Estados de carregamento, vazio, falha e nova tentativa mantêm os componentes e a identidade visual existentes. Falhas de gravação não geram mensagem de sucesso.

Rotas preservadas: `/login`, `/register`, `/recovery`, `/about`, `/home`, `/profile`, `/habits`, `/habits/create`, `/habits/edit`, `/checkin` e `/history`. Rotas privadas exigem usuário autenticado; ID inválido oferece orientação. A navegação continua lateral em telas largas e inferior em telas pequenas.

## Modelo de dados

| Coleção/documento | Campos |
| --- | --- |
| `usuarios/{uid}` | `uid`, `nome`, `telefone`, `email`, `createdAt`, `updatedAt` |
| `habitos/{habitId}` | `uid`, `title`, `description`, `weekdays`, `createdDay`, `createdAt`, `updatedAt`, `checkins` |
| `realizacoes/{habitId}` | `uid`, `habitId`, `datas`, `createdDay`, `createdAt`, `updatedAt` |

`createdAt` e `updatedAt` usam `FieldValue.serverTimestamp()`. `createdDay` e as datas de check-in usam o calendário local `AAAA-MM-DD`, preservando o comportamento da Parte 1. Cada documento de `realizacoes` agrega as datas de **um hábito**, e não representa um único check-in. O histórico expande essas datas em linhas e obtém o título atual pelo ID do hábito.

### Consistência e segurança

- Criação grava hábito e documento de realizações na mesma transação.
- Check-in rele o hábito dentro da transação, adiciona/remove uma data como conjunto e atualiza os dois documentos atomicamente. Repetir a mesma marcação não duplica registros.
- Edição altera somente título, descrição, frequência e atualização; não sobrescreve os check-ins de outra sessão.
- Exclusão remove os dois documentos atomicamente, após confirmação na interface. Uma edição atrasada não recria um hábito excluído.
- Regras exigem `request.auth.uid`, impedem transferência de propriedade, validam campos/tipos/limites e timestamps, e usam `getAfter` para exigir igualdade entre as datas das duas coleções. Exclusão isolada é negada com `existsAfter`. Coleções não declaradas são negadas.
- As listas devem ser consultadas pelo UID; regras não filtram automaticamente consultas globais. Usuários anônimos e outros UIDs não acessam documentos existentes. Usuários autenticados podem consultar a inexistência de um ID para criar via transação.
- O aplicativo impede datas futuras e anteriores à criação. As regras validam o formato das datas acrescentadas, unicidade e alteração de no máximo uma data por operação; não validam o calendário completo nem o relógio local do cliente.

## Validar sem produção

```sh
flutter analyze
flutter test
flutter build web
npm ci
npm run test:rules
```

Para `npm run test:rules`, instalar Node compatível com os pacotes, Firebase CLI e Java 21, com `firebase` no PATH. O comando inicia o emulador, carrega as regras e executa testes com o projeto fictício `demo-habit-tracker`; não usa o banco de produção. As dependências JS são somente para os testes de regras; não são um backend da aplicação. As mensagens `PERMISSION_DENIED` nas tentativas negativas são esperadas quando os testes passam.

- Testes da Parte 1 continuam cobrindo formulários, CRUD, datas, navegação, logout e layouts em 360/1280 px.
- Testes Firebase usam `fake_cloud_firestore` e `firebase_auth_mocks` para perfil, UID, tradução de erros, chamada de recuperação, transações, sincronização externa, telas e repetição após falhas.
- Testes das regras usam o emulador oficial: leitura/escrita entre usuários, consultas, esquema, timestamps, datas malformadas e obrigatoriedade das operações atômicas.
- Mocks não comprovam entrega de e-mail ou configuração do Console. O emulador valida as regras locais; não comprova que essas regras já estejam publicadas.

O resultado atualizado dos comandos fica registrado em `VALIDACAO_PARTE_2.md`. O build Web fica em `build/web`. Nenhum deploy da aplicação foi realizado.

## Limitações e verificação manual

- Somente **Web** foi configurado pelo FlutterFire. Android/iOS/desktop exigem registrar as plataformas e gerar suas opções antes de execução. Não alegamos validação nessas plataformas.
- Transações exigem conexão; não existe fila própria de gravação offline. A leitura pode usar o cache padrão do SDK. As listas carregam os dados do usuário sem paginação, adequadas ao escopo acadêmico.
- Para manter exclusão atômica e evitar registros órfãos sem backend, as datas são agregadas por hábito. As regras limitam a 10.000 datas por hábito, também sujeitas ao limite de tamanho do documento Firestore. Uma aplicação de grande escala exigiria outro modelo.
- Auth e Firestore não compartilham transação. Se a gravação inicial do perfil falhar, tenta-se remover a conta recém-criada e encerra-se a sessão. Se essa compensação falhar, um login posterior repara o perfil ausente com nome disponível e telefone vazio; o telefone original não pode ser recuperado de uma gravação que falhou. Isso requer conferência manual no Console. Contas cujo perfil foi gravado podem entrar novamente após falha na sincronização de `displayName`.
- Telefone é armazenado, mas não verificado por SMS e não usado para login. A tela de perfil continua editando apenas o nome. Não há exclusão de conta nem mudança de e-mail.
- Não existe migração automática das contas ou hábitos demonstrativos da Parte 1. UIDs reais não são derivados do e-mail.
- Antes de apresentar o projeto: cadastrar usuário A, recarregar e conferir sessão/dados, testar recuperação em caixa real, verificar sincronização em duas janelas, editar sem perder registros, desmarcar, excluir e conferir que B não vê A. Esses passos com produção ainda precisam ser executados após configurar o Console e publicar as regras.

**Integrante:** Saulo da Silva Stuque Menegucci — **RA 2840482511024**.
