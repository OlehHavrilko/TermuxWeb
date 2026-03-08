import 'dart:io';
import 'package:flutter/foundation.dart';

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
}
