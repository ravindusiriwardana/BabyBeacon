import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/baby_monitor_service.dart'; // Ensure correct path
import 'profile_page.dart'; // Ensure correct path to your profile page

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? babyData;
  bool isLoading = true;
  bool hasProfile = false;

  // 🔹 Real-time Emotion State Variables
  String _currentMood = "Monitoring...";
  double _confidence = 0.0;
  bool _isMonitorConnected = false;

  @override
  void initState() {
    super.initState();
    _loadBabyProfile();
    
    // 🔹 Start Listening to WebSocket
    _connectToBabyMonitor();
  }

  @override
  void dispose() {
    // Optional: Disconnect when leaving page, or keep it running if you want background monitoring
    // BabyMonitorService().disconnect(); 
    super.dispose();
  }

  void _connectToBabyMonitor() {
    BabyMonitorService().connect(callback: (data) {
      if (mounted) {
        setState(() {
          // Format the mood string (e.g., "crying" -> "Crying")
          String rawMood = data['emotion'] ?? "Unknown";
          _currentMood = rawMood[0].toUpperCase() + rawMood.substring(1);
          
          // Handle confidence
          _confidence = (data['confidence'] ?? 0.0).toDouble();
          _isMonitorConnected = true;
        });
      }
    });
  }

  // 🔹 Helper to get color based on mood
  Color _getMoodColor(String mood) {
    mood = mood.toLowerCase();
    if (mood.contains('cry')) return Colors.red;
    if (mood.contains('laugh') || mood.contains('happy')) return Colors.green;
    if (mood.contains('silence') || mood.contains('sleep')) return Colors.blue;
    if (mood.contains('noise')) return Colors.orange;
    return Colors.pink; // Default
  }

  // 🔹 Helper to get icon based on mood
  String _getMoodIcon(String mood) {
    mood = mood.toLowerCase();
    if (mood.contains('cry')) return '😭';
    if (mood.contains('laugh') || mood.contains('happy')) return '😄';
    if (mood.contains('silence') || mood.contains('sleep')) return '😴';
    if (mood.contains('noise')) return '🔊';
    return '👂'; // Default/Listening
  }

  Future<void> _loadBabyProfile() async {
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
          if (doc.exists) {
            babyData = doc.data()!;
            hasProfile = true;
          } else {
            hasProfile = false;
          }
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
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
    BabyMonitorService().disconnect(); // Disconnect WS on logout
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  void _navigateToProfile() {
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => const BabyProfilePage())
    ).then((_) => _loadBabyProfile());
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
      appBar: AppBar(
        title: Text(
          hasProfile ? '👶 ${babyData!['name']}' : '👶 $parentName\'s Baby',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.pink[400],
        foregroundColor: Colors.white,
        actions: [
          // 🆕 EDIT PROFILE ICON BUTTON ADDED HERE
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Edit Profile',
            onPressed: _navigateToProfile,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadBabyProfile,
        color: Colors.pink[400],
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER SECTION ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.pink[400]!, Colors.purple[400]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink.withValues(alpha: 0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.child_care, size: 58, color: Colors.pink),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      hasProfile ? babyData!['name'] : 'Baby Profile',
                      style: const TextStyle(
                          fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        age,
                        style: const TextStyle(
                            fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // --- STATISTICS HEADER ---
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('📊', style: TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Today\'s Statistics',
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold, color: Colors.purple),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- STAT CARDS ---
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard('🥛', 'Feedings', '0', Colors.green, 'Tap to log'),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard('🛌', 'Sleep', '0h 0m', Colors.blue, 'Tap to log'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildStatCard('💙', 'Diapers', '0', Colors.orange, 'Tap to log'),
                  ),
                  const SizedBox(width: 16),
                  
                  // 🔹 DYNAMIC MOOD CARD
                  Expanded(
                    child: _buildStatCard(
                      _getMoodIcon(_currentMood), // Dynamic Icon
                      'Current Mood',
                      _currentMood, // Dynamic Text
                      _getMoodColor(_currentMood), // Dynamic Color
                      _isMonitorConnected 
                          ? 'Live • ${( _confidence * 100).toStringAsFixed(0)}% Match' 
                          : 'Connecting...', // Status text
                      isLive: true // Special styling flag
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 36),
              
              // Only showing growth if profile exists
              if (hasProfile) ...[
                 Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple[50],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('📈', style: TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Growth Metrics',
                      style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold, color: Colors.purple),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildGrowthMetric('📏', 'Height', '${babyData!['height']?.toStringAsFixed(1) ?? 0.0} cm', Colors.teal),
                      Container(width: 1.5, height: 60, color: Colors.grey[200]),
                      _buildGrowthMetric('⚖️', 'Weight', '${babyData!['weight']?.toStringAsFixed(1) ?? 0.0} kg', Colors.amber),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
              ],

              // Quick Actions Header
               Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('🚀', style: TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold, color: Colors.purple),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Quick Actions Grid - REMOVED PROFILE EDIT BUTTON FROM HERE
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2, // You can change this to 3 now if the items look too wide
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _buildActionCard(Icons.restaurant_rounded, 'Log Feeding', Colors.green, () {}),
                  _buildActionCard(Icons.bedtime_rounded, 'Log Sleep', Colors.blue, () {}),
                  _buildActionCard(Icons.child_care_rounded, 'Diaper Change', Colors.orange, () {}),
                  // Removed the Edit Profile button from here as requested
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 UPDATED STAT CARD WIDGET
  Widget _buildStatCard(
      String icon, String title, String value, Color color, String subtitle, {bool isLive = false}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isLive ? Border.all(color: color.withOpacity(0.3), width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: isLive ? color.withOpacity(0.1) : Colors.grey.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(icon, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isLive ? color : Colors.grey[800],
              ),
            ),
          ),
          const SizedBox(height: 6),
          if (isLive)
             Row(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 if (_isMonitorConnected)
                   Container(
                     margin: const EdgeInsets.only(right: 4),
                     width: 6,
                     height: 6,
                     decoration: const BoxDecoration(
                       color: Colors.red,
                       shape: BoxShape.circle,
                     ),
                   ),
                 Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
                 ),
               ],
             )
          else
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500),
            ),
        ],
      ),
    );
  }

  Widget _buildActionCard(IconData icon, String title, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrowthMetric(String icon, String title, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(icon, style: const TextStyle(fontSize: 28)),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800]),
        ),
      ],
    );
  }
}