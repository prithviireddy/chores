import 'package:cloud_firestore/cloud_firestore.dart';

class FlatModel {
  final String id;
  final String code;
  final String name;
  final String ownerId;
  final List<String> memberIds;
  final int memberCount;
  final DateTime createdAt;
  final String? password;

  FlatModel({
    required this.id,
    required this.code,
    required this.name,
    required this.ownerId,
    required this.memberIds,
    required this.memberCount,
    required this.createdAt,
    this.password,
  });

  factory FlatModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return FlatModel(
      id: doc.id,
      code: data['code'] ?? '',
      name: data['name'] ?? '',
      ownerId: data['ownerId'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      memberCount: data['memberCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      password: data['password'],
    );
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      'code': code,
      'name': name,
      'ownerId': ownerId,
      'memberIds': memberIds,
      'memberCount': memberCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
    
    // Only include password if it's not null and not empty
    if (password != null && password!.isNotEmpty) {
      map['password'] = password;
    }
    
    return map;
  }
}
