import 'package:flutter/material.dart';
import 'package:house_pal/models/user/app_user.dart';

class AvatarStack extends StatelessWidget {
  final List<AppUser> members;
  final double avatarRadius;
  final double overlap;
  final int maxDisplay;

  const AvatarStack({
    super.key,
    required this.members,
    this.avatarRadius = 14,
    this.overlap = 20,
    this.maxDisplay = 3,
  });

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return const SizedBox.shrink();

    final display = members.take(maxDisplay).toList();
    final extra = members.length - maxDisplay;

    final stackHeight = avatarRadius * 2 + 10;
    final stackWidth = overlap * maxDisplay + avatarRadius * 2;

    final fallbackColors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
    ];

    return SizedBox(
      height: stackHeight,
      width: stackWidth,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ...display.asMap().entries.map((entry) {
            final index = entry.key;
            final user = entry.value;

            final initial = user.name.isNotEmpty
                ? user.name.trim()[0].toUpperCase()
                : "U";

            final hasValidAvatar =
                user.avatarUrl != null &&
                user.avatarUrl!.trim().isNotEmpty &&
                user.avatarUrl!.trim() != "null";

            final bgColor = fallbackColors[index % fallbackColors.length];

            return Positioned(
              left: index * overlap,
              child: CircleAvatar(
                radius: avatarRadius,
                backgroundColor: hasValidAvatar ? Colors.transparent : bgColor,
                backgroundImage: hasValidAvatar
                    ? NetworkImage(user.avatarUrl!)
                    : null,
                child: hasValidAvatar
                    ? null
                    : Text(
                        initial,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: avatarRadius - 2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            );
          }),

          if (extra > 0)
            Positioned(
              left: maxDisplay * overlap,
              child: CircleAvatar(
                radius: avatarRadius,
                backgroundColor: const Color(0xFF333333),
                child: Text(
                  "+$extra",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: avatarRadius - 4,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
