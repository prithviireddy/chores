import 'package:cloud_firestore/cloud_firestore.dart';

class ChoreModel {
  final String id;
  final String title;
  final String frequency;
  final List<String> participants;
  final int rotationIndex;
  final String assignedTo;
  final DateTime nextDueDate;
  final DateTime? lastCompletedAt;
  final String? lastCompletedBy;
  final DateTime createdAt;
  final bool isActive;

  ChoreModel({
    required this.id,
    required this.title,
    required this.frequency,
    required this.participants,
    required this.rotationIndex,
    required this.assignedTo,
    required this.nextDueDate,
    this.lastCompletedAt,
    this.lastCompletedBy,
    required this.createdAt,
    this.isActive = true,
  });

  factory ChoreModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChoreModel(
      id: doc.id,
      title: data['title'] ?? '',
      frequency: data['frequency'] ?? 'Weekly',
      participants: List<String>.from(data['participants'] ?? []),
      rotationIndex: data['rotationIndex'] ?? 0,
      assignedTo: data['assignedTo'] ?? '',
      nextDueDate: (data['nextDueDate'] as Timestamp).toDate(),
      lastCompletedAt: data['lastCompletedAt'] != null ? (data['lastCompletedAt'] as Timestamp).toDate() : null,
      lastCompletedBy: data['lastCompletedBy'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'frequency': frequency,
      'participants': participants,
      'rotationIndex': rotationIndex,
      'assignedTo': assignedTo,
      'nextDueDate': Timestamp.fromDate(nextDueDate),
      'lastCompletedAt': lastCompletedAt != null ? Timestamp.fromDate(lastCompletedAt!) : null,
      'lastCompletedBy': lastCompletedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }
}
