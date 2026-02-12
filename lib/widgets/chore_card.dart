import 'package:flat_chore/models/chore_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChoreCard extends StatelessWidget {
  final ChoreModel chore;
  final String currentUserId;
  final Map<String, String>? memberNames;
  final bool isAdmin;
  final VoidCallback? onComplete;
  final VoidCallback? onJoin;
  final VoidCallback? onLeave;
  final Function(String)? onRemoveParticipant;
  final VoidCallback? onDelete;

  const ChoreCard({
    super.key,
    required this.chore,
    required this.currentUserId,
    this.memberNames,
    this.isAdmin = false,
    this.onComplete,
    this.onJoin,
    this.onLeave,
    this.onRemoveParticipant,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAssignedToMe = chore.assignedTo == currentUserId;
    final dateFormat = DateFormat('MMM d');
    
    String assignedName = isAssignedToMe ? "You" : (memberNames?[chore.assignedTo] ?? "Member");
    
    // Calculate Next
    int nextIdx = (chore.rotationIndex + 1) % chore.participants.length;
    String nextUserId = chore.participants[nextIdx];
    String nextName = nextUserId == currentUserId ? "You" : (memberNames?[nextUserId] ?? "Member");

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isAssignedToMe ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isAssignedToMe 
            ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => SimpleDialog(
                    title: Text(chore.title),
                    children: [
                      ...chore.participants.map((uid) {
                        String name = uid == currentUserId ? "You" : (memberNames?[uid] ?? "Member");
                        bool isCurrent = uid == chore.assignedTo;
                        return SimpleDialogOption(
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "${chore.participants.indexOf(uid) + 1}. $name",
                                  style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal),
                                ),
                              ),
                              if (isCurrent) const Padding(
                                padding: EdgeInsets.only(right: 8.0),
                                child: Text("(Current)", style: TextStyle(color: Colors.blue, fontSize: 12)),
                              ),
                              if (isAdmin && chore.participants.length > 1) 
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.grey, size: 20),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    onRemoveParticipant?.call(uid);
                                  },
                                ),
                            ],
                          ),
                        );
                      }),
                      const Divider(),
                      if (!chore.participants.contains(currentUserId))
                        SimpleDialogOption(
                          onPressed: () { 
                            Navigator.pop(context);
                            onJoin?.call(); 
                          },
                          child: const Text("Join Rotation", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ),
                      if (chore.participants.contains(currentUserId))
                        SimpleDialogOption(
                          onPressed: () {
                            Navigator.pop(context);
                            onLeave?.call();
                          },
                          child: const Text("Leave Rotation", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                );
              },
              title: Text(chore.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('Due: ${dateFormat.format(chore.nextDueDate)}', style: const TextStyle(color: Colors.black87)),
                  Text('Assigned to: $assignedName', style: TextStyle(
                    color: isAssignedToMe ? Theme.of(context).primaryColor : Colors.grey[700],
                    fontWeight: isAssignedToMe ? FontWeight.bold : FontWeight.normal
                  )),
                  Text('Next: $nextName', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              trailing: isAssignedToMe
                  ? ElevatedButton.icon(
                      onPressed: onComplete,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text("Done"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 2,
                      ),
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.hourglass_empty, color: Colors.grey),
                        Text("Waiting", style: TextStyle(fontSize: 10, color: Colors.grey))
                      ],
                    ),
            ),
          ),
          if (isAdmin)
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                onPressed: () {
                   showDialog(
                     context: context,
                     builder: (context) => AlertDialog(
                       title: const Text("Delete Chore"),
                       content: const Text("Are you sure you want to delete this chore?"),
                       actions: [
                         TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                         TextButton(
                           onPressed: () {
                             Navigator.pop(context);
                             onDelete?.call();
                           },
                           child: const Text("Delete", style: TextStyle(color: Colors.red)),
                         ),
                       ],
                     ),
                   );
                },
              ),
            ),
        ],
      ),
    );
  }
}
