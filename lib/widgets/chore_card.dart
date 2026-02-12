import 'package:flat_chore/models/chore_model.dart';
import 'package:flat_chore/screens/home/chore_detail_screen.dart';
import 'package:flat_chore/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChoreCard extends StatefulWidget {
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
  State<ChoreCard> createState() => _ChoreCardState();
}

class _ChoreCardState extends State<ChoreCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isAssignedToMe = widget.chore.assignedTo == widget.currentUserId;
    final dateFormat = DateFormat('MMM d');
    
    String assignedName = isAssignedToMe ? "You" : (widget.memberNames?[widget.chore.assignedTo] ?? "Member");
    
    // Calculate Next
    int nextIdx = (widget.chore.rotationIndex + 1) % widget.chore.participants.length;
    String nextUserId = widget.chore.participants[nextIdx];
    String nextName = nextUserId == widget.currentUserId ? "You" : (widget.memberNames?[nextUserId] ?? "Member");

    // Determine status color
    final now = DateTime.now();
    final daysUntilDue = widget.chore.nextDueDate.difference(now).inDays;
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    if (daysUntilDue < 0) {
      statusColor = AppColors.error;
      statusText = 'Overdue';
      statusIcon = Icons.warning_rounded;
    } else if (daysUntilDue == 0) {
      statusColor = AppColors.warning;
      statusText = 'Today';
      statusIcon = Icons.today_rounded;
    } else if (daysUntilDue <= 2) {
      statusColor = AppColors.info;
      statusText = 'Soon';
      statusIcon = Icons.schedule_rounded;
    } else {
      statusColor = AppColors.success;
      statusText = 'On Track';
      statusIcon = Icons.check_circle_rounded;
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        onTap: () {
          // Navigate to detail page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChoreDetailScreen(
                chore: widget.chore,
                currentUserId: widget.currentUserId,
                memberNames: widget.memberNames ?? {},
                isAdmin: widget.isAdmin,
                onComplete: widget.onComplete,
                onJoin: widget.onJoin,
                onLeave: widget.onLeave,
                onRemoveParticipant: widget.onRemoveParticipant,
                onDelete: widget.onDelete,
              ),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          child: Stack(
            children: [
              // Gradient Overlay for assigned chores
              if (isAssignedToMe)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryPurple.withOpacity(0.05),
                          AppColors.primaryBlue.withOpacity(0.02),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              
              // Main Content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      children: [
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, size: 14, color: statusColor),
                              const SizedBox(width: 4),
                              Text(
                                statusText,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Frequency Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.chore.frequency,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Title
                    Text(
                      widget.chore.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    
                    // Info Row
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 14, color: statusColor),
                        const SizedBox(width: 6),
                        Text(
                          dateFormat.format(widget.chore.nextDueDate),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.people_rounded, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          '${widget.chore.participants.length}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Assignment Info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isAssignedToMe 
                            ? AppColors.primaryPurple.withOpacity(0.1)
                            : AppColors.surfaceBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: isAssignedToMe 
                                ? AppColors.primaryPurple
                                : AppColors.textMuted,
                            child: Text(
                              assignedName[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Assigned to',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  assignedName,
                                  style: TextStyle(
                                    color: isAssignedToMe 
                                        ? AppColors.primaryPurple
                                        : AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                                  onTap: widget.onComplete,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.check_circle_rounded, size: 16, color: Colors.white),
                                        SizedBox(width: 4),
                                        Text(
                                          'Done',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
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
                    const SizedBox(height: 8),
                    
                    // Next Person
                    Row(
                      children: [
                        const Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          'Next: $nextName',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteDialog(BuildContext context) {
    return AlertDialog(
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
            Navigator.pop(context);
            widget.onDelete?.call();
          },
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
