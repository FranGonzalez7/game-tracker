import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/lists_provider.dart';

class ListsTab extends ConsumerWidget {
  const ListsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listsAsync = ref.watch(userListsStreamProvider);

    return listsAsync.when(
      data: (lists) {
        if (lists.isEmpty) {
          return Center(
            child: Text(
              'Aún no tienes listas. Crea la primera!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final list = lists[index];
            final name = list['name'] as String? ?? 'Sin nombre';
            IconData leadingIcon = Icons.list_alt_outlined;
            if (name == 'Mis juegos favoritos') {
              leadingIcon = Icons.favorite_border;
            } else if (name.startsWith('Jugados en ')) {
              leadingIcon = Icons.calendar_month;
            }
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFF8B00FF), width: 2),
              ),
              child: ListTile(
                title: Text(name),
                leading: Icon(leadingIcon, color: const Color(0xFF8B00FF)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: navegar al detalle de la lista
                },
              ),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemCount: lists.length,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Error al cargar listas: $e'),
      ),
    );
  }
}


