import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/note_provider.dart';
import '../models/note.dart';
import '../theme/app_theme.dart';
import 'add_edit_note_screen.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            Expanded(child: _buildNotesGrid(context)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'notes_fab',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditNoteScreen()),
        ),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notes',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 4),
          const Text(
            'Keep track of your thoughts and ideas',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesGrid(BuildContext context) {
    return Consumer<NoteProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
        }

        if (provider.notes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notes_rounded, size: 64, color: AppTheme.textMuted.withOpacity(0.3)),
                const SizedBox(height: 16),
                const Text(
                  'No notes yet',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: provider.notes.length,
          itemBuilder: (context, index) {
            final note = provider.notes[index];
            return _buildNoteCard(context, note);
          },
        );
      },
    );
  }

  Widget _buildNoteCard(BuildContext context, Note note) {
    final isDefaultColor = note.colorValue == 0xFF1F1F1F || note.colorValue == 0xFF000000;
    
    return Card(
      color: isDefaultColor ? Theme.of(context).cardTheme.color : Color(note.colorValue),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(
          color: isDefaultColor ? Theme.of(context).dividerColor.withOpacity(0.1) : Colors.white12,
        ),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddEditNoteScreen(note: note)),
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (note.title.isNotEmpty)
                Text(
                  note.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDefaultColor ? Theme.of(context).textTheme.bodyLarge?.color : Colors.white,
                  ),
                ),
              if (note.title.isNotEmpty) const SizedBox(height: 8),
              Expanded(
                child: Text(
                  note.content,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: (isDefaultColor ? Theme.of(context).textTheme.bodyMedium?.color : Colors.white)?.withOpacity(0.8),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('MMM d, h:mm a').format(note.updatedAt),
                style: TextStyle(
                  fontSize: 10,
                  color: (isDefaultColor ? Theme.of(context).textTheme.bodySmall?.color : Colors.white)?.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
