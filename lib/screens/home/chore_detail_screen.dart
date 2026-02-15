import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flat_chore/models/chore_model.dart';
import 'package:flat_chore/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChoreDetailScreen extends StatefulWidget {
  final ChoreModel chore;
  final String currentUserId;
  final String flatId;
  final Map<String, String> memberNames;
  final bool isAdmin;
  final VoidCallback? onComplete;
  final VoidCallback? onJoin;
  final VoidCallback? onLeave;
  final Function(String)? onRemoveParticipant;
  final VoidCallback? onDelete;

  const ChoreDetailScreen({
    super.key,
    required this.chore,
    required this.currentUserId,
    required this.flatId,
    required this.memberNames,
    required this.isAdmin,
    this.onComplete,
    this.onJoin,
    this.onLeave,
    this.onRemoveParticipant,
    this.onDelete,
  });

  @override
  State<ChoreDetailScreen> createState() => _ChoreDetailScreenState();
}

class _ChoreDetailScreenState extends State<ChoreDetailScreen> {
  List<Map<String, dynamic>> _completionHistory = [];
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadCompletionHistory();
  }

  Future<void> _loadCompletionHistory() async {
    try {
      // Fetch completion history from Firestore
      final snapshot = await FirebaseFirestore.instance
          .collection('flats')
          .doc(widget.flatId)
          .collection('chores')
          .doc(widget.chore.id)
          .collection('completions')
          .orderBy('completedAt', descending: true)
          .limit(50)
          .get();

      setState(() {
        _completionHistory = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'completedBy': data['completedBy'] ?? '',
            'completedAt': (data['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          };
        }).toList();
        _loadingHistory = false;
      });
    } catch (e) {
      setState(() => _loadingHistory = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final bool isAssignedToMe = widget.chore.assignedTo == widget.currentUserId;

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        title: const Text('Chore Details'),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.isAdmin)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppColors.cardBg,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: const Text(
                      'Delete Chore',
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                    ),
                    content: const Text(
                      'Are you sure you want to delete this chore? This action cannot be undone.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                        ),
                        onPressed: () {
                          Navigator.pop(context); // Close dialog
                          Navigator.pop(context); // Close detail screen
                          widget.onDelete?.call();
                        },
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chore Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppColors.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.cleaning_services_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.chore.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildInfoChip(Icons.calendar_today_rounded, dateFormat.format(widget.chore.nextDueDate)),
                      const SizedBox(width: 12),
                      _buildInfoChip(Icons.repeat_rounded, widget.chore.frequency),
                    ],
                  ),
                  if (widget.chore.lastCompletedAt != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Last completed by ${widget.memberNames[widget.chore.lastCompletedBy] ?? "Unknown"} on ${dateFormat.format(widget.chore.lastCompletedAt!)}',
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Current Assignment
            _buildSectionTitle('Current Assignment'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppColors.cardShadow,
                border: Border.all(
                  color: isAssignedToMe 
                      ? AppColors.primaryPurple.withOpacity(0.3)
                      : AppColors.textMuted.withOpacity(0.1),
                  width: isAssignedToMe ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: isAssignedToMe ? AppColors.primaryPurple : AppColors.textMuted,
                    child: Text(
                      (widget.memberNames[widget.chore.assignedTo] ?? "?")[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.memberNames[widget.chore.assignedTo] ?? "Unknown",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isAssignedToMe ? AppColors.primaryPurple : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          isAssignedToMe ? "It's your turn!" : "Currently assigned",
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  if (isAssignedToMe)
                    Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.successGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.success.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            widget.onComplete?.call();
                            Navigator.pop(context);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.check_circle_rounded, size: 18, color: Colors.white),
                                SizedBox(width: 6),
                                Text(
                                  'Complete',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Rotation Order
            _buildSectionTitle('Rotation Order'),
            const SizedBox(height: 12),
            ...widget.chore.participants.asMap().entries.map((entry) {
              int idx = entry.key;
              String uid = entry.value;
              String name = widget.memberNames[uid] ?? "Unknown";
              bool isCurrent = uid == widget.chore.assignedTo;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isCurrent ? AppColors.primaryPurple.withOpacity(0.1) : AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isCurrent 
                        ? AppColors.primaryPurple.withOpacity(0.3)
                        : AppColors.textMuted.withOpacity(0.1),
                    width: isCurrent ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: isCurrent ? AppColors.primaryGradient : null,
                        color: isCurrent ? null : AppColors.surfaceBg,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${idx + 1}',
                          style: TextStyle(
                            color: isCurrent ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Current',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (widget.isAdmin && widget.chore.participants.length > 1)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: AppColors.error, size: 20),
                        onPressed: () {
                          widget.onRemoveParticipant?.call(uid);
                          Navigator.pop(context);
                        },
                      ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),

            // Completion History
            _buildSectionTitle('Completion History'),
            const SizedBox(height: 12),
            if (_loadingHistory)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_completionHistory.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Column(
                    children: const [
                      Icon(Icons.history_rounded, size: 48, color: AppColors.textMuted),
                      SizedBox(height: 12),
                      Text(
                        'No completion history yet',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._completionHistory.map((completion) {
                final completedBy = completion['completedBy'] as String;
                final completedAt = completion['completedAt'] as DateTime;
                final userName = widget.memberNames[completedBy] ?? "Unknown";
                
                return GestureDetector(
                  onTap: () {
                    // Navigate to user's full completion history
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserCompletionHistoryScreen(
                          userId: completedBy,
                          userName: userName,
                          flatId: widget.flatId,
                          choreId: widget.chore.id,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.textMuted.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.success.withOpacity(0.2),
                          child: Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${dateFormat.format(completedAt)} at ${timeFormat.format(completedAt)}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 24),

            // Action Buttons
            if (!widget.chore.participants.contains(widget.currentUserId))
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                  ),
                  icon: const Icon(Icons.add_circle_rounded),
                  label: const Text('Join Rotation'),
                  onPressed: () {
                    widget.onJoin?.call();
                    Navigator.pop(context);
                  },
                ),
              ),
            if (widget.chore.participants.contains(widget.currentUserId) && !isAssignedToMe)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                  ),
                  icon: const Icon(Icons.exit_to_app_rounded),
                  label: const Text('Leave Rotation'),
                  onPressed: () {
                    widget.onLeave?.call();
                    Navigator.pop(context);
                  },
                ),
              ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// User Completion History Screen
class UserCompletionHistoryScreen extends StatelessWidget {
  final String userId;
  final String userName;
  final String flatId;
  final String choreId;

  const UserCompletionHistoryScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.flatId,
    required this.choreId,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        title: Text('$userName\'s History'),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('flats')
            .doc(flatId)
            .collection('chores')
            .doc(choreId)
            .collection('completions')
            .where('completedBy', isEqualTo: userId)
            .orderBy('completedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history_rounded, size: 64, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  Text(
                    'No completions yet',
                    style: const TextStyle(fontSize: 18, color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          final completions = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: completions.length,
            itemBuilder: (context, index) {
              final data = completions[index].data() as Map<String, dynamic>;
              final completedAt = (data['completedAt'] as Timestamp).toDate();

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: AppColors.successGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Completed',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateFormat.format(completedAt),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            timeFormat.format(completedAt),
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
