import 'package:flutter/material.dart';

class CardModel {
  final String name, image;
  final IconData? icon;
  final VoidCallback? onTap;
  final String? categoryKey; // Make categoryKey nullable for cards like "Add Your Own"
  final String heroTag; // Unique tag for Hero animations

  CardModel({
    required this.name,
    required this.image,
    this.icon,
    this.onTap,
    this.categoryKey, // Updated to be nullable
    // Auto-generate heroTag. Ensure it's unique for each card.
    // Using categoryKey if available, otherwise a sanitized name.
  }) : heroTag = 'card_hero_${categoryKey ?? name.replaceAll(' ', '_').toLowerCase()}';
}

List<CardModel> demoCardData = [
  CardModel(
    name: "English Songs",
    image: "english_image.png", // Assuming this is your image asset
    categoryKey: "english_data", // Trying "english_data" as the filter value
  ),
  CardModel(
    name: "Kannada Songs",
    image: "kannada_image.png", // Assuming this is your image asset
    categoryKey: "kannada_songs", // Key for Supabase query
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
