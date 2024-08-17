import 'package:flutter/material.dart';

class FollowButton extends StatelessWidget {
  VoidCallback? onPressed;
  final Color backgroundColor;
  final Color borderColor;
  final String text;
  final Color textColor;
  final double? width;
  final double? height;
  FollowButton(
      {super.key,
      this.onPressed,
      required this.backgroundColor,
      required this.borderColor,
      required this.text,
      this.width,
      this.height,
      required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 2),
      child: TextButton(
        onPressed: onPressed,
        child: Container(
          decoration: BoxDecoration(
              color: backgroundColor,
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(5)),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
          width: width ?? 250,
          height: height ?? 27,
        ),
      ),
    );
  }
}
