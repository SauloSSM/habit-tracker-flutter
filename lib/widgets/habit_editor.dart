import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../notifiers/habits_notifier.dart';
import '../services/local_dates.dart';
import '../services/validators.dart';
import 'common.dart';

class HabitEditor extends StatefulWidget {
  const HabitEditor({super.key, this.habit, required this.onSave, this.footer});
  final Habit? habit;
  final Future<bool> Function(
    String title,
    String description,
    Set<int> weekdays,
  )
  onSave;
  final Widget? footer;
  @override
  State<HabitEditor> createState() => _HabitEditorState();
}

class _HabitEditorState extends State<HabitEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late Set<int> _days;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.habit?.title);
    _description = TextEditingController(text: widget.habit?.description);
    _days = {...?widget.habit?.weekdays};
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final success = await widget.onSave(_title.text, _description.text, {
      ..._days,
    });
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
      showFeedback(
        context,
        widget.habit == null
            ? 'Hábito criado. Um passo de cada vez!'
            : 'Hábito atualizado.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HabitsNotifier>();
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _title,
            validator: Validators.title,
            maxLength: 80,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Título do hábito',
              hintText: 'Ex.: Ler algumas páginas',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _description,
            maxLines: 3,
            maxLength: 300,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Descrição (opcional)',
              hintText: 'O que torna este hábito especial para você?',
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Em quais dias?',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          const Text('Escolha pelo menos um dia da semana.'),
          const SizedBox(height: 12),
          FormField<Set<int>>(
            validator: (_) =>
                _days.isEmpty ? 'Selecione pelo menos um dia da semana.' : null,
            builder: (field) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var day = 1; day <= 7; day++)
                      FilterChip(
                        label: Text(weekdayLabels[day - 1]),
                        selected: _days.contains(day),
                        onSelected: state.saving
                            ? null
                            : (selected) {
                                setState(() {
                                  selected ? _days.add(day) : _days.remove(day);
                                });
                                field.didChange({..._days});
                              },
                      ),
                  ],
                ),
                if (field.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      field.errorText!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          BusyButton(
            label: widget.habit == null ? 'Criar hábito' : 'Salvar alterações',
            icon: Icons.check_rounded,
            busy: state.saving,
            onPressed: state.canEdit ? _save : null,
          ),
          const SizedBox(height: 16),
          const Notice(
            'Sua frequência é um guia. Uma pausa não apaga as realizações anteriores.',
          ),
          if (widget.footer != null) ...[
            const SizedBox(height: 24),
            widget.footer!,
          ],
        ],
      ),
    );
  }
}
