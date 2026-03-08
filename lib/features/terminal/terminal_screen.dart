import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/termux_service.dart';

class TerminalScreen extends StatefulWidget {
  const TerminalScreen({Key? key}) : super(key: key);
  @override
  _TerminalScreenState createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  final TextEditingController _cmdController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _output = 'Starting shell...\n';
  Process? _shellProcess;

  @override
  void initState() {
    super.initState();
    _initShell();
  }

  Future<void> _initShell() async {
    final termux = context.read<TermuxService>();
    try {
      debugPrint('TerminalScreen._initShell: starting shell');
      _shellProcess = await termux.startShell();
      final decoder = const Utf8Codec(allowMalformed: true).decoder;
      
      _shellProcess!.stdout.transform(decoder).listen((data) {
        _appendOutput(data);
      });

      _shellProcess!.stderr.transform(decoder).listen((data) {
        _appendOutput(data);
      });
      
      
      _appendOutput('Shell started.\n');
      debugPrint('TerminalScreen._initShell: shell started successfully');
    } catch (e, stackTrace) {
      debugPrint('TerminalScreen._initShell: failed to start shell: $e, stackTrace: $stackTrace');
      _appendOutput('Failed to start shell: $e\n');
    }
  }

  void _appendOutput(String text) {
    if (!mounted) {
      debugPrint('TerminalScreen._appendOutput: widget not mounted, skipping update');
      return;
    }
    setState(() {
      _output += text;
      if (_output.length > 15000) {
        _output = _output.substring(_output.length - 15000);
      }
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _shellProcess?.kill();
    _cmdController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _runCmd() {
    final cmd = _cmdController.text;
    if (cmd.isEmpty) return;

    debugPrint('TerminalScreen._runCmd: executing command "$cmd"');
    if (_shellProcess != null) {
      try {
        _shellProcess!.stdin.writeln(cmd);
        _appendOutput('\$ $cmd\n');
        _cmdController.clear();
        debugPrint('TerminalScreen._runCmd: command "$cmd" executed successfully');
      } catch (e, stackTrace) {
        debugPrint('TerminalScreen._runCmd: error executing command "$cmd": $e, stackTrace: $stackTrace');
        _appendOutput('Error executing command: $e\n');
      }
    } else {
      _appendOutput('Shell is not running.\n');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terminal')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.topLeft,
                child: Text(_output, style: const TextStyle(fontFamily: 'monospace')),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Text('\$ ', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: TextField(
                    controller: _cmdController,
                    decoration: const InputDecoration(
                      hintText: 'Enter command',
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _runCmd(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _runCmd,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
