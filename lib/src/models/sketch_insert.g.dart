// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sketch_insert.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SketchInsert _$SketchInsertFromJson(Map<String, dynamic> json) =>
    _SketchInsert(
      id: json['id'] as String,
      sketchId: json['sketchId'] as String?,
      sectionId: json['sectionId'] as String,
      points: const OffsetListConverter().fromJson(json['points'] as List),
      color: _$JsonConverterFromJson<int, Color>(
          json['color'], const ColorConverter().fromJson),
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
      type: $enumDecodeNullable(_$SketchInsertTypeEnumMap, json['type']) ??
          SketchInsertType.drawing,
      text: json['text'] as String?,
      textPosition: _$JsonConverterFromJson<Map<String, dynamic>, Offset>(
          json['textPosition'], const OffsetConverter().fromJson),
      fontSize: (json['fontSize'] as num?)?.toDouble(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$SketchInsertToJson(_SketchInsert instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sketchId': instance.sketchId,
      'sectionId': instance.sectionId,
      'points': const OffsetListConverter().toJson(instance.points),
      'color': _$JsonConverterToJson<int, Color>(
          instance.color, const ColorConverter().toJson),
      'strokeWidth': instance.strokeWidth,
      'type': _$SketchInsertTypeEnumMap[instance.type]!,
      'text': instance.text,
      'textPosition': _$JsonConverterToJson<Map<String, dynamic>, Offset>(
          instance.textPosition, const OffsetConverter().toJson),
      'fontSize': instance.fontSize,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) =>
    json == null ? null : fromJson(json as Json);

const _$SketchInsertTypeEnumMap = {
  SketchInsertType.drawing: 'drawing',
  SketchInsertType.text: 'text',
  SketchInsertType.eraser: 'eraser',
};

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) =>
    value == null ? null : toJson(value);
