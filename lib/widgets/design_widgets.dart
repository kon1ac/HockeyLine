import 'package:flutter/material.dart';
import 'package:hockeyline/theme/app_theme.dart';

/// Линия «лёд» под заголовком экрана.
PreferredSizeWidget hockeyIceAppBarBottom() {
  return PreferredSize(
    preferredSize: const Size.fromHeight(1),
    child: Container(
      height: 1,
      width: double.infinity,
      color: AppColors.iceLine,
    ),
  );
}

/// Баннер режима гостя под AppBar.
class GuestModeBanner extends StatelessWidget {
  const GuestModeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceSecondary,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.visibility_outlined, size: 20, color: AppColors.chartCool),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Text(
                'Режим просмотра: добавление и изменение данных недоступны.',
                style: AppTextStyles.bodySmallMuted(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Единый шаблон пустого состояния.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 56, color: AppColors.muted),
            const SizedBox(height: AppSpacing.s16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleSection(context),
            ),
            if (subtitle != null) ...<Widget>[
              const SizedBox(height: AppSpacing.s8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmallMuted(context),
              ),
            ],
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: AppSpacing.s24),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add, size: 20),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Вторичная карточка (звенья, заметки): тёмнее белой карточки игрока.
class SecondaryCardSurface extends StatelessWidget {
  const SecondaryCardSurface({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceSecondary,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppSpacing.s4),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
          child: child,
        ),
      ),
    );
  }
}

void showAppSnackBar(
  BuildContext context,
  String message, {
  bool error = false,
  bool success = false,
}) {
  Color? backgroundColor;
  if (error) {
    backgroundColor = AppColors.snackErrorBg;
  } else if (success) {
    backgroundColor = AppColors.snackSuccessBg;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
