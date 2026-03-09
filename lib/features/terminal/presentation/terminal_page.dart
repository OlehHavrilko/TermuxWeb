import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TerminalPage extends StatefulWidget {
  const TerminalPage({super.key});

  @override
  State<TerminalPage> createState() => _TerminalPageState();
}

class _TerminalPageState extends State<TerminalPage> {
  late Terminal _terminal;
  Process? _shellProcess;
  final TextEditingController _inputController = TextEditingController();
  final List<String> _commandHistory = [];
  int _historyIndex = -1;
  bool _isKeyboardVisible = false;

  @override
  void initState() {
    super.initState();
    _initTerminal();
  }

  void _initTerminal() {
    _terminal = Terminal(
      maxLines: 10000,
    );

    _startShell();
  }

  Future<void> _startShell() async {
    try {
      // For Android Termux, we use the built-in shell
      _shellProcess = await Process.start(
        '/data/data/com.termux/files/usr/bin/bash',
        [],
        environment: {'TERM': 'xterm-256color'},
        workingDirectory: '/data/data/com.termux/files/home',
      );

      // Set terminal IO
      _shellProcess!.stdout.listen(
        (data) {
          _terminal.write(utf8.decode(data));
        },
        onError: (e) {
          _terminal.write('\r\n[Error: $e]\r\n');
        },
      );

      _shellProcess!.stderr.listen(
        (data) {
          _terminal.write(utf8.decode(data));
        },
      );

      _shellProcess!.exitCode.then((code) {
        _terminal.write('\r\n[Process exited with code $code]\r\n');
      });

      // Handle terminal input
      _terminal.onOutput = (data) {
        _shellProcess?.stdin.add(utf8.encode(data));
      };
    } catch (e) {
      _terminal.write('Failed to start shell: $e\r\n');
      // Fallback to demo mode
      _terminal.write('Running in demo mode\r\n');
      _terminal.write('This app requires Termux to be installed\r\n');
    }
  }

  void _sendCommand() {
    final command = _inputController.text;
    if (command.isEmpty) return;

    _terminal.write('\r\n\$ $command\r\n');
    _shellProcess?.stdin.add(utf8.encode('$command\n'));
    
    _commandHistory.add(command);
    _historyIndex = _commandHistory.length;
    _inputController.clear();
  }

  void _navigateHistory(bool up) {
    if (_commandHistory.isEmpty) return;

    if (up) {
      if (_historyIndex > 0) {
        _historyIndex--;
        _inputController.text = _commandHistory[_historyIndex];
        _inputController.selection = TextSelection.fromPosition(
          TextPosition(offset: _inputController.text.length),
        );
      }
    } else {
      if (_historyIndex < _commandHistory.length - 1) {
        _historyIndex++;
        _inputController.text = _commandHistory[_historyIndex];
        _inputController.selection = TextSelection.fromPosition(
          TextPosition(offset: _inputController.text.length),
        );
      } else {
        _historyIndex = _commandHistory.length;
        _inputController.clear();
      }
    }
  }

  @override
  void dispose() {
    _shellProcess?.kill();
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terminal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _terminal.write('\x1B[2J\x1B[H'); // Clear terminal
              _startShell();
            },
            tooltip: 'Restart Shell',
          ),
          IconButton(
            icon: const Icon(Icons.content_copy),
            onPressed: () {
              // Clipboard.setData(ClipboardData(text: _terminal.getText()));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Terminal copy not supported yet')),
              );
            },
            tooltip: 'Copy',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: const Color(0xFF0D0D0D),
              child: TerminalView(
                _terminal,
                textStyle: const TerminalStyle(
                  fontSize: 14,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
          // Command input area
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  '\$ ',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00FF00),
                  ),
                ),
                Expanded(
                  child: KeyboardListener(
                    focusNode: FocusNode(),
                    onKeyEvent: (event) {
                      if (event is KeyDownEvent) {
                        if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                          _navigateHistory(true);
                        } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                          _navigateHistory(false);
                        }
                      }
                    },
                    child: TextField(
                      controller: _inputController,
                      style: const TextStyle(fontFamily: 'monospace'),
                      decoration: const InputDecoration(
                        hintText: 'Enter command...',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      onSubmitted: (_) => _sendCommand(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendCommand,
                  color: const Color(0xFF00FF00),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
