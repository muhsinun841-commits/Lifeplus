import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  runApp(const LifePlusApp());
}

// ============================================================
// COLORS
// ============================================================

const yellow = Color(0xFFFFD21F);
const yellowSoft = Color(0xFFFFF7D1);
const dark = Color(0xFF171717);
const darkSoft = Color(0xFF5F6368);
const green = Color(0xFF20B26B);
const red = Color(0xFFE74C3C);
const blue = Color(0xFF2589E8);
const orange = Color(0xFFFF9800);
const background = Color(0xFFF7F8FA);

// ============================================================
// TASK MODEL
// ============================================================

class Task {
  String id;
  String title;
  DateTime date;
  TimeOfDay time;
  String priority;
  String note;
  bool done;

  Task({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.priority,
    this.note = '',
    this.done = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'hour': time.hour,
      'minute': time.minute,
      'priority': priority,
      'note': note,
      'done': done,
    };
  }

  factory Task.fromJson(Map<String, dynamic> j) {
    return Task(
      id: j['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: j['title']?.toString() ?? '',
      date: DateTime.tryParse(j['date']?.toString() ?? '') ?? DateTime.now(),
      time: TimeOfDay(
        hour: (j['hour'] ?? 0) as int,
        minute: (j['minute'] ?? 0) as int,
      ),
      priority: j['priority']?.toString() ?? 'Sedang',
      note: j['note']?.toString() ?? '',
      done: j['done'] ?? false,
    );
  }
}

// ============================================================
// REMINDER MODEL
// ============================================================

class Reminder {
  String id;
  String title;
  DateTime date;
  TimeOfDay time;
  String repeat;
  bool active;

  Reminder({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    this.repeat = 'Sekali',
    this.active = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'hour': time.hour,
      'minute': time.minute,
      'repeat': repeat,
      'active': active,
    };
  }

  factory Reminder.fromJson(Map<String, dynamic> j) {
    return Reminder(
      id: j['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title: j['title']?.toString() ?? '',
      date: DateTime.tryParse(j['date']?.toString() ?? '') ?? DateTime.now(),
      time: TimeOfDay(
        hour: (j['hour'] ?? 0) as int,
        minute: (j['minute'] ?? 0) as int,
      ),
      repeat: j['repeat']?.toString() ?? 'Sekali',
      active: j['active'] ?? true,
    );
  }
}

// ============================================================
// STORE
// ============================================================

class LifePlusStore extends ChangeNotifier {
  List<Task> tasks = [];
  List<Reminder> reminders = [];

  String userName = 'Muhammad';

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();

    userName = p.getString('userName') ?? 'Muhammad';

    final taskData = p.getString('tasks');
    final reminderData = p.getString('reminders');

