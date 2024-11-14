// lib/widgets/team_display.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TeamDisplay extends StatelessWidget {
  final String teamName;
  final String teamFlag;

  const TeamDisplay({
    Key? key,
    required this.teamName,
    required this.teamFlag,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CachedNetworkImage(
          imageUrl: teamFlag,
          imageBuilder: (context, imageProvider) => CircleAvatar(
            radius: 30,
            backgroundColor: Colors.transparent,
            backgroundImage: imageProvider,
          ),
          placeholder: (context, url) => const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey,
            child: CircularProgressIndicator(),
          ),
          errorWidget: (context, url, error) => const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey,
            child: Icon(Icons.error),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          teamName,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}