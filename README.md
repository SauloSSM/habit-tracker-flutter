# HabitTracker — Parte 1

Projeto acadêmico de **Desenvolvimento Mobile**, em Flutter, Dart e Material 3. A proposta é acompanhar hábitos com gentileza: dias sem realização não apagam o progresso acumulado.

**Escopo:** interfaces, navegação e estado com ChangeNotifier/provider. Login, cadastro e recuperação são demonstrações locais. Não há Firebase, backend, API de aplicação ou banco remoto.

**Auditoria final:** [relatório RF001–RF007](AUDITORIA_FINAL.md), com evidências de **21 testes automatizados aprovados** e análise estática sem problemas. Recuperação real por e-mail não está implementada.

## Execução

Recomendado: **Flutter 3.47.7 / Dart 3.13.5**, versões usadas na validação. Dependências fixadas em pubspec.lock. Com Flutter estável instalado, execute na raiz:

~~~sh
flutter pub get
flutter run -d chrome --web-port 7357
~~~

Alternativas: flutter run -d edge ou servidor local:

~~~sh
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 7357
~~~

Abra o endereço exibido pelo Flutter. Mantenha a mesma porta para preservar a origem de armazenamento no navegador.

Para Android, instale Android SDK, aceite as licenças e conecte um dispositivo ou inicie um emulador:

~~~sh
flutter doctor
flutter doctor --android-licenses
flutter devices
flutter run -d <id-do-dispositivo>
~~~

Neste ambiente foi preparado um SDK isolado em **.tools/flutter**, ignorado pelo Git. No PowerShell, use **.\.tools\flutter\bin\flutter.bat** no lugar de flutter e **.\.tools\flutter\bin\dart.bat** no lugar de dart. Em outro computador use sua própria instalação; esse SDK não faz parte da distribuição.

## Conta demonstrativa

- E-mail: **estudante@habit.local**
- Senha: **Habito123!**
- Toque em **Preencher conta de exemplo** e depois em **Entrar**.
- Também é possível cadastrar uma conta nova e usá-la durante a mesma execução.
- A Home começa vazia. **Adicionar hábitos de exemplo** insere dois hábitos e registros antigos somente por ação explícita do usuário.

## Telas e rotas

| Tela | Rota | Arquivo em lib/screens |
| --- | --- | --- |
| Login | /login | login_screen.dart |
| Cadastro | /register | register_screen.dart |
| Recuperação simulada | /recovery | recovery_screen.dart |
| Sobre | /about | about_screen.dart |
| Home | /home | home_screen.dart |
| Perfil protegido | /profile | profile_screen.dart |
| Listar hábitos | /habits | habits_list_screen.dart |
| Criar hábito | /habits/create | create_habit_screen.dart |
| Editar/excluir hábito | /habits/edit | edit_habit_screen.dart |
| Registrar realização | /checkin | habit_checkin_screen.dart |
| Histórico | /history | habit_history_screen.dart |

As cinco funcionalidades têm telas e arquivos próprios; a Home é adicional. As rotas estão centralizadas em [main.dart](lib/main.dart). Edição recebe o ID do hábito como argumento; registro e histórico aceitam um ID opcional para filtrar um hábito. Rotas privadas mostram o login sem uma conta autenticada. IDs inexistentes exibem um estado informativo.

## Matriz RF001 a RF007

A matriz relaciona os requisitos às telas e aos arquivos que os implementam. RF006 reúne as cinco funcionalidades específicas; RF007 documenta a listagem de dados com `ListView.builder`.

