import 'package:flutter/material.dart';
import 'package:hear_well/core/localization/app_localizations.dart';
import 'package:hear_well/core/localization/translation_helper.dart';
import 'package:hear_well/core/theme/app_gradients.dart';
import 'package:url_launcher/url_launcher.dart';

class HearingResourcesScreen extends StatelessWidget {
  const HearingResourcesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr("hearing_health_guide")),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.backgroundGradient(
            Theme.of(context).brightness,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCard(
                  context,
                  title: context.tr("part1_title"),
                  icon: Icons.volume_off,
                  color: Colors.red.shade600,
                  children: [
                    Text(
                      context.tr("part1_intro"),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),

                    Text(
                      context.tr("how_loud_title"),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      context.tr("how_loud_description"),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),

                    // Sound levels table
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black12 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Table(
                        border: TableBorder.all(
                          color:
                              isDark
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade300,
                          width: 1,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        columnWidths: const {
                          0: FlexColumnWidth(2),
                          1: FlexColumnWidth(1),
                          2: FlexColumnWidth(2),
                        },
                        defaultVerticalAlignment:
                            TableCellVerticalAlignment.middle,
                        children: _buildSoundLevelsTable(context),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      context.tr("protection_title"),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    _buildProtectionPoint(
                      context,
                      "prevent",
                      Icons.volume_down,
                    ),
                    _buildProtectionPoint(context, "protect", Icons.headphones),
                    _buildProtectionPoint(context, "plan", Icons.event_note),
                    _buildProtectionPoint(
                      context,
                      "provide_rest",
                      Icons.hourglass_bottom,
                    ),
                  ],
                ),

                _buildCard(
                  context,
                  title: context.tr("part2_title"),
                  icon: Icons.clean_hands,
                  color: Colors.blue.shade600,
                  children: [
                    Text(
                      context.tr("part2_intro"),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),

                    Text(
                      context.tr("ear_cleaning_donts"),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    _buildDontPoint(
                      context,
                      "dont_swabs",
                      Icons.do_not_disturb,
                    ),
                    _buildDontPoint(
                      context,
                      "dont_candles",
                      Icons.do_not_disturb,
                    ),
                    _buildDontPoint(
                      context,
                      "dont_sharp",
                      Icons.do_not_disturb,
                    ),
                    const SizedBox(height: 16),

                    Text(
                      context.tr("ear_cleaning_dos"),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    _buildDoPoint(context, "do_selfclean", Icons.check_circle),
                    _buildDoPoint(context, "do_outer", Icons.check_circle),
                    _buildDoPoint(
                      context,
                      "do_professional",
                      Icons.check_circle,
                    ),
                  ],
                ),

                _buildCard(
                  context,
                  title: context.tr("part3_title"),
                  icon: Icons.favorite,
                  color: Colors.green.shade600,
                  children: [
                    Text(
                      context.tr("part3_intro"),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),

                    _buildHealthPoint(
                      context,
                      "manage_conditions",
                      Icons.local_hospital,
                    ),
                    _buildHealthPoint(context, "dont_smoke", Icons.smoke_free),
                    _buildHealthPoint(
                      context,
                      "medication_awareness",
                      Icons.medication,
                    ),
                  ],
                ),

                _buildCard(
                  context,
                  title: context.tr("part4_title"),
                  icon: Icons.hearing,
                  color: Colors.purple.shade600,
                  children: [
                    Text(
                      context.tr("part4_intro"),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),

                    Text(
                      context.tr("signs_title"),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    _buildSignsList(context),
                    const SizedBox(height: 16),

                    Text(
                      context.tr("what_to_do_title"),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    _buildWhatToDoPoint(context, "dont_ignore", Icons.warning),
                    _buildWhatToDoPoint(context, "get_test", Icons.hearing),
                    _buildWhatToDoPoint(
                      context,
                      "consult_professional",
                      Icons.person,
                    ),
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.tr("sudden_loss_warning"),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                _buildCard(
                  context,
                  title: context.tr("action_plan_title"),
                  icon: Icons.checklist,
                  color: Colors.amber.shade700,
                  children: [
                    _buildActionItem(context, "action_baseline"),
                    _buildActionItem(context, "action_protect"),
                    _buildActionItem(context, "action_volume"),
                    _buildActionItem(context, "action_hygiene"),
                    _buildActionItem(context, "action_health"),
                    _buildActionItem(context, "action_signs"),
                  ],
                ),

                _buildCard(
                  context,
                  title: context.tr("sources_title"),
                  icon: Icons.library_books,
                  color: Colors.teal.shade600,
                  children: [
                    Text(
                      context.tr("sources_intro"),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),

                    _buildSourceLink(
                      context,
                      "World Health Organization (WHO)",
                      "https://www.who.int/health-topics/hearing-loss",
                    ),
                    _buildSourceLink(
                      context,
                      "National Institute on Deafness (NIDCD)",
                      "https://www.nidcd.nih.gov/health/noise-induced-hearing-loss",
                    ),
                    _buildSourceLink(
                      context,
                      "Centers for Disease Control and Prevention (CDC)",
                      "https://www.cdc.gov/nceh/hearing_loss/",
                    ),
                    _buildSourceLink(
                      context,
                      "American Speech-Language-Hearing Association",
                      "https://www.asha.org/public/hearing/",
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        context.tr("disclaimer"),
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color:
                              isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(color: color),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Card content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<TableRow> _buildSoundLevelsTable(BuildContext context) {
    return [
      // Header row
      TableRow(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              context.tr("sound_source"),
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              context.tr("decibels"),
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              context.tr("safe_time"),
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
      // Data rows
      _buildTableRow(context, "conversation", "60-70", "safe"),
      _buildTableRow(context, "traffic", "80-85", "8_hours"),
      _buildTableRow(context, "motorcycle", "95", "50_minutes"),
      _buildTableRow(context, "power_tools", "105", "5_minutes"),
      _buildTableRow(context, "concert", "110", "2_minutes"),
      _buildTableRow(context, "siren", "120+", "immediate_danger"),
    ];
  }

  TableRow _buildTableRow(
    BuildContext context,
    String soundKey,
    String dbLevel,
    String timeKey,
  ) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(context.tr("sound_$soundKey"), textAlign: TextAlign.left),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(dbLevel, textAlign: TextAlign.center),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(context.tr("time_$timeKey"), textAlign: TextAlign.center),
        ),
      ],
    );
  }

  Widget _buildProtectionPoint(
    BuildContext context,
    String key,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: Colors.red.shade700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr("${key}_title"),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(context.tr("${key}_description")),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDontPoint(BuildContext context, String key, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(child: Text(context.tr(key))),
        ],
      ),
    );
  }

  Widget _buildDoPoint(BuildContext context, String key, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(context.tr(key))),
        ],
      ),
    );
  }

  Widget _buildHealthPoint(BuildContext context, String key, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: Colors.green.shade700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr("${key}_title"),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(context.tr("${key}_description")),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignsList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSignsPoint(context, "sign_repeating"),
        _buildSignsPoint(context, "sign_understanding"),
        _buildSignsPoint(context, "sign_mumbling"),
        _buildSignsPoint(context, "sign_volume"),
        _buildSignsPoint(context, "sign_tinnitus"),
        _buildSignsPoint(context, "sign_tired"),
      ],
    );
  }

  Widget _buildSignsPoint(BuildContext context, String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(context.tr(key))),
        ],
      ),
    );
  }

  Widget _buildWhatToDoPoint(BuildContext context, String key, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.purple.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: Colors.purple.shade700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr("${key}_title"),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(context.tr("${key}_description")),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(BuildContext context, String key) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade800
                : Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade300, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: Colors.amber.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.tr(key),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceLink(BuildContext context, String name, String url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _launchURL(url),
        child: Row(
          children: [
            Icon(
              Icons.link,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }
}
