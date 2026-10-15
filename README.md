# HabitTracker — Parte 1

Projeto acadêmico de **Desenvolvimento Mobile**, em Flutter, Dart e Material 3. A proposta é acompanhar hábitos com gentileza: dias sem realização não apagam o progresso acumulado.

**Escopo:** interfaces, navegação e estado com ChangeNotifier/provider. Login, cadastro e recuperação são demonstrações locais. Não há Firebase, backend, API de aplicação ou banco remoto.

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

Como os códigos não vieram acompanhados de descrições individuais no pedido, esta entrega adota a associação explícita abaixo para rastreabilidade.

| Requisito | Implementação | Arquivos principais |
| --- | --- | --- |
| RF001 — Login | Logotipo em imagem, obrigatórios, formato de e-mail e credenciais mockadas; links para cadastro e recuperação | [login_screen.dart](lib/screens/login_screen.dart), [auth_notifier.dart](lib/notifiers/auth_notifier.dart), [demo_auth_repository.dart](lib/repositories/demo_auth_repository.dart) |
| RF002 — Cadastro | Nome, e-mail, telefone, senha e confirmação; validações e acesso após cadastro | [register_screen.dart](lib/screens/register_screen.dart), [validators.dart](lib/services/validators.dart) |
| RF003 — Recuperação | E-mail validado e simulação explicitamente sem envio de e-mail | [recovery_screen.dart](lib/screens/recovery_screen.dart) |
| RF004 — Sobre | Objetivo, contexto acadêmico e integrantes com placeholders editáveis | [about_screen.dart](lib/screens/about_screen.dart), [project_info.dart](lib/config/project_info.dart) |
| RF005 — Perfil | Nome/e-mail autenticados, edição apenas do nome, mínimo de 3 caracteres, confirmação e saudação atualizada | [profile_screen.dart](lib/screens/profile_screen.dart), [auth_notifier.dart](lib/notifiers/auth_notifier.dart), proteção em [main.dart](lib/main.dart) |
| RF006 — Cinco funcionalidades | ListView.builder e estado vazio; criação; edição/exclusão; check-in por data; histórico | [habits_list_screen.dart](lib/screens/habits_list_screen.dart), [create_habit_screen.dart](lib/screens/create_habit_screen.dart), [edit_habit_screen.dart](lib/screens/edit_habit_screen.dart), [habit_checkin_screen.dart](lib/screens/habit_checkin_screen.dart), [habit_history_screen.dart](lib/screens/habit_history_screen.dart) |
| RF007 — Integração | Home, navegação, Material 3 responsivo, ChangeNotifier/provider e persistência local por usuário | [home_screen.dart](lib/screens/home_screen.dart), [app_shell.dart](lib/widgets/app_shell.dart), [habits_notifier.dart](lib/notifiers/habits_notifier.dart), [habits_repository.dart](lib/repositories/habits_repository.dart) |

## Funcionalidades de hábitos

1. **Listar:** título, descrição, frequência e acessos a registro, histórico e edição; estado vazio com orientação.
2. **Criar:** título obrigatório (até 80 caracteres), descrição opcional (até 300) e pelo menos um dia da semana.
3. **Editar/excluir:** altera informações sem perder registros; exclusão do hábito e registros exige confirmação, com opção de cancelar.
4. **Registrar:** escolhe uma data e marca/desmarca realização. Impede datas futuras e anteriores à criação. Permite realizar fora dos dias planejados.
5. **Histórico:** filtro por hábito, registros do mais recente ao mais antigo, total de realizações, dias com realizações e últimos sete dias. Sem pontuação negativa ou sequência que zera após pausas.

## Arquitetura e estado

~~~text
lib/
  config/         integrantes editáveis
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

Antes de apresentar, substitua os placeholders em [lib/config/project_info.dart](lib/config/project_info.dart) pelos nomes reais dos integrantes.

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

Resultados executados nesta entrega:

- Dependências resolvidas e formatação executada.
- Análise estática sem problemas.
- **18 testes automatizados aprovados** em [state_test.dart](test/state_test.dart) e [screens_test.dart](test/screens_test.dart).
- Formulários: obrigatórios, e-mail, credenciais, confirmação de senha, recuperação simulada e nome mínimo do perfil.
- Estado: CRUD, JSON, separação por usuário, gravação pendente de outra sessão e preservação de dados inválidos.
- Check-ins: horários distintos no mesmo dia, desmarcação, datas inválidas e progresso preservado após pausas.
- Fluxo das cinco telas, exclusão com cancelamento/confirmação e rotas em **360 px e 1280 px**, sem overflow.
- Build Web compilado; aplicativo iniciado com flutter run -d web-server e resposta HTTP 200.
- Android não compilado nem executado neste ambiente: Android SDK/emulador ausente.
- A integração de navegador do ambiente falhou ao iniciar. A revisão visual usa capturas renderizadas pelos widgets Flutter, sem alegar teste manual de navegador.

Capturas opcionais para revisão visual:

~~~powershell
$env:FLUTTER_ROOT = 'CAMINHO_DO_SEU_SDK_FLUTTER'
flutter test tool/capture_previews.dart
~~~

As imagens ficam em **.validation/**, ignorada pelo Git.

## Roteiro de vídeo — até 4 minutos

| Tempo | Demonstração |
| --- | --- |
| 0:00–0:25 | Apresente o propósito, logotipo e escopo acadêmico. Mostre uma validação do login. |
| 0:25–0:55 | Mostre o cadastro, confirmação de senha e criação de conta demonstrativa. |
| 0:55–1:20 | Apresente a Home e a lista vazia; crie um hábito com título e frequência semanal. |
| 1:20–1:45 | Mostre a lista, entre em Editar, altere título/frequência e salve. |
| 1:45–2:15 | Em Registrar, selecione hoje; marque, desmarque e marque novamente. Explique a ausência de duplicações. |
| 2:15–2:40 | Em Histórico, mostre totais e registros. Explique que pausas preservam o progresso. |
| 2:40–3:05 | Em Perfil, altere o nome e volte ao Início para mostrar a saudação atualizada. |
| 3:05–3:25 | Mostre Sobre com integrantes; abra a exclusão de hábito, cancele e depois confirme. |
| 3:25–3:50 | Saia e demonstre Recuperação. Mostre a mensagem de simulação sem envio e encerre com as limitações da Parte 1. |

Para mostrar registros antigos, use a conta fixa e **Adicionar hábitos de exemplo**. Os exemplos são opcionais e podem ser excluídos na edição.
