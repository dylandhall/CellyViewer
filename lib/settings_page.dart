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
  late int _selectedBitNumber;
  late List<SeedPoint> _seedPoints;

  @override
  void initState() {
    super.initState();
    _selectedBitNumber = widget.initialSettings.bitNumber;
    _widthController = TextEditingController(
      text: widget.initialSettings.width.toString(),
    );
    _heightController = TextEditingController(
      text: widget.initialSettings.height.toString(),
    );
    _seedPoints = widget.initialSettings.seedPoints
        .map((e) => SeedPoint(fraction: e.fraction, pixels: e.pixels))
        .toList();
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      final newSettings = AppSettings(
        bitNumber: _selectedBitNumber,
        width: int.parse(_widthController.text),
        height: int.parse(_heightController.text),
        seedPoints: _seedPoints,
      );

      await widget.settingsService.saveSettings(newSettings);
      if (mounted) {
        Navigator.pop(context, true); // Indicate that settings were saved
      }
    }
  }

  void _addSeedPoint() {
    setState(() {
      _seedPoints.add(SeedPoint(fraction: 0.5, pixels: 1));
    });
  }

  void _removeSeedPoint(int index) {
    if (_seedPoints.length <= 1) return;
    setState(() {
      if (_seedPoints.length > 1) {
        _seedPoints.removeAt(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
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
                items:
                    List.generate(
                          6,
                          (index) => index + 3,
                        ) // Generates 3, 4, 5, 6, 7, 8
                        .map(
                          (bit) =>
                              DropdownMenuItem(value: bit, child: Text('$bit')),
                        )
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
                  if (value == null || value.isEmpty)
                    return 'Please enter a width.';
                  final n = int.tryParse(value);
                  if (n == null) return 'Please enter a valid number.';
                  if (n < 1 || n > 2000)
                    return 'Width must be between 1 and 2000.';
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
                  if (value == null || value.isEmpty)
                    return 'Please enter a height.';
                  final n = int.tryParse(value);
                  if (n == null) return 'Please enter a valid number.';
                  if (n < 1 || n > 5000)
                    return 'Height must be between 1 and 5000.';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Column(
                children: List.generate(_seedPoints.length, (index) {
                  final sp = _seedPoints[index];
                  return Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: sp.fraction,
                          onChanged: (v) {
                            setState(() {
                              sp.fraction = v;
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        child: DropdownButton<int>(
                          isExpanded: true,
                          value: sp.pixels.clamp(1, 8),
                          items: List.generate(8, (i) => i + 1)
                              .map(
                                (v) => DropdownMenuItem(
                                  value: v,
                                  child: Text('$v'),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                sp.pixels = val;
                              });
                            }
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: _seedPoints.length == 1
                            ? null
                            : () => _removeSeedPoint(index),
                      ),
                    ],
                  );
                }),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _addSeedPoint,
                  child: const Text('Add Point'),
                ),
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
