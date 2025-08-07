import 'package:flutter/material.dart';

/// Custom FutureBuilder wrapper for loading data from APIs
class DataFutureBuilder<T> extends StatelessWidget {
  final Future<T> future;
  final Widget Function(BuildContext, T) builder;
  final Widget? loadingWidget;
  final Widget Function(BuildContext, Object)? errorBuilder;
  final String? loadingMessage;

  const DataFutureBuilder({
    super.key,
    required this.future,
    required this.builder,
    this.loadingWidget,
    this.errorBuilder,
    this.loadingMessage,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget ?? 
                 Center(
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       const CircularProgressIndicator(),
                       if (loadingMessage != null) ...[
                         const SizedBox(height: 16),
                         Text(
                           loadingMessage!,
                           style: Theme.of(context).textTheme.bodyMedium,
                         ),
                       ],
                     ],
                   ),
                 );
        }

        if (snapshot.hasError) {
          return errorBuilder?.call(context, snapshot.error!) ??
                 _buildDefaultError(context, snapshot.error!);
        }

        if (snapshot.hasData) {
          return builder(context, snapshot.data as T);
        }

        return const Center(
          child: Text('No data available'),
        );
      },
    );
  }

  Widget _buildDefaultError(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Trigger rebuild by calling setState in parent
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

/// Custom StreamBuilder wrapper for real-time data
class DataStreamBuilder<T> extends StatelessWidget {
  final Stream<T> stream;
  final Widget Function(BuildContext, T) builder;
  final Widget? loadingWidget;
  final Widget Function(BuildContext, Object)? errorBuilder;
  final String? loadingMessage;
  final T? initialData;

  const DataStreamBuilder({
    super.key,
    required this.stream,
    required this.builder,
    this.loadingWidget,
    this.errorBuilder,
    this.loadingMessage,
    this.initialData,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: stream,
      initialData: initialData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return loadingWidget ?? 
                 Center(
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       const CircularProgressIndicator(),
                       if (loadingMessage != null) ...[
                         const SizedBox(height: 16),
                         Text(
                           loadingMessage!,
                           style: Theme.of(context).textTheme.bodyMedium,
                         ),
                       ],
                     ],
                   ),
                 );
        }

        if (snapshot.hasError) {
          return errorBuilder?.call(context, snapshot.error!) ??
                 _buildDefaultError(context, snapshot.error!);
        }

        if (snapshot.hasData) {
          return builder(context, snapshot.data as T);
        }

        return const Center(
          child: Text('No data available'),
        );
      },
    );
  }

  Widget _buildDefaultError(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Connection Error',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Unable to load real-time data',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Trigger rebuild by calling setState in parent
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

/// Paginated list builder for large datasets
class PaginatedListBuilder<T> extends StatefulWidget {
  final Future<List<T>> Function(int page, int limit) fetchData;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final int itemsPerPage;
  final Widget? loadingWidget;
  final Widget? emptyWidget;
  final ScrollController? scrollController;

  const PaginatedListBuilder({
    super.key,
    required this.fetchData,
    required this.itemBuilder,
    this.itemsPerPage = 20,
    this.loadingWidget,
    this.emptyWidget,
    this.scrollController,
  });

  @override
  State<PaginatedListBuilder<T>> createState() => _PaginatedListBuilderState<T>();
}

class _PaginatedListBuilderState<T> extends State<PaginatedListBuilder<T>> {
  final List<T> _items = [];
  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_onScroll);
    _loadMore();
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newItems = await widget.fetchData(_currentPage, widget.itemsPerPage);
      
      setState(() {
        _items.addAll(newItems);
        _currentPage++;
        _hasMore = newItems.length == widget.itemsPerPage;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty && _isLoading) {
      return widget.loadingWidget ?? const Center(child: CircularProgressIndicator());
    }

    if (_items.isEmpty) {
      return widget.emptyWidget ?? const Center(child: Text('No items found'));
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _items.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _items.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return widget.itemBuilder(context, _items[index], index);
      },
    );
  }
}