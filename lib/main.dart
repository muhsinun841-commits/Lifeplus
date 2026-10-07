import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LifePlusApp());
}

const yellow = Color(0xFFFFD21F);
const dark = Color(0xFF111417);
const green = Color(0xFF20B26B);
const red = Color(0xFFE74C3C);
const blue = Color(0xFF2589E8);

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

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'date': date.toIso8601String(),
    'hour': time.hour,
    'minute': time.minute,
    'priority': priority,
    'note': note,
    'done': done,
  };

  factory Task.fromJson(Map<String, dynamic> j) => Task(
    id: j['id'],
    title: j['title'],
    date: DateTime.parse(j['date']),
    time: TimeOfDay(hour: j['hour'], minute: j['minute']),
    priority: j['priority'],
    note: j['note'] ?? '',
    done: j['done'] ?? false,
  );
}

class Reminder {
  String id;
  String title;
  TimeOfDay time;
  bool active;

  Reminder({
    required this.id,
    required this.title,
    required this.time,
    this.active = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'hour': time.hour,
    'minute': time.minute,
    'active': active,
  };

  factory Reminder.fromJson(Map<String, dynamic> j) => Reminder(
    id: j['id'],
    title: j['title'],
    time: TimeOfDay(hour: j['hour'], minute: j['minute']),
    active: j['active'] ?? true,
  );
}

class LifePlusStore extends ChangeNotifier {
  List<Task> tasks = [];
  List<Reminder> reminders = [];
  String userName = 'Muhammad';

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    userName = p.getString('userName') ?? 'Muhammad';
    final ts = p.getString('tasks');
    final rs = p.getString('reminders');
    if (ts != null) {
      tasks = (jsonDecode(ts) as List).map((e) => Task.fromJson(e)).toList();
    }
    if (rs != null) {
      reminders = (jsonDecode(rs) as List).map((e) => Reminder.fromJson(e)).toList();
    }
    notifyListeners();
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('userName', userName);
    await p.setString('tasks', jsonEncode(tasks.map((e) => e.toJson()).toList()));
    await p.setString('reminders', jsonEncode(reminders.map((e) => e.toJson()).toList()));
  }

  Future<void> addTask(Task t) async { tasks.add(t); await save(); notifyListeners(); }
  Future<void> updateTask(Task t) async {
    final i = tasks.indexWhere((x) => x.id == t.id);
    if (i >= 0) tasks[i] = t;
    await save(); notifyListeners();
  }
  Future<void> deleteTask(String id) async {
    tasks.removeWhere((x) => x.id == id);
    await save(); notifyListeners();
  }
  Future<void> addReminder(Reminder r) async { reminders.add(r); await save(); notifyListeners(); }
  Future<void> updateReminder(Reminder r) async {
    final i = reminders.indexWhere((x) => x.id == r.id);
    if (i >= 0) reminders[i] = r;
    await save(); notifyListeners();
  }
  Future<void> setName(String name) async { userName = name.trim().isEmpty ? 'Pengguna' : name.trim(); await save(); notifyListeners(); }
}

class LifePlusApp extends StatefulWidget {
  const LifePlusApp({super.key});
  @override State<LifePlusApp> createState() => _LifePlusAppState();
}

class _LifePlusAppState extends State<LifePlusApp> {
  final store = LifePlusStore();

  @override
  void initState() {
    super.initState();
    store.load();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (_, __) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'LIFE+',
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF8F9FA),
          colorScheme: ColorScheme.fromSeed(seedColor: yellow, brightness: Brightness.light),
          fontFamily: 'sans',
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
        home: MainShell(store: store),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  final LifePlusStore store;
  const MainShell({super.key, required this.store});
  @override State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(store: widget.store, onAdd: () => _addTask(context)),
      TasksPage(store: widget.store, onAdd: () => _addTask(context)),
      StatsPage(store: widget.store),
      SettingsPage(store: widget.store),
    ];
    return Scaffold(
      body: SafeArea(child: pages[index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (v) => setState(() => index = v),
        indicatorColor: yellow,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.check_box_outlined), selectedIcon: Icon(Icons.check_box), label: 'Tugas'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Statistik'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Pengaturan'),
        ],
      ),
    );
  }

  Future<void> _addTask(BuildContext context) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => AddTaskPage(store: widget.store)));
  }
}

