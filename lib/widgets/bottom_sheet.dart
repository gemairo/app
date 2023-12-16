import 'package:flutter/material.dart';

showGemairoModalBottomSheet(
    {List<Widget> children = const [], required context}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    isDismissible: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 640),
    shape: Theme.of(context).bottomSheetTheme.shape,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.2,
      maxChildSize: 1,
      snap: true,
      snapSizes: const [.4, 1],
      expand: false,
      builder: (_, controller) => ListView(
        controller: controller,
        children: children,
      ),
    ),
  );
}
