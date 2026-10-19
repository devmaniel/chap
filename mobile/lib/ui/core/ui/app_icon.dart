import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Stroke icons copied from the master mockup, one SVG each in assets/icons.
enum AppIconName {
  arrow,
  back,
  chat,
  close,
  compass,
  friends,
  heart,
  heartFilled,
  image,
  lock,
  mic,
  micOff,
  person,
  phone,
  plus,
  search,
  send,
  spark,
  speaker,
  wifiOff,
}

/// Decorative icon; the surrounding button or row carries the label.
class AppIcon extends StatelessWidget {
  const AppIcon(this.name, {super.key, required this.color, this.size = 22});

  final AppIconName name;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/${name.name}.svg',
      width: size,
      height: size,
      excludeFromSemantics: true,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
