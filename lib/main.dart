import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LifePlusApp());
}

// ============================================================
// COLORS
// ============================================================

const Color lifeYellow = Color(0xFFFFD21F);
const Color lifeDark = Color(0xFF111417);
const Color lifeGreen = Color(0xFF20B26B);
const Color lifeRed = Color(0xFFE74C3C);
const Color lifeBlue = Color(0xFF2589E8);
const Color lifeOrange = Color(0xFFFF9F1C);
const Color background = Color(0xFFF6F7F9);

// ============================================================
// HELPERS
// ============================================================

String two(int n) => n.toString().padLeft(2, '0');

String formatDate(DateTime d) {
  const months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

String formatShortDate(DateTime d) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  return '${d.day} ${months[d.month - 1]}';
}

String formatDay(DateTime d) {
  const days = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  return days[d.weekday - 1];
}

String greeting() {
  final hour = DateTime.now().hour;

  if (hour < 11) return 'pagi';
  if (hour < 15) return 'siang';
  if (hour < 18) return 'sore';
  return 'malam';
}

int timeToMinutes(TimeOfDay t) {
  return t.hour * 60 + t.minute;
}

bool sameDay(DateTime a, DateTime b) {
  return a.year == b.year &&
      a.month == b.month &&
      a.day == b.day;
}

String timeText(TimeOfDay time) {
  return '${two(time.hour)}:${two(time.minute)}';
}

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

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      date: DateTime.parse(json['date'].toString()),
      time: TimeOfDay(
        hour: json['hour'] ?? 0,
        minute: json['minute'] ?? 0,
      ),
      priority: json['priority']?.toString() ?? 'Sedang',
      note: json['note']?.toString() ?? '',
      done: json['done'] ?? false,
    );
  }
}

// ============================================================
// REMINDER MODEL
// ============================================================

class Reminder {
  String id;
  String title;
  TimeOfDay time;
  bool active;
  bool repeatDaily;

