import 'package:flutter/material.dart';

class Detection {
  final String label;
  final double score;
  final Rect rect;

  Detection({
    required this.label,
    required this.score,
    required this.rect,
  });

  Map<String, dynamic> toMap() => {
        'label': label,
        'score': score,
        'left': rect.left,
        'top': rect.top,
        'width': rect.width,
        'height': rect.height,
      };

  factory Detection.fromMap(Map<String, dynamic> map) => Detection(
        label: map['label'],
        score: map['score'],
        rect: Rect.fromLTWH(
          map['left'],
          map['top'],
          map['width'],
          map['height'],
        ),
      );
}
