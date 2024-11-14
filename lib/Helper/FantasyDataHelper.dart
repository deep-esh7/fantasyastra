import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/FantasyMatchListModel.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'FilterOptions.dart';
import 'TimeUtils.dart';




class FantasyMatchDataHelper {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String collectionName = 'Fantasy Matches List';

  // Connection check with retry mechanism
  Future<bool> waitForConnection() async {
    int retries = 0;
    const maxRetries = 3;

    while (retries < maxRetries) {
      try {
        print('Attempting to connect to Firestore (Attempt ${retries + 1}/$maxRetries)');
        await _firestore.collection(collectionName)
            .limit(1)
            .get(const GetOptions(source: Source.server));
        print('Connection successful');
        return true;
      } catch (e) {
        print('Connection attempt failed: $e');
        retries++;
        if (retries < maxRetries) {
          print('Waiting before retry...');
          await Future.delayed(Duration(seconds: 2 * retries));
        }
      }
    }
    return false;
  }



  // Create new match
  Future<void> createMatch(String matchName, FantasyMatchListModel match) async {
    try {
      print('Creating match: $matchName');
      await _firestore
          .collection(collectionName)
          .doc(matchName)
          .set(match.toMap());
      print('Match created successfully');
    } catch (e) {
      print('Error creating match: $e');
      throw Exception('Failed to create match: $e');
    }
  }



  // Update fields
  Future<void> updateMatchFields(String matchName, Map<String, dynamic> fields) async {
    try {
      print('Updating fields for match: $matchName');
      print('Fields to update: $fields');
      await _firestore.collection(collectionName).doc(matchName).update(fields);
      print('Fields updated successfully');
    } catch (e) {
      print('Error updating fields: $e');
      throw Exception('Failed to update match fields: $e');
    }
  }




