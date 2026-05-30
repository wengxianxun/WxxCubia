enum BlockType {
  green_star("green_star", 0),
  blue_star('blue_star', 1),
  yellow_star('yellow_star', 2),
  purple_star('purple_star', 3),
  red_star('red_star', 4),
  rocket_blue('rocket_blue', 14), //火箭蓝
  rocket_red('rocket_red', 15), //火箭红
  rocket_purple('rocket_purple', 16), //火箭紫
  rocket_green('rocket_green', 17), //火箭绿
  rocket_yellow('rocket_yellow', 18), //火箭黄
  box('box', 19), //盲盒
  rainbow('rainbow', 20), //彩虹
  lightning("lightning", 21), //闪电
  radar("radar", 22); //卫星

  const BlockType(this.value, this.number);
  final String value;
  final int number;
}

/// BlockType扩展方法
extension BlockTypeExtension on BlockType {
  /// 判断当前BlockType是否是星星类型
  bool get isStar {
    return [
      BlockType.green_star,
      BlockType.blue_star,
      BlockType.yellow_star,
      BlockType.purple_star,
      BlockType.red_star,
    ].contains(this);
  }
}
