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
    image: "english_image.png", // Assuming this is your image asset
  ),
  CardModel(
    name: "Kannada Songs",
    image: "kannada_image.png", // Assuming this is your image asset
  ),
  CardModel(
    name: "Add Your Own",
    image: "english_image.png", // Or a different placeholder image
    icon: Icons.add_circle_outline_rounded,
    // No categoryKey needed, or a special one if it has a function
    onTap: () {
      print("Add Your Own tapped");
      // TODO: Implement navigation or action for adding songs
    }
  ),
];
