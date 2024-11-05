import 'package:flutter/material.dart';

class TodoItem extends StatelessWidget {
  final String title;
  final String description;
  final String time;
  final String date;
  final bool isCompleted;
  final Function(bool?) onChanged;

  TodoItem({
    required this.title,
    this.description = '',
    this.time = '',
    this.date = '',
    required this.isCompleted,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Color(0xFFF3F4F6), // Light background color
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Rounded corners
        side: BorderSide(color: Color(0xFF002347), width: 1.2), // Border color and width
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: ListTile(
          contentPadding: EdgeInsets.zero, // Removes default padding
          leading: Checkbox(
            value: isCompleted,
            onChanged: onChanged,
            activeColor: Color(0xFF002347), // Checkbox color
          ),
          title: Text(
            title,
            style: TextStyle(
              decoration: isCompleted ? TextDecoration.lineThrough : null,
              color: isCompleted ? Colors.grey : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          subtitle: description.isNotEmpty || time.isNotEmpty || date.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (description.isNotEmpty)
                        Text(
                          description,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 15,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (time.isNotEmpty)
                            Row(
                              children: [
                                Icon(Icons.access_time,
                                    size: 16, color: Color(0xFF002347)),
                                SizedBox(width: 4),
                                Text(
                                  time,
                                  style: TextStyle(
                                    color: Color(0xFF002347),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          if (date.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 10.0),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today,
                                      size: 16, color: Colors.grey),
                                  SizedBox(width: 4),
                                  Text(
                                    date,
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