class HomePage extends StatelessWidget {
  final LifePlusStore store;
  final VoidCallback onAdd;
  const HomePage({super.key, required this.store, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = store.tasks.where((t) => _sameDay(t.date, now)).toList()
      ..sort((a,b) => _minutes(a.time).compareTo(_minutes(b.time)));
    final done = store.tasks.where((t) => t.done).length;
    final total = store.tasks.length;
    final progress = total == 0 ? 0.0 : done / total;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        Row(
          children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Selamat ${_greeting()},', style: const TextStyle(fontSize: 15)),
              Text('${store.userName} 👋', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              const Text('Apa yang perlu diselesaikan hari ini?', style: TextStyle(color: Colors.black54)),
            ])),
            IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsPage(store: store))), icon: const Icon(Icons.settings_outlined)),
          ],
        ),
        const SizedBox(height: 18),
        Card(
          elevation: 0,
          color: yellow,
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.calendar_month, color: dark)),
            title: const Text('Hari ini', style: TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now)),
            trailing: const Icon(Icons.chevron_right),
          ),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _statCard(Icons.notifications_none, '${store.reminders.where((r)=>r.active).length}', 'Pengingat', red)),
          const SizedBox(width: 10),
          Expanded(child: _statCard(Icons.task_alt, '$total', 'Tugas', green)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _statCard(Icons.bar_chart, 'Rp 0', 'Pengeluaran hari ini', blue)),
          const SizedBox(width: 10),
          Expanded(child: _statCard(Icons.track_changes, '${(progress*100).round()}%', 'Tugas selesai', red)),
        ]),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Tugas Terdekat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TasksPage(store: store, onAdd: onAdd))), child: const Text('Lihat semua')),
        ]),
        if (today.isEmpty)
          _empty('Belum ada tugas untuk hari ini.', onAdd)
        else
          ...today.take(5).map((t) => _taskTile(context, t)),
        const SizedBox(height: 8),
        SizedBox(height: 52, child: FilledButton.icon(
          onPressed: onAdd,
          style: FilledButton.styleFrom(backgroundColor: yellow, foregroundColor: dark),
          icon: const Icon(Icons.add),
          label: const Text('Tambah Tugas', style: TextStyle(fontWeight: FontWeight.w800)),
        )),
      ],
    );
  }

  Widget _statCard(IconData icon, String value, String label, Color iconColor) => Card(
    elevation: 0,
    child: Padding(padding: const EdgeInsets.all(15), child: Row(children: [
      Icon(icon, color: iconColor, size: 28),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ])),
    ])),
  );
}

class TasksPage extends StatefulWidget {
  final LifePlusStore store;
  final VoidCallback onAdd;
  const TasksPage({super.key, required this.store, required this.onAdd});
  @override State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  int filter = 0;
  @override
  Widget build(BuildContext context) {
    List<Task> list = [...widget.store.tasks];
    if (filter == 1) list = list.where((t) => !t.done).toList();
    if (filter == 2) list = list.where((t) => t.done).toList();
    list.sort((a,b) {
      final d = a.date.compareTo(b.date);
      return d != 0 ? d : _minutes(a.time).compareTo(_minutes(b.time));
    });

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        const Text('Tugas', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('Semua')),
            ButtonSegment(value: 1, label: Text('Belum Selesai')),
            ButtonSegment(value: 2, label: Text('Selesai')),
          ],
          selected: {filter},
          onSelectionChanged: (s) => setState(() => filter = s.first),
        ),
        const SizedBox(height: 16),
        if (list.isEmpty) _empty('Belum ada tugas.', widget.onAdd)
        else ...list.map((t) => _taskTile(context, t, store: widget.store)),
        const SizedBox(height: 12),
        FloatingActionButton.extended(
          onPressed: widget.onAdd,
          backgroundColor: yellow,
          foregroundColor: dark,
          icon: const Icon(Icons.add),
          label: const Text('Tambah Tugas'),
        ),
      ],
    );
  }
}

