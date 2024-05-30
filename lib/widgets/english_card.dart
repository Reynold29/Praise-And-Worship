import 'package:flutter/material.dart';

class LanguageCard extends StatefulWidget {
  final String imagePath;
  final bool isSelected;
  final VoidCallback onTap;

  const LanguageCard({
    Key? key,
    required this.imagePath,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  _LanguageCardState createState() => _LanguageCardState();
}

class _LanguageCardState extends State<LanguageCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final cardWidth = MediaQuery.of(context).size.width * 0.95; // Adjust as needed
    final cardHeight = cardWidth * 0.9; // Adjust aspect ratio if needed

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: Card(
        elevation: _isPressed ? 12.0 : 6.0, // Adjusted elevation for 3D effect
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Container(
          width: cardWidth,
          height: cardHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Image.asset(
                  widget.imagePath,
                  fit: BoxFit.cover,
                ),
              ),
              // Text at the top
              Positioned(
                top: 8.0,
                left: 8.0,
                child: Text(
                  'English Songs',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Arrow at the bottom
              Positioned(
                bottom: 8.0,
                right: 8.0,
                child: Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
