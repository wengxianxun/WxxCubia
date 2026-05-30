import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class ItemWidget extends StatefulWidget {
  final int number;
  final String imgPath;

  const ItemWidget({super.key, required this.number, required this.imgPath});

  @override
  State<ItemWidget> createState() => _ItemWidget();
}

class _ItemWidget extends State<ItemWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  @override
  void initState() {
    super.initState();

    // 初始化动画控制器
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // 创建果冻动画
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.0, end: 2.5),
        weight: 1.2,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 2.5, end: 0.7),
        weight: 1.2,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.7, end: 1.2),
        weight: 1,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.2, end: 1.0),
        weight: 1,
      ),
    ]).animate(_animationController);

    // 在组件渲染后开始动画
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _startJellyAnimation();
    });
  }

  @override
  void didUpdateWidget(covariant ItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当number属性变化时重新触发果冻动画
    if (oldWidget.number != widget.number) {
      _startJellyAnimation();
    }
  }

  // 开始循环的果冻动画
  void _startJellyAnimation() {
    _animationController.repeat(count: 1);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset('assets/images/btn/btn_bg.png', width: 45, height: 45),
          Image.asset(widget.imgPath, width: 40, height: 40),
          Positioned(top: 0, right: 0, child: badgeWidget()),
        ],
      ),
    );
  }

  Widget badgeWidget() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.only(left: 3, right: 3, top: 0, bottom: 0),
            child: Text(
              '${widget.number}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
