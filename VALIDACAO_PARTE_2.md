# Validação da Parte 2

Executada em **18/11/2026**, na branch `parte-2-firebase`, com Flutter **3.47.7**
e Dart **3.13.5**, usando o SDK local `.tools/flutter`.

| Comando | Resultado observado |
| --- | --- |
| `dart format lib test tool` | Nenhuma alteração de formatação pendente na execução final |
| `flutter analyze` | `No issues found!` |
| `flutter test --reporter expanded` | **30 testes aprovados**, nenhuma falha |
| `npm run test:rules` | **7 testes aprovados**, nenhuma falha, emulador Firestore oficial 1.22.0, projeto fictício `demo-habit-tracker` |
| `flutter build web` | Compilação concluída: `Built build/web` |
| `git diff --check` | Sem erros de whitespace; Git emitiu avisos de conversão LF/CRLF |

O build apresentou avisos sobre a possibilidade de usar Wasm e a fonte opcional
CupertinoIcons; concluiu com sucesso. Não foi compilado nem testado um build Wasm.

Os logs completos da execução local estão em arquivos ignorados pelo Git:

- `.validation/parte2-analyze.txt`
- `.validation/parte2-test.txt`
- `.validation/parte2-rules.txt`
- `.validation/parte2-build-web.txt`

## Cobertura

Os 21 testes de regressão da Parte 1 foram mantidos com o repositório local como
fixture. Os oito testes de repositórios Firebase verificam cadastro/perfil,
telefone e timestamps, UID, erros de autenticação, chamada do SDK para recuperação,
CRUD nas duas coleções, preservação de check-ins após edição, unicidade e
desmarcação, remoção conjunta, rejeição de edição após exclusão, streams por UID,
alterações externas, limpeza após troca de conta, falha de cadastro, repetição
após falha de leitura/gravação e limites de data. Um teste adicional de widgets
usa os repositórios Firebase com mocks para conferir atualização das duas telas,
edição externa de título e exclusão.

Os sete testes do emulador avaliam as regras reais do arquivo `firestore.rules`:

1. Criação conjunta e consulta de ambas as coleções pelo UID; consulta global negada.
2. Leitura, gravação e exclusão negadas para usuário anônimo e outro UID.
3. Check-ins exigem atualização conjunta; edição de metadados preserva o histórico.
4. Exclusão de apenas um dos documentos é negada; exclusão conjunta é permitida.
5. Perfil exige proprietário, campos permitidos, e-mail autenticado e timestamps.
6. Frequência inválida, título vazio, descrição excessiva e campos extras são negados.
7. Datas com formato inválido e substituição de todo o histórico são negadas.

Os `PERMISSION_DENIED` das tentativas negativas são resultados esperados e foram
verificados com `assertFails`. Testes Flutter usam mocks; testes de regras usam
o emulador oficial, sem dados de produção.

## O que ainda depende do Firebase Console

Não houve acesso autenticado ao Console, envio real de e-mail durante a validação,
teste manual em produção nem deploy de aplicação ou regras. A configuração Web
foi identificada no arquivo FlutterFire já existente; a habilitação dos serviços
e os domínios autorizados não foram presumidos.

Conferir no projeto `habit-tracker-flutter-81c6c`:

1. Authentication: provedor Email/Password habilitado.
2. Authentication: domínio de execução autorizado, incluindo `localhost` quando usado.
3. Firestore: banco Standard `(default)` criado e região escolhida.
4. Firestore Rules: publicar o arquivo local somente após conferir esta validação.
5. Criar conta de teste, conferir o perfil no Firestore, recarregar a sessão,
   solicitar recuperação e verificar a entrega e o link em uma caixa real.
6. Testar sincronização entre duas janelas e isolamento entre duas contas reais.

O procedimento completo está no [README](README.md). A auditoria antiga em
`AUDITORIA_FINAL.md` permanece um registro histórico da Parte 1.