  // Upload head to head image
  Future<void> uploadHeadToHeadImage(String matchName, Uint8List imageData) async {
    final cloudFunctionUrl = 'https://uploadheadtoheadimage-vhaafjlbna-el.a.run.app';

    try {
      print('Uploading head to head image for match: $matchName');

      final base64Image = base64Encode(imageData);
      final response = await http.post(
        Uri.parse(cloudFunctionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'matchName': matchName,
          'imageData': base64Image,
        }),
      );

      if (response.statusCode == 200) {
        print('Head to head image uploaded successfully');
      } else {
        print('Failed to upload head to head image: ${response.body}');
        throw Exception('Failed to upload image: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  // Upload mega team image
  Future<void> uploadMegaTeamImage(String matchName, Uint8List imageData) async {
    final cloudFunctionUrl = 'https://uploadmegateamimage-vhaafjlbna-el.a.run.app'; // Replace with your Cloud Function URL

    try {
      print('Uploading mega team image for match: $matchName');

      final base64Image = base64Encode(imageData);
      final response = await http.post(
        Uri.parse(cloudFunctionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'matchName': matchName,
          'imageData': base64Image,
        }),
      );

      if (response.statusCode == 200) {
        print('Mega team image uploaded successfully');
      } else {
        print('Failed to upload mega team image: ${response.body}');
        throw Exception('Failed to upload image: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
      throw Exception('Failed to upload image: $e');
    }
  }








  // Upload head to head image
  Future<void> uploadAndUpdateHeadToHeadImage(String matchName, Uint8List imageData) async {
    try {
      print('Uploading head to head image for match: $matchName');
      final storageRef = _storage
          .ref()
          .child('match_images')
          .child('head_to_head')
          .child('$matchName.jpg');

      await storageRef.putData(
        imageData,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final imageUrl = await storageRef.getDownloadURL();
      print('Image uploaded successfully. URL: $imageUrl');

      await _firestore.collection(collectionName).doc(matchName).update({
        'headToHeadTeamImageUrl': imageUrl,
        'lastUpdateHeadToHeadTime': DateTime.now().toIso8601String(),
      });
      print('Head to head image updated successfully');
    } catch (e) {
      print('Error uploading head to head image: $e');
      throw Exception('Failed to upload head to head image: $e');
    }
  }

  // Upload mega team image
  Future<void> uploadAndUpdateMegaTeamImage(String matchName, Uint8List imageData) async {
    try {
      print('Uploading mega team image for match: $matchName');
      final storageRef = _storage
          .ref()
          .child('match_images')
          .child('mega_team')
          .child('$matchName.jpg');

      await storageRef.putData(
        imageData,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final imageUrl = await storageRef.getDownloadURL();
      print('Image uploaded successfully. URL: $imageUrl');

      await _firestore.collection(collectionName).doc(matchName).update({
        'megaTeamImageUrl': imageUrl,
        'lastUpdateMegaContestTime': DateTime.now().toIso8601String(),
      });
      print('Mega team image updated successfully');
    } catch (e) {
      print('Error uploading mega team image: $e');
      throw Exception('Failed to upload mega team image: $e');
    }
  }
  // Get single match
  Future<FantasyMatchListModel?> getMatch(String matchName) async {
    try {
      print('Fetching match: $matchName');
      final doc = await _firestore.collection(collectionName).doc(matchName).get();

      if (doc.exists) {
        print('Match found');
        return FantasyMatchListModel.fromMap(doc.data()!);
      }
      print('Match not found');
      return null;
    } catch (e) {
      print('Error fetching match: $e');
      throw Exception('Failed to get match: $e');
    }
  }

  // Get filtered matches
  Stream<List<FantasyMatchListModel>> getFilteredMatches({List<QueryFilter>? filters}) {
    Query query = _firestore.collection(collectionName);

    if (filters != null) {
      for (var filter in filters) {
        switch (filter.operator) {
          case FilterOperator.equals:
            query = query.where(filter.fieldName, isEqualTo: filter.value);
            break;
          case FilterOperator.greaterThan:
            query = query.where(filter.fieldName, isGreaterThan: filter.value);
            break;
          case FilterOperator.lessThan:
            query = query.where(filter.fieldName, isLessThan: filter.value);
            break;
          case FilterOperator.whereIn:
            query = query.where(filter.fieldName, whereIn: filter.value);
            break;
          case FilterOperator.arrayContains:
            query = query.where(filter.fieldName, arrayContains: filter.value);
            break;
        }
      }
    }

    return query.snapshots().map((snapshot) {
      final results = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        try {
          return FantasyMatchListModel.fromMap(data);
        } catch (e) {
          print('Error converting document ${doc.id}: $e');
          rethrow;
        }
      }).toList();

      results.sort((a, b) {
        final aMinutes = TimeUtils.getMinutesFromMatchTime(a.matchTime);
        final bMinutes = TimeUtils.getMinutesFromMatchTime(b.matchTime);
        return aMinutes.compareTo(bMinutes);
      });

      return results;
    });
  }




  // Get all matches
  Stream<List<FantasyMatchListModel>> getAllMatches() {
    return getFilteredMatches();
  }

  // Get active matches
  Stream<List<FantasyMatchListModel>> getActiveMatches() {
    return getFilteredMatches(
      filters: [
        QueryFilter(
          fieldName: 'isMatchStarted',
          operator: FilterOperator.equals,
          value: false,
        ),
      ],
    );
  }

  // Get a specific match as a stream
  Stream<FantasyMatchListModel?> getMatchStream(String matchName) {
    return _firestore.collection(collectionName).doc(matchName).snapshots().map((docSnapshot) {
      if (docSnapshot.exists) {
        return FantasyMatchListModel.fromMap(docSnapshot.data()!);
      }
      return null;
    });
  }

  // Get custom sorted matches
  Stream<List<FantasyMatchListModel>> getSortedMatches({
    List<QueryFilter>? filters,
    bool ascending = true,
  }) {
    return getFilteredMatches(filters: filters).map((matches) {
      matches.sort((a, b) {
        final aMinutes = TimeUtils.getMinutesFromMatchTime(a.matchTime);
        final bMinutes = TimeUtils.getMinutesFromMatchTime(b.matchTime);
        return ascending ? aMinutes.compareTo(bMinutes) : bMinutes.compareTo(aMinutes);
      });
      return matches;
    });
  }
}
