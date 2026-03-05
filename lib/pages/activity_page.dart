import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent Activity'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('login_records')
            .where('uid', isEqualTo: user?.uid)
            .orderBy('loginTime', descending: true)
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
                  Icon(Icons.history_toggle_off, size: 64, color: colorScheme.outline),
                  const SizedBox(height: 16),
                  const Text('No activity history found.'),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              final time = (data['loginTime'] as Timestamp?)?.toDate();
              final method = data['method'] as String? ?? 'unknown';

              return Card(
                elevation: 0,
                color: colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.primaryContainer,
                    child: Icon(
                      method == 'google' 
                        ? FontAwesomeIcons.google 
                        : method == 'github' 
                        ? FontAwesomeIcons.github 
                        : Icons.email,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                  ),
                  title: Text('Login via ${method[0].toUpperCase()}${method.substring(1)}'),
                  subtitle: Text(
                    time != null 
                    ? '${time.day}/${time.month}/${time.year} ${time.hour}:${time.minute.toString().padLeft(2, '0')}' 
                    : 'Unknown time'
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 16),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
