import 'package:flat_chore/models/chore_model.dart';
import 'package:flat_chore/models/user_model.dart';
import 'package:flat_chore/models/flat_model.dart';
import 'package:flat_chore/services/chore_service.dart';
import 'package:flat_chore/screens/home/add_chore_screen.dart';
import 'package:flat_chore/widgets/chore_card.dart';
import 'package:flat_chore/utils/theme.dart';
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

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final ChoreService _choreService = ChoreService();
  final FlatService _flatService = FlatService();
  late final ConfettiController _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  Map<String, String> _memberNames = {};
  FlatModel? _currentFlat;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _memberNames[widget.user.uid] = widget.user.displayName ?? 'You';
    
    if (widget.user.currentFlatId != null) {
      _fetchMembers();
      _fetchFlatInfo();
    }
    
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _fabAnimationController.dispose();
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
      // Handle error silently
    }
  }

  Future<void> _fetchFlatInfo() async {
    if (widget.user.currentFlatId == null) return;
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('flats').doc(widget.user.currentFlatId).get();
      if (doc.exists && mounted) {
        setState(() {
          _currentFlat = FlatModel.fromFirestore(doc);
        });
      }
    } catch (e) {
      // Handle error silently
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
         [AppColors.success, AppColors.info, AppColors.warning],
         [AppColors.primaryPurple, AppColors.primaryBlue, AppColors.accentPink],
         [AppColors.accentOrange, AppColors.warning, AppColors.success],
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
      backgroundColor: AppColors.lightBg,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: AppColors.lightBg,
        elevation: 0,
        title: ShaderMask(
          shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
          child: Text(
            _currentFlat?.name ?? 'FlatChore',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: FlatDrawer(user: widget.user),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          Column(
            children: [
              // Members Section
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.people_rounded, color: Colors.white, size: 20),
                    ),
                    title: const Text(
                      "Flat Members",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      "${_memberNames.length} members",
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    children: _memberNames.entries.map((entry) {
                      bool isCurrentUser = entry.key == widget.user.uid;
                      bool isFlatAdmin = entry.key == _currentFlat?.ownerId;
                      
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isCurrentUser 
                                  ? AppColors.primaryPurple
                                  : AppColors.textMuted,
                              child: Text(
                                entry.value[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.value,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    isCurrentUser ? "You" : (isFlatAdmin ? "Admin" : "Member"),
                                    style: TextStyle(
                                      color: isCurrentUser || isFlatAdmin 
                                          ? AppColors.primaryPurple
                                          : AppColors.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isFlatAdmin)
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  gradient: AppColors.accentGradient,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.star_rounded, color: Colors.white, size: 16),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              
              // Chores List
              Expanded(
                child: StreamBuilder<List<ChoreModel>>(
                  stream: _choreService.streamChores(widget.user.currentFlatId!),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                       return Center(
                         child: Column(
                           mainAxisAlignment: MainAxisAlignment.center,
                           children: [
                             const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                             const SizedBox(height: 16),
                             Text(
                               'Error: ${snapshot.error}',
                               style: const TextStyle(color: AppColors.error),
                             ),
                           ],
                         ),
                       );
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                       return Center(
                         child: Column(
                           mainAxisAlignment: MainAxisAlignment.center,
                           children: [
                             Container(
                               padding: const EdgeInsets.all(24),
                               decoration: BoxDecoration(
                                 gradient: AppColors.primaryGradient,
                                 shape: BoxShape.circle,
                                 boxShadow: AppColors.softShadow,
                               ),
                               child: const Icon(
                                 Icons.cleaning_services_rounded,
                                 size: 48,
                                 color: Colors.white,
                               ),
                             ),
                             const SizedBox(height: 24),
                             const Text(
                               'No chores yet!',
                               style: TextStyle(
                                 fontSize: 24,
                                 fontWeight: FontWeight.bold,
                                 color: AppColors.textPrimary,
                               ),
                             ),
                             const SizedBox(height: 8),
                             const Text(
                               'Add one using the + button below',
                               style: TextStyle(
                                 color: AppColors.textSecondary,
                                 fontSize: 16,
                               ),
                             ),
                           ],
                         ),
                       );
                    }
                    
                    final chores = snapshot.data!;
                    return ListView.builder(
                      itemCount: chores.length,
                      padding: const EdgeInsets.only(bottom: 100, top: 8),
                      itemBuilder: (context, index) {
                        return ChoreCard(
                          chore: chores[index], 
                          currentUserId: widget.user.uid,
                          flatId: widget.user.currentFlatId!,
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
                                    content: Row(
                                      children: [
                                        const Icon(Icons.celebration_rounded, color: Colors.white),
                                        const SizedBox(width: 12),
                                        Text(ChoreService.getRandomSuccessMessage()),
                                      ],
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: AppColors.success,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    duration: const Duration(seconds: 2),
                                  )
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Error: $e"),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }
                          },
                          onJoin: () async {
                             try {
                                await _choreService.joinChore(widget.user.currentFlatId!, chores[index].id, widget.user.uid);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Joined rotation!"),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }
                             } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Error: $e"),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                             }
                          },
                          onLeave: () async {
                             try {
                                await _choreService.leaveChore(widget.user.currentFlatId!, chores[index].id, widget.user.uid);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Left rotation!"),
                                      backgroundColor: AppColors.warning,
                                    ),
                                  );
                                }
                             } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Error: $e"),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                             }
                          },
                          onRemoveParticipant: (uid) async {
                             try {
                                await _choreService.removeParticipant(widget.user.currentFlatId!, chores[index].id, uid);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Removed user from rotation."),
                                      backgroundColor: AppColors.info,
                                    ),
                                  );
                                }
                             } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Error: $e"),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                             }
                          },
                          onDelete: () async {
                             try {
                                await _choreService.deleteChore(widget.user.currentFlatId!, chores[index].id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Chore deleted."),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                             } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Error: $e"),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
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
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppColors.softShadow,
          ),
          child: FloatingActionButton.extended(
            backgroundColor: Colors.transparent,
            elevation: 0,
            icon: const Icon(Icons.add_rounded, size: 28),
            label: const Text(
              'Add Chore',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            onPressed: () {
               Navigator.of(context).push(
                 PageRouteBuilder(
                   pageBuilder: (context, animation, secondaryAnimation) => AddChoreScreen(user: widget.user),
                   transitionsBuilder: (context, animation, secondaryAnimation, child) {
                     return FadeTransition(
                       opacity: animation,
                       child: SlideTransition(
                         position: Tween<Offset>(
                           begin: const Offset(0, 0.1),
                           end: Offset.zero,
                         ).animate(animation),
                         child: child,
                       ),
                     );
                   },
                 ),
               );
            },
          ),
        ),
      ),
    );
  }
}
