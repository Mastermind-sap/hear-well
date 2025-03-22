
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'widgets.dart';

class ProfileContent extends StatelessWidget {
  final String profileImageUrl;
  final String username;
  final String email;
  final int maxUsageHours;
  final List<String> badges;
  final VoidCallback editProfile;
  const ProfileContent({super.key, 
  required this.profileImageUrl,
  required this.username,
  required this.email,
  required this.maxUsageHours,
  required this.badges,
  required this.editProfile,

  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey.shade900, Colors.grey.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Hero(
                    tag: 'profile-image',
                    child: Container(
                      padding: EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Colors.purple, Colors.blue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: profileImageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: CachedNetworkImage(
                              imageUrl: profileImageUrl,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => CircularProgressIndicator(),
                              errorWidget: (context, url, error) => Icon(Icons.person, size: 40, color: Colors.white),
                            ),
                          )
                        : CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.grey.shade700,
                            child: Icon(Icons.person, size: 40, color: Colors.white),
                          ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: TextStyle(
                            fontSize: 20, 
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          email,
                          style: TextStyle(
                            fontSize: 14, 
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: editProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit, size: 16),
                        SizedBox(width: 4),
                        Text("Edit"),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),
            
            // Stats Section
            Text(
              "Usage Statistics",
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.access_time_filled,
                    value: "$maxUsageHours",
                    label: "Maximum Usage (Hours)",
                    color: Colors.blueAccent,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    icon: Icons.calendar_today,
                    value: "14",
                    label: "Days Active",
                    color: Colors.greenAccent,
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),
            
            // Badges Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Badges",
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    "See All",
                    style: TextStyle(color: Colors.blueAccent),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: badges.isEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.emoji_events_outlined, color: Colors.amber, size: 24),
                          SizedBox(width: 8),
                          Text(
                            "Unlock Your First Badge",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Echo-Aid badges have been updated. Complete activities to earn new badges.",
                        style: TextStyle(
                          fontSize: 14, 
                          color: Colors.grey[400],
                        ),
                      ),
                      SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: 0.2,
                        backgroundColor: Colors.grey[700],
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                      ),
                    ],
                  )
                : Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: badges.map((badge) => Badges(badge: badge,)).toList(),
                  ),
            ),
            
            SizedBox(height: 20),
            
            // Device Section
            Text(
              "My Devices",
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 12),
            
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey[900],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.headphones, color: Colors.white, size: 32),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Echo Buds",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Connected",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.settings, color: Colors.grey),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}