    if (taskData != null && taskData.isNotEmpty) {
      try {
        tasks = (jsonDecode(taskData) as List)
            .map((e) => Task.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } catch (_) {
        tasks = [];
      }
    }

    if (reminderData != null && reminderData.isNotEmpty) {
      try {
        reminders = (jsonDecode(reminderData) as List)
            .map((e) => Reminder.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } catch (_) {
        reminders = [];
      }
    }

    notifyListeners();
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();

    await p.setString('userName', userName);

    await p.setString(
      'tasks',
      jsonEncode(tasks.map((e) => e.toJson()).toList()),
    );

    await p.setString(
      'reminders',
      jsonEncode(reminders.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> addTask(Task task) async {
    tasks.add(task);
    await save();
    notifyListeners();
  }

  Future<void> updateTask(Task task) async {
    final index = tasks.indexWhere((x) => x.id == task.id);

    if (index >= 0) {
      tasks[index] = task;
    }

    await save();
    notifyListeners();
  }

  Future<void> deleteTask(String id) async {
    tasks.removeWhere((x) => x.id == id);
    await save();
    notifyListeners();
  }

  Future<void> addReminder(Reminder reminder) async {
    reminders.add(reminder);
    await save();
    notifyListeners();
  }

  Future<void> updateReminder(Reminder reminder) async {
    final index = reminders.indexWhere((x) => x.id == reminder.id);

    if (index >= 0) {
      reminders[index] = reminder;
    }

    await save();
    notifyListeners();
  }

  Future<void> deleteReminder(String id) async {
    reminders.removeWhere((x) => x.id == id);
    await save();
    notifyListeners();
  }

  Future<void> setName(String name) async {
    userName = name.trim().isEmpty ? 'Pengguna' : name.trim();

    await save();
    notifyListeners();
  }
}

// ============================================================
// APP
// ============================================================

class LifePlusApp extends StatefulWidget {
  const LifePlusApp({super.key});

  @override
  State<LifePlusApp> createState() => _LifePlusAppState();
}

class _LifePlusAppState extends State<LifePlusApp> {
  final LifePlusStore store = LifePlusStore();
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await store.load();

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (_, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'LIFE+',
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: background,
            colorScheme: ColorScheme.fromSeed(
              seedColor: yellow,
              brightness: Brightness.light,
            ),
            fontFamily: 'sans',
            appBarTheme: const AppBarTheme(
              backgroundColor: background,
              foregroundColor: dark,
              elevation: 0,
              centerTitle: false,
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          home: loading
              ? const SplashPage()
              : MainShell(store: store),
        );
      },
    );
  }
}

// ============================================================
// SPLASH
// ============================================================

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: yellow,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Center(
                child: Text(
                  '+',
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    color: dark,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'LIFE+',
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: dark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Atur Hari, Raih Hidup yang Lebih Baik',
              style: TextStyle(
                fontSize: 13,
                color: dark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// MAIN SHELL
// ============================================================

class MainShell extends StatefulWidget {
  final LifePlusStore store;

  const MainShell({
    super.key,
    required this.store,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        store: widget.store,
        onAdd: () => _addTask(context),
      ),
      TasksPage(
        store: widget.store,
        onAdd: () => _addTask(context),
      ),
      ReminderPage(
        store: widget.store,
      ),
      StatsPage(
        store: widget.store,
      ),
      SettingsPage(
        store: widget.store,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: pages[index],
      ),
      bottomNavigationBar: NavigationBar(
        height: 76,
        selectedIndex: index,
        onDestinationSelected: (value) {
          setState(() {
            index = value;
          });
        },
        indicatorColor: yellow,
        backgroundColor: const Color(0xFFFFF9EC),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_box_outlined),
            selectedIcon: Icon(Icons.check_box),
            label: 'Tugas',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none),
            selectedIcon: Icon(Icons.notifications),
            label: 'Pengingat',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Statistik',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }

  Future<void> _addTask(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTaskPage(
          store: widget.store,
        ),
      ),
    );
  }
}

// ============================================================
// HOME
// ============================================================

class HomePage extends StatelessWidget {
  final LifePlusStore store;
  final VoidCallback onAdd;

  const HomePage({
    super.key,
    required this.store,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final today = store.tasks.where((task) {
      return _sameDay(task.date, now);
    }).toList();

    today.sort((a, b) {
      return _minutes(a.time).compareTo(_minutes(b.time));
    });

    final totalToday = today.length;
    final doneToday = today.where((t) => t.done).length;

    final progress = totalToday == 0
        ? 0.0
        : doneToday / totalToday;

    final activeReminders =
        store.reminders.where((r) => r.active).length;

    return RefreshIndicator(
      onRefresh: () async {
        await store.load();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          // HEADER
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selamat ${_greeting()}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: darkSoft,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${store.userName} 👋',
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Mari buat hari ini lebih produktif.',
                      style: TextStyle(
                        fontSize: 13,
                        color: darkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SettingsPage(store: store),
                      ),
                    );
                  },
                  icon: const Icon(Icons.settings_outlined),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // DATE CARD
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  yellow,
                  Color(0xFFFFDF45),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.9),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: const Icon(
                    Icons.calendar_month,
                    color: dark,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hari ini',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        DateFormat(
                          'EEEE, d MMMM yyyy',
                          'id_ID',
                        ).format(now),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // PRODUCTIVITY CARD
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.04),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Produktivitas Hari Ini',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '$doneToday dari $totalToday tugas selesai',
                  style: const TextStyle(
                    color: darkSoft,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: Colors.black12,
                    color: green,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // MINI STATS
          Row(
            children: [
              Expanded(
                child: _miniStat(
                  icon: Icons.task_alt,
                  value: '$totalToday',
                  label: 'Tugas hari ini',
                  color: green,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniStat(
                  icon: Icons.notifications_none,
                  value: '$activeReminders',
                  label: 'Pengingat aktif',
                  color: blue,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // TASK HEADER
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tugas Hari Ini',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TasksPage(
                        store: store,
                        onAdd: onAdd,
                      ),
                    ),
                  );
                },
                child: const Text('Lihat semua'),
              ),
            ],
          ),

          const SizedBox(height: 4),

          if (today.isEmpty)
            _homeEmpty(onAdd)
          else
            ...today.take(5).map(
                  (task) => _homeTaskCard(
                    context,
                    task,
                    store,
                  ),
                ),

          const SizedBox(height: 16),

          // ADD TASK
          SizedBox(
            height: 56,
            child: FilledButton.icon(
              onPressed: onAdd,
              style: FilledButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor: dark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text(
                'Tambah Tugas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 27,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 11,
                    color: darkSoft,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _homeEmpty(VoidCallback onAdd) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: green.withOpacity(.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 38,
              color: green,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Belum ada tugas hari ini',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Tambahkan tugas agar aktivitas hari ini lebih teratur.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: darkSoft,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Tambah sekarang'),
          ),
        ],
      ),
    );
  }

