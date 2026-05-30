import 'package:flutter/material.dart';

class HuuuaButton extends StatefulWidget {
  final String? text;
  final Color backgroundColor;
  final Icon? icon;
  final VoidCallback onTap;
  final double borderRadius;
  final BoxBorder? border;
  final EdgeInsetsGeometry? padding;
  const HuuuaButton({
    super.key,
    this.text,
    this.icon,
    required this.backgroundColor,
    required this.onTap,
    this.borderRadius = 18,
    this.border,
    this.padding,
  });

  @override
  State<HuuuaButton> createState() => _CartoonButtonState();
}

class _CartoonButtonState extends State<HuuuaButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // SoundPool().playButton();
        widget.onTap();
      },
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.9 : 1.0, // 按下缩小
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 36,
          constraints: const BoxConstraints(minWidth: 80),
          padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 15),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: widget.border ?? Border.all(color: Colors.orange, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: widget.borderRadius,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) widget.icon ?? SizedBox.shrink(),
              if (widget.icon != null && widget.text != null)
                SizedBox(width: 2),
              if (widget.text != null)
                Text(
                  widget.text!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.5,
                    shadows: [
                      Shadow(
                        blurRadius: 2,
                        color: Colors.black45,

                        offset: Offset(0.5, 0.5),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
