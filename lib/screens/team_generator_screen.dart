import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../Helper/FantasyDataHelper.dart';

class TeamGeneratorScreen extends StatefulWidget {
  final String matchName;
  final String? headToheadImagePath;
  final String? megaContestImagePath;

  TeamGeneratorScreen({
    required this.matchName,
    this.headToheadImagePath,
    this.megaContestImagePath,
  });

  @override
  _TeamGeneratorScreenState createState() => _TeamGeneratorScreenState();
}

class _TeamGeneratorScreenState extends State<TeamGeneratorScreen> {
  final FantasyMatchDataHelper _dataHelper = FantasyMatchDataHelper();
  final ImagePicker _picker = ImagePicker();
  String? headToHeadImageBase64;
  String? megaContestImageBase64;
  bool isUploading = false;

  Future<void> _uploadImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          isUploading = true;
        });

        Uint8List imageData = await pickedFile.readAsBytes();
        String base64Image = base64Encode(imageData);

        if (widget.headToheadImagePath != null) {
          await _dataHelper.uploadHeadToHeadImage(widget.matchName, imageData);
          setState(() {
            headToHeadImageBase64 = base64Image;
          });
        } else if (widget.megaContestImagePath != null) {
          await _dataHelper.uploadMegaTeamImage(widget.matchName, imageData);
          setState(() {
            megaContestImageBase64 = base64Image;
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image uploaded successfully!')),
        );
      }
    } catch (e) {
      debugPrint('$e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isUploading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeImages();
  }

  void _initializeImages() {
    setState(() {
      headToHeadImageBase64 = widget.headToheadImagePath;
      megaContestImageBase64 = widget.megaContestImagePath;
    });
  }

  Widget _buildImageFromBase64(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return Container(
        child: Image.asset("assets/comingsoon.jpeg", fit: BoxFit.cover),
      );
    }

    try {
      final String pureBase64 = base64String.contains(',')
          ? base64String.split(',')[1]
          : base64String;

      return Image.memory(
        base64Decode(pureBase64),
        fit: BoxFit.fill,
        alignment: Alignment.center,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading image: $error');
          return Container(color: Colors.green);
        },
      );
    } catch (e) {
      print('Error decoding base64: $e');
      return Container(color: Colors.green);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFFb34d46),
        automaticallyImplyLeading: false,
        title: Text(
          '${widget.matchName}',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.upload, color: Colors.white),
            onPressed: isUploading ? null : _uploadImage, // Disable button while uploading
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(

                    child: Text("FANTASY AI GENERATED TEAM", style: TextStyle(

                        color: Colors.black,fontWeight: FontWeight.w500,
                      fontSize: 22
                    ),),
                  ),

                  Center(
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.75,
                      width: MediaQuery.of(context).size.width * 0.8,

                      alignment: Alignment.center,
                      child: Card(
                        elevation: 10,
                        child: _buildImageFromBase64(
                          headToHeadImageBase64 ?? megaContestImageBase64,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isUploading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: Color(0xFFb34d46),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Uploading Image...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
