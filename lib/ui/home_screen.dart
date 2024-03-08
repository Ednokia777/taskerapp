import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:taskerapp/db/task.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../service/app_localizations.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late String _filter;
  late GlobalKey<AnimatedListState> _listKey;
  late List<Task> _tasks;

  @override
  void initState() {
    super.initState();
    _filter = 'all';
    _tasks = Hive.box<Task>('tasks').values.toList();
    _listKey = GlobalKey<AnimatedListState>();
  }

  void _updateTasksList() {
    setState(() {
      _tasks = Hive.box<Task>('tasks').values.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    List<DropdownMenuItem<String>> filterItems = [
      DropdownMenuItem(value: 'all', child: Text(loc.translate('all'))),
      DropdownMenuItem(value: 'completed', child: Text(loc.translate('completed'))),
      DropdownMenuItem(value: 'not_completed', child: Text(loc.translate('not_completed'))),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('my_tasks')),
        actions: [
          _buildFilterDropdown(filterItems),
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Task>('tasks').listenable(),
        builder: (context, Box<Task> box, _) {
          var tasks = box.values.toList();
          if (_filter == 'completed') {
            tasks = tasks.where((Task task) => task.isCompleted == true).toList();
          } else if (_filter == 'not_completed') {
            tasks = tasks.where((Task task) => task.isCompleted == false).toList();
          }
          return AnimatedList(
            key: _listKey,
            initialItemCount: tasks.length,
            itemBuilder: (context, index, animation) {
              final task = tasks[index];
              return _buildTaskItem(context, task, index, animation);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterDropdown(List<DropdownMenuItem<String>> filterItems) {
    return DropdownButton<String>(
      value: _filter,
      onChanged: (String? newValue) {
        setState(() {
          _filter = newValue!;
          _listKey = GlobalKey<AnimatedListState>();
        });
      },
      items: filterItems,
    );
  }

  Widget _buildTaskItem(BuildContext context, Task task, int index, Animation<double> animation) {
    final box = Hive.box<Task>('tasks');
    final loc = AppLocalizations.of(context)!;
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-1, 0),
        end: Offset(0, 0),
      ).animate(animation),
      child: GestureDetector(
        onTap: () => _showTaskDialog(context, task, index),
        onLongPress: () async {
          final currentTask = box.getAt(index) as Task;
          final updatedTask = Task(
            id: currentTask.id,
            title: currentTask.title,
            description: currentTask.description,
            isCompleted: !currentTask.isCompleted,
            dueDate: currentTask.dueDate,
          );
          await box.putAt(index, updatedTask);
          setState(() {});
        },
        child: Card(
          key: ValueKey(task.id),
          child: ListTile(
            title: Text(
              task.title,
              style: TextStyle(
                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                color: task.isCompleted ? Colors.grey : Colors.black,
              ),
            ),
            subtitle: Text(
              '${loc.translate('date_complete')} ${DateFormat('yyyy-MM-dd').format(task.dueDate)}',
              style: TextStyle(
                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                color: task.isCompleted ? Colors.grey : Colors.black,
              ),
            ),
            trailing: Icon(task.isCompleted ? Icons.check : Icons.hourglass_empty),
          ),
        ),
      ),
    );
  }

  void _addNewTask(Task newTask) async {
    var box = Hive.box<Task>('tasks');
    await box.add(newTask);
    _updateTasksList();
    _listKey.currentState?.insertItem(_tasks.indexOf(newTask), duration: Duration(milliseconds: 300));
  }
  void addItem(Task newTask) {
    var box = Hive.box<Task>('tasks');
    box.add(newTask);

    int newIndex = box.values.length - 1;
    _listKey.currentState?.insertItem(newIndex);
  }

  void removeItem(int index) {
    var box = Hive.box<Task>('tasks');
    Task taskToRemove = _tasks[index];
    _listKey.currentState?.removeItem(
      index,
          (context, animation) => _buildTaskItem(context, taskToRemove, index, animation),
      duration: Duration(milliseconds: 250),
    );
    box.deleteAt(box.keys.toList()[index]);
    _updateTasksList();
  }

  void _showAddTaskDialog(BuildContext context) {
    final TextEditingController _titleController = TextEditingController();
    final TextEditingController _descriptionController = TextEditingController();
    DateTime? _dueDate;
    Future<void> _selectDueDate(BuildContext context, StateSetter setState) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _dueDate ?? DateTime.now(),
        firstDate: DateTime(2022),
        lastDate: DateTime(2101),
      );
      if (picked != null && picked != _dueDate) {
        setState(() {
          _dueDate = picked;
        });
      }
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final loc = AppLocalizations.of(context)!;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(loc.translate('add_new_task')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(hintText: loc.translate('task_name_hint')),
                    ),
                    TextField(
                      controller: _descriptionController,
                      decoration: InputDecoration(hintText: loc.translate('task_description_hint')),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => _selectDueDate(context, setState),
                      child: Text(loc.translate('select_due_date')),
                    ),
                    if (_dueDate != null)
                      Text('${loc.translate('selected_due_date')} ${DateFormat('yyyy-MM-dd').format(_dueDate!)}'),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(loc.translate('cancel')),
                ),
                TextButton(
                  onPressed: () async {
                    final String title = _titleController.text.trim();
                    final String description = _descriptionController.text.trim();
                    if (title.isEmpty || description.isEmpty || _dueDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(loc.translate('all_fields_required'))),
                      );
                      return;
                    }

                    var newTask = Task(
                      title: title,
                      description: description,
                      isCompleted: false,
                      dueDate: _dueDate!,
                    );
                    _addNewTask(newTask);
                    Navigator.of(context).pop();
                  },
                  child: Text(loc.translate('create')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showTaskDialog(BuildContext context, Task task, int taskIndex) {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController _titleController = TextEditingController(text: task.title);
        final TextEditingController _descriptionController = TextEditingController(text: task.description);
        DateTime? _dueDate = task.dueDate;
        final loc = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(loc.translate('task_info')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(hintText: loc.translate('task_name_hint')),
                ),
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(hintText: loc.translate('task_description_hint')),
                ),
                Text('${loc.translate('date_complete')} ${DateFormat('yyyy-MM-dd').format(_dueDate)}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                final editedTask = Task(
                  title: _titleController.text,
                  description: _descriptionController.text,
                  isCompleted: task.isCompleted,
                  dueDate: _dueDate!,
                );
                Hive.box<Task>('tasks').putAt(taskIndex, editedTask);
                Navigator.of(context).pop();
              },
              child: Text(loc.translate('save')),
            ),
            TextButton(
              onPressed: () {
                _confirmDelete(context, taskIndex);
              },
              child: Text(loc.translate('delete')),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(loc.translate('close')),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, int taskIndex) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(loc.translate('confirm_deletion')),
          content: Text(loc.translate('confirm_deletion_text')),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                final task = Hive.box<Task>('tasks').getAt(taskIndex) as Task;
                _listKey.currentState!.removeItem(taskIndex, (context, animation) {
                  return _buildTaskItem(context, task, taskIndex, animation);
                }, duration: Duration(milliseconds: 250));
                Future.delayed(Duration(milliseconds: 250), () {
                  Hive.box<Task>('tasks').deleteAt(taskIndex);
                });
                Navigator.of(context).pop();
              },
              child: Text(loc.translate('yes')),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(loc.translate('no')),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final loc = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(loc.translate('confirmation')),
          content: Text(loc.translate('logout_confirmation')),
          actions: <Widget>[
            TextButton(
              child: Text(loc.translate('no')),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(loc.translate('yes')),
              onPressed: () {
                _logout(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _logout(BuildContext context) async {
    final box = Hive.box<Task>('tasks');
    await box.clear();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => LoginScreen()));
  }
}
