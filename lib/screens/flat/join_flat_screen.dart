import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flat_chore/models/user_model.dart';
import 'package:flat_chore/screens/flat/create_flat_screen.dart';
import 'package:flat_chore/services/auth_service.dart';
import 'package:flat_chore/services/flat_service.dart';
import 'package:flutter/material.dart';

class JoinFlatScreen extends StatefulWidget {
  const JoinFlatScreen({super.key});

  @override
  State<JoinFlatScreen> createState() => _JoinFlatScreenState();
}

class _JoinFlatScreenState extends State<JoinFlatScreen> {
  final _formKey = GlobalKey<FormState>();
  String code = '';
  bool loading = false;
  
  final FlatService _flatService = FlatService();
  final AuthService _auth = AuthService();

  Future<String?> _showPasswordDialog(String flatName) async {
    String? enteredPassword;
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Join "$flatName"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This flat is password protected.'),
            const SizedBox(height: 10),
            TextField(
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
              onChanged: (val) => enteredPassword = val,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, enteredPassword),
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join or Create Flat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Enter the 6-character code to join your flat',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Flat Code', hintText: 'e.g. ABC123'),
                validator: (val) => val!.length < 6 ? 'Enter a valid 6-char code' : null,
                onChanged: (val) => setState(() => code = val.toUpperCase()),
              ),
              const SizedBox(height: 20),
              if (loading) 
                const CircularProgressIndicator() 
              else 
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) return;
                        
                        setState(() => loading = true);
                        try {
                          User? firebaseUser = FirebaseAuth.instance.currentUser;
                          if (firebaseUser == null) throw Exception("User not logged in");

                          // Fetch flat info first to check for password
                          QuerySnapshot query = await FirebaseFirestore.instance
                              .collection('flats')
                              .where('code', isEqualTo: code)
                              .limit(1)
                              .get();
                          
                          if (query.docs.isEmpty) {
                            throw Exception('Flat not found with code: $code');
                          }

                          DocumentSnapshot flatDoc = query.docs.first;
                          Map<String, dynamic> data = flatDoc.data() as Map<String, dynamic>;
                          String flatId = flatDoc.id;
                          String flatName = data['name'] ?? "Flat";
                          
                          // More robust field check
                          String? flatPassword;
                          try {
                            flatPassword = flatDoc.get('password');
                          } catch (e) {
                            flatPassword = null;
                          }
                          
                          bool hasPassword = flatPassword != null && flatPassword.isNotEmpty;
                          

                          UserModel userModel = UserModel(
                              uid: firebaseUser.uid, 
                              email: firebaseUser.email ?? '', 
                              flatIds: [],
                              createdAt: DateTime.now() 
                          );

                          String? pass;
                          if (hasPassword) {
                            // Check if already a member? If already a member, maybe skip?
                            // But for "Join", let's always ask if has password for simplicity.
                            pass = await _showPasswordDialog(flatName);
                            if (pass == null) {
                              setState(() => loading = false);
                              return;
                            }
                          }

                          await _flatService.joinFlat(code: code, user: userModel, providedPassword: pass);
                          // Success! Wrapper will handle navigation.
                        } catch (e) {
                          if (mounted) {
                            setState(() => loading = false);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                          }
                        }
                      },
                      child: const Text('Join Flat'),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CreateFlatScreen()),
                        );
                      },
                      child: const Text('Create a new Flat instad'),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              const Divider(),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text("Or join a public flat:", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: StreamBuilder<List<dynamic>>( // using dynamic to avoid import issues if any, but ideally FlatModel
                  stream: _flatService.getPublicFlats(),
                  builder: (context, snapshot) {
                     if (snapshot.connectionState == ConnectionState.waiting) {
                       return const Center(child: CircularProgressIndicator());
                     }
                     if (!snapshot.hasData || snapshot.data!.isEmpty) {
                       return const Text("No flats found.");
                     }
                     
                     var flats = snapshot.data!;
                     return ListView.builder(
                       itemCount: flats.length,
                       itemBuilder: (context, index) {
                         var flat = flats[index];
                         bool hasPassword = flat.password != null && (flat.password as String).isNotEmpty;
                         
                         return ListTile(
                           title: Text(flat.name),
                            subtitle: Text("Members: ${flat.memberCount}"),
                           trailing: Icon(hasPassword ? Icons.lock : Icons.arrow_forward),
                            onTap: () async {
                               User? user = FirebaseAuth.instance.currentUser;
                               if (user == null) return;
                               
                               // Always ask for the flat code as password when joining from public list
                               String? enteredCode = await showDialog<String>(
                                 context: context,
                                 builder: (context) {
                                   String code = '';
                                   return AlertDialog(
                                     title: Text('Join "${flat.name}"'),
                                     content: Column(
                                       mainAxisSize: MainAxisSize.min,
                                       children: [
                                         const Text('Enter the 6-character flat code to join:'),
                                         const SizedBox(height: 10),
                                         TextField(
                                           decoration: const InputDecoration(labelText: 'Flat Code'),
                                           onChanged: (val) => code = val.toUpperCase(),
                                         ),
                                       ],
                                     ),
                                     actions: [
                                       TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                       ElevatedButton(
                                         onPressed: () => Navigator.pop(context, code),
                                         child: const Text('Join'),
                                       ),
                                     ],
                                   );
                                 },
                               );
                               
                               if (enteredCode == null || enteredCode.isEmpty) return;
                               
                               // Verify the code matches
                               if (enteredCode != flat.code) {
                                 if (mounted) {
                                   ScaffoldMessenger.of(context).showSnackBar(
                                     const SnackBar(content: Text('Incorrect flat code!'))
                                   );
                                 }
                                 return;
                               }

                               if (mounted) setState(() => loading = true);
                               try {
                                  UserModel userModel = UserModel(
                                     uid: user.uid, 
                                     email: user.email ?? '', 
                                     flatIds: [],
                                     createdAt: DateTime.now() 
                                  );
                                  await _flatService.joinFlat(code: flat.code, user: userModel, providedPassword: flat.password);
                               } catch (e) {
                                  if (mounted) {
                                    setState(() => loading = false);
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
        ),
      ),
    );
  }
}
