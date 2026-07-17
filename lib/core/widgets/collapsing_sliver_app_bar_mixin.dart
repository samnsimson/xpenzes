import 'package:flutter/material.dart';

/// Shows/hides a `SliverAppBar`'s collapsed title once the scroll offset
/// passes [collapsedThreshold]. Mix this into any `State` that owns a
/// `ScrollController` feeding a `CustomScrollView`'s `SliverAppBar`, to
/// avoid re-implementing the same listener/setState dance per screen.
mixin CollapsingSliverAppBarMixin<T extends StatefulWidget> on State<T> {
  double get collapsedThreshold => 150.0;

  final scrollController = ScrollController();
  bool showCollapsedTitle = false;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final show = scrollController.offset > collapsedThreshold;
    if (show != showCollapsedTitle) {
      setState(() => showCollapsedTitle = show);
    }
  }
}