  Widget _homeTaskCard(
    BuildContext context,
    Task task,
    LifePlusStore store,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddTaskPage(
                store: store,
                task: task,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 9,
          ),
          child: Row(
            children: [
              Checkbox(
                value: task.done,
                activeColor: green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                onChanged: (value) async {
                  task.done = value ?? false;
                  await store.updateTask(task);
                },
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        decoration:
                            task.done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: darkSoft,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          task.time.format(context),
                          style: const TextStyle(
                            fontSize: 12,
                            color: darkSoft,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _priority(task.priority),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// TASKS PAGE
// ============================================================

class TasksPage extends StatefulWidget {
  final LifePlusStore store;
  final VoidCallback onAdd;

  const TasksPage({
    super.key,
    required this.store,
    required this.onAdd,
  });

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  int filter = 0;

  @override
  Widget build(BuildContext context) {
    List<Task> list = [...widget.store.tasks];

    if (filter == 1) {
      list = list.where((task) => !task.done).toList();
    }

    if (filter == 2) {
      list = list.where((task) => task.done).toList();
    }

    list.sort((a, b) {
      final dateCompare = a.date.compareTo(b.date);

      if (dateCompare != 0) {
        return dateCompare;
      }

      return _minutes(a.time).compareTo(_minutes(b.time));
    });

    final total = widget.store.tasks.length;
    final done = widget.store.tasks.where((t) => t.done).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tugas',
                    style: TextStyle(
                      fontSize: 29,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Atur semua aktivitas Anda',
                    style: TextStyle(
                      color: darkSoft,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: yellowSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '$done/$total',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        SegmentedButton<int>(
          segments: const [
            ButtonSegment(
              value: 0,
              label: Text('Semua'),
            ),
            ButtonSegment(
              value: 1,
              label: Text('Belum'),
            ),
            ButtonSegment(
              value: 2,
              label: Text('Selesai'),
            ),
          ],
          selected: {filter},
          onSelectionChanged: (value) {
            setState(() {
              filter = value.first;
            });
          },
        ),

        const SizedBox(height: 18),

        if (list.isEmpty)
          _emptyTask(widget.onAdd)
        else
          ...list.map(
            (task) => _taskCard(
              context,
              task,
              widget.store,
            ),
          ),

        const SizedBox(height: 14),

        SizedBox(
          height: 54,
          child: FilledButton.icon(
            onPressed: widget.onAdd,
            style: FilledButton.styleFrom(
              backgroundColor: yellow,
              foregroundColor: dark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text(
              'Tambah Tugas',
              style: TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _taskCard(
    BuildContext context,
    Task task,
    LifePlusStore store,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddTaskPage(
                store: store,
                task: task,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              Checkbox(
                value: task.done,
                activeColor: green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                onChanged: (value) async {
                  task.done = value ?? false;
                  await store.updateTask(task);
                },
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        decoration:
                            task.done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: darkSoft,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat(
                            'd MMM yyyy',
                            'id_ID',
                          ).format(task.date),
                          style: const TextStyle(
                            fontSize: 11,
                            color: darkSoft,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: darkSoft,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          task.time.format(context),
                          style: const TextStyle(
                            fontSize: 11,
                            color: darkSoft,
                          ),
                        ),
                      ],
                    ),
                    if (task.note.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        task.note,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: darkSoft,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 5),
              Column(
                children: [
                  _priority(task.priority),
                  const SizedBox(height: 5),
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert,
                      color: darkSoft,
                    ),
                    onSelected: (value) async {
                      if (value == 'edit') {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddTaskPage(
                              store: store,
                              task: task,
                            ),
                          ),
                        );
                      }

                      if (value == 'delete') {
                        await _confirmDelete(
                          context,
                          task,
                          store,
                        );
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined),
                            SizedBox(width: 10),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              color: red,
                            ),
                            SizedBox(width: 10),
                            Text('Hapus'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyTask(VoidCallback onAdd) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.task_alt,
            size: 60,
            color: green,
          ),
          const SizedBox(height: 12),
          const Text(
            'Belum ada tugas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tambahkan tugas pertama Anda untuk mulai menggunakan LIFE+.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: darkSoft,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 15),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Tambah sekarang'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    Task task,
    LifePlusStore store,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Hapus tugas?',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'Tugas "${task.title}" akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (result == true) {
      await store.deleteTask(task.id);
    }
  }
}

// ============================================================
// ADD / EDIT TASK
// ============================================================

class AddTaskPage extends StatefulWidget {
  final LifePlusStore store;
  final Task? task;

  const AddTaskPage({
    super.key,
    required this.store,
    this.task,
  });

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  late TextEditingController title;
  late TextEditingController note;

  late DateTime date;
  late TimeOfDay time;
  late String priority;

  bool get isEdit => widget.task != null;

  @override
  void initState() {
    super.initState();

    final task = widget.task;

    title = TextEditingController(
      text: task?.title ?? '',
    );

    note = TextEditingController(
      text: task?.note ?? '',
    );

    date = task?.date ?? DateTime.now();

    time = task?.time ?? TimeOfDay.now();

    priority = task?.priority ?? 'Sedang';
  }

  @override
  void dispose() {
    title.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(
        const Duration(days: 3650),
      ),
      lastDate: DateTime.now().add(
        const Duration(days: 3650),
      ),
      initialDate: date,
      locale: const Locale('id', 'ID'),
    );

    if (selected != null) {
      setState(() {
        date = selected;
      });
    }
  }

  Future<void> pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: time,
    );

    if (selected != null) {
      setState(() {
        time = selected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Tugas' : 'Tambah Tugas',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: yellowSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: yellow,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.task_alt,
                    color: dark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isEdit
                        ? 'Perbarui detail tugas Anda.'
                        : 'Buat tugas baru agar aktivitas lebih teratur.',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'Nama Tugas',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 8),

          TextField(
            controller: title,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Contoh: Follow up calon anggota',
              prefixIcon: Icon(Icons.edit_outlined),
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'Jadwal',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 8),

          _choice(
            Icons.calendar_month,
            'Tanggal',
            DateFormat(
              'EEEE, d MMMM yyyy',
              'id_ID',
            ).format(date),
            pickDate,
          ),

          _choice(
            Icons.access_time,
            'Waktu',
            time.format(context),
            pickTime,
          ),

          _choice(
            Icons.flag_outlined,
            'Prioritas',
            priority,
            _pickPriority,
          ),

          const SizedBox(height: 12),

          const Text(
            'Catatan',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 8),

          TextField(
            controller: note,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Tambahkan catatan jika diperlukan...',
              alignLabelWithHint: true,
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            height: 56,
            child: FilledButton.icon(
              onPressed: _saveTask,
              style: FilledButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor: dark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: Icon(
                isEdit ? Icons.save_outlined : Icons.add_task,
              ),
              label: Text(
                isEdit ? 'Simpan Perubahan' : 'Simpan Tugas',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _choice(
    IconData icon,
    String label,
    String value,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: darkSoft,
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
        ),
        onTap: onTap,
      ),
    );
  }

  Future<void> _pickPriority() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(10),
                child: Text(
                  'Pilih Prioritas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _priorityOption('Tinggi', red),
              _priorityOption('Sedang', orange),
              _priorityOption('Rendah', green),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );

    if (result != null) {
      setState(() {
        priority = result;
      });
    }
  }

  Widget _priorityOption(
    String value,
    Color color,
  ) {
    return ListTile(
      leading: Icon(
        Icons.flag,
        color: color,
      ),
      title: Text(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
        ),
      ),
      onTap: () => Navigator.pop(context, value),
    );
  }

  Future<void> _saveTask() async {
    final taskTitle = title.text.trim();

    if (taskTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama tugas belum diisi.'),
        ),
      );
      return;
    }

    if (isEdit) {
      final task = widget.task!;

      task.title = taskTitle;
      task.date = date;
      task.time = time;
      task.priority = priority;
      task.note = note.text.trim();

      await widget.store.updateTask(task);
    } else {
      final task = Task(
        id: DateTime.now()
            .microsecondsSinceEpoch
            .toString(),
        title: taskTitle,
        date: date,
        time: time,
        priority: priority,
        note: note.text.trim(),
      );

      await widget.store.addTask(task);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }
}

// ============================================================
// REMINDER PAGE
// ============================================================

class ReminderPage extends StatefulWidget {
  final LifePlusStore store;

  const ReminderPage({
    super.key,
    required this.store,
  });

  @override
  State<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  @override
  Widget build(BuildContext context) {
    final reminders = [...widget.store.reminders];

    reminders.sort((a, b) {
      return _minutes(a.time).compareTo(
        _minutes(b.time),
      );
    });

    final active =
        reminders.where((r) => r.active).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pengingat',
                    style: TextStyle(
                      fontSize: 29,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Jangan lewatkan aktivitas penting.',
                    style: TextStyle(
                      fontSize: 13,
                      color: darkSoft,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: yellowSoft,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                '$active aktif',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        if (reminders.isEmpty)
          _emptyReminder()
        else
          ...reminders.map(
            (reminder) => _reminderCard(
              context,
              reminder,
            ),
          ),

        const SizedBox(height: 12),

        SizedBox(
          height: 54,
          child: FilledButton.icon(
            onPressed: _addReminder,
            style: FilledButton.styleFrom(
              backgroundColor: yellow,
              foregroundColor: dark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            icon: const Icon(Icons.add_alarm),
            label: const Text(
              'Tambah Pengingat',
              style: TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: blue.withOpacity(.08),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                color: blue,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Pengingat V2 tersimpan di perangkat. '
                  'Notifikasi sistem Android otomatis akan '
                  'kita aktifkan pada tahap V3.',
                  style: TextStyle(
                    fontSize: 12,
                    color: darkSoft,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _reminderCard(
    BuildContext context,
    Reminder reminder,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _editReminder(reminder),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: reminder.active
                      ? yellowSoft
                      : Colors.black12,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.notifications,
                  color: reminder.active
                      ? dark
                      : darkSoft,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          reminder.time.format(context),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(.05),
                            borderRadius:
                                BorderRadius.circular(8),
                          ),
                          child: Text(
                            reminder.repeat,
                            style: const TextStyle(
                              fontSize: 10,
                              color: darkSoft,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Switch(
                value: reminder.active,
                activeColor: yellow,
                onChanged: (value) async {
                  reminder.active = value;

                  await widget.store
                      .updateReminder(reminder);

                  setState(() {});
                },
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'edit') {
                    await _editReminder(reminder);
                  }

                  if (value == 'delete') {
                    await _deleteReminder(reminder);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit'),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Hapus'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyReminder() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.notifications_none,
            size: 60,
            color: blue,
          ),
          SizedBox(height: 12),
          Text(
            'Belum ada pengingat',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Buat pengingat agar aktivitas penting tidak terlupakan.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: darkSoft,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addReminder() async {
    await _reminderForm();
  }

  Future<void> _editReminder(
    Reminder reminder,
  ) async {
    await _reminderForm(
      reminder: reminder,
    );
  }

  Future<void> _reminderForm({
    Reminder? reminder,
  }) async {
    final titleController = TextEditingController(
      text: reminder?.title ?? '',
    );

    DateTime date =
        reminder?.date ?? DateTime.now();

    TimeOfDay time =
        reminder?.time ?? TimeOfDay.now();

    String repeat =
        reminder?.repeat ?? 'Sekali';

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 10,
                bottom: MediaQuery.of(context)
                        .viewInsets
                        .bottom +
                    20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder == null
                          ? 'Tambah Pengingat'
                          : 'Edit Pengingat',
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 18),

                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        hintText:
                            'Nama pengingat...',
                        prefixIcon: Icon(
                          Icons.notifications_none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    ListTile(
                      tileColor: background,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                      leading: const Icon(
                        Icons.calendar_month,
                      ),
                      title: const Text(
                        'Tanggal',
                        style: TextStyle(
                          fontSize: 11,
                          color: darkSoft,
                        ),
                      ),
                      subtitle: Text(
                        DateFormat(
                          'EEEE, d MMMM yyyy',
                          'id_ID',
                        ).format(date),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                      ),
                      onTap: () async {
                        final selected =
                            await showDatePicker(
                          context: context,
                          initialDate: date,
                          firstDate: DateTime.now()
                              .subtract(
                            const Duration(
                              days: 3650,
                            ),
                          ),
                          lastDate:
                              DateTime.now().add(
                            const Duration(
                              days: 3650,
                            ),
                          ),
                          locale:
                              const Locale('id', 'ID'),
                        );

                        if (selected != null) {
                          setSheetState(() {
                            date = selected;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 8),

                    ListTile(
                      tileColor: background,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                      leading: const Icon(
                        Icons.access_time,
                      ),
                      title: const Text(
                        'Waktu',
                        style: TextStyle(
                          fontSize: 11,
                          color: darkSoft,
                        ),
                      ),
                      subtitle: Text(
                        time.format(context),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                      ),
                      onTap: () async {
                        final selected =
                            await showTimePicker(
                          context: context,
                          initialTime: time,
                        );

                        if (selected != null) {
                          setSheetState(() {
                            time = selected;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 8),

                    ListTile(
                      tileColor: background,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                      leading: const Icon(
                        Icons.repeat,
                      ),
                      title: const Text(
                        'Pengulangan',
                        style: TextStyle(
                          fontSize: 11,
                          color: darkSoft,
                        ),
                      ),
                      subtitle: Text(
                        repeat,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                      ),
                      onTap: () async {
                        final selected =
                            await showModalBottomSheet<
                                String>(
                          context: context,
                          showDragHandle: true,
                          builder: (_) {
                            return SafeArea(
                              child: Column(
                                mainAxisSize:
                                    MainAxisSize.min,
                                children: [
                                  _repeatOption(
                                    context,
                                    'Sekali',
                                  ),
                                  _repeatOption(
                                    context,
                                    'Setiap Hari',
                                  ),
                                  _repeatOption(
                                    context,
                                    'Setiap Minggu',
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                ],
                              ),
                            );
                          },
                        );

                        if (selected != null) {
                          setSheetState(() {
                            repeat = selected;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: () {
                          if (titleController.text
                              .trim()
                              .isEmpty) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Nama pengingat belum diisi.',
                                ),
                              ),
                            );
                            return;
                          }

                          Navigator.pop(
                            sheetContext,
                            true,
                          );
                        },
                        style:
                            FilledButton.styleFrom(
                          backgroundColor: yellow,
                          foregroundColor: dark,
                        ),
                        icon: const Icon(
                          Icons.save_outlined,
                        ),
                        label: Text(
                          reminder == null
                              ? 'Simpan Pengingat'
                              : 'Simpan Perubahan',
                          style: const TextStyle(
                            fontWeight:
                                FontWeight.w900,
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
      },
    );

    if (result == true) {
      if (reminder == null) {
        await widget.store.addReminder(
          Reminder(
            id: DateTime.now()
                .microsecondsSinceEpoch
                .toString(),
            title: titleController.text.trim(),
            date: date,
            time: time,
            repeat: repeat,
          ),
        );
      } else {
        reminder.title =
            titleController.text.trim();
        reminder.date = date;
        reminder.time = time;
        reminder.repeat = repeat;

        await widget.store
            .updateReminder(reminder);
      }

      setState(() {});
    }

    titleController.dispose();
  }

  Widget _repeatOption(
    BuildContext context,
    String value,
  ) {
    return ListTile(
      leading: const Icon(Icons.repeat),
      title: Text(value),
      onTap: () {
        Navigator.pop(context, value);
      },
    );
  }

  Future<void> _deleteReminder(
    Reminder reminder,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Hapus pengingat?',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'Pengingat "${reminder.title}" akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: red,
            ),
            onPressed: () =>
                Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (result == true) {
      await widget.store
          .deleteReminder(reminder.id);

      setState(() {});
    }
  }
}

// ============================================================
// STATISTICS
// ============================================================

class StatsPage extends StatefulWidget {
  final LifePlusStore store;

  const StatsPage({
    super.key,
    required this.store,
  });

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  int period = 0;

  @override
  Widget build(BuildContext context) {
    final total = widget.store.tasks.length;

    final done = widget.store.tasks
        .where((task) => task.done)
        .length;

    final pending = total - done;

    final pct = total == 0
        ? 0
        : ((done / total) * 100).round();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        30,
      ),
      children: [
        const Text(
          'Statistik',
          style: TextStyle(
            fontSize: 29,
            fontWeight: FontWeight.w900,
          ),
        ),

        const SizedBox(height: 3),

        const Text(
          'Lihat perkembangan produktivitas Anda.',
          style: TextStyle(
            fontSize: 13,
            color: darkSoft,
          ),
        ),

        const SizedBox(height: 18),

        SegmentedButton<int>(
          segments: const [
            ButtonSegment(
              value: 0,
              label: Text('Minggu'),
            ),
            ButtonSegment(
              value: 1,
              label: Text('Bulan'),
            ),
            ButtonSegment(
              value: 2,
              label: Text('Semua'),
            ),
          ],
          selected: {period},
          onSelectionChanged: (value) {
            setState(() {
              period = value.first;
            });
          },
        ),

        const SizedBox(height: 18),

        // MAIN SCORE
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: total == 0
                            ? 0
                            : done / total,
                        strokeWidth: 13,
                        backgroundColor:
                            Colors.black12,
                        color: green,
                      ),
                    ),
                    Column(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        Text(
                          '$pct%',
                          style: const TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Text(
                          'Produktif',
                          style: TextStyle(
                            fontSize: 11,
                            color: darkSoft,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 18),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _legend(
                      green,
                      'Selesai',
                      done,
                    ),
                    _legend(
                      blue,
                      'Belum selesai',
                      pending,
                    ),
                    _legend(
                      red,
                      'Terlambat',
                      _lateCount(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // STAT CARDS
        Row(
          children: [
            Expanded(
              child: _numberCard(
                'Total',
                '$total',
                Icons.assignment_outlined,
                blue,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _numberCard(
                'Selesai',
                '$done',
                Icons.check_circle_outline,
                green,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _numberCard(
                'Belum',
                '$pending',
                Icons.pending_actions,
                orange,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _numberCard(
                'Terlambat',
                '${_lateCount()}',
                Icons.warning_amber_outlined,
                red,
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // WEEKLY CHART
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Aktivitas 7 Hari',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Jumlah tugas yang selesai',
                style: TextStyle(
                  fontSize: 11,
                  color: darkSoft,
                ),
              ),
              const SizedBox(height: 20),
              _weeklyChart(),
            ],
          ),
        ),

        const SizedBox(height: 18),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: yellowSoft,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: yellow,
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: dark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _motivation(pct),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _numberCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 27,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: darkSoft,
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(
    Color color,
    String label,
    int number,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 6,
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
              ),
            ),
          ),
          Text(
            '$number',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _weeklyChart() {
    final now = DateTime.now();

    final days = List.generate(
      7,
      (index) => DateTime(
        now.year,
        now.month,
        now.day - (6 - index),
      ),
    );

    final values = days.map((day) {
      return widget.store.tasks.where((task) {
        return task.done &&
            _sameDay(task.date, day);
      }).length;
    }).toList();

    final maxValue =
        values.fold<int>(1, (max, value) {
      return value > max ? value : max;
    });

    return SizedBox(
      height: 190,
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.end,
        mainAxisAlignment:
            MainAxisAlignment.spaceAround,
        children: List.generate(
          7,
          (index) {
            final value = values[index];

            final height = value == 0
                ? 12.0
                : 30 +
                    (value / maxValue) * 105;

            return Column(
              mainAxisAlignment:
                  MainAxisAlignment.end,
              children: [
                Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  width: 24,
                  height: height,
                  decoration: BoxDecoration(
                    color: green,
                    borderRadius:
                        BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  DateFormat(
                    'EEE',
                    'id_ID',
                  ).format(days[index]),
                  style: const TextStyle(
                    fontSize: 10,
                    color: darkSoft,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  int _lateCount() {
    final now = DateTime.now();

    return widget.store.tasks.where((task) {
      if (task.done) return false;

      final taskDateTime = DateTime(
        task.date.year,
        task.date.month,
        task.date.day,
        task.time.hour,
        task.time.minute,
      );

      return taskDateTime.isBefore(now);
    }).length;
  }

  String _motivation(int pct) {
    if (pct >= 80) {
      return 'Luar biasa! Produktivitas Anda sangat baik. Pertahankan konsistensinya.';
    }

    if (pct >= 50) {
      return 'Bagus! Lebih dari setengah tugas sudah selesai. Tinggal sedikit lagi.';
    }

    if (pct > 0) {
      return 'Tetap semangat. Selesaikan satu tugas demi satu tugas.';
    }

    return 'Belum ada tugas yang selesai. Yuk mulai dari satu tugas kecil hari ini.';
  }
}

// ============================================================
// SETTINGS
// ============================================================

class SettingsPage extends StatelessWidget {
  final LifePlusStore store;

  const SettingsPage({
    super.key,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        30,
      ),
      children: [
        const Text(
          'Pengaturan',
          style: TextStyle(
            fontSize: 29,
            fontWeight: FontWeight.w900,
          ),
        ),

        const SizedBox(height: 3),

        const Text(
          'Atur pengalaman LIFE+ Anda.',
          style: TextStyle(
            fontSize: 13,
            color: darkSoft,
          ),
        ),

        const SizedBox(height: 20),

        // PROFILE
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                yellow,
                Color(0xFFFFE36A),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.person,
                  size: 31,
                  color: dark,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pengguna LIFE+',
                      style: TextStyle(
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      store.userName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () =>
                    _editName(context),
                icon: const Icon(
                  Icons.edit_outlined,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        const Text(
          'Preferensi',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),

        const SizedBox(height: 8),

        Card(
          child: Column(
            children: [
              ListTile(
                leading: _settingIcon(
                  Icons.notifications_none,
                  blue,
                ),
                title: const Text(
                  'Pengingat',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: const Text(
                  'Atur pengingat aktivitas',
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReminderPage(
                        store: store,
                      ),
                    ),
                  );
                },
              ),

              const Divider(height: 1),

              ListTile(
                leading: _settingIcon(
                  Icons.palette_outlined,
                  orange,
                ),
                title: const Text(
                  'Tema',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: const Text(
                  'Tampilan terang LIFE+',
                ),
                trailing: const Text(
                  'Terang',
                  style: TextStyle(
                    color: darkSoft,
                  ),
                ),
                onTap: () {
                  _showThemeInfo(context);
                },
              ),

              const Divider(height: 1),

              ListTile(
                leading: _settingIcon(
                  Icons.storage_outlined,
                  green,
                ),
                title: const Text(
                  'Data & Penyimpanan',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  '${store.tasks.length} tugas • '
                  '${store.reminders.length} pengingat',
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                ),
                onTap: () {
                  _showDataInfo(context);
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        const Text(
          'Tentang',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),

        const SizedBox(height: 8),

        Card(
          child: ListTile(
            leading: _settingIcon(
              Icons.auto_awesome,
              yellow,
            ),
            title: const Text(
              'Tentang LIFE+',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: const Text(
              'Atur Hari, Raih Hidup yang Lebih Baik',
            ),
            trailing: const Text(
              'V2.0',
              style: TextStyle(
                color: darkSoft,
              ),
            ),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'LIFE+',
                applicationVersion: '2.0.0',
                applicationIcon:
                    const Icon(Icons.add_circle),
                applicationLegalese:
                    'Atur Hari, Raih Hidup yang Lebih Baik',
              );
            },
          ),
        ),

        const SizedBox(height: 22),

        Center(
          child: Text(
            'LIFE+ V2.0',
            style: TextStyle(
              fontSize: 11,
              color: Colors.black.withOpacity(.35),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _settingIcon(
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(
        icon,
        color: color == yellow ? dark : color,
      ),
    );
  }

  Future<void> _editName(
    BuildContext context,
  ) async {
    final controller =
        TextEditingController(
      text: store.userName,
    );

    final result =
        await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Nama pengguna',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization:
              TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Masukkan nama...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: yellow,
              foregroundColor: dark,
            ),
            onPressed: () =>
                Navigator.pop(
              context,
              controller.text,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (result != null) {
      await store.setName(result);
    }
  }

  void _showThemeInfo(
    BuildContext context,
  ) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Tema LIFE+',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Saat ini LIFE+ menggunakan tema terang dengan identitas warna kuning, hitam, hijau dan putih.',
              style: TextStyle(
                color: darkSoft,
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showDataInfo(
    BuildContext context,
  ) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Data LIFE+',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 18),
            ListTile(
              leading: const Icon(
                Icons.task_alt,
                color: green,
              ),
              title: const Text('Tugas'),
              trailing: Text(
                '${store.tasks.length}',
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.notifications,
                color: blue,
              ),
              title: const Text('Pengingat'),
              trailing: Text(
                '${store.reminders.length}',
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// HELPERS
// ============================================================

Widget _priority(String priority) {
  Color color;

  if (priority == 'Tinggi') {
    color = red;
  } else if (priority == 'Sedang') {
    color = orange;
  } else {
    color = green;
  }

  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 9,
      vertical: 5,
    ),
    decoration: BoxDecoration(
      color: color.withOpacity(.11),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      priority,
      style: TextStyle(
        fontSize: 10,
        color: color,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

bool _sameDay(
  DateTime a,
  DateTime b,
) {
  return a.year == b.year &&
      a.month == b.month &&
      a.day == b.day;
}

int _minutes(TimeOfDay time) {
  return time.hour * 60 + time.minute;
}

String _greeting() {
  final hour = DateTime.now().hour;

  if (hour < 11) {
    return 'pagi';
  }

  if (hour < 15) {
    return 'siang';
  }

  if (hour < 18) {
    return 'sore';
  }

  return 'malam';
}
