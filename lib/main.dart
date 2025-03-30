import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

void main() async {
  // Initialize logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });

  // Initialize timezone database
  tz.initializeTimeZones();

  WidgetsFlutterBinding.ensureInitialized();
  await WorkoutData.loadWorkouts();
  SocialFeatures.checkAchievements(); // Check achievements on startup
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Workout Tracker',
      debugShowCheckedModeBanner: false,
      theme: _isDarkMode ? _darkTheme : _lightTheme,
      home: Builder(
        builder: (context) {
          // Set system UI overlay style based on theme
          SystemChrome.setSystemUIOverlayStyle(
            _isDarkMode
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark,
          );
          return CalendarScreen(
            toggleTheme: () {
              setState(() {
                _isDarkMode = !_isDarkMode;
              });
            },
            isDarkMode: _isDarkMode,
          );
        },
      ),
    );
  }

  final ThemeData _lightTheme = ThemeData(
    colorScheme: ColorScheme.light(
      primary: Colors.deepOrange,
      secondary: Colors.orangeAccent,
      surface: Colors.white,
    ),
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    cardTheme: CardTheme(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: EdgeInsets.zero,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.deepOrange,
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      centerTitle: true,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.deepOrange,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        elevation: 4,
        textStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      bodyLarge: TextStyle(
        color: Colors.black87,
      ),
    ),
    iconTheme: const IconThemeData(
      color: Colors.deepOrange,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Colors.deepOrange,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.deepOrange.withOpacity(0.2),
      labelStyle: const TextStyle(
        color: Colors.deepOrange,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  final ThemeData _darkTheme = ThemeData(
    colorScheme: ColorScheme.dark(
      primary: Colors.deepOrange,
      secondary: Colors.orangeAccent,
      surface: Colors.grey[800]!,
    ),
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.grey[900],
    cardTheme: CardTheme(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.grey[800],
      margin: EdgeInsets.zero,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.grey[900],
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
      centerTitle: true,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.deepOrange,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        elevation: 4,
        textStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    ),
    textTheme: TextTheme(
      headlineMedium: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      bodyLarge: TextStyle(
        color: Colors.grey[300]!,
      ),
    ),
    iconTheme: const IconThemeData(
      color: Colors.deepOrange,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Colors.deepOrange,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.deepOrange.withOpacity(0.2),
      labelStyle: const TextStyle(
        color: Colors.deepOrange,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

class Achievement {
  final String title;
  final String description;
  final bool unlocked;
  final DateTime? unlockedDate;

  Achievement({
    required this.title,
    required this.description,
    this.unlocked = false,
    this.unlockedDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'unlocked': unlocked,
      'unlockedDate': unlockedDate?.toIso8601String(),
    };
  }

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      title: json['title'],
      description: json['description'],
      unlocked: json['unlocked'],
      unlockedDate: json['unlockedDate'] != null
          ? DateTime.parse(json['unlockedDate'])
          : null,
    );
  }
}

class WarmupSet {
  final int reps;
  final double percentage; // Percentage of working weight

  WarmupSet({required this.reps, required this.percentage});

  Map<String, dynamic> toJson() {
    return {
      'reps': reps,
      'percentage': percentage,
    };
  }

  factory WarmupSet.fromJson(Map<String, dynamic> json) {
    return WarmupSet(
      reps: json['reps'],
      percentage: json['percentage'].toDouble(),
    );
  }
}

class Workout {
  final String name;
  final List<Exercise> exercises;
  final DateTime date;
  final String intensity; // 'light', 'medium', or 'intense'

  Workout({
    required this.name,
    required this.exercises,
    required this.date,
    this.intensity = 'medium', // default to medium
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'date': date.toIso8601String(),
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'intensity': intensity,
    };
  }

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      name: json['name'],
      date: DateTime.parse(json['date']),
      exercises: (json['exercises'] as List)
          .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      intensity: json['intensity'] ?? 'medium', // default if not specified
    );
  }
}

class Exercise {
  final String name;
  int sets;
  int reps;
  double weight;
  List<WarmupSet> warmupSets;
  String notes;

  Exercise({
    required this.name,
    this.sets = 3,
    this.reps = 10,
    this.weight = 0.0,
    this.warmupSets = const [],
    this.notes = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'warmupSets': warmupSets.map((w) => w.toJson()).toList(),
      'notes': notes,
    };
  }

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      name: json['name'],
      sets: json['sets'],
      reps: json['reps'],
      weight: (json['weight'] is int)
          ? (json['weight'] as int).toDouble()
          : json['weight'],
      warmupSets: (json['warmupSets'] as List?)
              ?.map((w) => WarmupSet.fromJson(w))
              .toList() ??
          [],
      notes: json['notes'] ?? '',
    );
  }
}

