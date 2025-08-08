import 'package:flutter/material.dart';

/// Custom floating action button with different styles and purposes
class CustomFloatingActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool mini;

  const CustomFloatingActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
    this.mini = false,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
      foregroundColor: foregroundColor ?? Colors.white,
      mini: mini,
      child: Icon(icon),
    );
  }
}

/// Extended floating action button with text
class CustomExtendedFloatingActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const CustomExtendedFloatingActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
      foregroundColor: foregroundColor ?? Colors.white,
    );
  }
}

/// Multiple floating action buttons with animation
class MultiFab extends StatefulWidget {
  final List<FabOption> options;
  final IconData mainIcon;
  final Color? backgroundColor;

  const MultiFab({
    super.key,
    required this.options,
    this.mainIcon = Icons.add,
    this.backgroundColor,
  });

  @override
  State<MultiFab> createState() => _MultiFabState();
}

class _MultiFabState extends State<MultiFab> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...widget.options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          return AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -60.0 * (index + 1) * _animation.value),
                child: Opacity(
                  opacity: _animation.value,
                  child: FloatingActionButton(
                    mini: true,
                    onPressed: _isOpen ? option.onPressed : null,
                    backgroundColor: option.backgroundColor,
                    child: Icon(option.icon),
                  ),
                ),
              );
            },
          );
        }),
        FloatingActionButton(
          onPressed: _toggle,
          backgroundColor: widget.backgroundColor ?? Theme.of(context).primaryColor,
          child: AnimatedRotation(
            turns: _isOpen ? 0.125 : 0,
            duration: const Duration(milliseconds: 300),
            child: Icon(widget.mainIcon),
          ),
        ),
      ],
    );
  }
}

class FabOption {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;

  FabOption({
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
  });
}