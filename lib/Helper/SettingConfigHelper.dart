import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/SettingsConfigModel.dart';


class SettingConfigDataHelper {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;





  // Update the setting configuration in Firestore
  Future<void> updateSettingConfig(SettingConfigModel config) async {
    try {
      await _firestore.collection('Settings').doc('config').set(config.toMap());
    } catch (e) {
      print('Error updating setting config: $e');
    }
  }


  // Get the setting configuration from Firestore
  Future<SettingConfigModel?> getSettingConfig() async {
    try {
      DocumentSnapshot doc = await _firestore.collection('Settings').doc('config').get();
      if (doc.exists) {
        return SettingConfigModel.fromMap(doc.data() as Map<String, dynamic>);
      } else {
        return null;
      }
    } catch (e) {
      print('Error getting setting config: $e');
      return null;
    }
  }

}
