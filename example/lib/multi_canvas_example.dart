import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_sketchpad/flutter_sketchpad.dart';

void main() {
  runApp(const MultiCanvasExampleApp());
}

class MultiCanvasExampleApp extends StatelessWidget {
  const MultiCanvasExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Multi-Canvas Sketch Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'SF Pro Display',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'SF Pro Display',
      ),
      home: const MultiCanvasExamplePage(),
    );
  }
}

/// Example demonstrating multiple canvas sections on a single scrollable page
/// Perfect for documents, notes, or multi-section annotation apps
class MultiCanvasExamplePage extends StatefulWidget {
  const MultiCanvasExamplePage({super.key});

  @override
  State<MultiCanvasExamplePage> createState() => _MultiCanvasExamplePageState();
}

class _MultiCanvasExamplePageState extends State<MultiCanvasExamplePage> {
  // Controller will be initialized after loading inserts from server
  MultiCanvasSketchController? controller;
  final List<SketchInsert> inserts = []; // This will be synced from controller

  // Sketch mode state - now controlled by the widget
  bool isSketchMode = false;

  // Loading state for async inserts
  bool isLoadingInserts = true;

  // Animation configuration state
  Duration _animationDuration = const Duration(milliseconds: 350);
  Curve _animationCurve = Curves.easeOutBack;

  // Animation presets for demo
  final List<Map<String, dynamic>> _animationPresets = [
    {
      'name': 'Bounce',
      'duration': const Duration(milliseconds: 600),
      'curve': Curves.elasticOut,
    },
    {
      'name': 'Quick',
      'duration': const Duration(milliseconds: 200),
      'curve': Curves.easeOut,
    },
    {
      'name': 'Smooth',
      'duration': const Duration(milliseconds: 350),
      'curve': Curves.easeOutBack,
    },
    {
      'name': 'Slow',
      'duration': const Duration(milliseconds: 800),
      'curve': Curves.easeInOutCubic,
    },
  ];

  int _currentPresetIndex = 2; // Start with 'Smooth'

  // Sample sections content
  final List<Map<String, dynamic>> sections = [
    {
      'title': 'Meeting Notes',
      'subtitle': 'Q4 Planning Session',
      'content':
          'Team meeting to discuss quarterly goals and objectives.\n\n• Review current progress\n• Set new targets\n• Assign responsibilities',
      'color': Colors.blue[50],
      'icon': Icons.meeting_room,
    },
    {
      'title': 'Design Ideas',
      'subtitle': 'App Mockups',
      'content':
          'Brainstorming session for the new app design.\n\n• User interface concepts\n• Color schemes\n• Navigation patterns',
      'color': Colors.green[50],
      'icon': Icons.palette,
    },
    {
      'title': 'Technical Notes',
      'subtitle': 'Architecture Planning',
      'content':
          'Technical implementation details and decisions.\n\n• Database schema\n• API endpoints\n• Performance considerations',
      'color': Colors.orange[50],
      'icon': Icons.code,
    },
    {
      'title': 'Action Items',
      'subtitle': 'Follow-up Tasks',
      'content':
          'List of tasks and deadlines from today\'s discussions.\n\n• Update documentation\n• Schedule reviews\n• Prepare presentations',
      'color': Colors.purple[50],
      'icon': Icons.task_alt,
    },
  ];

  @override
  void initState() {
    super.initState();

    // Load sample inserts asynchronously and initialize controller with them
    _loadInsertsFromServer();
  }

  /// Simulate loading inserts from server with delay, then initialize controller
  Future<void> _loadInsertsFromServer() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Create sample inserts
    final sampleInserts = _createSampleInserts();

    // Initialize controller with loaded inserts
    controller = MultiCanvasSketchController(
      initialColor: Colors.red,
      initialStrokeWidth: 4.0,
      initialFontSize: 16.0,
      maxHistorySteps: 30,
      defaultInserts: sampleInserts, // Pass loaded inserts directly
    );

    // Listen to controller changes to sync when needed
    controller!.addListener(_onControllerChanged);

    // Update loading state
    setState(() {
      isLoadingInserts = false;
    });

