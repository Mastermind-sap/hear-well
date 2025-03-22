import 'package:flutter/material.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connection Screen'),
      ),
      body: const Center(
        child: Text('Connection Screen'),
      ),
      floatingActionButton: FloatingActionButton(onPressed: () {
        
      }),
    );
  }
}