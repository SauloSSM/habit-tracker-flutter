# Auditoria final — HabitTracker Parte 1

Data: 14/10/2026. Escopo: requisitos documentados, interfaces, navegação, formulários, ChangeNotifier e operações locais. O design foi preservado.

**Conclusão:** não foi detectada falha funcional bloqueante nos fluxos exercitados. A demonstração da Parte 1 está funcional. A recuperação permanece sem envio real de e-mail. A identificação final contém somente Saulo da Silva Stuque Menegucci, RA 2840482511024, conforme informado pelo próprio integrante. Autenticação é demonstrativa, sem backend, conforme a correção de escopo do projeto.

## Referência dos RF001 a RF007

A numeração segue a orientação da entrega: RF006 corresponde às cinco funcionalidades específicas e RF007 à listagem de dados com `ListView.builder`. A matriz abaixo relaciona cada requisito às evidências disponíveis.

| RF | Situação verificada | Evidência e limite |
| --- | --- | --- |
| RF001 — Login | **Atendido na demonstração** | `lib/screens/login_screen.dart`: imagem de logotipo, Form, e-mail, senha, navegação para cadastro/recuperação, obrigatórios e formato de e-mail. `lib/notifiers/auth_notifier.dart` e `lib/repositories/demo_auth_repository.dart`: rejeição de credenciais incorretas e acesso com credenciais válidas. Não é autenticação real nem persistente. |
| RF002 — Cadastro | **Atendido na demonstração** | `lib/screens/register_screen.dart`: nome, e-mail, telefone, senha e confirmação. Valida campos vazios, nome mínimo, e-mail, comprimento do telefone, senha mínima e igualdade das senhas. Cadastro válido abre a Home; duplicidade do e-mail é rejeitada na mesma execução. Conta fica em memória; telefone não é persistido ou verificado. |
| RF003 — Recuperação | **Parcial quanto ao envio real; simulação da Parte 1 atendida** | `lib/screens/recovery_screen.dart`: obrigatórios, formato de e-mail, botão e feedback. `DemoAuthRepository.requestPasswordReset`, em `lib/repositories/demo_auth_repository.dart`, retorna explicitamente “Nenhum e-mail foi enviado”. Não envia e-mail, não gera token e não altera senha. Isso não equivale a recuperação real. Não foi acrescentada integração externa porque o escopo autorizado a exclui. |
| RF004 — Sobre | **Atendido** | `lib/screens/about_screen.dart`: objetivo, contexto e identificação do integrante. `lib/config/project_info.dart` contém apenas Saulo da Silva Stuque Menegucci — RA 2840482511024, nome e RA fornecidos pelo próprio integrante. O segundo placeholder foi removido. |
| RF005 — Perfil | **Atendido na sessão demonstrativa** | `lib/screens/profile_screen.dart`: nome e e-mail da conta atual, apenas um campo editável (nome), mínimo de 3 caracteres, confirmação por SnackBar e saudação da Home atualizada. `lib/main.dart`, classe `_Protected`, bloqueia o acesso sem conta. Nome editado não é preservado ao reiniciar o app. |
| RF006 — Cinco funcionalidades | **Atendido** | As cinco interfaces, arquivos, rotas e operações estão relacionadas abaixo. Home é uma sexta interface adicional e não substitui nenhuma delas. |
| RF007 — Listagem de dados | **Atendido** | `lib/screens/habits_list_screen.dart`: `ListView.builder` recebe `itemCount: state.habits.length` e usa `itemBuilder` para construir `HabitCard` com `state.habits[index]`. A tela consome `HabitsNotifier` e orienta o usuário quando não há hábitos. |

Se a avaliação exigir autenticação real, permanência das contas ou recuperação real, esses aspectos permanecem **parciais/não implementados**, mesmo com as interfaces aprovadas. O escopo atual é exclusivamente a Parte 1 demonstrativa.

## Cinco interfaces próprias

| Operação | Arquivo Dart exato | Classe / rota | Resultado conferido |
| --- | --- | --- | --- |
| Listar | `lib/screens/habits_list_screen.dart` | `HabitsListScreen` / `/habits` | Estado vazio e `ListView.builder` com hábitos reais do estado. |
| Criar | `lib/screens/create_habit_screen.dart` | `CreateHabitScreen` / `/habits/create` | Título, descrição opcional, frequência semanal e validação de pelo menos um dia; hábito aparece na lista. |
| Editar/excluir | `lib/screens/edit_habit_screen.dart` | `EditHabitScreen` / `/habits/edit` | Atualiza informações sem perder check-ins. Exclusão tem confirmação e cancelamento, removendo também os registros do hábito. |
| Registrar | `lib/screens/habit_checkin_screen.dart` | `HabitCheckinScreen` / `/checkin` | Seleção de data, marcar/desmarcar e prevenção de duplicação por hábito/dia. Impede futuro e datas anteriores à criação. |
| Histórico | `lib/screens/habit_history_screen.dart` | `HabitHistoryScreen` / `/history` | Registros, totais, dias com realizações, últimos sete dias e filtro funcional por hábito. Pausas não apagam registros. |

