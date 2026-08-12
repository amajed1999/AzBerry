class AppBanner {
  final String id;
  final String imageUrl;
  final String actionType; // none | product | category | url
  final String? actionValue;
  final int sortOrder;

  AppBanner({
    required this.id,
    required this.imageUrl,
    required this.actionType,
    this.actionValue,
    required this.sortOrder,
  });

  factory AppBanner.fromMap(Map<String, dynamic> m) => AppBanner(
        id: m['id'] as String,
        imageUrl: m['image_url'] as String,
        actionType: m['action_type'] as String? ?? 'none',
        actionValue: m['action_value'] as String?,
        sortOrder: (m['sort_order'] as int?) ?? 0,
      );
}