| Requisito | Implementação | Arquivos principais |
| --- | --- | --- |
| RF001 — Login | Logotipo em imagem, obrigatórios, formato de e-mail e credenciais mockadas; links para cadastro e recuperação | [login_screen.dart](lib/screens/login_screen.dart), [auth_notifier.dart](lib/notifiers/auth_notifier.dart), [demo_auth_repository.dart](lib/repositories/demo_auth_repository.dart) |
| RF002 — Cadastro | Nome, e-mail, telefone, senha e confirmação; validações e acesso após cadastro | [register_screen.dart](lib/screens/register_screen.dart), [validators.dart](lib/services/validators.dart) |
| RF003 — Recuperação | E-mail validado e simulação explicitamente sem envio de e-mail | [recovery_screen.dart](lib/screens/recovery_screen.dart) |
| RF004 — Sobre | Objetivo, contexto acadêmico e identificação de Saulo da Silva Stuque Menegucci, RA 2840482511024 | [about_screen.dart](lib/screens/about_screen.dart), [project_info.dart](lib/config/project_info.dart) |
| RF005 — Perfil | Nome/e-mail autenticados, edição apenas do nome, mínimo de 3 caracteres, confirmação e saudação atualizada | [profile_screen.dart](lib/screens/profile_screen.dart), [auth_notifier.dart](lib/notifiers/auth_notifier.dart), proteção em [main.dart](lib/main.dart) |
| RF006 — Cinco funcionalidades | Listar hábitos; criar hábito; editar/excluir hábito; registrar realização por data; consultar histórico, cada uma com tela própria | [habits_list_screen.dart](lib/screens/habits_list_screen.dart), [create_habit_screen.dart](lib/screens/create_habit_screen.dart), [edit_habit_screen.dart](lib/screens/edit_habit_screen.dart), [habit_checkin_screen.dart](lib/screens/habit_checkin_screen.dart), [habit_history_screen.dart](lib/screens/habit_history_screen.dart) |
| RF007 — Listagem de dados | `ListView.builder` constrói os cartões dos hábitos a partir de `HabitsNotifier`, com `itemCount`, `itemBuilder` e orientação quando a lista está vazia | [habits_list_screen.dart](lib/screens/habits_list_screen.dart), [habit_card.dart](lib/widgets/habit_card.dart), [habits_notifier.dart](lib/notifiers/habits_notifier.dart) |

## Funcionalidades de hábitos

1. **Listar:** título, descrição, frequência e acessos a registro, histórico e edição; estado vazio com orientação.
2. **Criar:** título obrigatório (até 80 caracteres), descrição opcional (até 300) e pelo menos um dia da semana.
3. **Editar/excluir:** altera informações sem perder registros; exclusão do hábito e registros exige confirmação, com opção de cancelar.
4. **Registrar:** escolhe uma data e marca/desmarca realização. Impede datas futuras e anteriores à criação. Permite realizar fora dos dias planejados.
5. **Histórico:** filtro por hábito, registros do mais recente ao mais antigo, total de realizações, dias com realizações e últimos sete dias. Sem pontuação negativa ou sequência que zera após pausas.

## Arquitetura e estado

~~~text
lib/
  config/         identificação acadêmica do integrante
  models/         AppUser e Habit
  repositories/   contrato de autenticação, mock em memória e hábitos locais
  notifiers/      AuthNotifier e HabitsNotifier (ChangeNotifier)
  services/       validações e datas locais
  screens/        uma tela por arquivo
  theme/          identidade Material 3
  widgets/        formulários e componentes compartilhados
  main.dart       inicialização, providers, rotas e proteção
~~~

- **AuthNotifier:** conta, perfil, processamento e erros. O repositório publica mudanças e as telas consomem o estado pelo provider.
- **HabitsNotifier:** lista, frequência e check-ins. Gravações confirmadas notificam as telas relacionadas. A lista publicada é imutável.
- Na troca de conta, os hábitos visíveis são limpos e recarregados pela identidade atual. Gravações pendentes da conta anterior não substituem o estado da nova conta.
- JSON versão 1, em chaves **habittracker.v1.habits.<id-do-usuário>** no shared_preferences. Falhas de leitura preservam os dados originais e impedem sobrescrita; falhas de gravação mantêm o estado anterior e mostram feedback.
- Check-ins são conjuntos de datas locais **AAAA-MM-DD**, sem horário. Repetir a marcação de um hábito no mesmo dia mantém apenas um registro.
- Navegação lateral em telas largas e inferior nas menores; conteúdo com rolagem; interface e seletor de datas em português brasileiro.

