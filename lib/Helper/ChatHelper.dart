
// helper/chat_helper.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/UserModel.dart';

class ChatHelper {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String chatCollection = 'chat_messages';

  // Get messages stream grouped by date
  Stream<Map<String, List<QueryDocumentSnapshot>>> getMessagesGroupedByDate() {
    return _firestore
        .collection(chatCollection)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      final Map<String, List<QueryDocumentSnapshot>> groupedMessages = {};

      for (var doc in snapshot.docs) {
        final timestamp = (doc.data()['timestamp'] as Timestamp?)?.toDate();
        if (timestamp != null) {
          final date = DateFormat('MMMM dd, yyyy').format(timestamp);
          if (!groupedMessages.containsKey(date)) {
            groupedMessages[date] = [];
          }
          groupedMessages[date]!.add(doc);
        }
      }

      return groupedMessages;
    });
  }

  // Send a new message
  Future<void> sendMessage({
    required String message,
    required UserModel? user,
  }) async {
    if (message.trim().isEmpty || user == null) {
      throw Exception('Message cannot be empty or user not found');
    }

    try {
      await _firestore.collection(chatCollection).add({
        'text': message.trim(),
        'userId': user.uid ?? 'anonymous',
        'userName': user.name.isNotEmpty ? user.name : 'Anonymous User',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sending message: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  // Delete a message
  Future<void> deleteMessage(String messageId) async {
    try {
      await _firestore.collection(chatCollection).doc(messageId).delete();
    } catch (e) {
      print('Error deleting message: $e');
      throw Exception('Failed to delete message: $e');
    }
  }

  // Update a message
  Future<void> updateMessage(String messageId, String newText) async {
    try {
      await _firestore.collection(chatCollection).doc(messageId).update({
        'text': newText.trim(),
        'edited': true,
        'editedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating message: $e');
      throw Exception('Failed to update message: $e');
    }
  }
}

