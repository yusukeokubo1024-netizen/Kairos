import '../l10n/app_localizations.dart';

/// Fixed personal calendar categories, in addition to actual shared groups.
/// Stored in [Schedule.groupId] as these string ids (null still means the
/// original plain "個人の予定" default, for backward compatibility with
/// schedules created before these categories existed).
const _personalCategoryIds = ['work', 'partner', 'family', 'friend', 'other'];

Map<String, String> personalCategories(AppLocalizations l10n) => {
      'work': l10n.categoryWork,
      'partner': l10n.categoryPartner,
      'family': l10n.categoryFamily,
      'friend': l10n.categoryFriend,
      'other': l10n.categoryOther,
    };

String personalCategoryDefaultLabel(AppLocalizations l10n) => l10n.categoryPersonal;

/// Resolves a display label for a schedule's groupId when it isn't one of
/// the user's real shared groups (i.e. null or a personal category id).
String? personalCategoryLabel(AppLocalizations l10n, String? groupId) {
  if (groupId == null) return personalCategoryDefaultLabel(l10n);
  if (!_personalCategoryIds.contains(groupId)) return null;
  return personalCategories(l10n)[groupId];
}