  Reminder({
    required this.id,
    required this.title,
    required this.time,
    this.active = true,
    this.repeatDaily = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'hour': time.hour,
      'minute': time.minute,
      'active': active,
      'repeatDaily': repeatDaily,
    };
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      time: TimeOfDay(
        hour: json['hour'] ?? 0,
        minute: json['minute'] ?? 0,
      ),
      active: json['active'] ?? true,
      repeatDaily: json['repeatDaily'] ?? false,
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
    final prefs = await SharedPreferences.getInstance();

    userName = prefs.getString('userName') ?? 'Muhammad';

    final taskData = prefs.getString('tasks');
    final reminderData = prefs.getString('reminders');

    if (taskData != null && taskData.isNotEmpty) {
      try {
        final decoded = jsonDecode(taskData) as List;

        tasks = decoded
            .map(
              (item) => Task.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
      } catch (_) {
        tasks = [];
      }
    }

    if (reminderData != null && reminderData.isNotEmpty) {
      try {
        final decoded = jsonDecode(reminderData) as List;

        reminders = decoded
            .map(
              (item) => Reminder.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
      } catch (_) {
        reminders = [];
      }
    }

    notifyListeners();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('userName', userName);

    await prefs.setString(
      'tasks',
      jsonEncode(
        tasks.map((task) => task.toJson()).toList(),
      ),
    );

    await prefs.setString(
      'reminders',
      jsonEncode(
        reminders.map((item) => item.toJson()).toList(),
      ),
    );
  }

  Future<void> addTask(Task task) async {
    tasks.add(task);
    await save();
    notifyListeners();
  }

  Future<void> updateTask(Task task) async {
    final index = tasks.indexWhere(
      (item) => item.id == task.id,
    );

    if (index >= 0) {
      tasks[index] = task;
    }

    await save();
    notifyListeners();
  }

  Future<void> deleteTask(String id) async {
    tasks.removeWhere((task) => task.id == id);

    await save();
    notifyListeners();
  }

  Future<void> addReminder(Reminder reminder) async {
    reminders.add(reminder);

    await save();
    notifyListeners();
  }

  Future<void> updateReminder(Reminder reminder) async {
    final index = reminders.indexWhere(
      (item) => item.id == reminder.id,
    );

    if (index >= 0) {
      reminders[index] = reminder;
    }

    await save();
    notifyListeners();
  }

  Future<void> deleteReminder(String id) async {
    reminders.removeWhere(
      (reminder) => reminder.id == id,
    );

    await save();
    notifyListeners();
  }

  Future<void> setName(String name) async {
    final cleaned = name.trim();

    userName = cleaned.isEmpty ? 'Pengguna' : cleaned;

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

  @override
  void initState() {
    super.initState();
    store.load();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'LIFE+',
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: background,
            colorScheme: ColorScheme.fromSeed(
              seedColor: lifeYellow,
              brightness: Brightness.light,
            ),
            fontFamily: 'sans',
            appBarTheme: const AppBarTheme(
              backgroundColor: background,
              foregroundColor: lifeDark,
              elevation: 0,
              centerTitle: false,
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: lifeYellow,
                  width: 2,
                ),
              ),
            ),
          ),
          home: MainShell(store: store),
        );
      },
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
        child: IndexedStack(
          index: index,
          children: pages,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) {
          setState(() {
            index = value;
          });
        },
        indicatorColor: lifeYellow,
        backgroundColor: Colors.white,
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
// HOME PAGE
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

    final today = store.tasks
        .where((task) => sameDay(task.date, now))
        .toList();

    today.sort(
      (a, b) => timeToMinutes(a.time)
          .compareTo(timeToMinutes(b.time)),
    );

    final total = store.tasks.length;
    final done = store.tasks.where((task) => task.done).length;

    final progress =
        total == 0 ? 0.0 : done / total;

    final activeReminders =
        store.reminders.where((item) => item.active).length;

    return RefreshIndicator(
      onRefresh: () async {
        await store.load();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          20,
          20,
          30,
        ),
        children: [
          _header(context),
          const SizedBox(height: 22),

          _todayCard(now),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _summaryCard(
                  icon: Icons.task_alt,
                  value: '$total',
                  label: 'Total Tugas',
                  color: lifeGreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryCard(
                  icon: Icons.check_circle_outline,
                  value: '$done',
                  label: 'Selesai',
                  color: lifeBlue,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _summaryCard(
                  icon: Icons.notifications_none,
                  value: '$activeReminders',
                  label: 'Pengingat',
                  color: lifeOrange,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryCard(
                  icon: Icons.percent,
                  value: '${(progress * 100).round()}%',
                  label: 'Produktivitas',
                  color: lifeRed,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tugas Hari Ini',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
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

          const SizedBox(height: 8),

          if (today.isEmpty)
            _emptyHome(onAdd)
          else
            ...today
                .take(5)
                .map(
                  (task) => _taskTile(
                    context,
                    task,
                    store,
                  ),
                ),

          const SizedBox(height: 18),

          SizedBox(
            height: 56,
            child: FilledButton.icon(
              onPressed: onAdd,
              style: FilledButton.styleFrom(
                backgroundColor: lifeYellow,
                foregroundColor: lifeDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text(
                'Tambah Tugas',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: lifeYellow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Text(
              'L+',
              style: TextStyle(
                color: lifeDark,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Selamat ${greeting()},',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              Text(
                '${store.userName} 👋',
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SettingsPage(
                  store: store,
                ),
              ),
            );
          },
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
    );
  }

  Widget _todayCard(DateTime now) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: lifeYellow,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.calendar_month,
              color: lifeDark,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hari ini',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${formatDay(now)}, ${formatDate(now)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                color: color,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyHome(VoidCallback add) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color:lifeGreen.withValues(alpha: .10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.task_alt,
                size: 36,
                color: lifeGreen,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Belum ada tugas hari ini',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Tambahkan tugas agar hari Anda lebih teratur.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: add,
              icon: const Icon(Icons.add),
              label: const Text('Tambah sekarang'),
            ),
          ],
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
      final date =
          a.date.compareTo(b.date);

      if (date != 0) {
        return date;
      }

      return timeToMinutes(a.time)
          .compareTo(timeToMinutes(b.time));
    });

    final pending =
        widget.store.tasks.where((t) => !t.done).length;

    return Scaffold(
      backgroundColor: background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: widget.onAdd,
        backgroundColor: lifeYellow,
        foregroundColor: lifeDark,
        icon: const Icon(Icons.add),
        label: const Text(
          'Tambah',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          24,
          20,
          100,
        ),
        children: [
          const Text(
            'Tugas',
            style: TextStyle(
              fontSize: 29,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '$pending tugas belum selesai',
            style: const TextStyle(
              color: Colors.black54,
            ),
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
            _emptyTask()
          else
            ...list.map(
              (task) => _taskTile(
                context,
                task,
                widget.store,
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptyTask() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            const Icon(
              Icons.assignment_outlined,
              size: 60,
              color: Colors.black26,
            ),
            const SizedBox(height: 14),
            const Text(
              'Belum ada tugas',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Buat tugas pertama Anda sekarang.',
              style: TextStyle(
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 15),
            OutlinedButton.icon(
              onPressed: widget.onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Buat tugas'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ADD / EDIT TASK PAGE
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
  State<AddTaskPage> createState() =>
      _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  late TextEditingController titleController;
  late TextEditingController noteController;

  late DateTime date;
  late TimeOfDay time;
  late String priority;

  bool get editing => widget.task != null;

  @override
  void initState() {
    super.initState();

    final task = widget.task;

    titleController = TextEditingController(
      text: task?.title ?? '',
    );

    noteController = TextEditingController(
      text: task?.note ?? '',
    );

    date = task?.date ?? DateTime.now();
    time = task?.time ?? TimeOfDay.now();
    priority = task?.priority ?? 'Sedang';
  }

  @override
  void dispose() {
    titleController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    final result = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (result != null) {
      setState(() {
        date = result;
      });
    }
  }

  Future<void> pickTime() async {
    final result = await showTimePicker(
      context: context,
      initialTime: time,
    );

    if (result != null) {
      setState(() {
        time = result;
      });
    }
  }

  Future<void> pickPriority() async {
    final result =
        await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      builder: (context) {
        final values = [
          ('Rendah', lifeGreen),
          ('Sedang', lifeOrange),
          ('Tinggi', lifeRed),
        ];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Pilih Prioritas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                ...values.map(
                  (item) => ListTile(
                    leading: Icon(
                      Icons.flag,
                      color: item.$2,
                    ),
                    title: Text(item.$1),
                    trailing: priority == item.$1
                        ? const Icon(
                            Icons.check,
                            color: lifeGreen,
                          )
                        : null,
                    onTap: () {
                      Navigator.pop(
                        context,
                        item.$1,
                      );
                    },
                  ),
                ),
              ],
            ),
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

  Future<void> saveTask() async {
    final title = titleController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nama tugas belum diisi.',
          ),
        ),
      );
      return;
    }

    if (editing) {
      final task = widget.task!;

      task.title = title;
      task.date = date;
      task.time = time;
      task.priority = priority;
      task.note = noteController.text.trim();

      await widget.store.updateTask(task);
    } else {
      final task = Task(
        id: DateTime.now()
            .microsecondsSinceEpoch
            .toString(),
        title: title,
        date: date,
        time: time,
        priority: priority,
        note: noteController.text.trim(),
      );

      await widget.store.addTask(task);
    }

    if (!mounted) return;

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          editing ? 'Edit Tugas' : 'Tambah Tugas',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          10,
          20,
          30,
        ),
        children: [
          const Text(
            'Nama Tugas',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),

          TextField(
            controller: titleController,
            autofocus: !editing,
            textInputAction:
                TextInputAction.next,
            decoration: const InputDecoration(
              hintText: 'Contoh: Rapat tim marketing',
              prefixIcon: Icon(Icons.edit_outlined),
            ),
          ),

          const SizedBox(height: 20),

          _choiceCard(
            icon: Icons.calendar_month,
            title: 'Tanggal',
            value: formatDate(date),
            onTap: pickDate,
          ),

          const SizedBox(height: 10),

          _choiceCard(
            icon: Icons.access_time,
            title: 'Waktu',
            value: timeText(time),
            onTap: pickTime,
          ),

          const SizedBox(height: 10),

          _choiceCard(
            icon: Icons.flag_outlined,
            title: 'Prioritas',
            value: priority,
            onTap: pickPriority,
          ),

          const SizedBox(height: 20),

          const Text(
            'Catatan',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 8),

          TextField(
            controller: noteController,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText:
                  'Tambahkan catatan jika diperlukan...',
              alignLabelWithHint: true,
            ),
          ),

          const SizedBox(height: 25),

          SizedBox(
            height: 56,
            child: FilledButton.icon(
              onPressed: saveTask,
              style: FilledButton.styleFrom(
                backgroundColor: lifeYellow,
                foregroundColor: lifeDark,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(17),
                ),
              ),
              icon: Icon(
                editing
                    ? Icons.save_outlined
                    : Icons.add_task,
              ),
              label: Text(
                editing
                    ? 'Simpan Perubahan'
                    : 'Simpan Tugas',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _choiceCard({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 4,
        ),
        leading: Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: lifeYellow.withValues(alpha: .20),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            color: lifeDark,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 15,
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
}

// ============================================================
// TASK TILE
// ============================================================

Widget _taskTile(
  BuildContext context,
  Task task,
  LifePlusStore store,
) {
  return Card(
    margin: const EdgeInsets.only(bottom: 9),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onLongPress: () {
        _taskActions(
          context,
          task,
          store,
        );
      },
      onTap: () {
        Navigator.push(
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
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Checkbox(
              value: task.done,
              activeColor: lifeGreen,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(5),
              ),
              onChanged: (value) async {
                task.done = value ?? false;
                await store.updateTask(task);
              },
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      decoration: task.done
                          ? TextDecoration.lineThrough
                          : null,
                      color: task.done
                          ? Colors.black45
                          : lifeDark,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 13,
                        color: Colors.black45,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formatShortDate(task.date),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(width: 9),
                      const Icon(
                        Icons.access_time,
                        size: 13,
                        color: Colors.black45,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeText(task.time),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            _priorityChip(task.priority),
          ],
        ),
      ),
    ),
  );
}

Widget _priorityChip(String priority) {
  Color color;

  if (priority == 'Tinggi') {
    color = lifeRed;
  } else if (priority == 'Sedang') {
    color = lifeOrange;
  } else {
    color = lifeGreen;
  }

  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 9,
      vertical: 6,
    ),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      priority,
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.w800,
        fontSize: 10,
      ),
    ),
  );
}

Future<void> _taskActions(
  BuildContext context,
  Task task,
  LifePlusStore store,
) async {
  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(25),
      ),
    ),
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(18),
              child: Text(
                'Kelola Tugas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),

            ListTile(
              leading: const Icon(
                Icons.edit_outlined,
                color: lifeBlue,
              ),
              title: const Text('Edit tugas'),
              onTap: () {
                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddTaskPage(
                      store: store,
                      task: task,
                    ),
                  ),
                );
              },
            ),

            ListTile(
              leading: Icon(
                task.done
                    ? Icons.undo
                    : Icons.check_circle_outline,
                color: lifeGreen,
              ),
              title: Text(
                task.done
                    ? 'Tandai belum selesai'
                    : 'Tandai selesai',
              ),
              onTap: () async {
                Navigator.pop(context);

                task.done = !task.done;

                await store.updateTask(task);
              },
            ),

            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: lifeRed,
              ),
              title: const Text(
                'Hapus tugas',
                style: TextStyle(
                  color: lifeRed,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);

                final confirm =
                    await showDialog<bool>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text(
                        'Hapus tugas?',
                      ),
                      content: Text(
                        'Tugas "${task.title}" akan dihapus.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(
                              context,
                              false,
                            );
                          },
                          child:
                              const Text('Batal'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: lifeRed,
                          ),
                          onPressed: () {
                            Navigator.pop(
                              context,
                              true,
                            );
                          },
                          child:
                              const Text('Hapus'),
                        ),
                      ],
                    );
                  },
                );

                if (confirm == true) {
                  await store.deleteTask(
                    task.id,
                  );
                }
              },
            ),

            const SizedBox(height: 10),
          ],
        ),
      );
    },
  );
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
  State<ReminderPage> createState() =>
      _ReminderPageState();
}

