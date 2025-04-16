import 'package:equatable/equatable.dart';

class SubscriptionPlan extends Equatable {
  final String id;
  final String title;
  final String description;
  final double price;
  final String period;
  final List<String> features;

  const SubscriptionPlan({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.period,
    required this.features,
  });

  @override
  List<Object?> get props => [id, title, price, period];
}