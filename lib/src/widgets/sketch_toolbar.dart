import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'controls/sketch_color_button.dart';
import 'controls/sketch_font_size_button.dart';
import 'sketch_stroke_width_button.dart';
import '../controllers/multi_canvas_sketch_controller.dart';
import '../models/sketch_mode.dart';

/// A toolbar that provides sketch tools for marking up content with built-in animations.
class SketchToolbar extends StatefulWidget {
  /// Creates a sketch toolbar.
  const SketchToolbar({
    required this.controller,
    this.isEnabled = true,
    this.enableAnimation = true,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeInOut,
    super.key,
  });

  /// Controller for automatic state management
  final MultiCanvasSketchController controller;

  /// Whether the sketch toolbar is enabled
  final bool isEnabled;

  /// Whether to animate show/hide transitions
  final bool enableAnimation;

  /// Duration of show/hide animations
  final Duration animationDuration;

  /// Curve for show/hide animations
  final Curve animationCurve;

  @override
  State<SketchToolbar> createState() => _SketchToolbarState();
}

class _SketchToolbarState extends State<SketchToolbar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: widget.animationCurve,
    );

    // Set initial state
    if (widget.isEnabled) {
      _animationController.value = 1.0;
    }

    // Listen to controller changes
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SketchToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update listener if controller changed
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }

    // Update animation duration if changed
    if (widget.animationDuration != oldWidget.animationDuration) {
      _animationController.duration = widget.animationDuration;
    }

    // Update animation curve if changed
    if (widget.animationCurve != oldWidget.animationCurve) {
      _animation = CurvedAnimation(
        parent: _animationController,
        curve: widget.animationCurve,
      );
    }

    // Handle enabled state changes
    if (widget.isEnabled != oldWidget.isEnabled) {
      _updateAnimation();
    }
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {
        // Rebuild when controller state changes
      });
    }
  }

  void _updateAnimation() {
    if (!widget.enableAnimation) {
      _animationController.value = widget.isEnabled ? 1.0 : 0.0;
      return;
    }

    if (widget.isEnabled) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enableAnimation) {
      // No animation - use simple conditional rendering
      return widget.isEnabled ? _buildToolbar() : const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // Remove from widget tree when animation is complete and disabled
        if (!widget.isEnabled && _animation.value == 0.0) {
          return const SizedBox.shrink();
        }

        // Show animated toolbar during transitions
        return _buildAnimatedToolbar(_animation.value);
      },
    );
  }

  Widget _buildAnimatedToolbar(double animationValue) {
    // Create scale animation for polished effect
    final scaleValue = 0.8 + (0.2 * animationValue);

    // Clamp opacity to valid range (0.0 to 1.0) to handle overshooting curves
    final clampedOpacity = animationValue.clamp(0.0, 1.0);

    return Transform.scale(
      scale: scaleValue,
      child: Opacity(
        opacity: clampedOpacity,
        child: _buildToolbar(),
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          // Primary shadow for depth
          BoxShadow(
            color: Colors.black.withAlpha(64),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withAlpha(204),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drawing mode toggle (pen icon)
                _buildToolbarButton(
                  icon: LucideIcons.pen,
                  isSelected: widget.controller.mode == SketchMode.drawing,
                  tooltip: 'Toggle Drawing Mode',
                  onPressed: () => widget.controller.setMode(
                    widget.controller.mode == SketchMode.drawing
                        ? SketchMode.none
                        : SketchMode.drawing,
                  ),
                  context: context,
                ),

                const SizedBox(width: 12),
                // Highlight mode toggle
                _buildToolbarButton(
                  icon: LucideIcons.highlighter,
                  isSelected: widget.controller.mode == SketchMode.highlighting,
                  tooltip: 'Toggle Highlight Mode',
                  onPressed: () => widget.controller.setMode(
                    widget.controller.mode == SketchMode.highlighting
                        ? SketchMode.none
                        : SketchMode.highlighting,
                  ),
                  context: context,
                ),

                const SizedBox(width: 12),
                // Text mode toggle (text icon)
                _buildToolbarButton(
                  icon: LucideIcons.type,
                  isSelected: widget.controller.mode == SketchMode.text,
                  tooltip: 'Toggle Text Mode',
                  onPressed: () => widget.controller.setMode(
                    widget.controller.mode == SketchMode.text
                        ? SketchMode.none
                        : SketchMode.text,
                  ),
                  context: context,
                ),

                const SizedBox(width: 12),
                // Eraser mode toggle
                _buildToolbarButton(
                  icon: LucideIcons.eraser,
                  isSelected: widget.controller.mode == SketchMode.eraser,
                  tooltip: 'Toggle Eraser Mode',
                  onPressed: () {
                    if (widget.controller.mode == SketchMode.eraser) {
                      widget.controller.setMode(SketchMode.none);
                    } else {
                      widget.controller.setMode(SketchMode.eraser);
                      // Set default stroke width for eraser to 16 pixels
                      widget.controller.setStrokeWidth(16.0);
                    }
                  },
                  context: context,
                ),

                // Drawing mode controls: color & stroke width only
                if (widget.controller.mode == SketchMode.drawing) ...[
                  const SizedBox(width: 12),
                  _buildDivider(),
                  const SizedBox(width: 12),
                  SketchColorButton(
                    color: widget.controller.selectedColor,
                    onColorSelected: widget.controller.setColor,
                  ),
                  const SizedBox(width: 12),
                  SketchStrokeWidthButton(
                    strokeWidth: widget.controller.selectedStrokeWidth,
                    isHighlightMode: false,
                    isEraserMode: false,
                    onStrokeWidthSelected: widget.controller.setStrokeWidth,
                  ),
                ],

                // Highlight mode controls: color & stroke width
                if (widget.controller.mode == SketchMode.highlighting) ...[
                  const SizedBox(width: 12),
                  _buildDivider(),
                  const SizedBox(width: 12),
                  SketchColorButton(
                    color: widget.controller.selectedColor,
                    onColorSelected: widget.controller.setColor,
                  ),
                  const SizedBox(width: 12),
                  SketchStrokeWidthButton(
                    strokeWidth: widget.controller.selectedStrokeWidth,
                    isHighlightMode: true,
                    isEraserMode: false,
                    onStrokeWidthSelected: widget.controller.setStrokeWidth,
                  ),
                ],

                // Eraser mode controls: stroke width only
                if (widget.controller.mode == SketchMode.eraser) ...[
                  const SizedBox(width: 12),
                  _buildDivider(),
                  const SizedBox(width: 12),
                  SketchStrokeWidthButton(
                    strokeWidth: widget.controller.selectedStrokeWidth,
                    isHighlightMode: false,
                    isEraserMode: true,
                    onStrokeWidthSelected: widget.controller.setStrokeWidth,
                  ),
                ],

                // Text mode controls: color & font size
                if (widget.controller.mode == SketchMode.text) ...[
                  const SizedBox(width: 12),
                  _buildDivider(),
                  const SizedBox(width: 12),
                  SketchColorButton(
                    color: widget.controller.selectedColor,
                    onColorSelected: widget.controller.setColor,
                  ),
                  const SizedBox(width: 12),
                  SketchFontSizeButton(
                    fontSize: widget.controller.selectedFontSize,
                    onFontSizeSelected: widget.controller.setFontSize,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a toolbar button with consistent styling.
  Widget _buildToolbarButton({
    required IconData icon,
    required bool isSelected,
    required String tooltip,
    required VoidCallback onPressed,
    required BuildContext context,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isSelected
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 24,
      width: 1,
      color: Colors.grey.withAlpha(77),
    );
  }
}
