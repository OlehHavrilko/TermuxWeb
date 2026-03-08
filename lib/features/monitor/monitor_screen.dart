import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/termux_service.dart';

class MonitorScreen extends StatefulWidget {
  const MonitorScreen({Key? key}) : super(key: key);
  @override
  _MonitorScreenState createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorScreen> {
  String _cpu = 'Loading...';
  String _ram = 'Loading...';
  String _storage = 'Loading...';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchStats();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _fetchStats());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchStats() async {
    debugPrint('MonitorScreen._fetchStats: fetching system stats');
    final termux = context.read<TermuxService>();
    try {
      final cpuRes = await termux.runCommand("top -bn1 | grep 'Cpu(s)' | awk '{print \$2 + \$4}'");
      final ramRes = await termux.runCommand("free -m | awk 'NR==2{printf \"%.2f%%\", \$3*100/\$2}'");
      final storageRes = await termux.runCommand("df -h /data | awk 'NR==2{print \$5}'");

      if (mounted) {
        setState(() {
          _cpu = cpuRes.trim().isNotEmpty ? '${cpuRes.trim()}%' : 'N/A';
          _ram = ramRes.trim().isNotEmpty ? ramRes.trim() : 'N/A';
          _storage = storageRes.trim().isNotEmpty ? storageRes.trim() : 'N/A';
        });
      }
      debugPrint('MonitorScreen._fetchStats: cpu=$_cpu, ram=$_ram, storage=$_storage');
    } catch (e, stackTrace) {
      debugPrint('MonitorScreen._fetchStats: error fetching stats: $e, stackTrace: $stackTrace');
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(icon, size: 48, color: Colors.greenAccent),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('System Monitor')),
      body: ListView(
        children: [
          _buildStatCard('CPU Usage', _cpu, Icons.memory),
          _buildStatCard('RAM Usage', _ram, Icons.storage),
          _buildStatCard('Storage (/)', _storage, Icons.sd_storage),
        ],
      ),
    );
  }
}