class _ReminderPageState
    extends State<ReminderPage> {
  Future<void> addReminder({
    Reminder? existing,
  }) async {
    final titleController =
        TextEditingController(
      text: existing?.title ?? '',
    );

    TimeOfDay selectedTime =
        existing?.time ?? TimeOfDay.now();

    bool repeatDaily =
        existing?.repeatDaily ?? false;

    final result =
        await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context)
                        .viewInsets
                        .bottom +
                    20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    existing == null
                        ? 'Tambah Pengingat'
                        : 'Edit Pengingat',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 18),

                  TextField(
                    controller: titleController,
                    decoration:
                        const InputDecoration(
                      prefixIcon: Icon(
                        Icons.notifications_none,
                      ),
                      hintText:
                          'Contoh: Waktu olahraga',
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
                      Icons.access_time,
                    ),
                    title: const Text(
                      'Waktu',
                    ),
                    subtitle: Text(
                      timeText(selectedTime),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                    ),
                    onTap: () async {
                      final selected =
                          await showTimePicker(
                        context: context,
                        initialTime:
                            selectedTime,
                      );

                      if (selected != null) {
                        setModalState(() {
                          selectedTime = selected;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 5),

                  SwitchListTile(
                    contentPadding:
                        EdgeInsets.zero,
                    title: const Text(
                      'Ulangi setiap hari',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                    subtitle: const Text(
                      'Pengingat aktif setiap hari',
                    ),
                    value: repeatDaily,
                    activeColor: lifeYellow,
                    onChanged: (value) {
                      setModalState(() {
                        repeatDaily = value;
                      });
                    },
                  ),

                  const SizedBox(height: 15),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: () {
                        if (titleController
                            .text
                            .trim()
                            .isEmpty) {
                          return;
                        }

                        if (existing != null) {
                          existing.title =
                              titleController
                                  .text
                                  .trim();
                          existing.time =
                              selectedTime;
                          existing.repeatDaily =
                              repeatDaily;
                        }

                        Navigator.pop(
                          context,
                          true,
                        );
                      },
                      style:
                          FilledButton.styleFrom(
                        backgroundColor:
                            lifeYellow,
                        foregroundColor:
                            lifeDark,
                      ),
                      child: Text(
                        existing == null
                            ? 'Simpan Pengingat'
                            : 'Simpan Perubahan',
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    final title =
        titleController.text.trim();

    titleController.dispose();

    if (result != true || title.isEmpty) {
      return;
    }

    if (existing != null) {
      await widget.store
          .updateReminder(existing);
    } else {
      await widget.store.addReminder(
        Reminder(
          id: DateTime.now()
              .microsecondsSinceEpoch
              .toString(),
          title: title,
          time: selectedTime,
          repeatDaily: repeatDaily,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reminders =
        [...widget.store.reminders];

    reminders.sort(
      (a, b) => timeToMinutes(a.time)
          .compareTo(timeToMinutes(b.time)),
    );

    return Scaffold(
      backgroundColor: background,
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () => addReminder(),
        backgroundColor: lifeYellow,
        foregroundColor: lifeDark,
        icon: const Icon(Icons.add),
        label: const Text(
          'Tambah',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          24,
          20,
          100,
        ),
        children: [
          const Text(
            'Pengingat',
            style: TextStyle(
              fontSize: 29,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Atur waktu agar tidak ada hal penting yang terlewat.',
            style: TextStyle(
              color: Colors.black54,
            ),
          ),

          const SizedBox(height: 20),

          if (reminders.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    const Icon(
                      Icons.notifications_none,
                      size: 58,
                      color: Colors.black26,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Belum ada pengingat',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Tambahkan pengingat pertama Anda.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...reminders.map(
              (reminder) =>
                  _reminderCard(reminder),
            ),

          const SizedBox(height: 20),

          Card(
            color: const Color(0xFFFFF9D7),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: lifeOrange,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Pengingat V2 tersimpan di HP. Notifikasi sistem Android akan kita aktifkan pada tahap berikutnya.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reminderCard(
    Reminder reminder,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 6,
        ),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: reminder.active
                ? lifeYellow
                : Colors.black12,
            borderRadius:
                BorderRadius.circular(15),
          ),
          child: Icon(
            reminder.repeatDaily
                ? Icons.repeat
                : Icons.notifications,
            color: reminder.active
                ? lifeDark
                : Colors.black38,
          ),
        ),
        title: Text(
          reminder.title,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: reminder.active
                ? lifeDark
                : Colors.black45,
          ),
        ),
        subtitle: Text(
          '${timeText(reminder.time)} • ${reminder.repeatDaily ? 'Setiap hari' : 'Sekali'}',
        ),
        trailing: Switch(
          value: reminder.active,
          activeColor: lifeYellow,
          onChanged: (value) async {
            reminder.active = value;

            await widget.store
                .updateReminder(reminder);
          },
        ),
        onTap: () {
          addReminder(
            existing: reminder,
          );
        },
        onLongPress: () async {
          await _reminderActions(
            reminder,
          );
        },
      ),
    );
  }

  Future<void> _reminderActions(
    Reminder reminder,
  ) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'Kelola Pengingat',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.edit_outlined,
                  color: lifeBlue,
                ),
                title: const Text(
                  'Edit pengingat',
                ),
                onTap: () {
                  Navigator.pop(context);

                  addReminder(
                    existing: reminder,
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: lifeRed,
                ),
                title: const Text(
                  'Hapus pengingat',
                  style: TextStyle(
                    color: lifeRed,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);

                  final confirm =
                      await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text(
                          'Hapus pengingat?',
                        ),
                        content: Text(
                          'Pengingat "${reminder.title}" akan dihapus.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(
                                context,
                                false,
                              );
                            },
                            child:
                                const Text('Batal'),
                          ),
                          FilledButton(
                            style:
                                FilledButton.styleFrom(
                              backgroundColor:
                                  lifeRed,
                            ),
                            onPressed: () {
                              Navigator.pop(
                                context,
                                true,
                              );
                            },
                            child:
                                const Text('Hapus'),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirm == true) {
                    await widget.store
                        .deleteReminder(
                      reminder.id,
                    );
                  }
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// STATISTICS PAGE
// ============================================================

class StatsPage extends StatefulWidget {
  final LifePlusStore store;

  const StatsPage({
    super.key,
    required this.store,
  });

  @override
  State<StatsPage> createState() =>
      _StatsPageState();
}

class _StatsPageState
    extends State<StatsPage> {
  int period = 0;

  @override
  Widget build(BuildContext context) {
    final total = widget.store.tasks.length;

    final done = widget.store.tasks
        .where((task) => task.done)
        .length;

    final pending = total - done;

    final percentage = total == 0
        ? 0
        : ((done / total) * 100).round();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        20,
        24,
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

        const SizedBox(height: 5),

        const Text(
          'Lihat perkembangan produktivitas Anda.',
          style: TextStyle(
            color: Colors.black54,
          ),
        ),

        const SizedBox(height: 20),

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

        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                SizedBox(
                  width: 125,
                  height: 125,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child:
                            CircularProgressIndicator(
                          value: total == 0
                              ? 0
                              : done / total,
                          strokeWidth: 13,
                          backgroundColor:
                              Colors.black12,
                          color: lifeGreen,
                        ),
                      ),
                      Column(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          Text(
                            '$percentage%',
                            style:
                                const TextStyle(
                              fontSize: 25,
                              fontWeight:
                                  FontWeight.w900,
                            ),
                          ),
                          const Text(
                            'Selesai',
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 22),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      _legend(
                        lifeGreen,
                        'Selesai',
                        done,
                      ),
                      _legend(
                        lifeBlue,
                        'Belum selesai',
                        pending,
                      ),
                      _legend(
                        lifeRed,
                        'Terlambat',
                        _lateTasks(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 18),

        Row(
          children: [
            Expanded(
              child: _statBox(
                '$total',
                'Total',
                lifeBlue,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statBox(
                '$done',
                'Selesai',
                lifeGreen,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statBox(
                '$pending',
                'Belum',
                lifeOrange,
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Perkembangan Mingguan',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 22),

                SizedBox(
                  height: 150,
                  child: _weeklyChart(),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 18),

        Card(
          color: const Color(0xFFFFF9D7),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration:
                      const BoxDecoration(
                    color: lifeYellow,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: lifeDark,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tetap semangat!',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        total == 0
                            ? 'Mulai buat tugas untuk melihat perkembangan Anda.'
                            : 'Anda sudah menyelesaikan $percentage% dari semua tugas.',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  int _lateTasks() {
    final now = DateTime.now();

    return widget.store.tasks.where((task) {
      if (task.done) return false;

      final dateTime = DateTime(
        task.date.year,
        task.date.month,
        task.date.day,
        task.time.hour,
        task.time.minute,
      );

      return dateTime.isBefore(now);
    }).length;
  }

  Widget _legend(
    Color color,
    String label,
    int value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
              ),
            ),
          ),
          Text(
            '$value',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBox(
    String value,
    String label,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 8,
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _weeklyChart() {
    final now = DateTime.now();

    final values = <int>[];

    for (int i = 6; i >= 0; i--) {
      final day =
          DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(
            Duration(days: i),
          );

      final count =
          widget.store.tasks.where((task) {
        return sameDay(task.date, day) &&
            task.done;
      }).length;

      values.add(count);
    }

    final maxValue = values.isEmpty
        ? 1
        : values.reduce(
              (a, b) => a > b ? a : b,
            ) ==
            0
        ? 1
        : values.reduce(
              (a, b) => a > b ? a : b,
            );

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.end,
      mainAxisAlignment:
          MainAxisAlignment.spaceAround,
      children: List.generate(7, (index) {
        final height =
            25 +
            ((values[index] / maxValue) * 85);

        final day =
            now.subtract(
              Duration(days: 6 - index),
            );

        return Column(
          mainAxisAlignment:
              MainAxisAlignment.end,
          children: [
            Text(
              '${values[index]}',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 25,
              height: height,
              decoration: BoxDecoration(
                color:
                  lifeGreen.withValues(alpha: .80),
                borderRadius:
                    BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              formatDay(day)
                  .substring(0, 3),
              style: const TextStyle(
                fontSize: 9,
                color: Colors.black54,
              ),
            ),
          ],
        );
      }),
    );
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
        24,
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

        const SizedBox(height: 5),

        const Text(
          'Sesuaikan LIFE+ dengan kebutuhan Anda.',
          style: TextStyle(
            color: Colors.black54,
          ),
        ),

        const SizedBox(height: 20),

        _profileCard(context),

        const SizedBox(height: 14),

        Card(
          child: Column(
            children: [
              _settingItem(
                icon: Icons.notifications_none,
                title: 'Pengingat',
                subtitle:
                    '${store.reminders.length} pengingat tersimpan',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ReminderPage(
                        store: store,
                      ),
                    ),
                  );
                },
              ),

              const Divider(height: 1),

              _settingItem(
                icon: Icons.palette_outlined,
                title: 'Tema',
                subtitle: 'Terang',
                onTap: () {
                  _showThemeInfo(context);
                },
              ),

              const Divider(height: 1),

              _settingItem(
                icon: Icons.storage_outlined,
                title: 'Data & Penyimpanan',
                subtitle:
                    '${store.tasks.length} tugas • ${store.reminders.length} pengingat',
                onTap: () {
                  _showStorageInfo(context);
                },
              ),

              const Divider(height: 1),

              _settingItem(
                icon: Icons.info_outline,
                title: 'Tentang LIFE+',
                subtitle: 'Versi 2.0',
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'LIFE+',
                    applicationVersion:
                        '2.0.0',
                    applicationIcon:
                        Container(
                      width: 48,
                      height: 48,
                      decoration:
                          BoxDecoration(
                        color: lifeYellow,
                        borderRadius:
                            BorderRadius.circular(
                          13,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'L+',
                          style: TextStyle(
                            fontWeight:
                                FontWeight.w900,
                            color: lifeDark,
                          ),
                        ),
                      ),
                    ),
                    applicationLegalese:
                        'Atur Hari, Raih Hidup yang Lebih Baik',
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: lifeYellow,
                  size: 30,
                ),
                const SizedBox(height: 8),
                const Text(
                  'LIFE+',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Atur Hari, Raih Hidup yang Lebih Baik',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _profileCard(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _editName(context),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            children: [
              Container(
                width: 55,
                height: 55,
                decoration: const BoxDecoration(
                  color: lifeYellow,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: lifeDark,
                  size: 29,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.userName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Pengguna LIFE+',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 5,
      ),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.Colors.black.withValues(alpha: .05),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 11,
        ),
      ),
      trailing:
          const Icon(Icons.chevron_right),
      onTap: onTap,
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
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Nama pengguna',
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization:
                TextCapitalization.words,
            decoration:
                const InputDecoration(
              hintText: 'Masukkan nama',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: lifeYellow,
                foregroundColor: lifeDark,
              ),
              onPressed: () {
                Navigator.pop(
                  context,
                  controller.text,
                );
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (result != null) {
      await store.setName(result);
    }
  }

  void _showThemeInfo(
    BuildContext context,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tema'),
          content: const Text(
            'Saat ini LIFE+ menggunakan tema terang dengan warna utama kuning LIFE+.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  void _showStorageInfo(
    BuildContext context,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Data & Penyimpanan',
          ),
          content: Text(
            'Data LIFE+ disimpan secara lokal di HP.\n\n'
            'Tugas: ${store.tasks.length}\n'
            'Pengingat: ${store.reminders.length}\n\n'
            'Data akan tetap tersedia selama data aplikasi tidak dihapus.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }
}
