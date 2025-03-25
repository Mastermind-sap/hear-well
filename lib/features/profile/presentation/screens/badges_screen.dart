import 'package:hear_well/core/theme/app_theme.dart';
import 'package:hear_well/features/profile/presentation/screens/widgets/gradient_container.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
// Add translation imports
import 'package:hear_well/core/localization/translation_helper.dart';

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _badges = [];

  @override
  void initState() {
    super.initState();
    _loadBadges();
  }

  Future<void> _loadBadges() async {
    // Simulate loading delay
    await Future.delayed(Duration(seconds: 2));

    // Example badges data - in a real app, this would come from an API or database
    setState(() {
      _badges = [
        {
          'name': 'First Steps',
          'description': 'Complete your first hearing test',
          'icon': Icons.accessibility_new,
          'color': Colors.blue,
          'earned': true,
          'progress': 1.0,
        },
        {
          'name': 'Daily Listener',
          'description': 'Use the app for 7 consecutive days',
          'icon': Icons.calendar_today,
          'color': Colors.green,
          'earned': true,
          'progress': 1.0,
        },
        {
          'name': 'Sound Explorer',
          'description': 'Try all sound environments',
          'icon': Icons.surround_sound,
          'color': Colors.purple,
          'earned': false,
          'progress': 0.6,
        },
        {
          'name': 'Sharing is Caring',
          'description': 'Share the app with a friend',
          'icon': Icons.share,
          'color': Colors.orange,
          'earned': false,
          'progress': 0.0,
        },
        {
          'name': 'Hearing Expert',
          'description': 'Complete 10 hearing tests',
          'icon': Icons.psychology,
          'color': Colors.red,
          'earned': false,
          'progress': 0.3,
        },
        {
          'name': 'Night Owl',
          'description': 'Use the app after midnight',
          'icon': Icons.nightlight_round,
          'color': Colors.indigo,
          'earned': true,
          'progress': 1.0,
        },
      ];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.black : Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          context.tr('my_badges'),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        elevation: 0,
      ),
      body: _isLoading ? _buildLoadingState() : _buildBadgesList(),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Shimmer.fromColors(
        baseColor:
            Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[800]!
                : Colors.grey[300]!,
        highlightColor:
            Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[700]!
                : Colors.grey[100]!,
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: 6,
          itemBuilder: (context, index) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBadgesList() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr("badges_unlock"),
            style: TextStyle(
              fontSize: 16,
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[400]
                      : Colors.grey[700],
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _badges.length,
              itemBuilder: (context, index) {
                final badge = _badges[index];
                return _buildBadgeCard(badge);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCard(Map<String, dynamic> badge) {
    final bool earned = badge['earned'];
    final Color badgeColor = badge['color'];
    final IconData badgeIcon = badge['icon'];

    return GestureDetector(
      onTap: () => _showBadgeDetails(badge),
      child: Container(
        decoration: BoxDecoration(
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[850]
                  : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
          border:
              earned
                  ? Border.all(color: badgeColor.withOpacity(0.5), width: 2)
                  : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    earned
                        ? badgeColor.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                badgeIcon,
                color: earned ? badgeColor : Colors.grey,
                size: 40,
              ),
            ),
            SizedBox(height: 12),
            Text(
              badge['name'],
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color:
                    earned
                        ? Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87
                        : Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LinearProgressIndicator(
                value: badge['progress'],
                backgroundColor: Colors.grey.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  earned ? badgeColor : Colors.grey,
                ),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            SizedBox(height: 8),
            Text(
              earned
                  ? context.tr("completed")
                  : "${(badge['progress'] * 100).toInt()}%",
              style: TextStyle(
                fontSize: 12,
                color: earned ? badgeColor : Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBadgeDetails(Map<String, dynamic> badge) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[900]
                    : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20),

              // Badge Icon
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color:
                      badge['earned']
                          ? badge['color'].withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  badge['icon'],
                  color: badge['earned'] ? badge['color'] : Colors.grey,
                  size: 60,
                ),
              ),
              SizedBox(height: 16),

              // Badge Name
              Text(
                badge['name'],
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),

              // Badge Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  badge['description'],
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 24),

              // Progress
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.tr("progress"),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          "${(badge['progress'] * 100).toInt()}%",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color:
                                badge['earned'] ? badge['color'] : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: badge['progress'],
                      backgroundColor: Colors.grey.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        badge['earned'] ? badge['color'] : Colors.grey,
                      ),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),

              // Status
              Container(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color:
                      badge['earned']
                          ? badge['color'].withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  badge['earned']
                      ? context.tr("badge_earned")
                      : context.tr("badge_locked"),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: badge['earned'] ? badge['color'] : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
