class EntityModel {
  final String text;
  final String type; // date, address, phone, price, email, url, unknown
  final double confidence;

  EntityModel({required this.text, required this.type, this.confidence = 1.0});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'text': text,
      'type': type,
      'confidence': confidence,
    };
  }

  factory EntityModel.fromMap(Map<String, dynamic> map) {
    return EntityModel(
      text: map['text'] as String,
      type: map['type'] as String,
      confidence: (map['confidence'] as num?)?.toDouble() ?? 1.0,
    );
  }

  EntityModel copyWith({String? text, String? type, double? confidence}) {
    return EntityModel(
      text: text ?? this.text,
      type: type ?? this.type,
      confidence: confidence ?? this.confidence,
    );
  }

  @override
  String toString() =>
      'Entity(text: $text, type: $type, confidence: $confidence)';
}
