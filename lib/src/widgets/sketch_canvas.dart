import 'dart:async';

import 'package:flutter/material.dart';

import '../models/sketch_insert.dart';
import '../models/sketch_mode.dart';
import '../models/sketch_painter.dart';

class SketchCanvas extends StatefulWidget {
  const SketchCanvas({
    required this.sectionId,
    required this.child,
    required this.inserts,
    required this.mode,
    required this.selectedColor,
    required this.selectedStrokeWidth,
    required this.selectedFontSize,
    required this.onSaveInsert,
    required this.onUpdateTextInsert,
    required this.onRemoveInsert,
    // required this.onEraseInsertAt,  // Future version
    super.key,
  });

  final String sectionId;
  final Widget child;
  final List<SketchInsert> inserts;
  final SketchMode mode;
  final Color selectedColor;
  final double selectedStrokeWidth;
  final double selectedFontSize;
  final void Function(SketchInsert insert) onSaveInsert;
  final void Function(String id, String text, Offset position)
      onUpdateTextInsert;
  final void Function(String id) onRemoveInsert;
  // final void Function(int sectionIndex, Offset position, double size)
  //     onEraseInsertAt;  // Future version

  @override
  State<SketchCanvas> createState() => _SketchCanvasState();
}

class _SketchCanvasState extends State<SketchCanvas> {
  late final DrawingController _drawingController;
  late final TextController _textController;

  // Track recently removed text to avoid duplicate removals
  final Set<String> _recentlyRemovedTextIds = {};

  // Eraser indicator position and visibility
  Offset? _eraserIndicatorPosition;
  bool _showEraserIndicator = false;

  @override
  void initState() {
    super.initState();
    _drawingController = DrawingController(
      onSaveInsert: widget.onSaveInsert,
      // onEraseInsertAt: widget.onEraseInsertAt,  // Future version
      onStateChanged: _handleStateChanged,
    );
    _textController = TextController(
      onSaveInsert: widget.onSaveInsert,
      onUpdateTextInsert: widget.onUpdateTextInsert,
      onStateChanged: _handleStateChanged,
    );
    _textController.initialize();
  }

  @override
  void dispose() {
    _drawingController.dispose();
    _textController.dispose();
    super.dispose();
  }

  SketchMode get _currentMode => widget.mode;

  List<SketchInsert> get _sectionInserts => widget.inserts
      .where((insert) => insert.sectionId == widget.sectionId)
      .toList();