extension WarmupExtension on Exercise {
  List<WarmupSet> getDefaultWarmup() {
    if (weight <= 0) return [];

    return [
      WarmupSet(reps: 8, percentage: 0.4),
      WarmupSet(reps: 5, percentage: 0.6),
      WarmupSet(reps: 3, percentage: 0.8),
    ];
  }

  double calculateWarmupWeight(WarmupSet set) {
    return (weight * set.percentage).roundToDouble();
  }
}

class SocialFeatures {
  static List<Achievement> achievements = [
    Achievement(
      title: 'First Workout',
      description: 'Complete your first workout',
    ),
    Achievement(
      title: 'Week Warrior',
      description: 'Complete 5 workouts in a week',
    ),
    Achievement(
      title: 'Strength Builder',
      description: 'Increase your max weight by 10% on any exercise',
    ),
  ];

  static Future<void> checkAchievements() async {
    final workouts =
        WorkoutData.workoutHistory.values.expand((x) => x).toList();

    if (workouts.isNotEmpty) {
      _unlockAchievement('First Workout');
    }

    // Check for Week Warrior
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekWorkouts =
        workouts.where((w) => w.date.isAfter(weekStart)).length;
    if (weekWorkouts >= 5) {
      _unlockAchievement('Week Warrior');
    }
  }

  static void _unlockAchievement(String title) {
    final index = achievements.indexWhere((a) => a.title == title);
    if (index != -1 && !achievements[index].unlocked) {
      achievements[index] = Achievement(
        title: achievements[index].title,
        description: achievements[index].description,
        unlocked: true,
        unlockedDate: DateTime.now(),
      );
    }
  }

  static void shareWorkout(Workout workout, BuildContext context) {
    final text =
        'I just completed ${workout.name} with ${workout.exercises.length} exercises! '
        'Check out my progress on Workout Tracker!';

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Share Your Workout', style: TextStyle(fontSize: 20)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.facebook, size: 40),
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Shared to Facebook')),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.message, size: 40),
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Shared via message')),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_horiz, size: 40),
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Shared to other apps')),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

final _workoutLogger = Logger('WorkoutData');

class WorkoutData {
  static Map<DateTime, List<Workout>> workoutHistory = {};
  static const String storageKey = 'workout_history';
  static const String achievementsKey = 'achievements';

  static Future<void> addWorkout(Workout workout) async {
    final date = _toIndiaTime(
        DateTime(workout.date.year, workout.date.month, workout.date.day));

    if (workoutHistory[date] == null) {
      workoutHistory[date] = [];
    }

    workoutHistory[date]!.add(workout);
    await _saveToLocalStorage();
    await SocialFeatures.checkAchievements();
  }

  static List<Workout> getWorkoutsForDay(DateTime day) {
    final date = _toIndiaTime(DateTime(day.year, day.month, day.day));
    return workoutHistory[date] ?? [];
  }

  static Future<void> loadWorkouts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? workoutJson = prefs.getString(storageKey);
      final String? achievementsJson = prefs.getString(achievementsKey);

      if (workoutJson != null) {
        final Map<String, dynamic> decodedMap = jsonDecode(workoutJson);

        workoutHistory = {};
        decodedMap.forEach((key, value) {
          final DateTime date = _toIndiaTime(DateTime.parse(key));
          final List<dynamic> workoutsJson = value;

          workoutHistory[date] = workoutsJson.map((workoutJson) {
            return Workout.fromJson(workoutJson);
          }).toList();
        });
      }

      if (achievementsJson != null) {
        final List<dynamic> decodedAchievements = jsonDecode(achievementsJson);
        SocialFeatures.achievements =
            decodedAchievements.map((a) => Achievement.fromJson(a)).toList();
      }
    } catch (e) {
      _workoutLogger.warning('Error loading data: $e');
    }
  }

  static Future<void> _saveToLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> encodableMap = {};

      workoutHistory.forEach((date, workouts) {
        final String dateStr = date.toIso8601String();
        encodableMap[dateStr] = workouts.map((w) => w.toJson()).toList();
      });

      final String workoutJson = jsonEncode(encodableMap);
      final String achievementsJson = jsonEncode(
          SocialFeatures.achievements.map((a) => a.toJson()).toList());

