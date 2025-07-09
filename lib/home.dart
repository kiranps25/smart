import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

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
          return SplashScreen();
        }

        if (snapshot.hasData) {
          return HomePage();
        }

        return LoginPage();
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[900],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.power_settings_new, size: 80, color: Colors.yellow[700]),
            SizedBox(height: 20),
            Text(
              'IoT Control',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Smart Home Automation',
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
            SizedBox(height: 30),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow[700]!),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Authentication failed')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              SizedBox(height: 20),
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(onPressed: _login, child: Text('Login')),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late DatabaseReference _dbRef;
  final Map<String, Map<String, dynamic>> _devices = {
    'LED_STATUS': {
      'name': 'Switch 1',
      'type': '',
      'icon': Icons.power_settings_new,
    },
    'LED_STATUS1': {
      'name': 'Switch 2',
      'type': '',
      'icon': Icons.power_settings_new,
    },
    'LED_STATUS2': {
      'name': 'Switch 3',
      'type': '',
      'icon': Icons.power_settings_new,
    },
    'LED_STATUS3': {
      'name': 'Switch 4',
      'type': '',
      'icon': Icons.power_settings_new,
    },
  };
  final Map<String, Timer?> _timers = {};
  final Map<String, int> _remainingTimes = {};
  final Map<String, int> _totalTimerSeconds = {};
  final TextEditingController _minutesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _dbRef =
        FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL:
              "https://homeauto-4c25b-default-rtdb.asia-southeast1.firebasedatabase.app",
        ).ref();

    // Initialize timers and remaining times
    for (var path in _devices.keys) {
      _timers[path] = null;
      _remainingTimes[path] = 0;
      _totalTimerSeconds[path] = 0;
    }

    // Set up Firebase listeners
    _setupFirebaseListeners();
  }

  void _setupFirebaseListeners() {
    for (var devicePath in _devices.keys) {
      _dbRef.child(devicePath).onValue.listen((event) {
        if (!mounted) return;

        if (event.snapshot.exists && event.snapshot.value != null) {
          int status = 0;
          int? timerStart;
          int? timerDuration;

          final value = event.snapshot.value;
          if (value is int) {
            status = value;
          } else if (value is Map) {
            final data = Map<String, dynamic>.from(value);
            status = data['status'] as int? ?? 0;
            timerStart = data['timer_start'] as int?;
            timerDuration = data['timer_duration'] as int?;
          }

          if (timerStart != null && timerDuration != null && status == 1) {
            final now = DateTime.now().millisecondsSinceEpoch;
            final elapsed = (now - timerStart) ~/ 1000;
            final remaining = timerDuration - elapsed;

            if (remaining > 0) {
              // Cancel existing timer if any
              _timers[devicePath]?.cancel();

              // Update remaining time
              _remainingTimes[devicePath] = remaining;
              _totalTimerSeconds[devicePath] = timerDuration;

              // Start new timer
              _startTimerInternal(devicePath, remaining);
            } else {
              // Timer expired - turn off device
              _dbRef.child(devicePath).update({
                'status': 0,
                'timer_start': null,
                'timer_duration': null,
              });
            }
          } else if (_timers[devicePath] != null && status == 0) {
            // Device was turned off manually - cancel timer
            _timers[devicePath]?.cancel();
            _timers[devicePath] = null;
            _remainingTimes[devicePath] = 0;
            setState(() {});
          }
        }
      });
    }
  }

  void _startTimerInternal(String devicePath, int seconds) {
    _timers[devicePath] = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_remainingTimes[devicePath]! > 0) {
          _remainingTimes[devicePath] = _remainingTimes[devicePath]! - 1;
        } else {
          timer.cancel();
          _timers[devicePath] = null;
          _dbRef.child(devicePath).update({
            'status': 0,
            'timer_start': null,
            'timer_duration': null,
          });
        }
      });
    });
  }

  Future<void> _toggleDevice(String devicePath, int currentStatus) async {
    int newStatus = currentStatus == 1 ? 0 : 1;
    try {
      await _dbRef.child(devicePath).set({
        'status': newStatus,
        'timer_start': null,
        'timer_duration': null,
      });

      if (_timers[devicePath] != null) {
        _timers[devicePath]?.cancel();
        _timers[devicePath] = null;
        _remainingTimes[devicePath] = 0;
        if (mounted) setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      }
    }
  }

  void _showTimerDialog(String devicePath) {
    _minutesController.clear();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Center(
              child: Text("Set Timer for ${_devices[devicePath]!['name']}"),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Turn off after (minutes):"),
                SizedBox(height: 10),
                TextField(
                  controller: _minutesController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter minutes',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  if (_minutesController.text.isNotEmpty) {
                    int minutes = int.tryParse(_minutesController.text) ?? 0;
                    if (minutes > 0) {
                      Navigator.pop(context);
                      _startTimer(devicePath, minutes);
                    }
                  }
                },
                child: Text("Set Timer"),
              ),
            ],
          ),
    );
  }

  void _startTimer(String devicePath, int minutes) async {
    _timers[devicePath]?.cancel();
    final duration = minutes * 60;
    final startTime = DateTime.now().millisecondsSinceEpoch;

    await _dbRef.child(devicePath).set({
      'status': 1,
      'timer_start': startTime,
      'timer_duration': duration,
    });

    _remainingTimes[devicePath] = duration;
    _totalTimerSeconds[devicePath] = duration;

    _startTimerInternal(devicePath, duration);
  }

  String _formatTime(int? seconds) {
    seconds ??= 0;
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _logout() async {
    try {
      // Cancel all active timers before logging out
      for (var timer in _timers.values) {
        timer?.cancel();
      }

      await FirebaseAuth.instance.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Logout failed: ${e.toString()}")),
        );
      }
    }
  }

  @override
  void dispose() {
    for (var timer in _timers.values) {
      timer?.cancel();
    }
    _minutesController.dispose();
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
                    if (snapshot.hasData &&
                        snapshot.data != null &&
                        snapshot.data!.snapshot.exists &&
                        snapshot.data!.snapshot.value != null) {
                      final value = snapshot.data!.snapshot.value;
                      if (value is int) {
                        status = value;
                      } else if (value is Map) {
                        final data = Map<String, dynamic>.from(value);
                        status = data['status'] as int? ?? 0;
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
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _toggleDevice(entry.key, status),
                        onLongPress: () => _showTimerDialog(entry.key),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
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
                                  color:
                                      status == 1 ? Colors.blue : Colors.grey,
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
                                      entry.value['type'],
                                      style: GoogleFonts.nunito(
                                        fontSize: 14,
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
