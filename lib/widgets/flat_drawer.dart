import 'package:flat_chore/models/flat_model.dart';
import 'package:flat_chore/models/user_model.dart';
import 'package:flat_chore/screens/flat/create_flat_screen.dart';
import 'package:flat_chore/screens/flat/join_flat_screen.dart';
import 'package:flat_chore/services/auth_service.dart';
import 'package:flat_chore/services/flat_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FlatDrawer extends StatefulWidget {
  final UserModel user;
  const FlatDrawer({super.key, required this.user});

  @override
  State<FlatDrawer> createState() => _FlatDrawerState();
}

class _FlatDrawerState extends State<FlatDrawer> {
  final FlatService _flatService = FlatService();
  final AuthService _authService = AuthService();
  List<FlatModel> _flats = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFlats();
  }

  Future<void> _loadFlats() async {
    try {
      if (widget.user.flatIds.isNotEmpty) {
        List<FlatModel> flats = await _flatService.getFlatsForUser(widget.user.flatIds);
        if (mounted) {
          setState(() {
            _flats = flats;
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }
  
  Future<void> _switchFlat(String newFlatId) async {
    if (newFlatId == widget.user.currentFlatId) return;
    
    // Update currentFlatId in Firestore
    // The main AuthWrapper stream will detect this change and update the UI automatically
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).update({
        'currentFlatId': newFlatId
      });
      if (mounted) Navigator.pop(context); // Close drawer
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error switching flat: $e")));
    }
  }

  Future<void> _confirmLeave(FlatModel flat) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Leave ${flat.name}?"),
        content: const Text("Are you sure you want to leave this flat? You will be removed from all chore rotations."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("Leave", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _flatService.leaveFlat(flat.id, widget.user);
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Left ${flat.name}")));
           _loadFlats(); // Refresh list
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Row(
              children: [
                Text(widget.user.displayName ?? 'User'),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white, size: 16),
                  onPressed: () {
                    TextEditingController controller = TextEditingController(text: widget.user.displayName);
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Edit Profile Name"),
                        content: TextField(controller: controller, decoration: const InputDecoration(labelText: "Display Name")),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                          TextButton(
                            onPressed: () async {
                              if (controller.text.isNotEmpty) {
                                await _authService.updateDisplayName(controller.text);
                                if (context.mounted) Navigator.pop(context);
                              }
                            },
                            child: const Text("Save"),
                          )
                        ],
                      ),
                    );
                  },
                )
              ],
            ),
            accountEmail: Text(widget.user.email),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                widget.user.displayName?[0].toUpperCase() ?? 'U',
                style: const TextStyle(fontSize: 24.0, color: Colors.blue),
              ),
            ),
          ),
          if (_loading)
            const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                   const Padding(
                     padding: EdgeInsets.all(16.0),
                     child: Text("Your Flats", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                   ),
                   ..._flats.map((flat) => ListTile(
                     leading: const Icon(Icons.home),
                     title: Text(flat.name),
                     subtitle: Text(flat.code),
                     selected: flat.id == widget.user.currentFlatId,
                     trailing: Row(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         IconButton(
                           icon: const Icon(Icons.exit_to_app, color: Colors.red, size: 20),
                           onPressed: () => _confirmLeave(flat),
                         ),
                         if (flat.id == widget.user.currentFlatId) 
                           const Icon(Icons.check, color: Colors.blue),
                       ],
                     ),
                     onTap: () => _switchFlat(flat.id),
                   )),
                   const Divider(),
                   ListTile(
                     leading: const Icon(Icons.add),
                     title: const Text('Join a Flat'),
                     onTap: () {
                        Navigator.pop(context); // Close drawer first
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const JoinFlatScreen()));
                     },
                   ),
                   ListTile(
                     leading: const Icon(Icons.create_new_folder),
                     title: const Text('Create a Flat'),
                     onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateFlatScreen()));
                     },
                   ),
                ],
              ),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await _authService.signOut();
              // Wrapper handles navigation, but we might need to manually ensure we are safe
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
