import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../shared/widgets/app_empty.dart';
import '../../../shared/widgets/app_error.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/app_shimmer.dart';
import '../model/reminder_model.dart';
import '../states/reminder_bloc.dart';
import '../states/reminder_event.dart';
import '../states/reminder_state.dart';

class ReminderListView extends StatelessWidget {
  const ReminderListView({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<ReminderBloc>()..add(RemindersRequested()),
    child: Builder(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Pengingat')),
        body: BlocBuilder<ReminderBloc, ReminderState>(
          builder: (context, state) => switch (state.status) {
            ReminderStatus.initial ||
            ReminderStatus.loading => const _ReminderListShimmer(),
            ReminderStatus.saving =>
              state.reminders.isEmpty
                  ? const AppLoading()
                  : _ReminderList(reminders: state.reminders),
            ReminderStatus.failure => AppError(
              message: state.errorMessage ?? 'Pengingat belum bisa dimuat.',
              onRetry: () =>
                  context.read<ReminderBloc>().add(RemindersRequested()),
            ),
            ReminderStatus.success =>
              state.reminders.isEmpty
                  ? const AppEmpty(
                      message:
                          'Belum ada pengingat. Tambahkan jadwal menonton.',
                    )
                  : _ReminderList(reminders: state.reminders),
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final notificationsAllowed = await context.push<bool>(
              '/reminders/new',
            );
            if (!context.mounted || notificationsAllowed == null) return;
            if (notificationsAllowed == false) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Pengingat tersimpan, tetapi izin notifikasi atau alarm tepat belum aktif. Waktu pengiriman bisa terlambat.',
                  ),
                ),
              );
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('Buat pengingat'),
        ),
      ),
    ),
  );
}

class _ReminderList extends StatelessWidget {
  const _ReminderList({required this.reminders});

  final List<ReminderModel> reminders;

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 104),
    physics: const BouncingScrollPhysics(),
    itemCount: reminders.length,
    separatorBuilder: (_, _) => const SizedBox(height: 8),
    itemBuilder: (context, index) {
      final reminder = reminders[index];
      return Card(
        child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.notifications_active)),
          title: Text(
            reminder.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(_formatDateTime(reminder.scheduledAt)),
          ),
          trailing: IconButton(
            tooltip: 'Hapus pengingat',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, reminder),
          ),
        ),
      );
    },
  );

  Future<void> _confirmDelete(
    BuildContext context,
    ReminderModel reminder,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus pengingat?'),
        content: Text('Pengingat “${reminder.title}” akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<ReminderBloc>().add(ReminderDeleted(reminder.id));
    }
  }
}

class _ReminderListShimmer extends StatelessWidget {
  const _ReminderListShimmer();

  @override
  Widget build(BuildContext context) => AppShimmer(
    child: ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, _) => const AppShimmerBox(height: 76),
    ),
  );
}

String _formatDateTime(DateTime dateTime) {
  final date =
      '${dateTime.day.toString().padLeft(2, '0')}/'
      '${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
  final time =
      '${dateTime.hour.toString().padLeft(2, '0')}:'
      '${dateTime.minute.toString().padLeft(2, '0')}';
  return '$date · $time';
}
