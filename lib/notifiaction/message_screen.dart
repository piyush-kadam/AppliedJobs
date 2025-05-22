import 'package:flutter/material.dart';

class MessageScreen extends StatelessWidget {
  final String id;
  final String? title;
  final String? body;
  final String? imageUrl;
  final String? senderName;

  const MessageScreen({
    Key? key,
    required this.id,
    this.title,
    this.body,
    this.imageUrl,
    this.senderName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final blue = Colors.blue.shade700;

    return Scaffold(
      appBar: AppBar(
        title: Text(title ?? 'Message $id'),
        backgroundColor: blue,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            if (imageUrl != null && imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl!,
                  height: 220,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return SizedBox(
                      height: 220,
                      child: Center(
                        child: CircularProgressIndicator(
                          value:  
                              progress.expectedTotalBytes != null
                                  ? progress.cumulativeBytesLoaded /
                                      progress.expectedTotalBytes!
                                  : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder:
                      (context, error, stackTrace) => const Icon(
                        Icons.broken_image,
                        size: 100,
                        color: Colors.grey,
                      ),
                ),
              ),
            const SizedBox(height: 15),
            Text(
              "Sender:",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: blue,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              senderName ?? 'Unknown',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Text(
              "Message:",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: blue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body ?? 'No content',
              style: const TextStyle(fontSize: 16, height: 1.4),
            ),
            const SizedBox(height: 10),
            Divider(color: Colors.grey.shade300),
            const SizedBox(height: 12),
            // Text(
            //   "Message ID: $id",
            //   style: TextStyle(
            //     fontSize: 12,
            //     color: Colors.grey.shade600,
            //     fontStyle: FontStyle.italic,
            //   ),
            //   textAlign: TextAlign.right,
            // ),
          ],
        ),
      ),
    );
  }
}
