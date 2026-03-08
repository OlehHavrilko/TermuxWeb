import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/termux_service.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({Key? key}) : super(key: key);
  @override
  _FilesScreenState createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  String _currentPath = '/data/data/com.termux/files/home';
  List<String> _files = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    debugPrint('FilesScreen._loadFiles: loading files from $_currentPath');
    setState(() => _isLoading = true);
    final termux = context.read<TermuxService>();
    try {
      final res = await termux.runCommand('ls -la "$_currentPath"');
      if (!mounted) {
        debugPrint('FilesScreen._loadFiles: widget not mounted, skipping update');
        return;
      }
      setState(() {
        _files = res.split('\n').where((f) => f.trim().isNotEmpty && !f.startsWith('total')).toList();
        _isLoading = false;
      });
      debugPrint('FilesScreen._loadFiles: loaded ${_files.length} files from $_currentPath');
    } catch (e, stackTrace) {
      debugPrint('FilesScreen._loadFiles: error loading files: $e, stackTrace: $stackTrace');
      if (!mounted) {
        debugPrint('FilesScreen._loadFiles: widget not mounted after error, skipping update');
        return;
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createFile() async {
    debugPrint('FilesScreen._createFile: creating new file/dir');
    String name = '';
    try {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('New File/Dir'),
          content: TextField(onChanged: (v) => name = v),
          actions: [
            TextButton(
              child: const Text('Create'),
              onPressed: () async {
                try {
                  Navigator.pop(context);
                  if (name.isNotEmpty) {
                    final termux = context.read<TermuxService>();
                    await termux.runCommand('touch "$_currentPath/$name"');
                    _loadFiles();
                    debugPrint('FilesScreen._createFile: file/dir $name created successfully');
                  }
                } catch (e, stackTrace) {
                  debugPrint('FilesScreen._createFile: error creating file/dir $name: $e, stackTrace: $stackTrace');
                }
              },
            ),
          ],
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('FilesScreen._createFile: error in dialog: $e, stackTrace: $stackTrace');
    }
  }

  Future<void> _deleteFile(String name) async {
    debugPrint('FilesScreen._deleteFile: deleting file/dir $name');
    try {
      final termux = context.read<TermuxService>();
      await termux.runCommand('rm -rf "$_currentPath/$name"');
      _loadFiles();
      debugPrint('FilesScreen._deleteFile: file/dir $name deleted successfully');
    } catch (e, stackTrace) {
      debugPrint('FilesScreen._deleteFile: error deleting file/dir $name: $e, stackTrace: $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentPath.split('/').last),
        leading: IconButton(
          icon: const Icon(Icons.arrow_upward),
          onPressed: () {
            if (_currentPath != '/') {
              setState(() {
                _currentPath = _currentPath.substring(0, _currentPath.lastIndexOf('/'));
                if (_currentPath.isEmpty) _currentPath = '/';
              });
              _loadFiles();
            }
          },
        ),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _createFile),
        ],
      ),
      body: Column(
        children: [
          if (_isLoading) const LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              itemCount: _files.length,
              itemBuilder: (context, index) {
                final fileLine = _files[index];
                final parts = fileLine.split(RegExp(r'\s+'));
                if (parts.length < 9) return const SizedBox();
                final name = parts.sublist(8).join(' ');
                final isDir = parts[0].startsWith('d');
                
                if (name == '.' || name == '..') return const SizedBox();

                return ListTile(
                  leading: Icon(isDir ? Icons.folder : Icons.insert_drive_file),
                  title: Text(name),
                  subtitle: Text(parts[0] + ' ' + parts[4] + ' bytes'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteFile(name),
                  ),
                  onTap: () {
                    if (isDir) {
                      setState(() => _currentPath = '$_currentPath/$name');
                      _loadFiles();
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
