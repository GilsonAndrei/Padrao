// models/base_model.dart
abstract class BaseModel {
  String get id;
  Map<String, dynamic> toMap();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BaseModel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