      await prefs.setString(storageKey, workoutJson);
      await prefs.setString(achievementsKey, achievementsJson);
      _workoutLogger.info('Data saved successfully');
    } catch (e) {
      _workoutLogger.warning('Error saving data: $e');
    }
  }

  static DateTime _toIndiaTime(DateTime dateTime) {
    final india = tz.getLocation('Asia/Kolkata');
    return tz.TZDateTime.from(dateTime, india);
  }
}

class CalendarScreen extends StatefulWidget {
  final Function() toggleTheme;
  final bool isDarkMode;

  const CalendarScreen({
    Key? key,
    required this.toggleTheme,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  CalendarScreenState createState() => CalendarScreenState();
}

class CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDay = WorkoutData._toIndiaTime(DateTime.now());
  DateTime _focusedDay = WorkoutData._toIndiaTime(DateTime.now());

  List<Workout> _selectedWorkouts = [];

  @override
  void initState() {
    super.initState();
    _updateSelectedWorkouts();
  }

  void _updateSelectedWorkouts() {
    setState(() {
      _selectedWorkouts = WorkoutData.getWorkoutsForDay(_selectedDay);
    });
  }

  Future<void> _editWorkout(Workout workout, int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutEditScreen(
          workout: workout,
          selectedDate: _selectedDay,
          isDarkMode: widget.isDarkMode,
        ),
      ),
    );