Criar e editar reutilizam o formulário em `lib/widgets/habit_editor.dart`. Cada operação mantém sua própria tela, classe e rota; compartilhar o formulário não elimina essa separação.

**ListView/GridView:** há `ListView.builder` na listagem e ListView em outras telas. Não há widget GridView. O requisito de usar ListView **ou** GridView está atendido por ListView; o ícone `Icons.grid_view_rounded` não é um GridView.

## ChangeNotifier e persistência

- `lib/notifiers/auth_notifier.dart`: `AuthNotifier extends ChangeNotifier`; publica conta, perfil, processamento e erros com `notifyListeners()`. Assinatura do repositório é cancelada em `dispose()`.
- `lib/notifiers/habits_notifier.dart`: `HabitsNotifier extends ChangeNotifier`; CRUD e check-ins notificam as telas após salvar. A lista publicada e os conjuntos do modelo são imutáveis.
- `lib/main.dart`: `ChangeNotifierProvider.value` recebe instâncias criadas fora do provider; o State proprietário as descarta em `dispose()`. A escuta da autenticação vincula os hábitos ao usuário correto e é removida ao descartar o app.
- Telas usam `context.watch` para reconstrução e `context.read` para comandos. `setState` fica nos estados locais dos formulários, filtros e seletor de data, sem substituir os notifiers.
- `lib/repositories/habits_repository.dart`: shared_preferences com JSON e chave por usuário. Testes cobrem restauração, troca de conta e gravação pendente da conta anterior.
- `lib/services/local_dates.dart` e `lib/models/habit.dart`: data local normalizada e conjunto de check-ins impedem duplicação no mesmo dia. Não há punição ou zeragem por pausas.
- Senhas não são gravadas no shared_preferences. O mock compara verificadores com salt apenas em memória; não representa autenticação de produção.

## Execuções desta auditoria

Os comandos abaixo foram executados com o SDK local `.tools/flutter/bin/flutter.bat` e PUB_CACHE em `.pub-cache`:

```sh
flutter analyze
flutter test
```

Resultado final: **análise sem problemas e 21 testes aprovados**, sem falhas. Os arquivos de testes são:

- `test/state_test.dart`: 11 testes de estado, persistência, credenciais, nome, datas, duplicação, desmarcação, pausas e isolamento por usuário.
- `test/screens_test.dart`: 7 testes de formulários, proteção de perfil, fluxo das cinco telas, exclusão e rotas/layouts.
- `test/final_audit_test.dart`: 3 testes adicionais que exercitam os controles da navegação em 360/1280 px, Sobre/Voltar, logout/proteção após saída, seletor de data, desmarcação pela interface e filtro do histórico.

As verificações existentes dos formulários também foram ampliadas para conferir todos os obrigatórios do cadastro, e-mail/telefone/senha inválidos, e-mail inválido na recuperação e nome vazio no perfil. A suíte continua exercitando credenciais inválidas, senhas diferentes e nome com menos de 3 caracteres.

Saída dos comandos disponível localmente em `.validation/final-audit-analyze.txt` e `.validation/final-audit-test.txt` (pasta ignorada pelo Git).

**Limite da evidência:** testes de widgets Flutter e estado não equivalem a teste manual de navegador ou dispositivo físico. Não foi feita nova compilação Web/APK nesta auditoria. A compilação Web anterior está registrada no README; Android SDK/emulador não estava disponível na implementação anterior. Não se declara validação nativa Android.

## Alterações e pendências

Na finalização da entrega, as únicas alterações de produção são a identificação do integrante em `lib/config/project_info.dart` e os textos correspondentes em `lib/screens/about_screen.dart`. Não houve alteração de design, navegação ou funcionalidades.

O commit reúne a documentação, os ajustes existentes no teste de auditoria e a identificação acadêmica autorizada. O README apresenta os 21 testes aprovados e a matriz RF001–RF007 corrigida. O roteiro permanece exclusivamente em `ROTEIRO_VIDEO.md`, separado do README.

Antes de entregar:

1. Conferir na tela Sobre a identificação: Saulo da Silva Stuque Menegucci — RA 2840482511024.
2. Declarar no vídeo que autenticação e recuperação são demonstrativas e que **não existe envio de e-mail real**.
3. Se a rubrica oficial exigir envio real ou prova de execução Android, registrar essas pendências; os testes desta Parte 1 não demonstram esses itens.

Roteiro com duração de **2min55s** e caminhos exatos: [ROTEIRO_VIDEO.md](ROTEIRO_VIDEO.md).
