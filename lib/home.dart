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
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _isDarkMode ? _darkTheme : _lightTheme,
      home: AuthWrapper(onThemeToggle: _toggleTheme, isDarkMode: _isDarkMode),
    );
  }

  ThemeData get _lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6366F1),
      brightness: Brightness.light,
    ),
  );

  ThemeData get _darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6366F1),
      brightness: Brightness.dark,
    ),
  );
}

class AuthWrapper extends StatelessWidget {
  final VoidCallback onThemeToggle;
  final bool isDarkMode;

  const AuthWrapper({
    Key? key,
    required this.onThemeToggle,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return HomePage(onThemeToggle: onThemeToggle, isDarkMode: isDarkMode);
        }
        return const LoginPage();
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _loading = false;
  String? _errorText;

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorText = "Please enter email and password";
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorText = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } catch (e) {
      setState(() {
        _errorText = "Login failed";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.home_rounded,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'SmartSwitch',
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Control your home from anywhere',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color:
                        isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 48),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(
                            color:
                                isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                          ),
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color:
                                isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor:
                              isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFF1F5F9),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(
                            color:
                                isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                          ),
                          prefixIcon: Icon(
                            Icons.lock_outlined,
                            color:
                                isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                          ),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color:
                                  isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor:
                              isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFF1F5F9),
                        ),
                      ),
                      if (_errorText != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _errorText!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child:
                              _loading
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Text(
                                    'Login',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
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
    );
  }
}

