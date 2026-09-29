import 'package:cloud_firestore/cloud_firestore.dart';

/// A recurring anniversary (birthday, wedding anniversary, monthly payment
/// day, etc.) with no specific year attached.
///
/// [recurrence] 'yearly' repeats on [month]/[day] every year (the original,
/// still-default behavior). 'monthly' repeats on [day] every month and
/// ignores [month] (null for monthly entries — there's no single month to
/// anchor to).
class Anniversary {
  final String id;
  final String ownerId;
  final String title;
  final String recurrence;
  final int? month;
  final int day;
  // When true, an occurrence that lands on a weekend or Japanese public
  // holiday is shown/notified on the next business day instead — for
  // due-date-style anniversaries (e.g. "payment day: the 25th") rather than
  // an actual-date one like a birthday, which should never move.
  final bool businessDayAdjust;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static const yearly = 'yearly';
  static const monthly = 'monthly';

  Anniversary({
    required this.id,
    required this.ownerId,
    required this.title,
    this.recurrence = yearly,
    this.month,
    required this.day,
    this.businessDayAdjust = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Anniversary.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Anniversary(
      id: doc.id,
      ownerId: data['ownerId'] as String,
      title: data['title'] as String,
      recurrence: data['recurrence'] as String? ?? yearly,
      month: data['month'] as int?,
      day: data['day'] as int,
      businessDayAdjust: data['businessDayAdjust'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'ownerId': ownerId,
      'title': title,
      'recurrence': recurrence,
      'month': month,
      'day': day,
      'businessDayAdjust': businessDayAdjust,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'ownerId': ownerId,
      'title': title,
      'recurrence': recurrence,
      'month': month,
      'day': day,
      'businessDayAdjust': businessDayAdjust,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
