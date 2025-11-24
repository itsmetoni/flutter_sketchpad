import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sketch_insert.freezed.dart';
part 'sketch_insert.g.dart';

enum SketchInsertType { drawing, text, eraser }

@freezed
sealed class SketchInsert with _$SketchInsert {
  /// An individual sketch insert tied to a specific section.
  const factory SketchInsert({
    /// Unique insert ID
    required String id,

    /// ID of the sketch this insert belongs to
    String? sketchId,

    /// ID of the section within the content
    required String sectionId,
    @OffsetListConverter() required List<Offset> points,
    @ColorConverter() Color? color,
    required double strokeWidth,
    @Default(SketchInsertType.drawing) SketchInsertType type,
    String? text,
    @OffsetConverter() Offset? textPosition,
    double? fontSize,
    DateTime? createdAt,
  }) = _SketchInsert;

  factory SketchInsert.fromJson(Map<String, dynamic> json) =>
      _$SketchInsertFromJson(json);
}

class ColorConverter implements JsonConverter<Color, int> {
  const ColorConverter();

  @override
  Color fromJson(int json) => Color(json);

  @override
  int toJson(Color color) {
    // Use ARGB components instead of deprecated .value
    return (color.a.round() << 24) |
        (color.r.round() << 16) |
        (color.g.round() << 8) |
        color.b.round();
  }
}

class OffsetConverter implements JsonConverter<Offset, Map<String, dynamic>> {
  const OffsetConverter();

  @override
  Offset fromJson(Map<String, dynamic> json) {
    return Offset(
      (json['dx'] as num).toDouble(),
      (json['dy'] as num).toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson(Offset offset) {
    return {'dx': offset.dx, 'dy': offset.dy};
  }
}

class OffsetListConverter
    implements JsonConverter<List<Offset>, List<dynamic>> {
  const OffsetListConverter();

  @override
  List<Offset> fromJson(List<dynamic> json) {
    return json
        .map(
          (e) =>
              Offset((e['dx'] as num).toDouble(), (e['dy'] as num).toDouble()),
        )
        .toList();
  }

  @override
  List<dynamic> toJson(List<Offset> offsets) {
    return offsets.map((offset) => {'dx': offset.dx, 'dy': offset.dy}).toList();
  }
}
