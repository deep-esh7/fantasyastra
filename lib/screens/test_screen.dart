import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firebase Test')),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('Fantasy Matches List')
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          // Debug prints
          print('Connection State: ${snapshot.connectionState}');
          print('Has Data: ${snapshot.hasData}');
          print('Has Error: ${snapshot.hasError}');
          if (snapshot.hasError) print('Error: ${snapshot.error}');

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No Documents Found'));
          }

          // Print all documents for debugging
          for (var doc in snapshot.data!.docs) {
            print('Document ID: ${doc.id}');
            print('Document Data: ${doc.data()}');
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;

              return ListTile(
                title: Text(doc.id),
                subtitle: Text(data.toString()),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Manual fetch test
          try {
            print('\n=== Testing Direct Fetch ===');
            var collection = await FirebaseFirestore.instance
                .collection('Fantasy Matches List')
                .get();

            print('Documents found: ${collection.docs.length}');
            for (var doc in collection.docs) {
              print('Document ID: ${doc.id}');
              print('Data: ${doc.data()}\n');
            }
          } catch (e) {
            print('Fetch Error: $e');
          }
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}