// models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String name;
  final String email;
  final String phoneNumber;
  final DateTime registrationDate;
  final DateTime lastActiveDate;
  final String deviceId;
  final String deviceToken;
  final bool isSubscribed;
  final String? uid; // Added UID for better user tracking

  UserModel({
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.registrationDate,
    required this.lastActiveDate,
    required this.deviceId,
    required this.deviceToken,
    this.isSubscribed = false,
    this.uid,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'registrationDate': Timestamp.fromDate(registrationDate),
      'lastActiveDate': Timestamp.fromDate(lastActiveDate),
      'deviceId': deviceId,
      'deviceToken': deviceToken,
      'isSubscribed': isSubscribed,
      'uid': uid,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      registrationDate: map['registrationDate'] is Timestamp
          ? (map['registrationDate'] as Timestamp).toDate()
          : DateTime.parse(map['registrationDate'].toString()),
      lastActiveDate: map['lastActiveDate'] is Timestamp
          ? (map['lastActiveDate'] as Timestamp).toDate()
          : DateTime.parse(map['lastActiveDate'].toString()),
      deviceId: map['deviceId'] ?? '',
      deviceToken: map['deviceToken'] ?? '',
      isSubscribed: map['isSubscribed'] ?? false,
      uid: map['uid'],
    );
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? phoneNumber,
    DateTime? registrationDate,
    DateTime? lastActiveDate,
    String? deviceId,
    String? deviceToken,
    bool? isSubscribed,
    String? uid,
  }) {
    return UserModel(
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      registrationDate: registrationDate ?? this.registrationDate,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      deviceId: deviceId ?? this.deviceId,
      deviceToken: deviceToken ?? this.deviceToken,
      isSubscribed: isSubscribed ?? this.isSubscribed,
      uid: uid ?? this.uid,
    );
  }
}