    if (result == true) {
      _updateSelectedWorkouts();
    }
  }

  Future<void> _deleteWorkout(Workout workout, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Workout'),
        content: const Text('Are you sure you want to delete this workout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final date = WorkoutData._toIndiaTime(
          DateTime(workout.date.year, workout.date.month, workout.date.day));
      setState(() {
        WorkoutData.workoutHistory[date]?.removeAt(index);
        if (WorkoutData.workoutHistory[date]?.isEmpty ?? false) {
          WorkoutData.workoutHistory.remove(date);
        }
      });
      await WorkoutData._saveToLocalStorage();
      _updateSelectedWorkouts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout deleted')),
        );
      }
    }
  }

  Color _getIntensityColor(DateTime day) {
    final workouts = WorkoutData.getWorkoutsForDay(day);
    if (workouts.isEmpty) return Colors.transparent;

    // Get the most intense workout for the day
    String intensity = workouts.map((w) => w.intensity).reduce((a, b) {
      if (a == 'intense' || b == 'intense') return 'intense';
      if (a == 'medium' || b == 'medium') return 'medium';
      return 'light';
    });

    switch (intensity) {
      case 'intense':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'light':
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout History'),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.toggleTheme,
          ),
        ],
      ),
      drawer: AppDrawer(
        toggleTheme: widget.toggleTheme,
        isDarkMode: widget.isDarkMode,
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: TableCalendar(
              focusedDay: _focusedDay,
              firstDay: WorkoutData._toIndiaTime(DateTime.utc(2020, 1, 1)),
              lastDay: WorkoutData._toIndiaTime(DateTime.utc(2030, 12, 31)),
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              eventLoader: (day) {
                return WorkoutData.getWorkoutsForDay(day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                  _updateSelectedWorkouts();
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepOrange, Colors.orangeAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepOrange, Colors.orangeAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: Colors.deepOrange.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                markersAutoAligned: false,
                markerSize: 8,
                markerMargin: const EdgeInsets.symmetric(horizontal: 1),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Workouts for ${_formatDate(_selectedDay)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedWorkouts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fitness_center,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No workouts recorded for this day',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _selectedWorkouts.length,
                    itemBuilder: (context, index) {
                      final workout = _selectedWorkouts[index];
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {},
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          workout.name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert),
                                        onSelected: (value) {
                                          if (value == 'edit') {
                                            _editWorkout(workout, index);
                                          } else if (value == 'delete') {
                                            _deleteWorkout(workout, index);
                                          } else if (value == 'share') {
                                            SocialFeatures.shareWorkout(
                                                workout, context);
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Text('Edit'),
                                          ),
                                          const PopupMenuItem(
                                            value: 'share',
                                            child: Text('Share'),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Text('Delete',
                                                style: TextStyle(
                                                    color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Date: ${_formatIndianDateTime(workout.date)}',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.color,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ...workout.exercises.map((exercise) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.circle,
                                            size: 8,
                                            color:
                                                Theme.of(context).primaryColor,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '${exercise.name}: ${exercise.sets} sets × ${exercise.reps} reps (${exercise.weight}kg)',
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkoutScreen(
                selectedDate: _selectedDay,
                isDarkMode: widget.isDarkMode,
              ),
            ),
          ).then((_) {
            _updateSelectedWorkouts();
          });
        },
      ),
    );
  }

  String _formatIndianDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')} IST';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class WorkoutEditScreen extends StatefulWidget {
  final Workout workout;
  final DateTime selectedDate;
  final bool isDarkMode;

  const WorkoutEditScreen({
    Key? key,
    required this.workout,
    required this.selectedDate,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  WorkoutEditScreenState createState() => WorkoutEditScreenState();
}

class WorkoutEditScreenState extends State<WorkoutEditScreen> {
  late List<Exercise> exercises;
  late TextEditingController workoutNameController;
  late String selectedIntensity;

  @override
  void initState() {
    super.initState();
    exercises = List.from(widget.workout.exercises);
    workoutNameController = TextEditingController(text: widget.workout.name);
    selectedIntensity = widget.workout.intensity;
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: widget.isDarkMode ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Workout'),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveChanges,
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: workoutNameController,
                decoration: InputDecoration(
                  labelText: 'Workout Name',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor:
                      widget.isDarkMode ? Colors.grey[800] : Colors.grey[100],
                ),
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Text('Workout Intensity: '),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: selectedIntensity,
                    items: const [
                      DropdownMenuItem(
                        value: 'light',
                        child: Text('Light'),
                      ),
                      DropdownMenuItem(
                        value: 'medium',
                        child: Text('Medium'),
                      ),
                      DropdownMenuItem(
                        value: 'intense',
                        child: Text('Intense'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedIntensity = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: exercises.length,
                itemBuilder: (context, index) {
                  final exercise = exercises[index];
                  final setsController =
                      TextEditingController(text: exercise.sets.toString());
                  final repsController =
                      TextEditingController(text: exercise.reps.toString());
                  final weightController =
                      TextEditingController(text: exercise.weight.toString());

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          ListTile(
                            title: Text(
                              exercise.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${exercise.sets} sets × ${exercise.reps} reps (${exercise.weight}kg)',
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      labelText: 'Sets',
                                      filled: true,
                                      fillColor: widget.isDarkMode
                                          ? Colors.grey[800]
                                          : Colors.grey[100],
                                    ),
                                    keyboardType: TextInputType.number,
                                    controller: setsController,
                                    onChanged: (value) {
                                      if (value.isNotEmpty) {
                                        exercises[index].sets =
                                            int.tryParse(value) ?? 3;
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      labelText: 'Reps',
                                      filled: true,
                                      fillColor: widget.isDarkMode
                                          ? Colors.grey[800]
                                          : Colors.grey[100],
                                    ),
                                    keyboardType: TextInputType.number,
                                    controller: repsController,
                                    onChanged: (value) {
                                      if (value.isNotEmpty) {
                                        exercises[index].reps =
                                            int.tryParse(value) ?? 10;
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      labelText: 'Weight (kg)',
                                      filled: true,
                                      fillColor: widget.isDarkMode
                                          ? Colors.grey[800]
                                          : Colors.grey[100],
                                    ),
                                    keyboardType: TextInputType.number,
                                    controller: weightController,
                                    onChanged: (value) {
                                      if (value.isNotEmpty) {
                                        exercises[index].weight =
                                            double.tryParse(value) ?? 0.0;
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (exercise.warmupSets.isNotEmpty) ...[
                            const Divider(),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Warmup Sets:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  ...exercise.warmupSets
                                      .map((warmup) => Padding(
                                            padding:
                                                const EdgeInsets.only(top: 4),
                                            child: Text(
                                              '${warmup.reps} reps @ ${(warmup.percentage * 100).toInt()}% (${exercise.calculateWarmupWeight(warmup)} kg)',
                                            ),
                                          ))
                                      .toList(),
                                ],
                              ),
                            ),
                          ],
                          TextField(
                            decoration: InputDecoration(
                              labelText: 'Notes',
                              filled: true,
                              fillColor: widget.isDarkMode
                                  ? Colors.grey[800]
                                  : Colors.grey[100],
                            ),
                            onChanged: (value) {
                              exercises[index].notes = value;
                            },
                            controller:
                                TextEditingController(text: exercise.notes),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    final editedWorkout = Workout(
      name: workoutNameController.text,
      exercises: exercises,
      date: widget.selectedDate,
      intensity: selectedIntensity,
    );

    final date = WorkoutData._toIndiaTime(DateTime(widget.selectedDate.year,
        widget.selectedDate.month, widget.selectedDate.day));

    if (WorkoutData.workoutHistory[date] != null) {
      final index = WorkoutData.workoutHistory[date]!
          .indexWhere((w) => w.name == widget.workout.name);
      if (index != -1) {
        WorkoutData.workoutHistory[date]![index] = editedWorkout;
        await WorkoutData._saveToLocalStorage();
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    }
  }
}

class WorkoutScreen extends StatefulWidget {
  final DateTime selectedDate;
  final bool isDarkMode;

  const WorkoutScreen({
    Key? key,
    required this.selectedDate,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  WorkoutScreenState createState() => WorkoutScreenState();
}

class WorkoutScreenState extends State<WorkoutScreen> {
  final Map<String, List<String>> muscleExercises = {
    'Back': [
      'Pull-ups',
      'Deadlifts',
      'Bent-over Rows',
      'Lat Pulldowns',
      'T-Bar Rows',
      'Single-arm Dumbbell Rows',
      'Seated Cable Rows',
      'Back Extensions',
      'Good Mornings',
      'Chin-ups'
    ],
    'Chest': [
      'Bench Press',
      'Push-ups',
      'Chest Fly',
      'Dips',
      'Incline Bench Press',
      'Decline Bench Press',
      'Dumbbell Press',
      'Cable Crossovers',
      'Pec Deck Fly',
      'Svend Press'
    ],
    'Biceps': [
      'Bicep Curls',
      'Hammer Curls',
      'Preacher Curls',
      'Concentration Curls',
      'EZ Bar Curls',
      'Spider Curls',
      'Zottman Curls',
      'Reverse Curls',
      'Cable Curls',
      'Cheat Curls'
    ],
    'Forearms': [
      'Wrist Curls',
      'Reverse Wrist Curls',
      'Farmer Walks',
      'Plate Pinches',
      'Behind-the-back Wrist Curls',
      'Grip Crushers',
      'Barbell Wrist Curls',
      'Hammer Curl Holds',
      'Deadhangs',
      'Towel Pull-ups'
    ],
    'Triceps': [
      'Tricep Dips',
      'Skull Crushers',
      'Tricep Pushdowns',
      'Close-grip Bench Press',
      'Overhead Tricep Extension',
      'Diamond Push-ups',
      'Tricep Kickbacks',
      'Bench Dips',
      'Cable Rope Overhead Extension',
      'JM Press'
    ],
    'Shoulders': [
      'Overhead Press',
      'Lateral Raises',
      'Front Raises',
      'Reverse Flyes',
      'Face Pulls',
      'Shrugs',
      'Upright Rows',
      'Arnold Press',
      'Push Press',
      'Bent-over Reverse Flyes'
    ],
    'Abs': [
      'Crunches',
      'Leg Raises',
      'Planks',
      'Russian Twists',
      'Mountain Climbers',
      'Ab Rollouts',
      'Hanging Leg Raises',
      'Cable Crunches',
      'Bicycle Crunches',
      'Reverse Crunches'
    ],
    'Legs': [
      'Squats',
      'Lunges',
      'Leg Press',
      'Calf Raises',
      'Leg Extensions',
      'Leg Curls',
      'Romanian Deadlifts',
      'Bulgarian Split Squats',
      'Hack Squats',
      'Box Jumps',
      'Good Mornings',
      'Hip Thrusts'
    ],
    'Cardio': [
      'Running',
      'Jump Rope',
      'Cycling',
      'Rowing',
      'Elliptical Trainer',
      'Stair Climber',
      'High-intensity Interval Training (HIIT)',
      'Swimming',
      'Battle Ropes',
      'Burpees'
    ],
  };

  Map<String, bool> selectedMuscles = {};

  @override
  void initState() {
    super.initState();
    for (var muscle in muscleExercises.keys) {
      selectedMuscles[muscle] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: widget.isDarkMode ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create New Workout'),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Step 1: Select Muscle Groups',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: muscleExercises.keys.map((muscle) {
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: CheckboxListTile(
                      title: Text(muscle),
                      value: selectedMuscles[muscle],
                      onChanged: (bool? value) {
                        setState(() {
                          selectedMuscles[muscle] = value!;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  bool anySelected =
                      selectedMuscles.values.any((isSelected) => isSelected);
                  if (!anySelected) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content:
                            Text('Please select at least one muscle group')));
                    return;
                  }

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ExerciseSelectionScreen(
                        muscleExercises: muscleExercises,
                        selectedMuscles: selectedMuscles,
                        selectedDate: widget.selectedDate,
                        isDarkMode: widget.isDarkMode,
                      ),
                    ),
                  );
                },
                child: const Text('Next: Select Exercises'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExerciseSelectionScreen extends StatefulWidget {
  final Map<String, List<String>> muscleExercises;
  final Map<String, bool> selectedMuscles;
  final DateTime selectedDate;
  final bool isDarkMode;

  const ExerciseSelectionScreen({
    Key? key,
    required this.muscleExercises,
    required this.selectedMuscles,
    required this.selectedDate,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  ExerciseSelectionScreenState createState() => ExerciseSelectionScreenState();
}

class ExerciseSelectionScreenState extends State<ExerciseSelectionScreen> {
  Map<String, bool> selectedExercises = {};

  @override
  void initState() {
    super.initState();

    // Initialize all exercises as unselected
    for (var muscle in widget.muscleExercises.keys) {
      if (widget.selectedMuscles[muscle] == true) {
        for (var exercise in widget.muscleExercises[muscle]!) {
          selectedExercises[exercise] = false;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Collect exercises for selected muscle groups
    List<String> exercises = [];
    widget.selectedMuscles.forEach((muscle, isSelected) {
      if (isSelected) {
        exercises.addAll(widget.muscleExercises[muscle]!);
      }
    });

    return Theme(
      data: widget.isDarkMode ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Step 2: Select Exercises'),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: exercises.length,
                itemBuilder: (context, index) {
                  final exercise = exercises[index];
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: CheckboxListTile(
                      title: Text(exercise),
                      value: selectedExercises[exercise] ?? false,
                      onChanged: (bool? value) {
                        setState(() {
                          selectedExercises[exercise] = value!;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  final selectedExerciseList = selectedExercises.entries
                      .where((entry) => entry.value)
                      .map((entry) => entry.key)
                      .toList();

                  if (selectedExerciseList.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Please select at least one exercise')));
                    return;
                  }

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => WorkoutSequenceScreen(
                        selectedExercises: selectedExerciseList,
                        selectedDate: widget.selectedDate,
                        isDarkMode: widget.isDarkMode,
                      ),
                    ),
                  );
                },
                child: const Text('Next: Create Workout Sequence'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WorkoutSequenceScreen extends StatefulWidget {
  final List<String> selectedExercises;
  final DateTime selectedDate;
  final bool isDarkMode;

  const WorkoutSequenceScreen({
    Key? key,
    required this.selectedExercises,
    required this.selectedDate,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  WorkoutSequenceScreenState createState() => WorkoutSequenceScreenState();
}

class WorkoutSequenceScreenState extends State<WorkoutSequenceScreen> {
  List<Exercise> exercises = [];
  final TextEditingController workoutNameController = TextEditingController();
  String selectedIntensity = 'medium';

  @override
  void initState() {
    super.initState();
    exercises =
        widget.selectedExercises.map((name) => Exercise(name: name)).toList();
    workoutNameController.text =
        'Workout ${widget.selectedDate.day}/${widget.selectedDate.month}';
  }

  void _showWarmupDialog(int exerciseIndex) {
    final exercise = exercises[exerciseIndex];
    final defaultWarmup = exercise.getDefaultWarmup();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Configure Warmup Sets'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Default warmup sets for ${exercise.name}:'),
              const SizedBox(height: 10),
              ...defaultWarmup
                  .map((warmup) => ListTile(
                        title: Text(
                            '${warmup.reps} reps @ ${(warmup.percentage * 100).toInt()}%'),
                        subtitle: Text(
                            '${exercise.calculateWarmupWeight(warmup)} kg'),
                      ))
                  .toList(),
              const SizedBox(height: 20),
              ElevatedButton(
                child: const Text('Use Default Warmup'),
                onPressed: () {
                  setState(() {
                    exercises[exerciseIndex].warmupSets = defaultWarmup;
                  });
                  Navigator.pop(context);
                },
              ),
              TextButton(
                child: const Text('Customize'),
                onPressed: () {
                  Navigator.pop(context);
                  _showCustomWarmupDialog(exerciseIndex);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCustomWarmupDialog(int exerciseIndex) {
    final exercise = exercises[exerciseIndex];
    final warmupControllers = exercise.warmupSets
        .map(
            (w) => TextEditingController(text: w.percentage.toStringAsFixed(2)))
        .toList();
    final repsControllers = exercise.warmupSets
        .map((w) => TextEditingController(text: w.reps.toString()))
        .toList();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Custom Warmup Sets'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...List.generate(warmupControllers.length, (index) {
                      return Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: repsControllers[index],
                              decoration: const InputDecoration(
                                labelText: 'Reps',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: warmupControllers[index],
                              decoration: const InputDecoration(
                                labelText: 'Percentage (0-1)',
                              ),
                              keyboardType: TextInputType.numberWithOptions(
                                decimal: true,
                                signed: false,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d?\.?\d{0,2}'),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                warmupControllers.removeAt(index);
                                repsControllers.removeAt(index);
                              });
                            },
                          ),
                        ],
                      );
                    }),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          warmupControllers
                              .add(TextEditingController(text: '0.5'));
                          repsControllers.add(TextEditingController(text: '5'));
                        });
                      },
                      child: const Text('Add Warmup Set'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final newWarmupSets = <WarmupSet>[];
                    for (int i = 0; i < warmupControllers.length; i++) {
                      final percentage =
                          double.tryParse(warmupControllers[i].text) ?? 0.5;
                      final reps = int.tryParse(repsControllers[i].text) ?? 5;
                      newWarmupSets.add(WarmupSet(
                        reps: reps,
                        percentage: percentage.clamp(0.1, 0.9),
                      ));
                    }
                    setState(() {
                      exercises[exerciseIndex].warmupSets = newWarmupSets;
                    });
                    Navigator.pop(context);
                  },
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
  Widget build(BuildContext context) {
    return Theme(
      data: widget.isDarkMode ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Step 3: Arrange Workout Sequence'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                final workout = Workout(
                  name: workoutNameController.text,
                  exercises: exercises,
                  date: widget.selectedDate,
                  intensity: selectedIntensity,
                );
                SocialFeatures.shareWorkout(workout, context);
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: workoutNameController,
                decoration: InputDecoration(
                  labelText: 'Workout Name',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor:
                      widget.isDarkMode ? Colors.grey[800] : Colors.grey[100],
                ),
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Text('Workout Intensity: '),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: selectedIntensity,
                    items: const [
                      DropdownMenuItem(
                        value: 'light',
                        child: Text('Light'),
                      ),
                      DropdownMenuItem(
                        value: 'medium',
                        child: Text('Medium'),
                      ),
                      DropdownMenuItem(
                        value: 'intense',
                        child: Text('Intense'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedIntensity = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: exercises.length,
                itemBuilder: (context, index) {
                  final exercise = exercises[index];
                  final setsController =
                      TextEditingController(text: exercise.sets.toString());
                  final repsController =
                      TextEditingController(text: exercise.reps.toString());
                  final weightController =
                      TextEditingController(text: exercise.weight.toString());

                  setsController.addListener(() {
                    if (setsController.text.isNotEmpty) {
                      exercises[index].sets =
                          int.tryParse(setsController.text) ?? 3;
                    }
                  });

                  repsController.addListener(() {
                    if (repsController.text.isNotEmpty) {
                      exercises[index].reps =
                          int.tryParse(repsController.text) ?? 10;
                    }
                  });

                  weightController.addListener(() {
                    if (weightController.text.isNotEmpty) {
                      exercises[index].weight =
                          double.tryParse(weightController.text) ?? 0.0;
                    }
                  });

                  return Card(
                    key: ValueKey('${exercise.name}_$index'),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          ListTile(
                            leading: ReorderableDragStartListener(
                              index: index,
                              child: const Icon(Icons.drag_handle),
                            ),
                            title: Text(
                              exercise.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${exercise.sets} sets × ${exercise.reps} reps (${exercise.weight}kg)',
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      labelText: 'Sets',
                                      filled: true,
                                      fillColor: widget.isDarkMode
                                          ? Colors.grey[800]
                                          : Colors.grey[100],
                                    ),
                                    keyboardType: TextInputType.number,
                                    controller: setsController,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      labelText: 'Reps',
                                      filled: true,
                                      fillColor: widget.isDarkMode
                                          ? Colors.grey[800]
                                          : Colors.grey[100],
                                    ),
                                    keyboardType: TextInputType.number,
                                    controller: repsController,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      labelText: 'Weight (kg)',
                                      filled: true,
                                      fillColor: widget.isDarkMode
                                          ? Colors.grey[800]
                                          : Colors.grey[100],
                                    ),
                                    keyboardType: TextInputType.number,
                                    controller: weightController,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (exercise.warmupSets.isNotEmpty) ...[
                            const Divider(),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Warmup Sets:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  ...exercise.warmupSets
                                      .map((warmup) => Padding(
                                            padding:
                                                const EdgeInsets.only(top: 4),
                                            child: Text(
                                              '${warmup.reps} reps @ ${(warmup.percentage * 100).toInt()}% (${exercise.calculateWarmupWeight(warmup)} kg)',
                                            ),
                                          ))
                                      .toList(),
                                ],
                              ),
                            ),
                          ],
                          TextButton(
                            child: Text(
                              exercise.warmupSets.isEmpty
                                  ? 'Add Warmup Sets'
                                  : 'Edit Warmup Sets',
                            ),
                            onPressed: () => _showWarmupDialog(index),
                          ),
                          TextField(
                            decoration: InputDecoration(
                              labelText: 'Notes',
                              filled: true,
                              fillColor: widget.isDarkMode
                                  ? Colors.grey[800]
                                  : Colors.grey[100],
                            ),
                            onChanged: (value) {
                              exercises[index].notes = value;
                            },
                            controller:
                                TextEditingController(text: exercise.notes),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) {
                      newIndex -= 1;
                    }
                    final Exercise item = exercises.removeAt(oldIndex);
                    exercises.insert(newIndex, item);
                  });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  try {
                    final newWorkout = Workout(
                      name: workoutNameController.text,
                      exercises: exercises,
                      date: widget.selectedDate,
                      intensity: selectedIntensity,
                    );

                    await WorkoutData.addWorkout(newWorkout);

                    if (context.mounted) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Workout saved to calendar!')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error saving workout: $e')),
                      );
                    }
                  }
                },
                child: const Text('Save Workout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AchievementsScreen extends StatelessWidget {
  final bool isDarkMode;

  const AchievementsScreen({Key? key, required this.isDarkMode})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Achievements'),
          centerTitle: true,
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: SocialFeatures.achievements.length,
          itemBuilder: (context, index) {
            final achievement = SocialFeatures.achievements[index];
            return Card(
              child: ListTile(
                leading: Icon(
                  achievement.unlocked ? Icons.star : Icons.star_border,
                  color: achievement.unlocked ? Colors.amber : Colors.grey,
                ),
                title: Text(achievement.title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(achievement.description),
                    if (achievement.unlocked &&
                        achievement.unlockedDate != null)
                      Text(
                        'Unlocked: ${DateFormat('MMM d, y').format(achievement.unlockedDate!)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final Function() toggleTheme;
  final bool isDarkMode;

  const HomeScreen({
    Key? key,
    required this.toggleTheme,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Tracker'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: toggleTheme,
          ),
        ],
      ),
      drawer: AppDrawer(
        toggleTheme: toggleTheme,
        isDarkMode: isDarkMode,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [Colors.grey[900]!, Colors.grey[800]!]
                : [Colors.white, Colors.grey[50]!],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 150,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 30),
            Text(
              'Welcome to Workout Tracker!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
                shadows: [
                  Shadow(
                    blurRadius: 10,
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              'Track your workouts, monitor progress, and achieve your fitness goals',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 24),
              label: const Text(
                'Start New Workout',
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorkoutScreen(
                      selectedDate: DateTime.now(),
                      isDarkMode: isDarkMode,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today, size: 24),
              label: const Text(
                'View Workout History',
                style: TextStyle(fontSize: 18),
              ),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CalendarScreen(
                      toggleTheme: toggleTheme,
                      isDarkMode: isDarkMode,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class AppDrawer extends StatelessWidget {
  final Function() toggleTheme;
  final bool isDarkMode;

  const AppDrawer({
    Key? key,
    required this.toggleTheme,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepOrange, Colors.orangeAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Workout Tracker',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Icon(
                  Icons.fitness_center,
                  color: Colors.white,
                  size: 32,
                ),
                const Spacer(),
                Row(
                  children: [
                    const Text(
                      'Dark Mode',
                      style: TextStyle(color: Colors.white),
                    ),
                    const Spacer(),
                    Switch(
                      value: isDarkMode,
                      onChanged: (value) => toggleTheme(),
                      activeColor: Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => HomeScreen(
                    toggleTheme: toggleTheme,
                    isDarkMode: isDarkMode,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Workout History'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => CalendarScreen(
                    toggleTheme: toggleTheme,
                    isDarkMode: isDarkMode,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.fitness_center),
            title: const Text('New Workout'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => WorkoutScreen(
                    selectedDate: DateTime.now(),
                    isDarkMode: isDarkMode,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.emoji_events),
            title: const Text('Achievements'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AchievementsScreen(
                    isDarkMode: isDarkMode,
                  ),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            subtitle: const Text('Contact us for any issues or suggestions'),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Need Help?'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                            'For any issues, errors, or suggestions, contact us:'),
                        SizedBox(height: 10),
                        SelectableText('📧 Email: 22dit046@charusat.edu.com'),
                        SelectableText('📞 Phone: +91 8200549940'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Close'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
