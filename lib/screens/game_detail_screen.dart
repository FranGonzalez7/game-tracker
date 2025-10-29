import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/saved_game.dart';

/// Detail screen for viewing and editing a saved game
/// Allows modification of dates, rating, and notes
class GameDetailScreen extends StatefulWidget {
  final SavedGame game;

  const GameDetailScreen({
    super.key,
    required this.game,
  });

  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  late DateTime? _startDate;
  late DateTime? _completionDate;
  late double? _personalRating;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _startDate = widget.game.startDate;
    _completionDate = widget.game.completionDate;
    _personalRating = widget.game.personalRating;
    _notesController = TextEditingController(text: widget.game.notes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectCompletionDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _completionDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(1970),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _completionDate = picked;
      });
    }
  }

  void _saveChanges() {
    final updatedGame = widget.game.copyWith(
      startDate: _startDate,
      completionDate: _completionDate,
      personalRating: _personalRating,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    Navigator.pop(context, updatedGame);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.game.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveChanges,
            tooltip: 'Save changes',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Game Image
            if (widget.game.backgroundImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  widget.game.backgroundImage!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.videogame_asset,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 24),

            // Start Date
            Card(
              child: ListTile(
                leading: const Icon(Icons.play_arrow),
                title: const Text('Start Date'),
                subtitle: Text(
                  _startDate != null
                      ? DateFormat('yyyy-MM-dd').format(_startDate!)
                      : 'Not set',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _selectStartDate,
              ),
            ),

            const SizedBox(height: 12),

            // Completion Date
            Card(
              child: ListTile(
                leading: const Icon(Icons.check_circle),
                title: const Text('Completion Date'),
                subtitle: Text(
                  _completionDate != null
                      ? DateFormat('yyyy-MM-dd').format(_completionDate!)
                      : 'Not set',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _selectCompletionDate,
              ),
            ),

            const SizedBox(height: 24),

            // Personal Rating
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personal Rating',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: List.generate(5, (index) {
                        final rating = (index + 1).toDouble();
                        return IconButton(
                          icon: Icon(
                            _personalRating != null && rating <= _personalRating!
                                ? Icons.star
                                : Icons.star_border,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: () {
                            setState(() {
                              _personalRating = _personalRating == rating ? null : rating;
                            });
                          },
                        );
                      }),
                    ),
                    if (_personalRating != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${_personalRating!.toStringAsFixed(1)} / 5.0',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Notes
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notes',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Add your thoughts about this game...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saveChanges,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