class AddTaskPage extends StatefulWidget {
  final LifePlusStore store;
  const AddTaskPage({super.key, required this.store});
  @override State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final title = TextEditingController();
  final note = TextEditingController();
  DateTime date = DateTime.now();
  TimeOfDay time = TimeOfDay.now();
  String priority = 'Sedang';

  @override
  void dispose() { title.dispose(); note.dispose(); super.dispose(); }

  Future<void> pickDate() async {
    final d = await showDatePicker(context: context, firstDate: DateTime.now().subtract(const Duration(days: 3650)), lastDate: DateTime.now().add(const Duration(days: 3650)), initialDate: date);
    if (d != null) setState(() => date = d);
  }
  Future<void> pickTime() async {
    final t = await showTimePicker(context: context, initialTime: time);
    if (t != null) setState(() => time = t);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Tambah Tugas', style: TextStyle(fontWeight: FontWeight.w800))),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      TextField(controller: title, decoration: const InputDecoration(hintText: 'Masukkan nama tugas...', prefixIcon: Icon(Icons.edit))),
      const SizedBox(height: 12),
      _choice(Icons.calendar_month, 'Tanggal', DateFormat('d MMMM yyyy', 'id_ID').format(date), pickDate),
      _choice(Icons.access_time, 'Waktu', time.format(context), pickTime),
      _choice(Icons.flag_outlined, 'Prioritas', priority, () async {
        final p = await showModalBottomSheet<String>(context: context, builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: ['Rendah','Sedang','Tinggi'].map((x) => ListTile(title: Text(x), onTap: ()=>Navigator.pop(context,x))).toList())));
        if (p != null) setState(() => priority = p);
      }),
      const SizedBox(height: 12),
      TextField(controller: note, maxLines: 4, decoration: const InputDecoration(labelText: 'Catatan (opsional)', alignLabelWithHint: true, hintText: 'Tambahkan catatan...')),
      const SizedBox(height: 24),
      SizedBox(height: 52, child: FilledButton.icon(
        onPressed: () async {
          if (title.text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama tugas belum diisi.')));
            return;
          }
          await widget.store.addTask(Task(id: DateTime.now().microsecondsSinceEpoch.toString(), title: title.text.trim(), date: date, time: time, priority: priority, note: note.text.trim()));
          if (mounted) Navigator.pop(context);
        },
        style: FilledButton.styleFrom(backgroundColor: yellow, foregroundColor: dark),
        icon: const Icon(Icons.save_outlined),
        label: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.w800)),
      )),
    ]),
  );

  Widget _choice(IconData icon, String label, String value, VoidCallback onTap) => Card(
    elevation: 0,
    child: ListTile(leading: Icon(icon), title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)), subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.w700)), trailing: const Icon(Icons.chevron_right), onTap: onTap),
  );
}

