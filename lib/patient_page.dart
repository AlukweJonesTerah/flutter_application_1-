import 'package:flutter/material.dart';

class PatientPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Patient Page'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushNamed(context, '/patient_dashboard');
          },
          child: Text('Go to Dashboard'),
        ),
      ),
    );
  }
}
