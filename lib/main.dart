// A Flutter demo app that displays cellular automata images based on logic translated from the provided C# code.
// As you scroll, images will be generated for each rule, up to 2^(2^pow). Older images are dropped from the cache.
//
// Revised concurrency handling:
// 1) We do the generation logic that deals with raw pixel arrays in a separate function using compute, but we omit
//    any direct UI or Canvas-based calls in the isolate. The final resizing (Canvas, PictureRecorder) is done on
//    the main thread, so it won't break isolate restrictions.
//
// 2) We maintain up to four concurrent tasks. If there are already four tasks in flight, we won't generate more
//    until at least one finishes. This prevents a backlog of tasks that never complete.
//
// 3) We do not remove or scroll away items that are still in flight.

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:super_clipboard/super_clipboard.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cellular Automata Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const CellularAutomataPage(pow: 4),
    );
  }
}

class _GeneratedImage {
  final MemoryImage image;
  final bool isSkipped;
  const _GeneratedImage(this.image, {this.isSkipped = false});
}

class CellularAutomataPage extends StatefulWidget {
  final int pow;
  const CellularAutomataPage({super.key, this.pow = 4});

  @override
  State<CellularAutomataPage> createState() => _CellularAutomataPageState();
}

class _CellularAutomataPageState extends State<CellularAutomataPage> {
  // Cache and concurrency management
  final Map<int, _GeneratedImage> _generatedCache = {};
  final Set<int> _generatingRules = {};
  final int _concurrencyLimit = 4;
  final int maxStoredImages = 20;
  // int maxVisibleIndex = 20; // Replaced by _numberOfVisibleItems

  int _currentStartingRule = 0;
  int _numberOfVisibleItems = 20; // How many items to show from _currentStartingRule
  int _currentJumpAmount = 1;

  late TextEditingController _ruleInputController;
  late TextEditingController _jumpByController;
  late ScrollController _scrollController;
  final FocusNode _textFieldFocusNode = FocusNode();
  final FocusNode _jumpByFocusNode = FocusNode();


  @override
  void initState() {
    super.initState();
    _ruleInputController = TextEditingController();
    _jumpByController = TextEditingController(text: _currentJumpAmount.toString());
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _ruleInputController.dispose();
    _jumpByController.dispose();
    _scrollController.dispose();
    _textFieldFocusNode.dispose();
    _jumpByFocusNode.dispose();
    super.dispose();
  }