class StatsPage extends StatelessWidget {
  final LifePlusStore store;
  const StatsPage({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final total = store.tasks.length;
    final done = store.tasks.where((t)=>t.done).length;
    final pending = total - done;
    final pct = total == 0 ? 0 : (done / total * 100).round();

    return ListView(padding: const EdgeInsets.fromLTRB(20,20,20,24), children: [
      const Text('Statistik Tugas', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
      const SizedBox(height: 14),
      const SegmentedButton<int>(segments: [ButtonSegment(value: 0, label: Text('Minggu')), ButtonSegment(value: 1, label: Text('Bulan')), ButtonSegment(value: 2, label: Text('Tahun'))], selected: {0}, onSelectionChanged: null),
      const SizedBox(height: 18),
      Card(elevation: 0, child: Padding(padding: const EdgeInsets.all(22), child: Row(children: [
        SizedBox(width: 125, height: 125, child: Stack(alignment: Alignment.center, children: [
          CircularProgressIndicator(value: total == 0 ? 0 : done/total, strokeWidth: 14, backgroundColor: Colors.black12, color: green),
          Column(mainAxisSize: MainAxisSize.min, children: [Text('$total', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)), const Text('Total Tugas')])
        ])),
        const SizedBox(width: 22),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _legend(green, 'Selesai', done),
          _legend(blue, 'Belum selesai', pending),
          _legend(red, 'Terlambat', 0),
        ])
      ]))),
      const SizedBox(height: 18),
      Card(elevation: 0, child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Perkembangan', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        Row(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.spaceAround, children: List.generate(7, (i) {
          final h = total == 0 ? 12.0 : (20 + ((done + i) % (total+1)) * 12).toDouble();
          return Column(children: [Container(width: 22, height: h, decoration: BoxDecoration(color: green.withOpacity(.8), borderRadius: BorderRadius.circular(8))), const SizedBox(height: 5), Text(['Sen','Sel','Rab','Kam','Jum','Sab','Min'][i], style: const TextStyle(fontSize: 10))]);
        }))
      ]))),
      const SizedBox(height: 18),
      Card(elevation: 0, color: const Color(0xFFFFF9D7), child: ListTile(leading: const Icon(Icons.emoji_events, color: Colors.orange), title: const Text('Bagus!', style: TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('Kamu sudah menyelesaikan $pct% dari semua tugas.'))),
    ]);
  }

  Widget _legend(Color c, String label, int n) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [CircleAvatar(radius: 5, backgroundColor: c), const SizedBox(width: 8), Text('$label  $n')]));
}

class SettingsPage extends StatelessWidget {
  final LifePlusStore store;
  const SettingsPage({super.key, required this.store});

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(20,20,20,24), children: [
    const Text('Pengaturan', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
    const SizedBox(height: 16),
    Card(elevation: 0, child: ListTile(leading: const CircleAvatar(child: Icon(Icons.person)), title: Text(store.userName, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: const Text('LIFE+ User'), trailing: const Icon(Icons.chevron_right), onTap: () => _editName(context))),
    const SizedBox(height: 12),
    Card(elevation: 0, child: Column(children: [
      ListTile(leading: const Icon(Icons.notifications_none), title: const Text('Notifikasi'), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReminderPage(store: store)))),
      const Divider(height: 1),
      ListTile(leading: const Icon(Icons.palette_outlined), title: const Text('Tema'), trailing: const Text('Terang'), onTap: () {}),
      const Divider(height: 1),
      ListTile(leading: const Icon(Icons.storage_outlined), title: const Text('Data & Penyimpanan'), trailing: const Text('Data lokal'), onTap: () {}),
      const Divider(height: 1),
      ListTile(leading: const Icon(Icons.info_outline), title: const Text('Tentang Aplikasi'), trailing: const Text('Versi 1.0'), onTap: () => showAboutDialog(context: context, applicationName: 'LIFE+', applicationVersion: '1.0.0', applicationLegalese: 'Atur Hari, Raih Hidup yang Lebih Baik')),
    ])),
    const SizedBox(height: 20),
    Card(elevation: 0, child: ListTile(leading: const Icon(Icons.logout, color: red), title: const Text('Keluar', style: TextStyle(color: red)), onTap: () {})),
  ]);

  Future<void> _editName(BuildContext context) async {
    final c = TextEditingController(text: store.userName);
    final result = await showDialog<String>(context: context, builder: (_) => AlertDialog(title: const Text('Nama pengguna'), content: TextField(controller: c, autofocus: true), actions: [TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('Batal')), FilledButton(onPressed: ()=>Navigator.pop(context,c.text), child: const Text('Simpan'))]));
    c.dispose();
    if (result != null) await store.setName(result);
  }
}