class HomePage extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final bool isDarkMode;

  const HomePage({
    Key? key,
    required this.onThemeToggle,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final Map<String, Map<String, dynamic>> _devices = {
    'LED_STATUS': {
      'name': 'Switch 1',
      'icon': Icons.lightbulb_outlined,
      'activeIcon': Icons.lightbulb,
      'color': const Color(0xFFFBBF24),
    },
    'LED_STATUS1': {
      'name': 'Switch 2',
      'icon': Icons.bed_outlined,
      'activeIcon': Icons.bed,
      'color': const Color(0xFF8B5CF6),
    },
    'LED_STATUS2': {
      'name': 'Switch 3',
      'icon': Icons.kitchen_outlined,
      'activeIcon': Icons.kitchen,
      'color': const Color(0xFF10B981),
    },
    'LED_STATUS3': {
      'name': 'Switch 4',
      'icon': Icons.bathroom_outlined,
      'activeIcon': Icons.bathroom,
      'color': const Color(0xFF3B82F6),
    },
  };

  final Map<String, Timer?> _timers = {};
  final Map<String, int> _remainingTimes = {};
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  late AnimationController _animationController;

  List<Map<String, dynamic>> _scenes = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    for (var key in _devices.keys) {
      _timers[key] = null;
      _remainingTimes[key] = 0;
    }
    _startPreciseScheduler();
    _loadScenes();
  }

  Future<void> _loadScenes() async {
    if (!mounted) return;

    try {
      final snapshot = await _dbRef.child('scenes').get();

      List<Map<String, dynamic>> loadedScenes = [];

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map? ?? {});

        for (final entry in data.entries) {
          final sceneData = Map<String, dynamic>.from(
            entry.value as Map? ?? {},
          );
          sceneData['id'] = entry.key;
          loadedScenes.add(sceneData);
        }
      }

      if (mounted) {
        setState(() {
          _scenes = loadedScenes;
        });
      }
    } catch (e) {
      print('Error loading scenes: $e');
      if (mounted) {
        setState(() {
          _scenes = [];
        });
      }
    }
  }

  void _startPreciseScheduler() {
    _checkScheduledTasks();
    Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkScheduledTasks();
    });
  }

  void _checkScheduledTasks() async {
    final now = DateTime.now();
    final formatted = DateFormat('hh:mm:ss a').format(now);

    for (var key in _devices.keys) {
      try {
        final snapshot = await _dbRef.child(key).get();
        final data = snapshot.value;
        if (data is Map) {
          final map = Map<String, dynamic>.from(data);
          final scheduledOn = map['scheduled_on'] ?? '';
          final scheduledOff = map['scheduled_off'] ?? '';

          if (scheduledOn == formatted) {
            await _dbRef.child(key).update({'status': 1});
          } else if (scheduledOff == formatted) {
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
    _animationController.forward().then((_) => _animationController.reverse());
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  String _formatTime(int? seconds) {
    if (seconds == null || seconds <= 0) return '';
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _formatTimeWithoutSeconds(String timeString) {
    if (timeString == '--' || timeString.isEmpty) return '--';
    try {
      final parts = timeString.split(' ');
      if (parts.length == 2) {
        final timePart = parts[0].split(':');
        if (timePart.length >= 2) {
          return '${timePart[0]}:${timePart[1]} ${parts[1]}';
        }
      }
    } catch (e) {
      print('Error formatting time: $e');
    }
    return timeString;
  }

  Future<void> _executeScene(Map<String, dynamic> scene) async {
    try {
      final actions = scene['actions'] as List<dynamic>?;
      if (actions == null || actions.isEmpty) {
        print('Scene has no actions');
        return;
      }

      for (var action in actions) {
        final deviceKey = action['device'] as String?;
        final status = action['status'] as int?;

        if (deviceKey != null && status != null) {
          await _dbRef.child(deviceKey).update({'status': status});
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${scene['name'] ?? 'Scene'} activated'),
          duration: const Duration(seconds: 2),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } catch (e) {
      print('Error executing scene: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to execute scene'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // FIXED: Real-time scene state monitoring
  Stream<bool> _getSceneActiveStream(Map<String, dynamic> scene) {
    final actions = scene['actions'] as List<dynamic>? ?? [];
    if (actions.isEmpty) {
      return Stream.value(false);
    }

    // Get device keys from scene actions
    List<String> deviceKeys = [];
    for (var action in actions) {
      final deviceKey = action['device'] as String?;
      if (deviceKey != null && _devices.containsKey(deviceKey)) {
        deviceKeys.add(deviceKey);
      }
    }

    if (deviceKeys.isEmpty) {
      return Stream.value(false);
    }

    // Combine all device streams into one stream that checks scene state
    return _dbRef.onValue.map((event) {
      try {
        int matchingDevices = 0;
        int totalDevices = actions.length;

        for (var action in actions) {
          final deviceKey = action['device'] as String?;
          final expectedStatus = action['status'] as int? ?? 0;

          if (deviceKey != null && event.snapshot.child(deviceKey).exists) {
            final deviceData = event.snapshot.child(deviceKey).value;
            int currentStatus = 0;

            if (deviceData is int) {
              currentStatus = deviceData;
            } else if (deviceData is Map) {
              final map = Map<String, dynamic>.from(deviceData);
              currentStatus = map['status'] as int? ?? 0;
            }

            if (currentStatus == expectedStatus) {
              matchingDevices++;
            }
          }
        }

        // Scene is active if all devices match their expected states
        return matchingDevices == totalDevices;
      } catch (e) {
        print('Error checking scene state: $e');
        return false;
      }
    });
  }

  // FIXED: Toggle scene execution
  Future<void> _toggleScene(Map<String, dynamic> scene, bool turnOn) async {
    try {
      final actions = scene['actions'] as List<dynamic>? ?? [];
      if (actions.isEmpty) return;

      for (var action in actions) {
        final deviceKey = action['device'] as String?;
        final sceneStatus = action['status'] as int? ?? 0;

        if (deviceKey != null) {
          // If turning on, use scene's defined status; if turning off, set all to 0
          final targetStatus = turnOn ? sceneStatus : 0;
          await _dbRef.child(deviceKey).update({'status': targetStatus});
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${scene['name'] ?? 'Scene'} ${turnOn ? 'activated' : 'deactivated'}',
            ),
            duration: const Duration(seconds: 1),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      print('Error toggling scene: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to toggle scene'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _deleteScene(String sceneId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Scene'),
            content: const Text('Are you sure you want to delete this scene?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await _dbRef.child('scenes').child(sceneId).remove();
        await _loadScenes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Scene deleted successfully'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        print('Error deleting scene: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete scene'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  void _showCreateSceneDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descController = TextEditingController();
    IconData selectedIcon = Icons.lightbulb;
    Map<String, int> deviceStates = {};

    for (var key in _devices.keys) {
      deviceStates[key] = 0;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Create Scene',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Scene Name',
                          labelStyle: TextStyle(
                            color:
                                isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: descController,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Description (Optional)',
                          labelStyle: TextStyle(
                            color:
                                isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Icon: ',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children:
                                  [
                                        Icons.wb_sunny,
                                        Icons.nightlight_round,
                                        Icons.movie,
                                        Icons.restaurant,
                                        Icons.work,
                                        Icons.weekend,
                                      ]
                                      .map(
                                        (icon) => Padding(
                                          padding: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          child: GestureDetector(
                                            onTap:
                                                () => setDialogState(
                                                  () => selectedIcon = icon,
                                                ),
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color:
                                                    selectedIcon == icon
                                                        ? Theme.of(context)
                                                            .colorScheme
                                                            .primary
                                                            .withOpacity(0.2)
                                                        : (isDark
                                                            ? const Color(
                                                              0xFF334155,
                                                            )
                                                            : const Color(
                                                              0xFFF1F5F9,
                                                            )),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border:
                                                    selectedIcon == icon
                                                        ? Border.all(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .primary,
                                                        )
                                                        : null,
                                              ),
                                              child: Icon(
                                                icon,
                                                color:
                                                    selectedIcon == icon
                                                        ? Theme.of(
                                                          context,
                                                        ).colorScheme.primary
                                                        : (isDark
                                                            ? const Color(
                                                              0xFF94A3B8,
                                                            )
                                                            : const Color(
                                                              0xFF64748B,
                                                            )),
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Device States:',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...(_devices.entries.map((entry) {
                        final key = entry.key;
                        final device = entry.value;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(
                                      device['icon'],
                                      color:
                                          isDark
                                              ? const Color(0xFF94A3B8)
                                              : const Color(0xFF64748B),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        device['name'],
                                        style: GoogleFonts.inter(
                                          color:
                                              isDark
                                                  ? Colors.white
                                                  : Colors.black,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: deviceStates[key] == 1,
                                onChanged: (value) {
                                  setDialogState(() {
                                    deviceStates[key] = value ? 1 : 0;
                                  });
                                },
                                activeColor: device['color'],
                              ),
                            ],
                          ),
                        );
                      })),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color:
                          isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isNotEmpty) {
                      final sceneId =
                          DateTime.now().millisecondsSinceEpoch.toString();
                      final actions =
                          deviceStates.entries
                              .map(
                                (entry) => {
                                  'device': entry.key,
                                  'status': entry.value,
                                },
                              )
                              .toList();

                      final scene = {
                        'id': sceneId,
                        'name': nameController.text,
                        'description': descController.text,
                        'icon': selectedIcon.codePoint,
                        'actions': actions,
                        'created_at': DateTime.now().toIso8601String(),
                      };

                      try {
                        await _dbRef.child('scenes/$sceneId').set(scene);
                        await _loadScenes();
                        Navigator.pop(context);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Scene "${nameController.text}" created',
                              ),
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                            ),
                          );
                        }
                      } catch (e) {
                        print('Error creating scene: $e');
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showScheduleDialog(String key) {
    TimeOfDay? onTime;
    TimeOfDay? offTime;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Set Schedule',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.wb_sunny_outlined),
                      label: Text(
                        onTime != null
                            ? 'ON: ${onTime!.format(context)}'
                            : 'Pick ON Time',
                      ),
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          setDialogState(() {
                            onTime = time;
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.nightlight_outlined),
                      label: Text(
                        offTime != null
                            ? 'OFF: ${offTime!.format(context)}'
                            : 'Pick OFF Time',
                      ),
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          setDialogState(() {
                            offTime = time;
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color:
                          isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (onTime != null && offTime != null) {
                      final now = DateTime.now();
                      final format = DateFormat('hh:mm:ss a');
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
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (var timer in _timers.values) {
      timer?.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              expandedHeight: 100,
              // Move buttons to actions property for top-right positioning
              actions: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 18,
                    icon: Icon(
                      isDark ? Icons.light_mode : Icons.dark_mode,
                      color:
                          isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                    ),
                    onPressed: widget.onThemeToggle,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.only(right: 16), // Add right margin
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 18,
                    icon: const Icon(Icons.logout_rounded),
                    onPressed: _logout,
                    color:
                        isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        Theme.of(
                          context,
                        ).colorScheme.secondary.withOpacity(0.05),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Remove the Row with buttons since they're now in actions
                          Text(
                            'Welcome Home',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color:
                                  isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                            ),
                          ),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.6,
                            ),
                            child: Text(
                              'SmartSwitch',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                height: 1.0,
                                fontWeight: FontWeight.bold,
                                color:
                                    isDark
                                        ? Colors.white
                                        : const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // FIXED: Scene cards section with working toggle switches
            if (_scenes.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Quick Scenes',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color:
                              isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      IconButton(
                        onPressed: _showCreateSceneDialog,
                        icon: Icon(
                          Icons.add_circle_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 140,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _scenes.length,
                    itemBuilder: (context, index) {
                      final scene = _scenes[index];
                      final sceneId =
                          scene['id']?.toString() ?? index.toString();

                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Stack(
                          children: [
                            GestureDetector(
                              onTap: () => _executeScene(scene),
                              child: Container(
                                width: 100,
                                height: 120,
                                decoration: BoxDecoration(
                                  color:
                                      isDark
                                          ? const Color(0xFF1E293B)
                                          : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.3),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(
                                        isDark ? 0.3 : 0.08,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        IconData(
                                          scene['icon'] ??
                                              Icons.lightbulb.codePoint,
                                          fontFamily: 'MaterialIcons',
                                        ),
                                        size: 28,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        scene['name'] ?? 'Scene',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              isDark
                                                  ? Colors.white
                                                  : const Color(0xFF1E293B),
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      // FIXED: Real-time scene toggle switch using StreamBuilder
                                      StreamBuilder<bool>(
                                        stream: _getSceneActiveStream(scene),
                                        builder: (context, snapshot) {
                                          final isActive =
                                              snapshot.data ?? false;

                                          return Transform.scale(
                                            scale: 0.8,
                                            child: Switch(
                                              value: isActive,
                                              onChanged:
                                                  (value) => _toggleScene(
                                                    scene,
                                                    value,
                                                  ),
                                              activeColor:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () => _deleteScene(sceneId),
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ] else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Quick Scenes',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color:
                              isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      IconButton(
                        onPressed: _showCreateSceneDialog,
                        icon: Icon(
                          Icons.add_circle_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GestureDetector(
                    onTap: _showCreateSceneDialog,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              isDark ? 0.3 : 0.08,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_circle_outline,
                              color: Theme.of(context).colorScheme.primary,
                              size: 32,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Create your first scene',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color:
                                    isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Text(
                  'Devices',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final entry = _devices.entries.elementAt(index);
                  return DeviceCard(
                    deviceKey: entry.key,
                    deviceData: entry.value,
                    onToggle: () => _toggleDevice(entry.key, 0),
                    onSchedule: () => _showScheduleDialog(entry.key),
                    dbRef: _dbRef,
                    formatTime: _formatTime,
                    formatTimeWithoutSeconds: _formatTimeWithoutSeconds,
                    timers: _timers,
                    remainingTimes: _remainingTimes,
                  );
                }, childCount: _devices.length),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DeviceCard extends StatelessWidget {
  final String deviceKey;
  final Map<String, dynamic> deviceData;
  final VoidCallback onToggle;
  final VoidCallback onSchedule;
  final DatabaseReference dbRef;
  final String Function(int?) formatTime;
  final String Function(String) formatTimeWithoutSeconds;
  final Map<String, Timer?> timers;
  final Map<String, int> remainingTimes;

  const DeviceCard({
    Key? key,
    required this.deviceKey,
    required this.deviceData,
    required this.onToggle,
    required this.onSchedule,
    required this.dbRef,
    required this.formatTime,
    required this.formatTimeWithoutSeconds,
    required this.timers,
    required this.remainingTimes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<DatabaseEvent>(
      stream: dbRef.child(deviceKey).onValue,
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
            final map = Map<String, dynamic>.from(value);
            status = map['status'] as int? ?? 0;
            onTime = map['scheduled_on']?.toString() ?? '--';
            offTime = map['scheduled_off']?.toString() ?? '--';
          }
        }

        bool isActive = status == 1;
        bool hasTimer = timers[deviceKey] != null;
        String remainingTime = formatTime(remainingTimes[deviceKey]);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color:
                    isActive
                        ? deviceData['color'].withOpacity(0.3)
                        : Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                blurRadius: isActive ? 20 : 10,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color:
                  isActive
                      ? deviceData['color'].withOpacity(0.3)
                      : (isDark
                          ? const Color(0xFF334155)
                          : Colors.grey.withOpacity(0.1)),
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color:
                            isActive
                                ? deviceData['color'].withOpacity(0.2)
                                : (isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isActive
                            ? deviceData['activeIcon']
                            : deviceData['icon'],
                        size: 24,
                        color:
                            isActive
                                ? deviceData['color']
                                : (isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B)),
                      ),
                    ),
                    GestureDetector(
                      onTap: onSchedule,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color:
                              isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.schedule,
                          size: 18,
                          color:
                              isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Text(
                  deviceData['name'],
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  isActive ? 'ON' : 'OFF',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color:
                        isActive
                            ? deviceData['color']
                            : (isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B)),
                    fontWeight: FontWeight.w500,
                  ),
                ),

                if (onTime != '--' || offTime != '--') ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (onTime != '--')
                          Text(
                            'ON: ${formatTimeWithoutSeconds(onTime)}',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              color:
                                  isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                            ),
                          ),
                        if (onTime != '--' && offTime != '--')
                          const SizedBox(height: 2),
                        if (offTime != '--')
                          Text(
                            'OFF: ${formatTimeWithoutSeconds(offTime)}',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              color:
                                  isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],

                if (hasTimer) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      remainingTime,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],

                const Spacer(),

                GestureDetector(
                  onTap:
                      () => dbRef.child(deviceKey).update({
                        'status': status == 1 ? 0 : 1,
                      }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    height: 42,
                    decoration: BoxDecoration(
                      color:
                          isActive
                              ? deviceData['color']
                              : (isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        isActive ? 'Turn Off' : 'Turn On',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color:
                              isActive
                                  ? Colors.white
                                  : (isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
