/// Fixed personal calendar categories, in addition to actual shared groups.
/// Stored in [Schedule.groupId] as these string ids (null still means the
/// original plain "個人の予定" default, for backward compatibility with
/// schedules created before these categories existed).
const personalCategories = <String, String>{
  'work': '仕事用',
  'partner': '彼女・彼氏用',
  'family': '家族',
};

const personalCategoryDefaultLabel = '個人の予定';

/// Resolves a display label for a schedule's groupId when it isn't one of
/// the user's real shared groups (i.e. null or a personal category id).
String? personalCategoryLabel(String? groupId) {
  if (groupId == null) return personalCategoryDefaultLabel;
  return personalCategories[groupId];
}
