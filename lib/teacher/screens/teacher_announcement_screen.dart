import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// announcements_screen.dart
class AnnouncementsScreen extends StatefulWidget {
  @override
  _AnnouncementsScreenState createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Announcements'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showAddAnnouncementDialog(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('announcements')
            .where('teacherId', isEqualTo: user?.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final announcements = snapshot.data?.docs ?? [];

          if (announcements.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.campaign, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No announcements yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _showAddAnnouncementDialog(),
                    child: Text('Create Announcement'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              final announcement = announcements[index].data() as Map<String, dynamic>;
              final createdAt = (announcement['createdAt'] as Timestamp?)?.toDate();
              
              return Card(
                margin: EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              announcement['title'] ?? 'Untitled Announcement',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          PopupMenuButton(
                            itemBuilder: (context) => [
                              PopupMenuItem(child: Text('Edit'), value: 'edit'),
                              PopupMenuItem(child: Text('Delete'), value: 'delete'),
                            ],
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showEditAnnouncementDialog(announcements[index].id, announcement);
                              } else if (value == 'delete') {
                                _deleteAnnouncement(announcements[index].id);
                              }
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(announcement['content'] ?? 'No content'),
                      SizedBox(height: 8),
                      Text(
                        'Posted: ${createdAt != null ? "${createdAt.day}/${createdAt.month}/${createdAt.year}" : "Unknown"}',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddAnnouncementDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create Announcement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: contentController,
              decoration: InputDecoration(labelText: 'Content'),
              maxLines: 5,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty && contentController.text.isNotEmpty) {
                await FirebaseFirestore.instance.collection('announcements').add({
                  'title': titleController.text,
                  'content': contentController.text,
                  'teacherId': user?.uid,
                  'teacherName': user?.displayName ?? 'Unknown Teacher',
                  'createdAt': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
              }
            },
            child: Text('Post'),
          ),
        ],
      ),
    );
  }

  void _showEditAnnouncementDialog(String announcementId, Map<String, dynamic> announcement) {
    final titleController = TextEditingController(text: announcement['title']);
    final contentController = TextEditingController(text: announcement['content']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Announcement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: contentController,
              decoration: InputDecoration(labelText: 'Content'),
              maxLines: 5,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty && contentController.text.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('announcements')
                    .doc(announcementId)
                    .update({
                  'title': titleController.text,
                  'content': contentController.text,
                });
                Navigator.pop(context);
              }
            },
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  void _deleteAnnouncement(String announcementId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Announcement'),
        content: Text('Are you sure you want to delete this announcement?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('announcements')
                  .doc(announcementId)
                  .delete();
              Navigator.pop(context);
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
}