    debugPrint(
        'Loaded ${sampleInserts.length} inserts from server and initialized controller');
  }

  /// Create sample sketch inserts to demonstrate preloaded content
  List<SketchInsert> _createSampleInserts() {
    final now = DateTime.now();
    final List<SketchInsert> sampleInserts = [];

    // Sample inserts for section 0 (Meeting Notes)
    sampleInserts.addAll([
      // Drawing: Simple arrow pointing to "Review current progress"
      SketchInsert(
        id: 'arrow_1',
        sectionId: '0',
        points: const [
          Offset(50, 80),
          Offset(80, 80),
          Offset(75, 75),
          Offset(80, 80),
          Offset(75, 85),
        ],
        color: Colors.red,
        strokeWidth: 3.0,
        type: SketchInsertType.drawing,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),

      // Text annotation
      SketchInsert(
        id: 'note_1',
        sectionId: '0',
        points: const [], // Empty for text inserts
        color: Colors.blue,
        strokeWidth: 2.0,
        type: SketchInsertType.text,
        text: 'Priority!',
        textPosition: const Offset(100, 75),
        fontSize: 14.0,
        createdAt: now.subtract(const Duration(hours: 1)),
      ),

      // Additional text to be erased
      SketchInsert(
        id: 'temp_note',
        sectionId: '0',
        points: const [],
        color: Colors.grey,
        strokeWidth: 2.0,
        type: SketchInsertType.text,
        text: 'Old idea',
        textPosition: const Offset(180, 95),
        fontSize: 12.0,
        createdAt: now.subtract(const Duration(minutes: 50)),
      ),

      // Eraser: Cross out the old text
      SketchInsert(
        id: 'eraser_3',
        sectionId: '0',
        points: const [
          Offset(175, 90),
          Offset(210, 100),
          Offset(205, 95),
          Offset(180, 105),
        ],
        color: null, // Eraser doesn't use color
        strokeWidth: 12.0,
        type: SketchInsertType.eraser,
        createdAt: now.subtract(const Duration(minutes: 35)),
      ),
    ]);

    // Sample inserts for section 1 (Design Ideas)
    sampleInserts.addAll([
      // Drawing: Simple circle highlighting "Color schemes"
      SketchInsert(
        id: 'circle_1',
        sectionId: '1',
        points: _generateCirclePoints(const Offset(120, 110), 25),
        color: Colors.green,
        strokeWidth: 2.5,
        type: SketchInsertType.drawing,
        createdAt: now.subtract(const Duration(minutes: 45)),
      ),

      // Text annotation for design ideas
      SketchInsert(
        id: 'design_note_1',
        sectionId: '1',
        points: const [],
        color: Colors.purple,
        strokeWidth: 2.0,
        type: SketchInsertType.text,
        text: 'Consider dark mode',
        textPosition: const Offset(200, 130),
        fontSize: 12.0,
        createdAt: now.subtract(const Duration(minutes: 30)),
      ),

      // Eraser: Remove part of the circle (simulating editing)
      SketchInsert(
        id: 'eraser_2',
        sectionId: '1',
        points: const [
          Offset(140, 105),
          Offset(145, 110),
          Offset(142, 115),
          Offset(138, 112),
        ],
        color: null, // Eraser doesn't use color
        strokeWidth: 6.0,
        type: SketchInsertType.eraser,
        createdAt: now.subtract(const Duration(minutes: 25)),
      ),
    ]);

    // Sample inserts for section 2 (Technical Notes)
    sampleInserts.addAll([
      // Drawing: Underline for "Database schema"
      SketchInsert(
        id: 'underline_1',
        sectionId: '2',
        points: const [
          Offset(40, 95),
          Offset(140, 95),
        ],
        color: Colors.orange,
        strokeWidth: 3.0,
        type: SketchInsertType.drawing,
        createdAt: now.subtract(const Duration(minutes: 20)),
      ),

      // Text annotation
      SketchInsert(
        id: 'tech_note_1',
        sectionId: '2',
        points: const [],
        color: Colors.red,
        strokeWidth: 2.0,
        type: SketchInsertType.text,
        text: 'Review this!',
        textPosition: const Offset(150, 90),
        fontSize: 13.0,
        createdAt: now.subtract(const Duration(minutes: 15)),
      ),

      // Eraser: Remove part of the underline (simulating correction)
      SketchInsert(
        id: 'eraser_1',
        sectionId: '2',
        points: const [
          Offset(100, 90),
          Offset(120, 90),
          Offset(115, 95),
          Offset(105, 100),
        ],
        color: null, // Eraser doesn't use color
        strokeWidth: 8.0,
        type: SketchInsertType.eraser,
        createdAt: now.subtract(const Duration(minutes: 12)),
      ),
    ]);

    // Sample inserts for section 3 (Action Items)
    sampleInserts.addAll([
      // Drawing: Checkmark next to "Update documentation"
      SketchInsert(
        id: 'checkmark_1',
        sectionId: '3',
        points: const [
          Offset(20, 85),
          Offset(25, 90),
          Offset(35, 75),
        ],
        color: Colors.green,
        strokeWidth: 4.0,
        type: SketchInsertType.drawing,
        createdAt: now.subtract(const Duration(minutes: 10)),
      ),

      // Text showing deadline
      SketchInsert(
        id: 'deadline_1',
        sectionId: '3',
        points: const [],
        color: Colors.red,
        strokeWidth: 2.0,
        type: SketchInsertType.text,
        text: 'Due: Dec 15',
        textPosition: const Offset(250, 120),
        fontSize: 11.0,
        createdAt: now.subtract(const Duration(minutes: 5)),
      ),
    ]);

    return sampleInserts;
  }

  /// Helper method to generate points for a circle
  List<Offset> _generateCirclePoints(Offset center, double radius) {
    List<Offset> points = [];
    const int numPoints = 36; // 10 degree increments

    for (int i = 0; i <= numPoints; i++) {
      double angle = (i * 2 * 3.14159) / numPoints;
      double x = center.dx + radius * cos(angle);
      double y = center.dy + radius * sin(angle);
      points.add(Offset(x, y));
    }

    return points;
  }

  void _onControllerChanged() {
    // Only update if mounted and not already rebuilding
    if (!mounted) return;

    // Auto-sync when exiting sketch mode (deferred to avoid setState during build)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Could sync here in real-time, or only when exiting sketch mode
        // For now, we'll sync only when explicitly requested
        if (!isSketchMode) {
          // Auto-sync when exiting sketch mode
          _syncFromController();
        }
        setState(
            () {}); // Update UI for other changes (undo/redo buttons, etc.)
      }
    });
  }

  // Sync app state from controller (call when save button pressed, etc.)
  void _syncFromController() {
    if (controller == null) return;

    setState(() {
      inserts
        ..clear()
        ..addAll(controller!.inserts);
    });
    // Here you could save to database, call API, etc.
    debugPrint('Synced ${inserts.length} inserts from controller');
  }

  // Simple undo - no external coordination needed
  void _undo() {
    controller?.undo(); // Safe call with null check
  }

  // Simple redo - no external coordination needed
  void _redo() {
    controller?.redo(); // Safe call with null check
  }

  // Cycle through animation presets
  void _cycleAnimationPreset() {
    setState(() {
      _currentPresetIndex =
          (_currentPresetIndex + 1) % _animationPresets.length;
      final preset = _animationPresets[_currentPresetIndex];
      _animationDuration = preset['duration'] as Duration;
      _animationCurve = preset['curve'] as Curve;
    });
  }

  // Check if scrolling should be disabled
  bool _shouldDisableScrolling() {
    // Disable scrolling when:
    // 1. Sketch mode is active AND
    // 2. Controller exists AND
    // 3. A drawing mode is active (not SketchMode.none)
    return isSketchMode &&
        controller != null &&
        controller!.mode != SketchMode.none;
  }

  // Show test modal for long press testing
  void _showTestModal(BuildContext context, String sectionTitle) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[850]
                : Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Icon(
                Icons.check_circle,
                color: Colors.green[600],
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Long Press Detected!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Section: $sectionTitle',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  isSketchMode
                      ? '⚠️ Annotation mode is ENABLED\nLong press should NOT work!'
                      : '✅ Annotation mode is DISABLED\nLong press is working correctly!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        isSketchMode ? Colors.orange[700] : Colors.green[700],
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  // Build positioned toolbar based on current selection
  Widget _buildPositionedToolbar() {
    if (isLoadingInserts || controller == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 16,
      left: 0,
      right: 0,
      child: Center(
        child: SketchToolbar(
          controller: controller!,
          isEnabled: isSketchMode,
          enableAnimation: true,
          animationDuration: _animationDuration,
          animationCurve: _animationCurve,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MultiCanvasSketchWrapper(
      controller: controller ?? MultiCanvasSketchController(),
      isEnabled: isSketchMode && !isLoadingInserts && controller != null,
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
            appBar: AppBar(
              title: const Text('Multi-Section Annotations'),
              backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
              elevation: 0,
              actions: [
                // Loading indicator
                if (isLoadingInserts)
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    child: const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.blue,
                      ),
                    ),
                  ),

                // Manual sync button
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    onPressed:
                        isLoadingInserts ? null : () => _syncFromController(),
                    icon: Icon(
                      Icons.save_rounded,
                      color: isLoadingInserts
                          ? Colors.grey[400]
                          : Colors.green[600],
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: isLoadingInserts
                          ? Colors.grey[100]
                          : Colors.green[50],
                    ),
                    tooltip:
                        isLoadingInserts ? 'Loading...' : 'Save Current State',
                  ),
                ),

                // Animation preset cycle button
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    onPressed:
                        isLoadingInserts ? null : () => _cycleAnimationPreset(),
                    icon: Icon(
                      Icons.animation,
                      color: isLoadingInserts
                          ? Colors.grey[400]
                          : Colors.purple[600],
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: isLoadingInserts
                          ? Colors.grey[100]
                          : Colors.purple[50],
                    ),
                    tooltip: isLoadingInserts
                        ? 'Loading...'
                        : 'Animation: ${_animationPresets[_currentPresetIndex]['name']}',
                  ),
                ),
                // Sketch mode toggle - single controller
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    onPressed: isLoadingInserts
                        ? null
                        : () {
                            setState(() {
                              isSketchMode = !isSketchMode;
                            });
                          },
                    icon: Icon(
                      isSketchMode ? Icons.edit_off : Icons.edit,
                      color: isLoadingInserts
                          ? Colors.grey[400]
                          : (isSketchMode
                              ? Colors.orange[600]
                              : Colors.grey[600]),
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: isLoadingInserts
                          ? Colors.grey[100]
                          : (isSketchMode
                              ? Colors.orange[50]
                              : Colors.transparent),
                    ),
                    tooltip: isLoadingInserts
                        ? 'Loading...'
                        : (isSketchMode
                            ? 'Exit Sketch Mode'
                            : 'Enter Sketch Mode'),
                  ),
                ),

                // History controls - single controller
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    onPressed:
                        (controller?.canUndo == true && !isLoadingInserts)
                            ? () => _undo()
                            : null,
                    icon: Icon(
                      Icons.undo_rounded,
                      color: (controller?.canUndo == true && !isLoadingInserts)
                          ? Colors.blue[600]
                          : Colors.grey[400],
                    ),
                    tooltip: isLoadingInserts ? 'Loading...' : 'Undo',
                  ),
                ),

                // Redo button
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: IconButton(
                    onPressed:
                        (controller?.canRedo == true && !isLoadingInserts)
                            ? () => _redo()
                            : null,
                    icon: Icon(
                      Icons.redo_rounded,
                      color: (controller?.canRedo == true && !isLoadingInserts)
                          ? Colors.blue[600]
                          : Colors.grey[400],
                    ),
                    tooltip: isLoadingInserts ? 'Loading...' : 'Redo',
                  ),
                ),
              ],
            ),
            body: SingleChildScrollView(
              physics: _shouldDisableScrolling()
                  ? const NeverScrollableScrollPhysics()
                  : null,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[600]!, Colors.blue[400]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.description,
                          color: Colors.white,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isLoadingInserts
                                    ? 'Loading Annotations...'
                                    : 'Animated Toolbar Demo',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isLoadingInserts
                                    ? 'Fetching annotations from server...'
                                    : 'Animation',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 14,
                                ),
                              ),
                              if (isLoadingInserts) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Loading 8 annotations...',
                                      style: TextStyle(
                                        color:
                                            Colors.white.withValues(alpha: 0.8),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Sections
                  ...sections.asMap().entries.map((entry) {
                    final index = entry.key;
                    final section = entry.value;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: section['color'] as Color?,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: MultiCanvasRegion(
                        sectionId: index.toString(),
                        child: GestureDetector(
                          onLongPress: () {
                            print('long press');
                            _showTestModal(
                              context,
                              section['title'] as String,
                            );
                          },
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 200),
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        section['icon'] as IconData,
                                        color: Colors.grey[600],
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            section['title'] as String,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            section['subtitle'] as String,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  section['content'] as String,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.touch_app,
                                        size: 14,
                                        color: Colors.blue[700],
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Long press to test modal',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),

                  // Bottom spacing for toolbar
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          // Standalone toolbar positioned based on current selection
          _buildPositionedToolbar(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller?.dispose(); // Safe dispose with null check
    super.dispose();
  }
}
