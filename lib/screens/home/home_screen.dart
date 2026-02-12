import 'package:flat_chore/models/chore_model.dart';
import 'package:flat_chore/models/user_model.dart';
import 'package:flat_chore/models/flat_model.dart';
import 'package:flat_chore/services/chore_service.dart';
import 'package:flat_chore/screens/home/add_chore_screen.dart';
import 'package:flat_chore/widgets/chore_card.dart';
import 'package:flutter/material.dart';
import 'package:flat_chore/widgets/flat_drawer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

import 'package:flat_chore/services/flat_service.dart';

import 'package:confetti/confetti.dart';

class HomeScreen extends StatefulWidget {
  final UserModel user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ChoreService _choreService = ChoreService();
  final FlatService _flatService = FlatService();
  late final ConfettiController _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  Map<String, String> _memberNames = {};
  FlatModel? _currentFlat;

  @override
  void initState() {
    super.initState();
    _memberNames[widget.user.uid] = widget.user.displayName ?? 'You';
    
    if (widget.user.currentFlatId != null) {
      _fetchMembers();
      _fetchFlatInfo();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.user.currentFlatId != oldWidget.user.currentFlatId) {
      _fetchMembers();
      _fetchFlatInfo();
    }
  }

  Future<void> _fetchMembers() async {
    if (widget.user.currentFlatId == null) return;
    try {
      List<UserModel> members = await _flatService.getFlatMembers(widget.user.currentFlatId!);
      if (mounted) {
        setState(() {
          _memberNames = {for (var m in members) m.uid: m.displayName ?? 'Unknown'};
        });
      }
    } catch (e) {
    }
  }

  Future<void> _fetchFlatInfo() async {
    if (widget.user.currentFlatId == null) return;
    try {
      // Use a stream or one-time get. For admin check, one-time is fine but stream is better for sync.
      // But we already have a stream of chores. Let's just get flat once or use a listener.
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('flats').doc(widget.user.currentFlatId).get();
      if (doc.exists && mounted) {
        setState(() {
          _currentFlat = FlatModel.fromFirestore(doc);
        });
      }
    } catch (e) {
    }
  }

  // Confetti State
  double _blastDirection = -pi / 2; // Up
  double _gravity = 0.5;
  List<Color> _confettiColors = const [Colors.green, Colors.blue, Colors.pink];
  
  void _randomizeConfetti() {
    final random = Random();
    setState(() {
      int type = random.nextInt(3);
      if (type == 0) {
        _blastDirection = -pi / 2;
        _gravity = 0.3;
      } else if (type == 1) {
        _blastDirection = pi / 2; // Down
        _gravity = 0.1;
      } else {
         _blastDirection = 0; // Center/Radial
         _gravity = 0.2;
      }

      List<List<Color>> palettes = [
         [Colors.red, Colors.orange, Colors.yellow], // Fire
         [Colors.blue, Colors.cyan, Colors.purple], // Cool
         [Colors.green, Colors.lime, Colors.teal], // Nature
         [Colors.pink, Colors.purple, Colors.orange], // Party
         [Colors.black, Colors.amber, Colors.white], // Elegant
      ];
      _confettiColors = palettes[random.nextInt(palettes.length)];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.user.currentFlatId == null) {
      return const Scaffold(body: Center(child: Text("Error: No Flat ID")));
    }

    bool isAdmin = _currentFlat?.ownerId == widget.user.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentFlat?.name ?? 'FlatChore'),
      ),
      drawer: FlatDrawer(user: widget.user),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          Column(
            children: [
               // ... Members List ...
              ExpansionTile(
                title: Text("Flat Members (${_memberNames.length})"),
                children: _memberNames.entries.map((entry) => ListTile(
                  leading: CircleAvatar(child: Text(entry.value[0].toUpperCase())),
                  title: Text(entry.value),
                  subtitle: Text(entry.key == widget.user.uid ? "You" : 
                                 (entry.key == _currentFlat?.ownerId ? "Admin" : "Member")),
                  dense: true,
                )).toList(),
              ),
              const Divider(height: 1),
              Expanded(
                child: StreamBuilder<List<ChoreModel>>(
                  stream: _choreService.streamChores(widget.user.currentFlatId!),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                       return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                       return const Center(
                         child: Text('No chores yet! Add one using the + button.'),
                       );
                    }
                    
                    final chores = snapshot.data!;
                    return ListView.builder(
                      itemCount: chores.length,
                      padding: const EdgeInsets.only(bottom: 80),
                      itemBuilder: (context, index) {
                        return ChoreCard(
                          chore: chores[index], 
                          currentUserId: widget.user.uid,
                          memberNames: _memberNames,
                          isAdmin: isAdmin,
                          onComplete: () async {
                            try {
                              await _choreService.completeChore(widget.user.currentFlatId!, chores[index].id, widget.user.uid, isAdmin: isAdmin);
                              _randomizeConfetti();
                              _confettiController.play();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(ChoreService.getRandomSuccessMessage()),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: _confettiColors.first,
                                    duration: const Duration(seconds: 2),
                                  )
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                              }
                            }
                          },
                          onJoin: () async {
                             try {
                                await _choreService.joinChore(widget.user.currentFlatId!, chores[index].id, widget.user.uid);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Joined rotation!")));
                                }
                             } catch (e) {
                                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                             }
                          },
                          onLeave: () async {
                             try {
                                await _choreService.leaveChore(widget.user.currentFlatId!, chores[index].id, widget.user.uid);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Left rotation!")));
                                }
                             } catch (e) {
                                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                             }
                          },
                          onRemoveParticipant: (uid) async {
                             try {
                                await _choreService.removeParticipant(widget.user.currentFlatId!, chores[index].id, uid);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Removed user from rotation.")));
                                }
                             } catch (e) {
                                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                             }
                          },
                          onDelete: () async {
                             try {
                                await _choreService.deleteChore(widget.user.currentFlatId!, chores[index].id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Chore deleted.")));
                                }
                             } catch (e) {
                                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                             }
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: _confettiColors,
            gravity: _gravity,
            numberOfParticles: 30,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Chore'),
        onPressed: () {
           Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddChoreScreen(user: widget.user)));
        },
      ),
    );
  }
}
