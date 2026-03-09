import 'dart:io';
import 'package:flutter/foundation.dart';

class CommandResult {
  final bool isSuccess;
  final String output;
  final String error;

  CommandResult({
    required this.isSuccess,
    required this.output,
    required this.error,
  });
}

class FileItem {
  final String path;
  final String name;
  final bool isDirectory;
  final int size;
  final String permissions;

  FileItem({
    required this.path,
    required this.name,
    required this.isDirectory,
    required this.size,
    required this.permissions,
  });
}

class MemoryInfo {
  final int total;
  final int used;
  final int free;
  
  double get usedPercent => total > 0 ? (used / total) * 100 : 0.0;

  MemoryInfo({
    required this.total,
    required this.used,
    required this.free,
  });
}

class SystemInfo {
  final double cpuUsage;
  final MemoryInfo memoryInfo;
  final String kernel;
  final String uptime;

  SystemInfo({
    required this.cpuUsage,
    required this.memoryInfo,
    this.kernel = 'Linux',
    this.uptime = '0 min',
  });
}

class PackageInfo {
  final String name;
  final String version;
  final String description;

  PackageInfo({
    required this.name,
    required this.version,
    required this.description,
  });
}

class TermuxService {
  static final TermuxService _instance = TermuxService._internal();
  factory TermuxService() => _instance;
  TermuxService._internal();

  final String binPath = '/data/data/com.termux/files/usr/bin/';
  final String homePath = '/data/data/com.termux/files/home/';
  final String usrPath = '/data/data/com.termux/files/usr';

  Map<String, String> get environment => {
    'PREFIX': usrPath,
    'PATH': binPath,
    'LD_LIBRARY_PATH': '$usrPath/lib',
    'HOME': homePath,
    'TERM': 'xterm-256color',
  };

  Future<String> runCommand(String command, {List<String> args = const []}) async {
    debugPrint('TermuxService.runCommand: executing command="$command", args=$args');
    try {
      final result = await Process.run(
        '${binPath}bash',
        ['-c', '$command ${args.join(' ')}'],
        environment: environment,
        workingDirectory: homePath,
      );
      debugPrint('TermuxService.runCommand: exitCode=${result.exitCode}, stdout="${result.stdout}", stderr="${result.stderr}"');
      if (result.exitCode != 0) {
        return result.stderr.toString();
      }
      return result.stdout.toString();
    } catch (e) {
      debugPrint('TermuxService.runCommand: exception="$e"');
      return 'Error: $e';
    }
  }

  Future<Process> startShell() async {
    debugPrint('TermuxService.startShell: starting shell');
    try {
      final process = await Process.start(
        '${binPath}bash',
        [],
        environment: environment,
        workingDirectory: homePath,
      );
      debugPrint('TermuxService.startShell: shell started successfully');
      return process;
    } catch (e) {
      debugPrint('TermuxService.startShell: exception="$e"');
      rethrow;
    }
  }

  Future<bool> isInstalled() async {
    debugPrint('TermuxService.isInstalled: checking if Termux is installed at $binPath');
    try {
      final exists = await Directory(binPath).exists();
      debugPrint('TermuxService.isInstalled: result=$exists');
      if (exists) {
        debugPrint('TermuxService.isInstalled: checking home path $homePath');
        final homeExists = await Directory(homePath).exists();
        debugPrint('TermuxService.isInstalled: home path exists=$homeExists');
        return homeExists;
      }
      return false;
    } catch (e) {
      debugPrint('TermuxService.isInstalled: exception="$e"');
      return false;
    }
  }

  // --- Files implementation ---
  Future<List<FileItem>> listFiles(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) return [];
    
    final items = <FileItem>[];
    await for (final entity in dir.list()) {
      final isDir = entity is Directory;
      int size = 0;
      if (entity is File) {
        size = await entity.length();
      }
      items.add(FileItem(
        path: entity.path,
        name: entity.path.split('/').last,
        isDirectory: isDir,
        size: size,
        permissions: isDir ? 'drwxr-xr-x' : '-rw-r--r--',
      ));
    }
    return items;
  }

  Future<void> writeFile(String path, String content) async {
    final file = File(path);
    await file.writeAsString(content);
  }

  Future<void> createDirectory(String path) async {
    final dir = Directory(path);
    await dir.create(recursive: true);
  }

  Future<void> deleteFile(String path, {bool recursive = false}) async {
    final entity = File(path);
    if (await entity.exists()) {
      await entity.delete();
    } else {
      final dir = Directory(path);
      if (await dir.exists()) {
        await dir.delete(recursive: recursive);
      }
    }
  }

  Future<String> readFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      return await file.readAsString();
    }
    return '';
  }

  // --- Monitor implementation ---
  Future<double> getCpuUsage() async {
    return 0.0;
  }

  Future<MemoryInfo> getMemoryUsage() async {
    return MemoryInfo(total: 100, used: 50, free: 50);
  }

  Future<SystemInfo> getSystemInfo() async {
    return SystemInfo(
      cpuUsage: await getCpuUsage(),
      memoryInfo: await getMemoryUsage(),
      kernel: await executeBash('uname -r').then((r) => r.output),
      uptime: await executeBash('uptime -p').then((r) => r.output),
    );
  }

  // --- Packages implementation ---
  Future<List<PackageInfo>> getInstalledPackages() async {
    return [
      PackageInfo(name: 'bash', version: '5.2.15', description: 'GNU Bourne Again SHell'),
    ];
  }

  Future<void> updatePackageList() async {
    await runCommand('pkg update');
  }

  Future<void> installPackage(String name) async {
    await runCommand('pkg install -y $name');
  }

  Future<void> removePackage(String name) async {
    await runCommand('pkg uninstall -y $name');
  }

  // --- Scripts implementation ---
  Future<CommandResult> executeBash(String command) async {
    try {
      final output = await runCommand(command);
      return CommandResult(isSuccess: true, output: output, error: '');
    } catch (e) {
      return CommandResult(isSuccess: false, output: '', error: e.toString());
    }
  }
}
