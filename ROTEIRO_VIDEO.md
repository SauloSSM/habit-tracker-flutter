# Roteiro de vídeo — HabitTracker Parte 1 (2min55s)

Todos os caminhos abaixo são relativos à raiz do projeto e correspondem a arquivos existentes.

## Preparação antes de gravar

- Confira na tela Sobre o único integrante: Saulo da Silva Stuque Menegucci — RA 2840482511024, definido em `lib/config/project_info.dart`.
- Deixe o app executando e o editor com os arquivos da tabela abertos. Para cada etapa, mostre primeiro a operação e faça um corte rápido para o trecho de código indicado, mantendo a narração.
- Use uma execução nova e uma conta de vídeo ainda não cadastrada nessa execução, para começar com a lista vazia. Dados de exemplo para o cadastro: nome “Conta Vídeo”, e-mail `video@exemplo.com`, telefone `11999999999`, senha e confirmação `Habito123!`.
- Deixe os resultados de `flutter analyze` e `flutter test` já disponíveis no terminal para mostrar no encerramento; não espere pelos comandos durante o vídeo.
- Pode cortar pausas e tempo de digitação. Não corte as mensagens de validação, a confirmação de exclusão ou o aviso de simulação.

## Sequência com tempo e arquivos exatos

| Tempo | Operação e fala sugerida | Código a mostrar em corte rápido |
| --- | --- | --- |
| **0:00–0:10** | Na tela de login, abra **Conheça o HabitTracker**. Mostre objetivo e identificação do integrante, depois volte. Diga: “HabitTracker é a Parte 1 de um projeto acadêmico. Uma pausa não apaga o progresso.” | `lib/screens/about_screen.dart` — `AboutScreen`; `lib/config/project_info.dart` — `teamMembers`. |
| **0:10–0:25** | Mostre o logotipo, toque em **Entrar** com campos vazios e exiba um e-mail inválido. Use **Preencher conta de exemplo**, toque em **Entrar** e mostre a Home. Com um corte, vá a **Perfil → Sair da conta** para continuar no login. Diga: “O login valida os campos, o formato do e-mail e as credenciais de demonstração.” | `lib/screens/login_screen.dart` — `_submit` e Form; `lib/services/validators.dart` — `email`. A imagem fica em `assets/images/logo.svg`. |
| **0:25–0:37** | Abra **Esqueci minha senha**, informe `video@exemplo.com` e toque em **Simular solicitação**. Deixe visível o resultado. Diga exatamente: “Esta recuperação é uma simulação. Nenhum e-mail real é enviado e a senha não é alterada.” Volte ao login. | `lib/screens/recovery_screen.dart` — `_submit`; `lib/repositories/demo_auth_repository.dart` — `requestPasswordReset`. |
| **0:37–0:57** | Abra **Criar minha conta**. Preencha os cinco campos; use uma confirmação diferente para mostrar a validação, corrija e toque em **Criar conta**. Mostre a Home. Diga: “O cadastro valida os dados e permite acesso após a confirmação correta. Esta conta existe apenas nesta execução.” | `lib/screens/register_screen.dart` — Form e validação da confirmação; `_submit`. |
| **0:57–1:20** | Mostre a saudação da Home, abra **Hábitos** e a lista vazia. Toque em **Novo hábito**, cadastre “Ler 10 minutos”, descrição opcional e pelo menos um dia; salve e mostre a lista. Diga: “Home é adicional. Listar e criar possuem telas próprias.” | `lib/screens/home_screen.dart` — `HomeScreen`; `lib/screens/habits_list_screen.dart` — **`ListView.builder`**; `lib/screens/create_habit_screen.dart` — `CreateHabitScreen`. |
| **1:20–1:36** | Toque no lápis, altere para “Ler 15 minutos” e ajuste um dia da frequência; salve. Diga: “Editar tem sua própria interface e atualiza o hábito na lista.” | `lib/screens/edit_habit_screen.dart` — `EditHabitScreen`; `lib/widgets/habit_editor.dart` — `_save` e seleção dos dias. |
| **1:36–1:55** | Abra **Registrar realização**, mostre **Escolher data** e confirme hoje. Marque, desmarque e marque novamente. Diga: “O check-in aceita uma realização por hábito e data. Posso desmarcar sem perder os outros registros.” | `lib/screens/habit_checkin_screen.dart` — `_pickDate` e `CheckboxListTile`; `lib/notifiers/habits_notifier.dart` — **`setCheckin`**, conjunto de registros. |
| **1:55–2:10** | Toque em **Ver minhas realizações**. Mostre o total, registro e filtro de hábito. Diga: “Histórico é a quinta tela específica. Os totais permanecem mesmo com dias de pausa.” | `lib/screens/habit_history_screen.dart` — `HabitHistoryScreen`, filtro e resumo. |
| **2:10–2:29** | Vá a **Perfil**, mostre nome/e-mail, tente salvar um nome com 2 caracteres e depois salve “Vídeo Teste”. Mostre a confirmação e volte ao **Início** para a nova saudação. Diga: “Só o nome é editável. O mínimo é três caracteres e a alteração reflete na Home.” | `lib/screens/profile_screen.dart` — `_save` e `Validators.name`; `lib/notifiers/auth_notifier.dart` — `updateName`. |
| **2:29–2:41** | Em **Hábitos**, abra a edição, toque em **Excluir hábito**, mostre **Cancelar**, abra novamente e confirme **Excluir**. Diga: “A exclusão exige confirmação e remove também os check-ins.” | `lib/screens/edit_habit_screen.dart` — `_delete` e `showDialog<bool>`. |
| **2:41–2:55** | Faça cortes para os dois ChangeNotifiers e as rotas; mostre o terminal com **No issues found** e **21 testes aprovados**. Diga: “AuthNotifier e HabitsNotifier compartilham estado pelo provider. Hábitos são salvos localmente por usuário. Não há backend nem Firebase nesta Parte 1.” | `lib/notifiers/auth_notifier.dart` — `extends ChangeNotifier`; `lib/notifiers/habits_notifier.dart` — `extends ChangeNotifier` e `notifyListeners`; `lib/main.dart` — `MultiProvider` e `_route`. |

## Checagem antes de enviar o vídeo

- As cinco telas foram efetivamente abertas e seus cinco arquivos foram identificados com o nome completo.
- Apareceram `ListView.builder`, os dois `extends ChangeNotifier` e o uso de provider.
- Foram mostrados cadastro, validações, recuperação simulada, perfil, Sobre, criação/edição, check-in, histórico e confirmação da exclusão.
- A fala sobre e-mail não sugere envio real. Contas e nome editado são temporários; hábitos/check-ins têm persistência local.
- Duração total prevista: **175 segundos**, com 5 segundos de margem até o limite de 3 minutos.
