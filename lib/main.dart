import 'package:flutter/material.dart';
import 'database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: TaskManagerApp(),
  ));
}

class TaskManagerApp extends StatefulWidget {
  const TaskManagerApp({super.key});

  @override
  State<TaskManagerApp> createState() => _TaskManagerAppState();
}

class _TaskManagerAppState extends State<TaskManagerApp> {
  List<Task> _tasks = [];

  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshTaskList();
  }

  Future<void> _refreshTaskList() async {
    final data = await DatabaseHelper.instance.getTasks();
    setState(() {
      _tasks = data;
    });
  }

  void _showFormDialog({Task? task}) {
    if (task != null) {
      _titleController.text = task.title;
      _descController.text = task.description;
    } else {
      _titleController.clear();
      _descController.clear();
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(task == null ? 'New Task' : 'Edit Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_titleController.text.isEmpty) return;

              if (task == null) {
                await DatabaseHelper.instance.insertTask(Task(
                  title: _titleController.text,
                  description: _descController.text,
                ));
              } else {
                await DatabaseHelper.instance.updateTask(Task(
                  id: task.id,
                  title: _titleController.text,
                  description: _descController.text,
                  isCompleted: task.isCompleted,
                ));
              }
              _refreshTaskList();
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _toggleTaskStatus(Task task) async {
    final newTask = Task(
      id: task.id,
      title: task.title,
      description: task.description,
      isCompleted: task.isCompleted == 0 ? 1 : 0,
    );
    await DatabaseHelper.instance.updateTask(newTask);
    _refreshTaskList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _tasks.isEmpty
          ? const Center(child: Text('No tasks yet. Add one!'))
          : ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          final task = _tasks[index];
          final isDone = task.isCompleted == 1;

          return Card(
            color: isDone ? Colors.grey[200] : Colors.white,
            child: ListTile(
              leading: Checkbox(
                value: isDone,
                onChanged: (val) => _toggleTaskStatus(task),
                activeColor: Colors.teal,
              ),
              title: Text(
                task.title,
                style: TextStyle(
                  decoration: isDone ? TextDecoration.lineThrough : null,
                  color: isDone ? Colors.grey : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: task.description.isNotEmpty
                  ? Text(task.description, style: TextStyle(color: isDone ? Colors.grey : Colors.black54))
                  : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showFormDialog(task: task),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await DatabaseHelper.instance.deleteTask(task.id!);
                      _refreshTaskList();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}