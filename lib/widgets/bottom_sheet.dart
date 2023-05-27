import 'package:flutter/material.dart';

showSilvioModalBottomSheet(
    {List<Widget> children = const [], required context}) {
  double topPadding = View.of(context).padding.top;
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    isDismissible: true,
    useSafeArea: false,
    constraints: BoxConstraints(
        maxWidth: 640,
        maxHeight: MediaQuery.of(context).size.height - topPadding),
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
