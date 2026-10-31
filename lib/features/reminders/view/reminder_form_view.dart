import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../shared/widgets/app_shimmer.dart';
import '../model/reminder_model.dart';
import '../states/reminder_bloc.dart';
import '../states/reminder_event.dart';
import '../states/reminder_state.dart';

class ReminderFormView extends StatelessWidget {
  const ReminderFormView({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<ReminderBloc>(),
    child: const _ReminderForm(),
  );
}

class _ReminderForm extends StatefulWidget {
  const _ReminderForm();

  @override
  State<_ReminderForm> createState() => _ReminderFormState();
}

class _ReminderFormState extends State<_ReminderForm> {
  static const _months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  late DateTime _scheduledAt;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _scheduledAt = DateTime(now.year, now.month, now.day, now.hour + 1);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: context.select<ReminderBloc, bool>(
      (bloc) => bloc.state.status != ReminderStatus.saving,
    ),
    child: BlocListener<ReminderBloc, ReminderState>(
      listener: (context, state) {
        if (state.status == ReminderStatus.success) {
          context.pop(state.notificationsAllowed ?? true);
        } else if (state.status == ReminderStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.errorMessage ?? 'Pengingat belum bisa disimpan.',
              ),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Pengingat baru')),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                Text(
                  'Rencanakan jadwal menonton',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kami akan mengirim notifikasi pada waktu yang Anda pilih.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white60),
                ),
                const SizedBox(height: 26),
                TextFormField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    labelText: 'Judul pengingat',
                    hintText: 'Contoh: Menonton Star Wars bersama keluarga',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Masukkan judul pengingat.'
                      : null,
                ),
                const SizedBox(height: 18),
                _DateTimeTile(
                  icon: Icons.calendar_month_outlined,
                  label: 'Tanggal',
                  value:
                      '${_scheduledAt.day} ${_months[_scheduledAt.month - 1]} ${_scheduledAt.year}',
                  onTap: _selectDate,
                ),
                const SizedBox(height: 8),
                _DateTimeTile(
                  icon: Icons.access_time,
                  label: 'Waktu',
                  value:
                      '${_scheduledAt.hour.toString().padLeft(2, '0')}:${_scheduledAt.minute.toString().padLeft(2, '0')}',
                  onTap: _selectTime,
                ),
                const SizedBox(height: 30),
                BlocBuilder<ReminderBloc, ReminderState>(
                  builder: (context, state) => FilledButton.icon(
                    onPressed: state.status == ReminderStatus.saving
                        ? null
                        : _save,
                    icon: state.status == ReminderStatus.saving
                        ? const AppShimmer(
                            child: AppShimmerBox(
                              width: 18,
                              height: 18,
                              borderRadius: BorderRadius.all(
                                Radius.circular(9),
                              ),
                            ),
                          )
                        : const Icon(Icons.notifications_active_outlined),
                    label: Text(
                      state.status == ReminderStatus.saving
                          ? 'Menyimpan…'
                          : 'Simpan pengingat',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _scheduledAt.isBefore(now) ? now : _scheduledAt,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _scheduledAt = DateTime(
        selected.year,
        selected.month,
        selected.day,
        _scheduledAt.hour,
        _scheduledAt.minute,
      );
    });
  }

  Future<void> _selectTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _scheduledAt = DateTime(
        _scheduledAt.year,
        _scheduledAt.month,
        _scheduledAt.day,
        selected.hour,
        selected.minute,
      );
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (!_scheduledAt.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih waktu yang masih akan datang.')),
      );
      return;
    }
    final reminder = ReminderModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      scheduledAt: _scheduledAt,
    );
    context.read<ReminderBloc>().add(ReminderSaved(reminder));
  }
}

class _DateTimeTile extends StatelessWidget {
  const _DateTimeTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}