  @override
  Widget build(BuildContext context) {
    // Update text controller context (without canvas size)
    _textController.updateContext(
      sectionId: widget.sectionId,
      selectedColor: widget.selectedColor,
      selectedFontSize: widget.selectedFontSize,
      inserts: widget.inserts,
    );

    // Handle text mode changes
    if (widget.mode != SketchMode.text && _textController.isEditingText) {
      FocusScope.of(context).unfocus();
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        _buildDrawingLayer(),
        _buildInteractionLayer(),
        _buildTextInserts(),
        _buildTextEditor(),
        _buildEraserIndicator(),
      ],
    );
  }

  Widget _buildDrawingLayer() {
    return Positioned.fill(
      child: ClipRect(
        child: CustomPaint(
          painter: SketchInsertPainter(
            inserts: _sectionInserts,
            currentPoints: _drawingController.currentDrawingPoints,
            currentStrokeWidth: _getStrokeWidth(),
            currentColor: _getDrawingColor() ?? Colors.transparent,
            currentMode: _currentMode,
          ),
          child: Container(
            color: Colors.transparent,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      ),
    );
  }

  Widget _buildInteractionLayer() {
    final mode = _currentMode;
    if (mode == SketchMode.none) return const SizedBox.shrink();

    return Positioned.fill(
      child: GestureDetector(
        onPanStart: _shouldHandleDrawing(mode) ? _handlePanStart : null,
        onPanUpdate: _shouldHandleDrawing(mode) ? _handlePanUpdate : null,
        onPanEnd: _shouldHandleDrawing(mode) ? _handlePanEnd : null,
        onTapDown: mode == SketchMode.text ? _handleTextTap : null,
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildTextInserts() {
    final textInserts = _sectionInserts
        .where((insert) => insert.type == SketchInsertType.text)
        .where((insert) => !_textController.isEditing(insert.id));

    if (textInserts.isEmpty) return const SizedBox.shrink();

    return Positioned.fill(
      child: Stack(
        children: textInserts
            .map((insert) => TextInsertWidget(
                  key: ValueKey(insert.id),
                  insert: insert,
                  isInteractive: _currentMode == SketchMode.text,
                  onTap: () => _textController.editExisting(insert),
                  onDragStart: (position) =>
                      _textController.startDragging(insert.id, position),
                  onDragUpdate: (position) => _textController
                      .updateDragPosition(position, context.size),
                  onDragEnd: _textController.stopDragging,
                  // Always visible - no transparency changes
                  isTransparent: false,
                ))
            .toList(),
      ),
    );
  }

  Widget _buildTextEditor() {
    if (!_textController.isEditingText) return const SizedBox.shrink();

    return TextEditorWidget(
      position: _textController.editPosition!,
      controller: _textController.textEditingController,
      focusNode: _textController.focusNode,
      color: _textController.currentEditingColor ?? widget.selectedColor,
      fontSize:
          _textController.currentEditingFontSize ?? widget.selectedFontSize,
      onComplete: _textController.saveText,
      onTapOutside: () => FocusScope.of(context).unfocus(),
    );
  }

  bool _shouldHandleDrawing(SketchMode mode) {
    return mode == SketchMode.drawing ||
        mode == SketchMode.highlighting ||
        mode == SketchMode.eraser;
  }

  void _handlePanStart(DragStartDetails details) {
    final position = details.localPosition;
    if (!_isWithinBounds(position)) return;

    _drawingController.startDrawing(position);

    // Show eraser indicator for eraser mode
    if (_currentMode == SketchMode.eraser) {
      setState(() {
        _eraserIndicatorPosition = position;
        _showEraserIndicator = true;
      });
      _checkEraserCollisions(position);
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final position = details.localPosition;

    // Handle drawing with proper mid-drawing saves
    if (!_drawingController.isDrawing) return;

    final isWithinBounds = _isWithinBounds(position);

    if (isWithinBounds && _drawingController.isOutsideBounds) {
      // Coming back inside after being outside - save current drawing and start a new one
      _saveCurrentDrawingAndStartNew(position);
    } else if (isWithinBounds) {
      // Normal drawing within bounds
      _drawingController.continueDrawing(position);

      // Update eraser indicator position and check for collisions when erasing
      if (_currentMode == SketchMode.eraser) {
        setState(() {
          _eraserIndicatorPosition = position;
        });
        _checkEraserCollisions(position);
      }
    } else if (!_drawingController.isOutsideBounds) {
      // Just went outside - save current drawing
      _saveCurrentDrawing();
      _drawingController.setOutsideBounds(true);
    }
  }

  void _checkEraserCollisions(Offset eraserPosition) {
    final eraserRadius = _getStrokeWidth() / 2;

    // Check collisions with text inserts in this section
    final textInserts = _sectionInserts
        .where((insert) => insert.type == SketchInsertType.text)
        .where((insert) => !_recentlyRemovedTextIds.contains(insert.id))
        .toList();

    for (final textInsert in textInserts) {
      if (textInsert.textPosition == null) continue;

      // Calculate text bounds (approximate)
      final textSize = _calculateTextSize(textInsert);
      final textRect = Rect.fromLTWH(
        textInsert.textPosition!.dx,
        textInsert.textPosition!.dy,
        textSize.width,
        textSize.height,
      );

      // Check if eraser circle intersects with text rectangle
      final eraserRect = Rect.fromCircle(
        center: eraserPosition,
        radius: eraserRadius,
      );

      if (eraserRect.overlaps(textRect)) {
        // Mark as recently removed and remove the text insert
        _recentlyRemovedTextIds.add(textInsert.id);
        widget.onRemoveInsert(textInsert.id);
      }
    }
  }

  Size _calculateTextSize(SketchInsert textInsert) {
    if (textInsert.text == null || textInsert.text!.isEmpty) {
      return Size.zero;
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: textInsert.text!,
        style: TextStyle(
          fontSize: textInsert.fontSize ?? 16.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    return textPainter.size;
  }

  void _handlePanEnd(DragEndDetails details) {
    _drawingController.finishDrawing(
      widget.sectionId,
      _getStrokeWidth(),
      _getDrawingColor(),
      _currentMode == SketchMode.highlighting
          ? SketchInsertType.drawing
          : _currentMode == SketchMode.eraser
              ? SketchInsertType.eraser
              : SketchInsertType.drawing,
    );

    // Hide eraser indicator and clear tracking when stroke ends
    if (_currentMode == SketchMode.eraser) {
      setState(() {
        _eraserIndicatorPosition = null;
        _showEraserIndicator = false;
      });
      _recentlyRemovedTextIds.clear();
    }
  }

  void _handleTextTap(TapDownDetails details) {
    final position = details.localPosition;

    if (_textController.isEditingText) {
      FocusScope.of(context).unfocus();
      return;
    }

    if (_isWithinBounds(position)) {
      _textController.startNewText(position);
    }
  }

  double _getStrokeWidth() {
    return _currentMode == SketchMode.highlighting
        ? widget.selectedStrokeWidth * 2
        : widget.selectedStrokeWidth;
  }

  Color? _getDrawingColor() {
    // Return null for eraser mode since erasers don't use color
    if (_currentMode == SketchMode.eraser) {
      return null;
    }

    return _currentMode == SketchMode.highlighting
        ? widget.selectedColor.withValues(alpha: 0.3)
        : widget.selectedColor;
  }

  bool _isWithinBounds(Offset position) {
    final size = context.size;
    if (size == null) return false;

    return position.dx >= 0 &&
        position.dx <= size.width &&
        position.dy >= 0 &&
        position.dy <= size.height;
  }

  void _saveCurrentDrawing() {
    final points = _drawingController.getCurrentPointsForSave();
    if (points.length > 1) {
      final insertType = _currentMode == SketchMode.highlighting
          ? SketchInsertType.drawing
          : _currentMode == SketchMode.eraser
              ? SketchInsertType.eraser
              : SketchInsertType.drawing;

      widget.onSaveInsert(
        SketchInsert(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          sectionId: widget.sectionId,
          type: insertType,
          points: points,
          color: _getDrawingColor(),
          strokeWidth: _getStrokeWidth(),
        ),
      );
    }
    _drawingController.clearCurrentPoints();
  }

  void _saveCurrentDrawingAndStartNew(Offset newPosition) {
    _saveCurrentDrawing();
    _drawingController.startDrawing(newPosition);
  }

  void _handleStateChanged() {
    setState(() {});
  }

  Widget _buildEraserIndicator() {
    if (_currentMode != SketchMode.eraser ||
        !_showEraserIndicator ||
        _eraserIndicatorPosition == null) {
      return const SizedBox.shrink();
    }

    final eraserRadius = _getStrokeWidth() / 2;

    return Positioned(
      left: _eraserIndicatorPosition!.dx - eraserRadius,
      top: _eraserIndicatorPosition!.dy - eraserRadius,
      child: Container(
        width: eraserRadius * 2,
        height: eraserRadius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.8),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

// Extracted drawing controller
class DrawingController {
  DrawingController({
    required this.onSaveInsert,
    // required this.onEraseInsertAt,  // Future version
    required this.onStateChanged,
  });

  final void Function(SketchInsert insert) onSaveInsert;
  final VoidCallback onStateChanged;

  final List<Offset> _currentDrawingPoints = [];
  bool _isDrawing = false;
  bool _isOutsideBounds = false;

  List<Offset> get currentDrawingPoints =>
      _isDrawing ? List.unmodifiable(_currentDrawingPoints) : const [];

  bool get isDrawing => _isDrawing;
  bool get isOutsideBounds => _isOutsideBounds;

  void startDrawing(Offset position) {
    _currentDrawingPoints.clear();
    _currentDrawingPoints.add(position);
    _isDrawing = true;
    _isOutsideBounds = false;
    onStateChanged();
  }

  void continueDrawing(Offset position) {
    if (!_isDrawing) return;
    _currentDrawingPoints.add(position);
    onStateChanged();
  }

  void setOutsideBounds(bool value) {
    _isOutsideBounds = value;
    onStateChanged();
  }

  List<Offset> getCurrentPointsForSave() {
    return List<Offset>.from(_currentDrawingPoints);
  }

  void clearCurrentPoints() {
    _currentDrawingPoints.clear();
    onStateChanged();
  }

  void finishDrawing(String sectionId, double strokeWidth, Color? color,
      SketchInsertType type) {
    if (!_isDrawing) return;

    if (_currentDrawingPoints.length > 1) {
      onSaveInsert(
        SketchInsert(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          sectionId: sectionId,
          type: type,
          points: List<Offset>.from(_currentDrawingPoints),
          // Only include color for non-eraser types
          color: type == SketchInsertType.eraser ? null : color,
          strokeWidth: strokeWidth,
        ),
      );
    }

    _currentDrawingPoints.clear();
    _isDrawing = false;
    _isOutsideBounds = false;
    onStateChanged();
  }

  void eraseAt(String sectionId, Offset position, double size) {
    // onEraseInsertAt(sectionId, position, size);  // Future version
  }

  void dispose() {
    _currentDrawingPoints.clear();
  }
}

// Extracted text controller
class TextController {
  TextController({
    required this.onSaveInsert,
    required this.onUpdateTextInsert,
    required this.onStateChanged,
  });

  final void Function(SketchInsert insert) onSaveInsert;
  final void Function(String id, String text, Offset position)
      onUpdateTextInsert;
  final VoidCallback onStateChanged;

  final TextEditingController textEditingController = TextEditingController();
  late final FocusNode focusNode;

  String? _editingTextId;
  Offset? _editPosition;
  bool _isEditingText = false;
  String? _draggingTextId;
  Offset? _dragStartPosition;

  // Store original text properties when editing existing text
  Color? _originalTextColor;
  double? _originalTextFontSize;

  // Store parent context info for callbacks
  String? _sectionId;
  Color? _selectedColor;
  double? _selectedFontSize;
  List<SketchInsert>? _inserts;

  bool get isEditingText => _isEditingText;
  Offset? get editPosition => _editPosition;
  bool isEditing(String id) => _editingTextId == id;

  // Getters for the current editing properties
  Color? get currentEditingColor => _originalTextColor ?? _selectedColor;
  double? get currentEditingFontSize =>
      _originalTextFontSize ?? _selectedFontSize;

  void initialize() {
    focusNode = FocusNode();
    focusNode.addListener(_onFocusChange);
  }

  void updateContext({
    required String sectionId,
    required Color selectedColor,
    required double selectedFontSize,
    required List<SketchInsert> inserts,
  }) {
    _sectionId = sectionId;
    _selectedColor = selectedColor;
    _selectedFontSize = selectedFontSize;
    _inserts = inserts;
  }

  void _onFocusChange() {
    if (!focusNode.hasFocus && _isEditingText) {
      saveText();
    }
  }

  void startNewText(Offset position) {
    _editPosition = position;
    textEditingController.clear();
    _isEditingText = true;
    _editingTextId = null;

    // Clear original text properties for new text
    _originalTextColor = null;
    _originalTextFontSize = null;

    onStateChanged();

    Future.delayed(
      const Duration(milliseconds: 50),
      () {
        focusNode.requestFocus();
        // Automatically scroll to keep the text field visible
        _ensureTextFieldVisible();
      },
    );
  }

  void editExisting(SketchInsert insert) {
    _editPosition = insert.textPosition;
    textEditingController.text = insert.text ?? '';
    _isEditingText = true;
    _editingTextId = insert.id;
    onStateChanged();

    // Store original text properties
    _originalTextColor = insert.color;
    _originalTextFontSize = insert.fontSize;

    Future.delayed(
      const Duration(milliseconds: 50),
      () {
        focusNode.requestFocus();
        // Automatically scroll to keep the text field visible
        _ensureTextFieldVisible();
      },
    );
  }

  /// Automatically scroll to keep the text field visible
  void _ensureTextFieldVisible() {
    if (focusNode.context != null) {
      // Immediate smooth scroll for when keyboard is already active
      Scrollable.ensureVisible(
        focusNode.context!,
        curve: Curves.easeInOut,
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
        alignment: 0.3,
      );

      // Delayed refined scroll to handle keyboard appearance smoothly
      Future.delayed(const Duration(milliseconds: 300), () {
        if (focusNode.context != null && focusNode.hasFocus) {
          Scrollable.ensureVisible(
            focusNode.context!,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
            alignment: 0.3,
          );
        }
      });
    }
  }

  void saveText() {
    final text = textEditingController.text.trim();

    if (_editingTextId != null) {
      // Update existing text - this should save to history
      onUpdateTextInsert(_editingTextId!, text, _editPosition!);
    } else if (_editPosition != null &&
        _sectionId != null &&
        _selectedColor != null &&
        _selectedFontSize != null) {
      // Create new text insert
      onSaveInsert(
        SketchInsert(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          sectionId: _sectionId!,
          points: [],
          color: _selectedColor!,
          strokeWidth: 1.0,
          type: SketchInsertType.text,
          text: text,
          textPosition: _editPosition!,
          fontSize: _selectedFontSize!,
        ),
      );
    }

    _reset();
  }

  void startDragging(String id, Offset position) {
    _draggingTextId = id;
    _dragStartPosition = position;
  }

  void updateDragPosition(Offset position, Size? canvasSize) {
    if (_draggingTextId == null ||
        _dragStartPosition == null ||
        _inserts == null) return;

    // Find the insert
    final insert = _inserts!.firstWhere(
      (insert) => insert.id == _draggingTextId,
      orElse: () => throw StateError('Insert not found'),
    );

    if (insert.textPosition == null) return;

    // Calculate the delta from drag start
    final delta = position - _dragStartPosition!;

    // Apply the delta to the text position
    final rawPosition = insert.textPosition! + delta;

    // Clamp to within canvas bounds if size is available
    Offset newPosition;
    if (canvasSize != null) {
      final clampedDx = rawPosition.dx.clamp(0.0, canvasSize.width);
      final clampedDy = rawPosition.dy.clamp(0.0, canvasSize.height);
      newPosition = Offset(clampedDx, clampedDy);
    } else {
      newPosition = rawPosition;
    }

    // Update the drag start position for the next frame
    _dragStartPosition = position;

    // Update position WITHOUT saving to history
    onUpdateTextInsert(_draggingTextId!, insert.text ?? '', newPosition);
  }

  void stopDragging() {
    if (_draggingTextId != null) {
      // When dragging stops, save the final position to history
      final insert = _inserts?.firstWhere(
        (insert) => insert.id == _draggingTextId,
        orElse: () => throw StateError('Insert not found'),
      );

      if (insert != null && insert.textPosition != null) {
        onUpdateTextInsert(
            _draggingTextId!, insert.text ?? '', insert.textPosition!);
      }
    }

    _draggingTextId = null;
    _dragStartPosition = null;
  }

  void _reset() {
    _isEditingText = false;
    _editPosition = null;
    _editingTextId = null;
    _originalTextColor = null;
    _originalTextFontSize = null;
    textEditingController.clear();
    onStateChanged();
  }

  void dispose() {
    textEditingController.dispose();
    focusNode
      ..removeListener(_onFocusChange)
      ..dispose();
  }
}

// Extracted text insert widget
class TextInsertWidget extends StatelessWidget {
  const TextInsertWidget({
    required this.insert,
    required this.isInteractive,
    required this.onTap,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.isTransparent,
    super.key,
  });

  final SketchInsert insert;
  final bool isInteractive;
  final VoidCallback onTap;
  final void Function(Offset position) onDragStart;
  final void Function(Offset position) onDragUpdate;
  final VoidCallback onDragEnd;
  final bool isTransparent;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: insert.textPosition?.dx ?? 0,
      top: insert.textPosition?.dy ?? 0,
      child: GestureDetector(
        onTap: isInteractive ? onTap : null,
        onPanStart: isInteractive
            ? (details) => onDragStart(details.globalPosition)
            : null,
        onPanUpdate: isInteractive
            ? (details) => onDragUpdate(details.globalPosition)
            : null,
        onPanEnd: isInteractive ? (_) => onDragEnd() : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            insert.text ?? '',
            style: TextStyle(
              color: isTransparent ? Colors.transparent : insert.color,
              fontSize: insert.fontSize ?? 16,
            ),
          ),
        ),
      ),
    );
  }
}

// Extracted text editor widget
class TextEditorWidget extends StatelessWidget {
  const TextEditorWidget({
    required this.position,
    required this.controller,
    required this.focusNode,
    required this.color,
    required this.fontSize,
    required this.onComplete,
    required this.onTapOutside,
    super.key,
  });

  final Offset position;
  final TextEditingController controller;
  final FocusNode focusNode;
  final Color color;
  final double fontSize;
  final VoidCallback onComplete;
  final VoidCallback onTapOutside;

  static const double _minWidth = 20;
  static const double _maxWidth = 150;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTapOutside,
        child: IntrinsicWidth(
          child: Container(
            constraints: const BoxConstraints(
              minWidth: _minWidth,
              maxWidth: _maxWidth,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
              ),
              style: TextStyle(
                color: color,
                fontSize: fontSize,
              ),
              minLines: 1,
              maxLines: 5,
              onEditingComplete: onComplete,
            ),
          ),
        ),
      ),
    );
  }
}
