import 'package:flutter/material.dart';
import 'package:wxx_cubia/util_flame/sound_pool.dart';

class HuuuaIconButton extends StatefulWidget {
  final String? text;

  final Widget chilWidget;
  final VoidCallback onTap;
  const HuuuaIconButton({
    super.key,
    this.text,
    required this.chilWidget,
    required this.onTap,
  });

  @override
  State<HuuuaIconButton> createState() => _CartoonButtonState();
}

class _CartoonButtonState extends State<HuuuaIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        SoundPool().playButton();
        widget.onTap();
      },
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.9 : 1.0, // 按下缩小
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 45,
          height: 45,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/btn/btn_bg.png'),
            ),
          ),
          child: widget.chilWidget,
        ),
      ),
    );
  }
}