class ReminderPage extends StatefulWidget {
  final LifePlusStore store;
  const ReminderPage({super.key, required this.store});
  @override State<ReminderPage> createState() => _ReminderPageState();
}
class _ReminderPageState extends State<ReminderPage> {
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pengingat', style: TextStyle(fontWeight: FontWeight.w800))),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      ...widget.store.reminders.map((r) => Card(elevation: 0, child: ListTile(
        leading: CircleAvatar(backgroundColor: yellow, foregroundColor: dark, child: const Icon(Icons.notifications)),
        title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(r.time.format(context)),
        trailing: Switch(value: r.active, onChanged: (v) async { r.active=v; await widget.store.updateReminder(r); setState(() {}); }),
      ))),
      const SizedBox(height: 12),
      FilledButton.icon(onPressed: _add, style: FilledButton.styleFrom(backgroundColor: yellow, foregroundColor: dark), icon: const Icon(Icons.add), label: const Text('Tambah Pengingat')),
      const SizedBox(height: 12),
      const Text('Catatan V1: data pengingat sudah tersimpan di HP. Notifikasi sistem Android akan kita aktifkan pada tahap berikutnya.', style: TextStyle(color: Colors.black54)),
    ]),
  );

  Future<void> _add() async {
    final c = TextEditingController();
    TimeOfDay time = TimeOfDay.now();
    final ok = await showDialog<bool>(context: context, builder: (_) => StatefulBuilder(builder: (context,setDialog) => AlertDialog(
      title: const Text('Tambah Pengingat'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: c, decoration: const InputDecoration(hintText: 'Nama pengingat')),
        const SizedBox(height: 10),
        ListTile(leading: const Icon(Icons.access_time), title: Text(time.format(context)), onTap: () async { final t=await showTimePicker(context: context, initialTime: time); if(t!=null)setDialog(()=>time=t); })
      ]),
      actions: [TextButton(onPressed: ()=>Navigator.pop(context,false), child: const Text('Batal')), FilledButton(onPressed: ()=>Navigator.pop(context,c.text.trim().isNotEmpty), child: const Text('Simpan'))],
    )));
    if (ok == true) {
      await widget.store.addReminder(Reminder(id: DateTime.now().microsecondsSinceEpoch.toString(), title: c.text.trim(), time: time));
      setState(() {});
    }
    c.dispose();
  }
}

Widget _taskTile(BuildContext context, Task t, {LifePlusStore? store}) {
  return Card(elevation: 0, margin: const EdgeInsets.only(bottom: 8), child: ListTile(
    leading: Checkbox(value: t.done, onChanged: store == null ? null : (v) async { t.done=v??false; await store.updateTask(t); }),
    title: Text(t.title, style: TextStyle(fontWeight: FontWeight.w700, decoration: t.done ? TextDecoration.lineThrough : null)),
    subtitle: Text('${DateFormat('d MMM', 'id_ID').format(t.date)} • ${t.time.format(context)}'),
    trailing: _priority(t.priority),
    onLongPress: store == null ? null : () => _taskActions(context, t, store),
  ));
}

Future<void> _taskActions(BuildContext context, Task t, LifePlusStore store) async {
  await showModalBottomSheet(context: context, builder: (_) => SafeArea(child: Wrap(children: [
    ListTile(leading: const Icon(Icons.delete_outline, color: red), title: const Text('Hapus tugas'), onTap: () async { Navigator.pop(context); await store.deleteTask(t.id); }),
  ])));
}

Widget _priority(String p) {
  final c = p == 'Tinggi' ? red : p == 'Sedang' ? Colors.orange : green;
  return Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: c.withOpacity(.13), borderRadius: BorderRadius.circular(12)), child: Text(p, style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w700)));
}

Widget _empty(String text, VoidCallback onAdd) => Card(elevation: 0, child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [const Icon(Icons.check_circle_outline, size: 46, color: green), const SizedBox(height: 8), Text(text), const SizedBox(height: 10), OutlinedButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Tambah sekarang'))]));

bool _sameDay(DateTime a, DateTime b) => a.year==b.year && a.month==b.month && a.day==b.day;
int _minutes(TimeOfDay t) => t.hour*60+t.minute;
String _greeting() { final h=DateTime.now().hour; if(h<11)return 'pagi'; if(h<15)return 'siang'; if(h<18)return 'sore'; return 'malam'; }