  // Helper function to reset list state and scroll to top
  void _resetListViewAndScroll({int? newStartingRule, int? newJumpAmount}) {
    final maxRulesValue = 1 << (1 << widget.pow);
    setState(() {
      _generatedCache.clear();
      _generatingRules.clear();
      if (newStartingRule != null) {
        _currentStartingRule = newStartingRule.clamp(0, maxRulesValue -1);
      }
      if (newJumpAmount != null) {
        _currentJumpAmount = newJumpAmount.clamp(1, 999);
        _jumpByController.text = _currentJumpAmount.toString(); // Update text field if changed programmatically
      }
      _numberOfVisibleItems = 20; // Reset to a default page size
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollController.jumpTo(0.0);
        }
      });
    });
  }

  void _processInputsAndReset() {
    final String ruleText = _ruleInputController.text;
    final int? newRuleNumber = int.tryParse(ruleText);

    final String jumpText = _jumpByController.text;
    final int? newJumpAmount = int.tryParse(jumpText);

    final maxRulesValue = 1 << (1 << widget.pow);

    bool ruleIsValid = newRuleNumber != null && newRuleNumber >= 0 && newRuleNumber < maxRulesValue;
    bool jumpIsValid = newJumpAmount != null && newJumpAmount >= 1 && newJumpAmount <= 999;

    // Dismiss keyboards
    _textFieldFocusNode.unfocus();
    _jumpByFocusNode.unfocus();

    if (ruleText.isEmpty && jumpText.isEmpty) {
        // Both empty, do nothing or show a generic message
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a rule or jump amount.')),
        );
        return;
    }
    
    int? finalRuleNumber = _currentStartingRule; // Default to current if not changing or invalid
    int? finalJumpAmount = _currentJumpAmount; // Default to current if not changing or invalid

    bool ruleInputAttempted = ruleText.isNotEmpty;
    bool jumpInputAttempted = jumpText.isNotEmpty;

    if (ruleInputAttempted) {
        if (ruleIsValid) {
            finalRuleNumber = newRuleNumber;
        } else {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Invalid rule number (0 - ${maxRulesValue - 1}).')),
            );
            _ruleInputController.text = _currentStartingRule.toString(); // Reset to current valid
            return; // Stop if rule input was attempted and invalid
        }
    }

    if (jumpInputAttempted) {
        if (jumpIsValid) {
            finalJumpAmount = newJumpAmount;
        } else {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invalid jump amount (1-999).')),
            );
            _jumpByController.text = _currentJumpAmount.toString(); // Reset to current valid
            return; // Stop if jump input was attempted and invalid
        }
    }
    // If we reach here, all attempted inputs were valid, or inputs were empty (so we use current values)
    _resetListViewAndScroll(newStartingRule: finalRuleNumber, newJumpAmount: finalJumpAmount);
  }


  void _applyJumpAndRestart() {
    // This function now just calls the common processing function
    _processInputsAndReset();
  }

  void _goToRule() {
    // This function now just calls the common processing function
    _processInputsAndReset();
  }

  @override
  Widget build(BuildContext context) {
    final maxRules = 1 << (1 << widget.pow); // 2^(2^pow)
    return Scaffold(
      appBar: AppBar(
        centerTitle: true, // Center the entire title widget
        titleSpacing: 8.0, 
        title: Row(
          mainAxisSize: MainAxisSize.min, // Allow the Row to be centered if smaller than available space
          children: [
            const Text('Go to:'),
            const SizedBox(width: 4),
            Flexible(
              flex: 2, // Give more space to rule input
              child: SizedBox(
                height: 36,
                child: TextField(
                  controller: _ruleInputController,
                  focusNode: _textFieldFocusNode,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Rule',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
                  ),
                  onSubmitted: (_) => _goToRule(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _goToRule,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
              child: const Text('Go'),
            ),
            const SizedBox(width: 12),
            const Text('Jump:'),
            const SizedBox(width: 4),
            Flexible(
              flex: 1, // Less space for jump input
              child: SizedBox(
                height: 36,
                child: TextField(
                  controller: _jumpByController,
                  focusNode: _jumpByFocusNode,
                  keyboardType: TextInputType.number,
                  maxLength: 3, // Max 3 digits
                  decoration: const InputDecoration(
                    hintText: 'By',
                    counterText: "", // Hide the counter
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
                  ),
                  onSubmitted: (_) => _applyJumpAndRestart(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _applyJumpAndRestart,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
              child: const Text('Set'),
            ),
          ],
        ),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollNotification) {
          if (scrollNotification is ScrollEndNotification) {
            final metrics = scrollNotification.metrics;
            // If we are near the bottom and concurrency is not maxed, expand visible range
            if (metrics.pixels >= (metrics.maxScrollExtent - 10)) {
              if (_generatingRules.length < _concurrencyLimit) {
                setState(() {
                  // Calculate how many more items can be shown
                  int maxPossibleItems = (maxRules - _currentStartingRule + _currentJumpAmount - 1) ~/ _currentJumpAmount;
                  if (_numberOfVisibleItems < maxPossibleItems) {
                    _numberOfVisibleItems = (_numberOfVisibleItems + 10).clamp(0, maxPossibleItems);
                  }
                });
              }
            }
          }
          return false;
        },
        child: ListView.builder(
          controller: _scrollController,
          itemCount: ((maxRules - _currentStartingRule + _currentJumpAmount - 1) ~/ _currentJumpAmount)
                       .clamp(0, _numberOfVisibleItems), // Calculate max possible items with current jump and clamp by _numberOfVisibleItems
          itemBuilder: (context, index) {
            final actualRuleIndex = _currentStartingRule + (index * _currentJumpAmount);
            
            if (actualRuleIndex >= maxRules) { 
              return const SizedBox.shrink(); 
            }

            // If we've completed the image:
            if (_generatedCache.containsKey(actualRuleIndex)) {
              final gen = _generatedCache[actualRuleIndex]!;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Center(
                            child: Text(
                              gen.isSkipped
                                  ? 'Image $actualRuleIndex - Skipped (too simple)'
                                  : 'Image $actualRuleIndex',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        if (!gen.isSkipped) // Only show copy button if there's an image
                          IconButton(
                            icon: const Icon(Icons.content_copy),
                            tooltip: 'Copy Image to Clipboard',
                            onPressed: () async {
                              final bytes = gen.image.bytes;
                              if (kDebugMode) {
                                print('Attempting to copy image for Rule $actualRuleIndex, byte length: ${bytes.length}');
                              }

                              final clipboard = SystemClipboard.instance;
                              if (clipboard == null) {
                                if (mounted) { // Check if the widget is still in the tree
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Clipboard API not available on this platform.')),
                                  );
                                }
                                return;
                              }

                              final item = DataWriterItem();
                              // Add PNG representation using the Formats class.
                              // Formats.png is a pre-defined DataFormat<Uint8List>.
                              // Calling it with the bytes will produce the EncodedData.
                              item.add(Formats.png(bytes));
                              
                              // Example of adding a text fallback:
                              // item.add(Formats.plainText('Cellular Automaton Image - Rule $actualRuleIndex'));

                              try {
                                await clipboard.write([item]);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Image for Rule $actualRuleIndex copied!')),
                                  );
                                }
                              } catch (e) {
                                if (kDebugMode) {
                                  print('Error copying to clipboard: $e');
                                }
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to copy image: $e')),
                                  );
                                }
                              }
                            },
                          ),
                        if (gen.isSkipped) // Add a spacer if skipped to keep alignment consistent, or leave empty
                          const SizedBox(width: 48), // Approx width of IconButton
                      ],
                    ),
                    const SizedBox(height: 4), 
                    if (!gen.isSkipped)
                      Center(child: Image(image: gen.image)),
                  ],
                ),
              );
            }

            // If it is still generating:
            if (_generatingRules.contains(actualRuleIndex)) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            // If we have concurrency space, schedule generating for after the build:
            if (_generatingRules.length < _concurrencyLimit && !_generatingRules.contains(actualRuleIndex) && !_generatedCache.containsKey(actualRuleIndex)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                // Check again if still mounted and if the rule is still needed,
                // as the state might have changed by the time this callback runs.
                if (mounted && !_generatingRules.contains(actualRuleIndex) && !_generatedCache.containsKey(actualRuleIndex)) {
                  _startGenerating(actualRuleIndex);
                }
              });
            }

            // Display spinner while awaiting generation:
            return const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            );
          },
        ),
      ),
    );
  }

  Future<void> _startGenerating(int ruleIndex) async {
    if (kDebugMode) {
      print('[_startGenerating] Called for ruleIndex: $ruleIndex');
    }
    setState(() {
      _generatingRules.add(ruleIndex);
    });

    try {
      // Re-enabled original logic:
      // 1) Generate the raw pixel data directly on the main thread
      final computeResult = _generateRawPixelData(ruleIndex, widget.pow);

      final bool isSkipped = computeResult['isSkipped'] as bool;
      final Uint8List? pixelData = computeResult['pixelData'] as Uint8List?;

      if (!mounted) return;

      // 2) If we gave up due to too few lines, store 1x1 white
      if (isSkipped || pixelData == null) {
        if (kDebugMode) {
          print('[_startGenerating] Rule $ruleIndex is skipped or pixelData is null. Generating 1x1 white image.');
        }
        final skipImage = await _make1x1WhiteImage();
        _storeResult(ruleIndex, _GeneratedImage(skipImage, isSkipped: true));
        return;
      }

      // 3) On the main thread, do the final scaling using Canvas
      //    because we can't rely on Canvas/Recorder in the isolate.
      if (kDebugMode) {
        print('[_startGenerating] Scaling image for rule $ruleIndex.');
      }
      final scaledImage = await _finalScaleToImage(pixelData, 400, 1000);
      _storeResult(ruleIndex, _GeneratedImage(scaledImage, isSkipped: false));
      if (kDebugMode) {
        print('[_startGenerating] Stored scaled image for rule $ruleIndex.');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[_startGenerating] Error generating image for rule $ruleIndex: $e');
        print(stackTrace);
      }
      if (mounted) {
        setState(() {
          _generatingRules.remove(ruleIndex);
          // Optionally, add a placeholder error image to _generatedCache here
          // For now, just ensure the rule is removed from generating.
        });
      }
    }
  }

  void _storeResult(int ruleIndex, _GeneratedImage image) {
    if (kDebugMode) {
      print('[_storeResult] Called for ruleIndex: $ruleIndex, isSkipped: ${image.isSkipped}');
    }
    if (!mounted) {
      if (kDebugMode) {
        print('[_storeResult] Not mounted, returning for ruleIndex: $ruleIndex');
      }
      return;
    }
    setState(() {
      _generatingRules.remove(ruleIndex);
      if (kDebugMode) {
        print('[_storeResult] Removed $ruleIndex from _generatingRules. Current _generatingRules: $_generatingRules');
      }

      // If the cache is full, remove the first (oldest) that is not generating
      if (_generatedCache.length >= maxStoredImages) {
        final firstKey = _generatedCache.keys.firstWhere(
          (k) => !_generatingRules.contains(k),
          orElse: () => _generatedCache.keys.first,
        );
        _generatedCache.remove(firstKey);
      }

      _generatedCache[ruleIndex] = image;
      if (kDebugMode) {
        print('[_storeResult] Added $ruleIndex to _generatedCache. Cache size: ${_generatedCache.length}');
      }
    });
  }

  // Final scaling by 2x on main thread
  Future<MemoryImage> _finalScaleToImage(Uint8List pixelData, int cols, int rows) async {
    final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(pixelData);
    final ui.ImageDescriptor descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: cols,
      height: rows,
      pixelFormat: ui.PixelFormat.rgba8888,
    );
    final ui.Codec codec = await descriptor.instantiateCodec();
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ui.Image intermediateImage = fi.image;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final targetWidth = cols * 2;
    final targetHeight = rows * 2;

    canvas.drawImageRect(
      intermediateImage,
      Rect.fromLTWH(0, 0, cols.toDouble(), rows.toDouble()),
      Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
      Paint(),
    );

    final ui.Picture picture = recorder.endRecording();
    final ui.Image finalImage = await picture.toImage(targetWidth, targetHeight);
    final ByteData? pngBytes = await finalImage.toByteData(format: ui.ImageByteFormat.png);

    return MemoryImage(Uint8List.view(pngBytes!.buffer));
  }

  // This function now runs directly on the main thread.
  // It computes raw pixel data.
  Map<String, dynamic> _generateRawPixelData(int rule, int pow) {
    // Dimensions
  const cols = 400;
  const rows = 1000;
  const minLines = 25;

  // Bits for the rule
  final ruleBitsLength = 1 << pow;
  List<bool> ruleBits = List<bool>.generate(
    ruleBitsLength,
    (i) => ((rule >> i) & 1) == 1,
  );

  // Our initial row
  final pixelData = Uint8List(cols * rows * 4);
  List<bool> line = List<bool>.filled(cols, false);
  line[(cols / 4).floor()] = true;
  line[(cols / 3).floor()] = true;
  line[(2 * (cols / 3)).floor()] = true;

  List<List<bool>> distinctLines = [];
  bool hasEnoughDistinctLines = false;

  for (int l = 0; l < rows; l++) {
    final fractionThrough = l / rows;
    
    // Corrected colors based on C# Color.FromArgb(R, G, B) overload
    final int activeRed = (120 - 100 * fractionThrough).round().clamp(0, 255);
    final int activeGreen = 61; // Constant green
    final int activeBlue = (50 + 200 * fractionThrough).round().clamp(0, 255);
    const int activeAlpha = 255; // Fully opaque

    for (int p = 0; p < cols; p++) {
      final idx = (l * cols + p) * 4;
      if (line[p]) {
        pixelData[idx] = activeRed;
        pixelData[idx + 1] = activeGreen;
        pixelData[idx + 2] = activeBlue;
        pixelData[idx + 3] = activeAlpha;
      } else {
        // Bisque coloring
        pixelData[idx] = 255;
        pixelData[idx + 1] = 228;
        pixelData[idx + 2] = 196;
        pixelData[idx + 3] = 255;
      }
    }

    final newLine = List<bool>.from(line);
    for (int i = 0; i < line.length - pow; i++) {
      int val = 0;
      for (int j = 0; j < pow; j++) {
        if (line[i + j]) {
          val |= (1 << j);
        }
      }
      newLine[i + (pow ~/ 2)] = ruleBits[val];
    }

    // Distinct line check
    if (!hasEnoughDistinctLines) {
      // If not possible to reach minLines, skip
      if ((rows - l) < (minLines - distinctLines.length)) {
        return {'isSkipped': true, 'pixelData': null};
      }

      bool identical = false;
      for (var dLine in distinctLines) {
        if (_linesIdentical(dLine, newLine)) {
          identical = true;
          break;
        }
      }
      if (!identical) {
        if (distinctLines.length >= minLines) {
          hasEnoughDistinctLines = true;
          distinctLines.clear();
        } else {
          distinctLines.add(newLine);
        }
      }
    }

    line = newLine;
  }

  if (!hasEnoughDistinctLines) {
    return {'isSkipped': true, 'pixelData': null};
  }

  // Return data for final scaling in main thread
  return {
    'isSkipped': false,
    'pixelData': pixelData,
  };
  }
}

// Because we cannot use UI code in an isolate, we generate a 1x1 white image here in main isolate as well.
Future<MemoryImage> _make1x1WhiteImage() async {
  final blankData = Uint8List(4);
  blankData[0] = 255;
  blankData[1] = 255;
  blankData[2] = 255;
  blankData[3] = 255;

  final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(blankData);
  final ui.ImageDescriptor descriptor = ui.ImageDescriptor.raw(
    buffer,
    width: 1,
    height: 1,
    pixelFormat: ui.PixelFormat.rgba8888,
  );
  final ui.Codec codec = await descriptor.instantiateCodec();
  final ui.FrameInfo fi = await codec.getNextFrame();
  final ui.Image image = fi.image;
  final ByteData? pngBytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return MemoryImage(Uint8List.view(pngBytes!.buffer));
}

bool _linesIdentical(List<bool> a, List<bool> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
