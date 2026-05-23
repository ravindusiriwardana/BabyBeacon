import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/baby_monitor_service.dart';
import 'profile_page.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? babyData;
  bool isLoading = true;
  bool hasProfile = false;

  // Emotion
  String _currentMood = "Monitoring...";
  double _emotionConfidence = 0.0;

  // Posture
  String _currentPosture = "Detecting...";
  double _postureConfidence = 0.0;

  bool _isMonitorConnected = false;

  @override
  void initState() {
    super.initState();
    _loadBabyProfile();
    _connectToBabyMonitor();
  }

  void _connectToBabyMonitor() {
    BabyMonitorService().connect(callback: (data) {
      if (!mounted) return;

      setState(() {
        // Emotion
        String rawMood = data['emotion'] ?? "unknown";
        _currentMood = rawMood[0].toUpperCase() + rawMood.substring(1).toLowerCase();
        _emotionConfidence = (data['confidence'] ?? 0.0).toDouble();

        // Posture
        String rawPosture = data['posture'] ?? "unknown";
        _currentPosture = rawPosture[0].toUpperCase() + rawPosture.substring(1).toLowerCase();
        _postureConfidence = (data['posture_confidence'] ?? 0.0).toDouble();

        _isMonitorConnected = true;
      });
    });
  }

  Future<void> _loadBabyProfile() async {
    setState(() => isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) setState(() => isLoading = false);
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('babies')
          .doc(user.uid)
          .get();

      if (mounted) {
        setState(() {
          if (doc.exists && doc.data() != null) {
            babyData = doc.data()!;
            hasProfile = true;
          }
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String _calculateAge(String birthDate) {
    try {
      final birth = DateTime.parse(birthDate);
      final now = DateTime.now();
      final difference = now.difference(birth);
      final months = (difference.inDays / 30.44).floor();
      final days = difference.inDays % 30;

      if (months >= 12) {
        final years = months ~/ 12;
        final remainingMonths = months % 12;
        return '${years}y ${remainingMonths}m';
      } else if (months > 0) {
        return '$months months $days days';
      } else {
        return '$days days';
      }
    } catch (e) {
      return 'Not set';
    }
  }

  Future<void> _signOut(BuildContext context) async {
    BabyMonitorService().disconnect();
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BabyProfilePage()),
    ).then((_) => _loadBabyProfile());
  }

  // NEW: Navigate to Live Monitoring Tab
  void _navigateToLiveStream() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LiveMonitoringPage()),
    );
  }

  Color _getMoodColor() {
    final mood = _currentMood.toLowerCase();
    if (mood.contains('cry')) return Colors.red;
    if (mood.contains('laugh') || mood.contains('happy')) return Colors.green;
    if (mood.contains('silence') || mood.contains('sleep')) return Colors.blue;
    if (mood.contains('noise')) return Colors.orange;
    return Colors.pink;
  }

  String _getMoodIcon() {
    final mood = _currentMood.toLowerCase();
    if (mood.contains('cry')) return '😢';
    if (mood.contains('laugh') || mood.contains('happy')) return '😊';
    if (mood.contains('silence') || mood.contains('sleep')) return '😴';
    if (mood.contains('noise')) return '🔊';
    return '😐';
  }

  Color _getPostureColor() {
    final posture = _currentPosture.toLowerCase();
    if (posture.contains('sitting') || posture.contains('upright')) return Colors.green;
    if (posture.contains('lying') || posture.contains('supine')) return Colors.blue;
    if (posture.contains('crawling') || posture.contains('prone')) return Colors.orange;
    if (posture.contains('standing')) return Colors.purple;
    return Colors.grey;
  }

  String _getPostureIcon() {
    final posture = _currentPosture.toLowerCase();
    if (posture.contains('sitting')) return '🪑';
    if (posture.contains('lying') || posture.contains('supine')) return '🛏️';
    if (posture.contains('crawling') || posture.contains('prone')) return '🐛';
    if (posture.contains('standing')) return '🧍';
    return '❓';
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final String parentName = user?.displayName ?? user?.email?.split('@')[0] ?? 'Parent';
    final String age = babyData != null && babyData!['birthDate'] != null
        ? _calculateAge(babyData!['birthDate'])
        : 'Setup Required';

    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator(color: Colors.pink[400])),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: Colors.pink[400],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.pink[400]!, Colors.purple[300]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hello, $parentName 👋',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  hasProfile ? babyData!['name'] : 'Your Baby',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                _buildHeaderButton(Icons.edit_rounded, _navigateToProfile),
                                const SizedBox(width: 8),
                                _buildHeaderButton(Icons.logout_rounded, () => _signOut(context)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.cake_outlined, color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                age,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: RefreshIndicator(
              onRefresh: _loadBabyProfile,
              color: Colors.pink[400],
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LIVE MONITORING SECTION
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionHeader('📡 Live Monitoring', 'Real-time baby tracking'),
                        TextButton.icon(
                          onPressed: _navigateToLiveStream,
                          icon: const Icon(Icons.videocam_rounded, size: 18),
                          label: const Text('View Live'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.pink[400],
                            backgroundColor: Colors.pink[50],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    _buildModernLiveCard(
                      icon: _getMoodIcon(),
                      title: 'Current Mood',
                      value: _currentMood,
                      confidence: _emotionConfidence,
                      color: _getMoodColor(),
                      isConnected: _isMonitorConnected,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    _buildModernLiveCard(
                      icon: _getPostureIcon(),
                      title: 'Current Posture',
                      value: _currentPosture,
                      confidence: _postureConfidence,
                      color: _getPostureColor(),
                      isConnected: _isMonitorConnected,
                    ),

                    const SizedBox(height: 32),

                    _buildSectionHeader('📊 Today\'s Activity', 'Daily summary'),
                    const SizedBox(height: 16),
                    
                    _buildStatsGrid(),

                    const SizedBox(height: 32),

                    if (hasProfile) ...[
                      _buildSectionHeader('📈 Growth Tracking', 'Latest measurements'),
                      const SizedBox(height: 16),
                      _buildGrowthCard(),
                      const SizedBox(height: 32),
                    ],

                    _buildSectionHeader('⚡ Quick Actions', 'Log activities'),
                    const SizedBox(height: 16),
                    _buildQuickActionsGrid(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Existing UI Helper Methods...
  Widget _buildHeaderButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildModernLiveCard({
    required String icon,
    required String title,
    required String value,
    required double confidence,
    required Color color,
    required bool isConnected,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(icon, style: const TextStyle(fontSize: 32)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isConnected)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 4),
                            const Text('LIVE', style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
                const SizedBox(height: 4),
                Text(
                  isConnected ? '${(confidence * 100).toStringAsFixed(0)}% confidence' : 'Connecting...',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.15,
      children: [
        _buildStatCard('🍼', 'Feedings', '0', Colors.green),
        _buildStatCard('😴', 'Sleep', '0h 0m', Colors.blue),
        _buildStatCard('🩺', 'Diapers', '0', Colors.orange),
        _buildStatCard('🎯', 'Activity', 'Active', Colors.purple),
      ],
    );
  }

  Widget _buildStatCard(String icon, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 10),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildGrowthCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _buildGrowthMetric('📏', 'Height', '${babyData!['height']?.toStringAsFixed(1) ?? 0.0} cm', Colors.teal)),
          Container(width: 1, height: 60, color: Colors.grey[200]),
          Expanded(child: _buildGrowthMetric('⚖️', 'Weight', '${babyData!['weight']?.toStringAsFixed(1) ?? 0.0} kg', Colors.amber)),
        ],
      ),
    );
  }

  Widget _buildGrowthMetric(String icon, String title, String value, Color color) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 32)),
        const SizedBox(height: 8),
        Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildQuickActionsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.95,
      children: [
        _buildActionCard(Icons.restaurant_rounded, 'Feed', Colors.green, () {}),
        _buildActionCard(Icons.bedtime_rounded, 'Sleep', Colors.blue, () {}),
        _buildActionCard(Icons.child_care_rounded, 'Diaper', Colors.orange, () {}),
      ],
    );
  }

  Widget _buildActionCard(IconData icon, String title, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.06),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(height: 8),
              Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[800]), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// NEW LIVE MONITORING PAGE
// -----------------------------------------------------------------------------
class LiveMonitoringPage extends StatelessWidget {
  const LiveMonitoringPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Live Stream'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Placeholder for the actual WebRTC/Video stream
            Container(
              width: double.infinity,
              height: 300,
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.pink.withOpacity(0.5)),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 64),
                  SizedBox(height: 16),
                  Text(
                    'Initializing Video Stream...',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Once your camera device is active, the live feed will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}