// lib/widgets/jieqi_list_item.dart
import 'package:flutter/material.dart';
import '../models/jieqi_model.dart';

class JieQiListItem extends StatelessWidget {
  final JieQi jieqi;
  final bool isCurrent;
  final bool isPast;

  const JieQiListItem({
    super.key,
    required this.jieqi,
    this.isCurrent = false,
    this.isPast = false,
  });

  @override
  Widget build(BuildContext context) {
    Color seasonColor;
    IconData seasonIcon;

    switch (jieqi.getSeason()) {
      case '春':
        seasonColor = Colors.green;
        seasonIcon = Icons.local_florist;
        break;
      case '夏':
        seasonColor = Colors.redAccent;
        seasonIcon = Icons.wb_sunny;
        break;
      case '秋':
        seasonColor = Colors.orange;
        seasonIcon = Icons.eco;
        break;
      case '冬':
        seasonColor = Colors.blue;
        seasonIcon = Icons.ac_unit;
        break;
      default:
        seasonColor = Colors.teal;
        seasonIcon = Icons.event;
    }

    return Card(
      elevation: isCurrent ? 8 : 2,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCurrent
            ? BorderSide(color: seasonColor, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isPast ? Colors.grey : seasonColor,
          foregroundColor: Colors.white,
          child: Icon(seasonIcon),
        ),
        title: Text(
          jieqi.name,
          style: TextStyle(
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            fontSize: 18,
          ),
        ),
        subtitle: Text(jieqi.getFormattedDate()),
        trailing: isPast
            ? const Icon(Icons.check_circle, color: Colors.grey)
            : (isCurrent
            ? Icon(Icons.star, color: seasonColor)
            : null),
      ),
    );
  }
}
