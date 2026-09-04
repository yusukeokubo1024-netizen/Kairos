/// Keyword-based "what to prepare" suggestions for a schedule title.
/// No AI involved — just a lookup table, so it's free to run.
/// Users aren't able to edit this list yet (see kairos-future-smart-calendar
/// memory: a user-editable template feature is a possible follow-up).
const _prepTemplates = <String, List<String>>{
  '参観': ['プリントを確認する', '上履きを準備する', '名札を用意する'],
  '遠足': ['お弁当を準備する', '水筒を準備する', 'レジャーシートを準備する'],
  '運動会': ['お弁当を準備する', 'カメラを準備する', 'レジャーシートを準備する'],
  '病院': ['保険証を持っていく', '診察券を持っていく', 'お薬手帳を持っていく'],
  '歯医者': ['保険証を持っていく', '診察券を持っていく'],
  'プール': ['水着を準備する', 'タオルを準備する', '帽子を準備する'],
  '旅行': ['着替えを準備する', '充電器を持っていく', '常備薬を準備する'],
  '出張': ['資料を準備する', '充電器を持っていく', '名刺を持っていく'],
  '面接': ['履歴書を準備する', '証明写真を準備する'],
  '引っ越し': ['段ボールを準備する', '荷造りをする', '住所変更の手続きをする'],
};

/// Returns suggested prep items for a schedule [title], or an empty list if
/// no keyword matches.
List<String> suggestPrepItems(String title) {
  for (final entry in _prepTemplates.entries) {
    if (title.contains(entry.key)) return entry.value;
  }
  return const [];
}
