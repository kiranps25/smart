import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(home: AuthWrapper()));
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData) {
          return HomePage();
        }
        return LoginPage();
      },
    );
  }
}

class LoginPage extends StatelessWidget {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  Future<void> _login(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _email,
                decoration: InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: _password,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _login(context),
                child: Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Map<String, Map<String, dynamic>> _devices = {
    'LED_STATUS': {'name': 'Switch 1', 'icon': Icons.power},
    'LED_STATUS1': {'name': 'Switch 2', 'icon': Icons.power},
    'LED_STATUS2': {'name': 'Switch 3', 'icon': Icons.power},
    'LED_STATUS3': {'name': 'Switch 4', 'icon': Icons.power},
  };

  final Map<String, Timer?> _timers = {};
  final Map<String, int> _remainingTimes = {};
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    for (var key in _devices.keys) {
      _timers[key] = null;
      _remainingTimes[key] = 0;
    }
    _startPreciseScheduler();
  }

  void _startPreciseScheduler() {
    _checkScheduledTasks();
    Timer.periodic(Duration(seconds: 1), (_) => _checkScheduledTasks());
  }

  void _checkScheduledTasks() async {
    final now = DateTime.now();
    final formattedNow = DateFormat('HH:mm:ss').format(now);

    for (var key in _devices.keys) {
      try {
        final snapshot = await _dbRef.child(key).get();
        final data = snapshot.value;
        if (data is Map) {
          final map = Map<String, dynamic>.from(data);
          final scheduledOn = map['scheduled_on'] ?? '';
          final scheduledOff = map['scheduled_off'] ?? '';

          if (scheduledOn == formattedNow) {
            await _dbRef.child(key).update({'status': 1});
          } else if (scheduledOff == formattedNow) {
            await _dbRef.child(key).update({
              'status': 0,
              'scheduled_on': '',
              'scheduled_off': '',
            });
          }
        }
      } catch (e) {
        print('Error checking schedule: $e');
      }
    }
  }

  void _toggleDevice(String key, int status) {
    _dbRef.child(key).update({'status': status == 1 ? 0 : 1});
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  String _formatTime(int? seconds) {
    if (seconds == null || seconds <= 0) return '';
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _showScheduleDialog(String key) {
    TimeOfDay? onTime;
    TimeOfDay? offTime;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Set Schedule'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    onTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                  },
                  child: Text('Pick ON Time'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    offTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                  },
                  child: Text('Pick OFF Time'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (onTime != null && offTime != null) {
                    final now = DateTime.now();
                    final format = DateFormat('HH:mm:ss');
                    final onDate = DateTime(
                      now.year,
                      now.month,
                      now.day,
                      onTime!.hour,
                      onTime!.minute,
                    );
                    final offDate = DateTime(
                      now.year,
                      now.month,
                      now.day,
                      offTime!.hour,
                      offTime!.minute,
                    );
                    _dbRef.child(key).update({
                      'scheduled_on': format.format(onDate),
                      'scheduled_off': format.format(offDate),
                    });
                  }
                  Navigator.pop(context);
                },
                child: Text('Save'),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    for (var timer in _timers.values) {
      timer?.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'SmartHome',
          style: GoogleFonts.montserrat(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.black),
            onPressed: _logout,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(16),
          children:
              _devices.entries.map((entry) {
                return StreamBuilder<DatabaseEvent>(
                  stream: _dbRef.child(entry.key).onValue,
                  builder: (context, snapshot) {
                    int status = 0;
                    String onTime = '--';
                    String offTime = '--';
                    if (snapshot.hasData &&
                        snapshot.data!.snapshot.exists &&
                        snapshot.data!.snapshot.value != null) {
                      final value = snapshot.data!.snapshot.value;
                      if (value is int) {
                        status = value;
                      } else if (value is Map) {
                        final data = Map<String, dynamic>.from(value);
                        status = data['status'] as int? ?? 0;
                        onTime =
                            data['scheduled_on']?.toString().split(' ').last ??
                            '--';
                        offTime =
                            data['scheduled_off']?.toString().split(' ').last ??
                            '--';
                      }
                    }
                    bool hasTimer = _timers[entry.key] != null;
                    String remainingTime = _formatTime(
                      _remainingTimes[entry.key],
                    );
                    return Card(
                      margin: EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.access_time,
                                color: Colors.grey[700],
                              ),
                              onPressed: () => _showScheduleDialog(entry.key),
                            ),
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color:
                                    status == 1
                                        ? Colors.blue.withOpacity(0.2)
                                        : Colors.grey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                entry.value['icon'],
                                size: 28,
                                color: status == 1 ? Colors.blue : Colors.grey,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.value['name'],
                                    style: GoogleFonts.nunito(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'ON: $onTime / OFF: $offTime',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (hasTimer)
                              Padding(
                                padding: EdgeInsets.only(right: 8),
                                child: Text(
                                  remainingTime,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                            Switch(
                              value: status == 1,
                              onChanged:
                                  (value) => _toggleDevice(entry.key, status),
                              activeColor: Colors.blue,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
        ),
      ),
    );
  }
}
