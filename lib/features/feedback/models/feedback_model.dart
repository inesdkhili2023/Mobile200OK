import 'package:equatable/equatable.dart';

class FeedbackModel extends Equatable {
  final int? id;
  final String service;      // ex: Electrician, Plumber
  final String status;       // In Progress / Finished
  final int rating;          // 0..5
  final String comment;      // texte libre
  final String priceLabel;   // ex: "89DT"
  final DateTime createdAt;

  const FeedbackModel({
    this.id,
    required this.service,
    required this.status,
    required this.rating,
    required this.comment,
    required this.priceLabel,
    required this.createdAt,
  });

  FeedbackModel copyWith({
    int? id,
    String? service,
    String? status,
    int? rating,
    String? comment,
    String? priceLabel,
    DateTime? createdAt,
  }) {
    return FeedbackModel(
      id: id ?? this.id,
      service: service ?? this.service,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      priceLabel: priceLabel ?? this.priceLabel,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory FeedbackModel.fromMap(Map<String, dynamic> map) {
    return FeedbackModel(
      id: map['id'] as int?,
      service: map['service'] as String,
      status: map['status'] as String,
      rating: map['rating'] as int,
      comment: map['comment'] as String,
      priceLabel: map['price_label'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'service': service,
      'status': status,
      'rating': rating,
      'comment': comment,
      'price_label': priceLabel,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  @override
  List<Object?> get props => [id, service, status, rating, comment, priceLabel, createdAt];
}
