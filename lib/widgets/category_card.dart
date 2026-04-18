import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../theme/app_theme.dart';

class CategoryCard extends StatefulWidget {
  final CategoryModel category;
  final bool isSelected;

  const CategoryCard({
    super.key,
    required this.category,
    this.isSelected = false,
  });

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard>
    {

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bg = widget.isSelected ? colors.accent : colors.card;
    final borderColor = widget.isSelected ? colors.accent : colors.border;

    return GestureDetector(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.category.icon,
              color: widget.isSelected ? colors.background : colors.accent,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              widget.category.title,
              style: TextStyle(
                color: widget.isSelected ? colors.background : colors.secondaryText,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
