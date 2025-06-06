import 'package:flutter/material.dart';
import 'settings_model.dart';
import 'settings_service.dart';

class SettingsPage extends StatefulWidget {
  final AppSettings initialSettings;
  final SettingsService settingsService;

  const SettingsPage({
    super.key,
    required this.initialSettings,
    required this.settingsService,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _widthController;
  late TextEditingController _heightController;
  late TextEditingController _minLinesController;
  late int _selectedBitNumber;

  @override
  void initState() {
    super.initState();
    _selectedBitNumber = widget.initialSettings.bitNumber;
    _widthController = TextEditingController(text: widget.initialSettings.width.toString());
    _heightController = TextEditingController(text: widget.initialSettings.height.toString());
    _minLinesController = TextEditingController(text: widget.initialSettings.minLines.toString());
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    _minLinesController.dispose();
    super.dispose();
  }

  void _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      final newSettings = AppSettings(
        bitNumber: _selectedBitNumber,
        width: int.parse(_widthController.text),
        height: int.parse(_heightController.text),
        minLines: int.parse(_minLinesController.text),
      );

      await widget.settingsService.saveSettings(newSettings);
      if (mounted) {
        Navigator.pop(context, true); // Indicate that settings were saved
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<int>(
                value: _selectedBitNumber,
                decoration: const InputDecoration(
                  labelText: 'Bit Number (3-8)',
                  border: OutlineInputBorder(),
                ),
                items: List.generate(6, (index) => index + 3) // Generates 3, 4, 5, 6, 7, 8
                    .map((bit) => DropdownMenuItem(
                          value: bit,
                          child: Text('$bit'),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedBitNumber = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _widthController,
                decoration: const InputDecoration(
                  labelText: 'Width (max 2000)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter a width.';
                  final n = int.tryParse(value);
                  if (n == null) return 'Please enter a valid number.';
                  if (n < 1 || n > 2000) return 'Width must be between 1 and 2000.';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _heightController,
                decoration: const InputDecoration(
                  labelText: 'Height (max 5000)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter a height.';
                  final n = int.tryParse(value);
                  if (n == null) return 'Please enter a valid number.';
                  if (n < 1 || n > 5000) return 'Height must be between 1 and 5000.';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _minLinesController,
                decoration: const InputDecoration(
                  labelText: 'Minimum Unique Lines (MinLines)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter a minimum number of lines.';
                  final n = int.tryParse(value);
                  if (n == null) return 'Please enter a valid number.';
                  if (n < 1) return 'Minimum lines must be at least 1.';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveSettings,
                child: const Text('Save Settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
