import 'package:flutter/material.dart';

/// Switch list tile for toggling post visibility
class PostVisibilityToggle extends StatelessWidget {
  final bool isVisible;
  final Function(bool) onChanged;
  final String title;
  final String? subtitle;

  const PostVisibilityToggle({
    super.key,
    required this.isVisible,
    required this.onChanged,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      value: isVisible,
      onChanged: onChanged,
      secondary: Icon(
        isVisible ? Icons.visibility : Icons.visibility_off,
        color: isVisible ? Colors.green : Colors.red,
      ),
    );
  }
}

/// Data table for admin panel (web only)
class AdminDataTable extends StatelessWidget {
  final List<AdminTableRow> rows;
  final List<AdminTableColumn> columns;
  final Function(int)? onRowTapped;

  const AdminDataTable({
    super.key,
    required this.rows,
    required this.columns,
    this.onRowTapped,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: columns.map((col) => DataColumn(
          label: Text(
            col.label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        )).toList(),
        rows: rows.asMap().entries.map((entry) {
          final index = entry.key;
          final row = entry.value;
          return DataRow(
            cells: row.cells.map((cell) => DataCell(
              cell.widget ?? Text(cell.value),
              onTap: onRowTapped != null ? () => onRowTapped!(index) : null,
            )).toList(),
          );
        }).toList(),
      ),
    );
  }
}

/// Modal bottom sheet for quick moderation actions
class ModerationBottomSheet extends StatelessWidget {
  final String itemTitle;
  final String itemType;
  final List<ModerationAction> actions;

  const ModerationBottomSheet({
    super.key,
    required this.itemTitle,
    required this.itemType,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getIconForType(itemType),
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      itemTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Moderate $itemType',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          ...actions.map((action) => ListTile(
            leading: Icon(
              action.icon,
              color: action.color ?? Theme.of(context).primaryColor,
            ),
            title: Text(action.title),
            subtitle: action.description != null ? Text(action.description!) : null,
            onTap: () {
              Navigator.of(context).pop();
              action.onTap();
            },
          )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'post':
        return Icons.article;
      case 'business':
        return Icons.business;
      case 'event':
        return Icons.event;
      case 'user':
        return Icons.person;
      default:
        return Icons.help;
    }
  }

  static void show(
    BuildContext context, {
    required String itemTitle,
    required String itemType,
    required List<ModerationAction> actions,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => ModerationBottomSheet(
        itemTitle: itemTitle,
        itemType: itemType,
        actions: actions,
      ),
    );
  }
}

/// Admin statistics card
class AdminStatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  final String? subtitle;
  final VoidCallback? onTap;

  const AdminStatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? Theme.of(context).primaryColor;

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cardColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: cardColor,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  if (onTap != null)
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cardColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Data models
class AdminTableColumn {
  final String label;

  AdminTableColumn({required this.label});
}

class AdminTableRow {
  final List<AdminTableCell> cells;

  AdminTableRow({required this.cells});
}

class AdminTableCell {
  final String value;
  final Widget? widget;

  AdminTableCell({required this.value, this.widget});
}

class ModerationAction {
  final String title;
  final String? description;
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;

  ModerationAction({
    required this.title,
    this.description,
    required this.icon,
    this.color,
    required this.onTap,
  });
}