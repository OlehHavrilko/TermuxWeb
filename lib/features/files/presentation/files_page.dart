import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/termux_service.dart';

class FilesPage extends StatefulWidget {
  const FilesPage({super.key});

  @override
  State<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> {
  String _currentPath = '/data/data/com.termux/files/home';
  List<FileItem> _files = [];
  bool _isLoading = true;
  final List<String> _pathHistory = ['/data/data/com.termux/files/home'];
  int _historyIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadFiles(_currentPath);
  }

  Future<void> _loadFiles(String path) async {
    setState(() => _isLoading = true);
    
    try {
      final termuxService = context.read<TermuxService>();
      final files = await termuxService.listFiles(path);
      setState(() {
        _currentPath = path;
        _files = files;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _navigateToDirectory(String path) {
    // Update history
    if (_historyIndex < _pathHistory.length - 1) {
      _pathHistory.removeRange(_historyIndex + 1, _pathHistory.length);
    }
    _pathHistory.add(path);
    _historyIndex = _pathHistory.length - 1;
    _loadFiles(path);
  }

  void _navigateBack() {
    if (_historyIndex > 0) {
      _historyIndex--;
      _loadFiles(_pathHistory[_historyIndex]);
    }
  }

  void _navigateForward() {
    if (_historyIndex < _pathHistory.length - 1) {
      _historyIndex++;
      _loadFiles(_pathHistory[_historyIndex]);
    }
  }

  String _getFileName(String path) {
    return path.split('/').last;
  }

  String _getParentPath(String path) {
    final parts = path.split('/');
    if (parts.length <= 1) return '/';
    parts.removeLast();
    return parts.join('/');
  }

  Future<void> _createNewFile() async {
    final name = await _showNameDialog('Create File');
    if (name != null && name.isNotEmpty) {
      final path = '$_currentPath/$name';
      final termuxService = context.read<TermuxService>();
      await termuxService.writeFile(path, '');
      _loadFiles(_currentPath);
    }
  }

  Future<void> _createNewFolder() async {
    final name = await _showNameDialog('Create Folder');
    if (name != null && name.isNotEmpty) {
      final path = '$_currentPath/$name';
      final termuxService = context.read<TermuxService>();
      await termuxService.createDirectory(path);
      _loadFiles(_currentPath);
    }
  }

  Future<String?> _showNameDialog(String title) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteFile(FileItem file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete'),
        content: Text('Delete ${file.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final termuxService = context.read<TermuxService>();
      await termuxService.deleteFile(file.path, recursive: file.isDirectory);
      _loadFiles(_currentPath);
    }
  }

  Future<void> _viewFileContent(FileItem file) async {
    if (file.isDirectory) return;
    
    final termuxService = context.read<TermuxService>();
    final content = await termuxService.readFile(file.path);
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(file.name),
        content: SingleChildScrollView(
          child: SelectableText(
            content,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getFileName(_currentPath)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _historyIndex > 0 ? _navigateBack : null,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: _historyIndex < _pathHistory.length - 1 ? _navigateForward : null,
          ),
          IconButton(
            icon: const Icon(Icons.create_new_folder),
            onPressed: _createNewFolder,
            tooltip: 'New Folder',
          ),
          IconButton(
            icon: const Icon(Icons.note_add),
            onPressed: _createNewFile,
            tooltip: 'New File',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'home':
                  _navigateToDirectory('/data/data/com.termux/files/home');
                  break;
                case 'sdcard':
                  _navigateToDirectory('/storage/emulated/0');
                  break;
                case 'termux':
                  _navigateToDirectory('/data/data/com.termux/files');
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'home', child: Text('Home')),
              const PopupMenuItem(value: 'sdcard', child: Text('SD Card')),
              const PopupMenuItem(value: 'termux', child: Text('Termux Files')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Breadcrumb
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).colorScheme.surface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  InkWell(
                    onTap: () => _navigateToDirectory('/data/data/com.termux/files/home'),
                    child: const Text('root'),
                  ),
                  ..._currentPath.split('/').where((p) => p.isNotEmpty).expand((part) => [
                    const Icon(Icons.chevron_right, size: 16),
                    InkWell(
                      onTap: () {
                        final index = _currentPath.split('/').indexOf(part);
                        final newPath = '/${_currentPath.split('/').take(index + 1).join('/')}';
                        _navigateToDirectory(newPath);
                      },
                      child: Text(part),
                    ),
                  ]),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          // File list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _files.isEmpty
                    ? const Center(child: Text('Empty directory'))
                    : ListView.builder(
                        itemCount: _files.length,
                        itemBuilder: (context, index) {
                          final file = _files[index];
                          return ListTile(
                            leading: Icon(
                              file.isDirectory
                                  ? Icons.folder
                                  : Icons.insert_drive_file,
                              color: file.isDirectory ? Colors.amber : null,
                            ),
                            title: Text(file.name),
                            subtitle: Text(
                              file.isDirectory 
                                  ? '${file.permissions}'
                                  : _formatFileSize(file.size),
                            ),
                            onTap: () {
                              if (file.isDirectory) {
                                _navigateToDirectory(file.path);
                              } else {
                                _viewFileContent(file);
                              }
                            },
                            onLongPress: () => _showFileOptions(file),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showFileOptions(FileItem file) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('View'),
              onTap: () {
                Navigator.pop(context);
                _viewFileContent(file);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteFile(file);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
