// widgets/message_bubble.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:random_color/random_color.dart';

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isCurrentUser;
  final String userName;
  final DateTime? timestamp;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isCurrentUser,
    required this.userName,
    this.timestamp,
  }) : super(key: key);

  Widget _buildAvatar() {
    final randomColor = RandomColor();
    final backgroundColor = randomColor.randomColor(
      colorBrightness: ColorBrightness.dark,
      colorSaturation: ColorSaturation.highSaturation,
    );

    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : '?';

    return CircleAvatar(
      backgroundColor: backgroundColor,
      radius: 16,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  String _formatTime() {
    if (timestamp == null) return '';
    return DateFormat('hh:mm a').format(timestamp!);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isCurrentUser) ...[
            _buildAvatar(),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
              isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  userName.isEmpty ? 'Anonymous' : userName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isCurrentUser ? Theme.of(context).primaryColor : Colors.grey[300],
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isCurrentUser ? 20 : 0),
                      bottomRight: Radius.circular(isCurrentUser ? 0 : 20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        message,
                        style: TextStyle(
                          color: isCurrentUser ? Colors.white : Colors.black,
                        ),
                      ),
                      if (timestamp != null)
                        Text(
                          _formatTime(),
                          style: TextStyle(
                            fontSize: 10,
                            color: isCurrentUser ? Colors.white70 : Colors.black54,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: 8),
            _buildAvatar(),
          ],
        ],
      ),
    );
  }
}