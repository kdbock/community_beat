import 'package:flutter/material.dart';

/// Custom ListView.builder with common functionality
class CustomListView<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final bool isLoading;
  final VoidCallback? onRefresh;
  final VoidCallback? onLoadMore;
  final ScrollController? scrollController;
  final Widget? emptyWidget;
  final Widget? loadingWidget;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final Widget? separator;

  const CustomListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.isLoading = false,
    this.onRefresh,
    this.onLoadMore,
    this.scrollController,
    this.emptyWidget,
    this.loadingWidget,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.separator,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && items.isEmpty) {
      return loadingWidget ?? const Center(child: CircularProgressIndicator());
    }

    if (items.isEmpty) {
      return emptyWidget ?? _buildDefaultEmpty(context);
    }

    Widget listView;

    if (separator != null) {
      listView = ListView.separated(
        controller: scrollController,
        padding: padding,
        shrinkWrap: shrinkWrap,
        physics: physics,
        itemCount: items.length + (isLoading ? 1 : 0),
        separatorBuilder: (context, index) => separator!,
        itemBuilder: _buildItem,
      );
    } else {
      listView = ListView.builder(
        controller: scrollController,
        padding: padding,
        shrinkWrap: shrinkWrap,
        physics: physics,
        itemCount: items.length + (isLoading ? 1 : 0),
        itemBuilder: _buildItem,
      );
    }

    if (onRefresh != null) {
      return RefreshIndicator(
        onRefresh: () async {
          onRefresh!();
        },
        child: listView,
      );
    }

    return listView;
  }

  Widget _buildItem(BuildContext context, int index) {
    if (index == items.length) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return itemBuilder(context, items[index], index);
  }

  Widget _buildDefaultEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No items found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom GridView with common functionality
class CustomGridView<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final bool isLoading;
  final VoidCallback? onRefresh;
  final ScrollController? scrollController;
  final Widget? emptyWidget;
  final Widget? loadingWidget;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final SliverGridDelegate gridDelegate;

  const CustomGridView({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.gridDelegate,
    this.isLoading = false,
    this.onRefresh,
    this.scrollController,
    this.emptyWidget,
    this.loadingWidget,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && items.isEmpty) {
      return loadingWidget ?? const Center(child: CircularProgressIndicator());
    }

    if (items.isEmpty) {
      return emptyWidget ?? _buildDefaultEmpty(context);
    }

    Widget gridView = GridView.builder(
      controller: scrollController,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      gridDelegate: gridDelegate,
      itemCount: items.length + (isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == items.length) {
          return const Center(child: CircularProgressIndicator());
        }
        return itemBuilder(context, items[index], index);
      },
    );

    if (onRefresh != null) {
      return RefreshIndicator(
        onRefresh: () async {
          onRefresh!();
        },
        child: gridView,
      );
    }

    return gridView;
  }

  Widget _buildDefaultEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.grid_view,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No items found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}