O logotipo de duas folhas é autoral: [logo.svg](assets/images/logo.svg). Variantes PNG e ícones Android/Web estão incluídos. [generate_icons.ps1](tool/generate_icons.ps1) regenera os PNGs no Windows, opcionalmente.

## Limitações da Parte 1

- **Nenhuma recuperação envia e-mail.** A mensagem de resultado declara que a solicitação foi simulada.
- Não é necessário configurar Firebase ou serviços externos; não existem dependências Firebase no projeto.
- Contas cadastradas, nome editado e sessão existem **somente em memória**. Fechar/recarregar o app elimina essas informações. A conta fixa de exemplo é recriada ao iniciar.
- Não há senhas no shared_preferences. O mock mantém apenas verificadores SHA-256 com salt em memória para comparar credenciais. É uma simulação acadêmica, sem garantias de autenticação de produção.
- O telefone é obrigatório e validado no formulário, mas não é verificado, usado para login ou persistido.
- Hábitos e check-ins permanecem localmente. A identidade demo deriva do e-mail normalizado: recriar uma conta com o mesmo e-mail recupera seus hábitos locais. Esse isolamento serve à demonstração, sem proteção entre pessoas com acesso ao mesmo dispositivo.
- Limpar os dados do app/navegador remove o conteúdo. Trocar a origem/porta separa o armazenamento. Não há sincronização entre dispositivos.
- O APK usa a assinatura de depuração do template Flutter. Publicação em loja está fora do escopo.

**Integrante:** Saulo da Silva Stuque Menegucci — **RA 2840482511024**. A tela Sobre apresenta essa identificação a partir de [project_info.dart](lib/config/project_info.dart).

## Validação e compilação

~~~sh
flutter pub get
dart format .
flutter analyze
flutter test
flutter build web --no-web-resources-cdn
flutter build apk --debug
~~~

O build Web fica em **build/web**; sirva essa pasta por HTTP. A opção --no-web-resources-cdn inclui o renderizador localmente. Android exige Android SDK e licenças aceitas.

Resultados da validação registrada em `.validation/final-audit-analyze.txt` e `.validation/final-audit-test.txt` (arquivos locais, ignorados pelo Git):

- Dependências resolvidas e formatação executada.
- Análise estática sem problemas.
- **21 testes automatizados aprovados** em [state_test.dart](test/state_test.dart), [screens_test.dart](test/screens_test.dart) e [final_audit_test.dart](test/final_audit_test.dart).
- Formulários: obrigatórios, e-mail, credenciais, confirmação de senha, recuperação simulada e nome mínimo do perfil.
- Estado: CRUD, JSON, separação por usuário, gravação pendente de outra sessão e preservação de dados inválidos.
- Check-ins: horários distintos no mesmo dia, desmarcação, datas inválidas e progresso preservado após pausas.
- Fluxo das cinco telas, exclusão com cancelamento/confirmação e rotas em **360 px e 1280 px**, sem overflow.
- Auditoria final: botões da navegação lateral/inferior, Sobre/Voltar, logout, proteção após saída, seleção de data, desmarcação pela interface e filtro do histórico.
- Build Web compilado; aplicativo iniciado com flutter run -d web-server e resposta HTTP 200.
- Android não compilado nem executado neste ambiente: Android SDK/emulador ausente.
- A integração de navegador do ambiente falhou ao iniciar. A revisão visual usa capturas renderizadas pelos widgets Flutter, sem alegar teste manual de navegador.

Capturas opcionais para revisão visual:

~~~powershell
$env:FLUTTER_ROOT = 'CAMINHO_DO_SEU_SDK_FLUTTER'
flutter test tool/capture_previews.dart
~~~

As imagens ficam em **.validation/**, ignorada pelo Git.
