import 'package:flutter/cupertino.dart';
import 'package:gap/gap.dart';

extension ListGutter on List<Widget> {
  List<Widget> separate(double space) => length <= 1
      ? this
      : sublist(1)
          .fold([first], (prev, element) => [...prev, Gap(space), element]);
}