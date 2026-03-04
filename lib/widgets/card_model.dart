import 'package:flutter/material.dart';

class CardModel {
  final String name, image;
  final IconData? icon;
  final VoidCallback? onTap;
  final String heroTag; // Unique tag for Hero animations

  CardModel({
    required this.name,
    required this.image,
    this.icon,
    this.onTap,
  }) : heroTag = 'card_hero_${name.replaceAll(' ', '_').toLowerCase()}';
}

List<CardModel> demoCardData = [
  CardModel(
    name: "English Songs",
    image: "english_image.png",
  ),
  CardModel(
    name: "Kannada Songs",
    image: "kannada_image.png",
  ),
  CardModel(
    name: "Other Languages",
    image: "other_languages_image.png",
    icon: Icons.add_circle_outline_rounded,
  ),
];
