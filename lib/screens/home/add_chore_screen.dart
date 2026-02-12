import 'package:flat_chore/models/chore_model.dart';
import 'package:flat_chore/models/user_model.dart';
import 'package:flat_chore/services/chore_service.dart';
import 'package:flat_chore/services/flat_service.dart';
import 'package:flutter/material.dart';

class AddChoreScreen extends StatefulWidget {
  final UserModel user;

  const AddChoreScreen({super.key, required this.user});

  @override
  State<AddChoreScreen> createState() => _AddChoreScreenState();
}

class _AddChoreScreenState extends State<AddChoreScreen> {
  final _formKey = GlobalKey<FormState>();
  String title = '';
  String frequency = 'Weekly';
  List<UserModel> flatMembers = []; 
  List<String> selectedMemberIds = []; 
  bool loading = false;
  bool fetchingMembers = true;

  final FlatService _flatService = FlatService();
  final ChoreService _choreService = ChoreService();

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    try {
      if (widget.user.currentFlatId != null) {
        flatMembers = await _flatService.getFlatMembers(widget.user.currentFlatId!);
        selectedMemberIds = flatMembers.map((u) => u.uid).toList();
      }
    } catch (e) {
    } finally {
      if (mounted) setState(() => fetchingMembers = false);
    }
  }

  DateTime _getInitialDueDate(String freq) {
    DateTime now = DateTime.now();
    switch(freq) {
      case 'Daily': return now.add(const Duration(days: 1));
      case 'Weekly': return now.add(const Duration(days: 7));
      case 'Monthly': return now.add(const Duration(days: 30));
      default: return now.add(const Duration(days: 7));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Chore')),
      body: fetchingMembers ? const Center(child: CircularProgressIndicator()) :
      Form(
        key: _formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextFormField(
                decoration: const InputDecoration(labelText: 'Chore Title'),
                validator: (val) => val!.isEmpty ? 'Enter title' : null,
                onChanged: (val) => setState(() => title = val),
              ),
            ),
            Padding(
               padding: const EdgeInsets.symmetric(horizontal: 16.0),
               child: DropdownButtonFormField<String>(
                 value: frequency,
                 items: ['Daily', 'Weekly', 'Monthly'].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                 onChanged: (val) => setState(() => frequency = val!),
                 decoration: const InputDecoration(labelText: 'Frequency'),
               ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft, 
                child: Text("Participants (Drag to reorder rotation)", style: TextStyle(fontWeight: FontWeight.bold))
              ),
            ),
            Expanded(
              child: ReorderableListView(
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final String item = selectedMemberIds.removeAt(oldIndex);
                    selectedMemberIds.insert(newIndex, item);
                  });
                },
                children: selectedMemberIds.map((uid) {
                  final member = flatMembers.firstWhere((u) => u.uid == uid, orElse: () => UserModel(uid: uid, email: 'Unknown', flatIds: [], createdAt: DateTime.now()));
                  return ListTile(
                    key: ValueKey(uid),
                    title: Text(member.displayName ?? member.email),
                    leading: const Icon(Icons.drag_handle),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          selectedMemberIds.remove(uid);
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
             if (flatMembers.length > selectedMemberIds.length) 
               Padding(
                 padding: const EdgeInsets.all(8.0),
                 child: DropdownButton<String>(
                   hint: const Text('Add Participant'),
                   items: flatMembers.where((m) => !selectedMemberIds.contains(m.uid)).map((m) {
                     return DropdownMenuItem(value: m.uid, child: Text(m.displayName ?? m.email));
                   }).toList(),
                   onChanged: (uid) {
                     if (uid != null) {
                       setState(() {
                         selectedMemberIds.add(uid);
                       });
                     }
                   },
                 ),
               ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: loading ? null : () async {
                   if (_formKey.currentState!.validate()) {
                     if (selectedMemberIds.isEmpty) {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select at least one participant")));
                       return;
                     }
                     
                     setState(() => loading = true);
                     try {
                       ChoreModel chore = ChoreModel(
                         id: '', 
                         title: title,
                         frequency: frequency,
                         participants: selectedMemberIds,
                         rotationIndex: 0,
                         assignedTo: selectedMemberIds.first,
                         nextDueDate: _getInitialDueDate(frequency),
                         createdAt: DateTime.now(),
                         isActive: true,
                       );
                       
                       await _choreService.addChore(widget.user.currentFlatId!, chore);
                       if (mounted) Navigator.pop(context);
                     } catch (e) {
                       if (mounted) {
                         setState(() => loading = false);
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                       }
                     }
                   }
                },
                child: loading ? const CircularProgressIndicator() : const Text('Create Chore'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
