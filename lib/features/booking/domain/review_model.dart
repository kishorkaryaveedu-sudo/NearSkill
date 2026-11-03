/// ReviewModel – maps to public.reviews table
class ReviewModel {
  final String reviewId;
  final String requestId;
  final String reviewerUserId;
  final String ratedWorkerId;
  final double rating;
  final String? comment;
  final String? imageUrl;
  final DateTime createdAt;

  const ReviewModel({
    required this.reviewId,
    required this.requestId,
    required this.reviewerUserId,
    required this.ratedWorkerId,
    required this.rating,
    this.comment,
    this.imageUrl,
    required this.createdAt,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    return ReviewModel(
      reviewId: map['review_id'] ?? '',
      requestId: map['request_id'] ?? '',
      reviewerUserId: map['reviewer_user_id'] ?? '',
      ratedWorkerId: map['rated_worker_id'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      comment: map['comment'],
      imageUrl: map['image_url'],
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'review_id': reviewId,
      'request_id': requestId,
      'reviewer_user_id': reviewerUserId,
      'rated_worker_id': ratedWorkerId,
      'rating': rating,
      'comment': comment,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ReviewModel copyWith({
    String? reviewId,
    String? requestId,
    String? reviewerUserId,
    String? ratedWorkerId,
    double? rating,
    String? comment,
    String? imageUrl,
    DateTime? createdAt,
  }) {
    return ReviewModel(
      reviewId: reviewId ?? this.reviewId,
      requestId: requestId ?? this.requestId,
      reviewerUserId: reviewerUserId ?? this.reviewerUserId,
      ratedWorkerId: ratedWorkerId ?? this.ratedWorkerId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'ReviewModel(reviewId: $reviewId, rating: $rating)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReviewModel && other.reviewId == reviewId;
  }

  @override
  int get hashCode => reviewId.hashCode;
}
