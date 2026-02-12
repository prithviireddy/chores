import 'package:firebase_auth/firebase_auth.dart';
import 'package:flat_chore/models/user_model.dart';
import 'package:flat_chore/services/flat_service.dart';
import 'package:flutter/material.dart';

class CreateFlatScreen extends StatefulWidget {
  const CreateFlatScreen({super.key});

  @override
  State<CreateFlatScreen> createState() => _CreateFlatScreenState();
}

class _CreateFlatScreenState extends State<CreateFlatScreen> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String password = '';
  bool loading = false;
  
  final FlatService _flatService = FlatService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create a Flat')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Flat Name', 
                    hintText: 'e.g. "The Boys"',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val!.isEmpty ? 'Enter a name' : null,
                  onChanged: (val) => setState(() => name = val),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Joining Password (Optional)', 
                    hintText: 'Required for new members to join',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  onChanged: (val) => setState(() => password = val),
                ),
                const SizedBox(height: 30),
                if (loading) 
                  const CircularProgressIndicator() 
                else 
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() => loading = true);
                          try {
                            User? user = FirebaseAuth.instance.currentUser;
                            if (user != null) {
                               UserModel userModel = UserModel(
                                  uid: user.uid, 
                                  email: user.email ?? '', 
                                  flatIds: [],
                                  createdAt: DateTime.now() 
                               );
                               await _flatService.createFlat(
                                 name: name, 
                                 user: userModel, 
                                 password: password.isEmpty ? null : password
                               );
                               if (mounted) {
                                 Navigator.pop(context);
                               }
                            }
                          } catch (e) {
                             if (mounted) {
                               setState(() => loading = false);
                               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                             }
                          }
                        }
                      },
                      child: const Text('Create Flat'),
                    ),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
