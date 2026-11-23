class EventEntity {
  final int id;
  final String title;
  final String description;
  final String category; // BIRTHDAY, MEETING, EXAM, TASK, ANNIVERSARY, RELIGIOUS, CULTURAL, OTHER
  final int ethiopianYear;
  final int ethiopianMonth;
  final int ethiopianDay;
  final int gregorianYear;
  final int gregorianMonth;
  final int gregorianDay;
  final int hour;
  final int minute;
  final bool isAllDay;
  final String recurrence; // NONE, DAILY, WEEKLY, MONTHLY_ETHIOPIAN, MONTHLY_GREGORIAN, YEARLY_ETHIOPIAN, YEARLY_GREGORIAN
  final int reminderMinutesBefore; // -1 = None, 0 = At time, 15, 60, 1440
  final String colorHex;
  final bool isCompleted;
  final int createdAt;

  const EventEntity({
    this.id = 0,
    required this.title,
    this.description = '',
    this.category = 'TASK',
    required this.ethiopianYear,
    required this.ethiopianMonth,
    required this.ethiopianDay,
    required this.gregorianYear,
    required this.gregorianMonth,
    required this.gregorianDay,
    this.hour = 9,
    this.minute = 0,
    this.isAllDay = false,
    this.recurrence = 'NONE',
    this.reminderMinutesBefore = 15,
    this.colorHex = '#EF4444',
    this.isCompleted = false,
    required this.createdAt,
  });

  EventEntity copyWith({
    int? id,
    String? title,
    String? description,
    String? category,
    int? ethiopianYear,
    int? ethiopianMonth,
    int? ethiopianDay,
    int? gregorianYear,
    int? gregorianMonth,
    int? gregorianDay,
    int? hour,
    int? minute,
    bool? isAllDay,
    String? recurrence,
    int? reminderMinutesBefore,
    String? colorHex,
    bool? isCompleted,
    int? createdAt,
  }) {
    return EventEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      ethiopianYear: ethiopianYear ?? this.ethiopianYear,
      ethiopianMonth: ethiopianMonth ?? this.ethiopianMonth,
      ethiopianDay: ethiopianDay ?? this.ethiopianDay,
      gregorianYear: gregorianYear ?? this.gregorianYear,
      gregorianMonth: gregorianMonth ?? this.gregorianMonth,
      gregorianDay: gregorianDay ?? this.gregorianDay,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      isAllDay: isAllDay ?? this.isAllDay,
      recurrence: recurrence ?? this.recurrence,
      reminderMinutesBefore: reminderMinutesBefore ?? this.reminderMinutesBefore,
      colorHex: colorHex ?? this.colorHex,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'description': description,
      'category': category,
      'ethiopianYear': ethiopianYear,
      'ethiopianMonth': ethiopianMonth,
      'ethiopianDay': ethiopianDay,
      'gregorianYear': gregorianYear,
      'gregorianMonth': gregorianMonth,
      'gregorianDay': gregorianDay,
      'hour': hour,
      'minute': minute,
      'isAllDay': isAllDay ? 1 : 0,
      'recurrence': recurrence,
      'reminderMinutesBefore': reminderMinutesBefore,
      'colorHex': colorHex,
      'isCompleted': isCompleted ? 1 : 0,
      'createdAt': createdAt,
    };
    if (id > 0) {
      map['id'] = id;
    }
    return map;
  }

  factory EventEntity.fromMap(Map<String, dynamic> map) {
    return EventEntity(
      id: (map['id'] as num?)?.toInt() ?? 0,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? 'TASK',
      ethiopianYear: (map['ethiopianYear'] as num?)?.toInt() ?? 2017,
      ethiopianMonth: (map['ethiopianMonth'] as num?)?.toInt() ?? 1,
      ethiopianDay: (map['ethiopianDay'] as num?)?.toInt() ?? 1,
      gregorianYear: (map['gregorianYear'] as num?)?.toInt() ?? 2024,
      gregorianMonth: (map['gregorianMonth'] as num?)?.toInt() ?? 9,
      gregorianDay: (map['gregorianDay'] as num?)?.toInt() ?? 11,
      hour: (map['hour'] as num?)?.toInt() ?? 9,
      minute: (map['minute'] as num?)?.toInt() ?? 0,
      isAllDay: (map['isAllDay'] as num?)?.toInt() == 1,
      recurrence: map['recurrence'] as String? ?? 'NONE',
      reminderMinutesBefore: (map['reminderMinutesBefore'] as num?)?.toInt() ?? 15,
      colorHex: map['colorHex'] as String? ?? '#E6A817',
      isCompleted: (map['isCompleted'] as num?)?.toInt() == 1,
      createdAt: (map['createdAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  factory EventEntity.empty() {
    return EventEntity(
      id: 0,
      title: '',
      description: '',
      category: 'TASK',
      ethiopianYear: 2017,
      ethiopianMonth: 1,
      ethiopianDay: 1,
      gregorianYear: 2024,
      gregorianMonth: 9,
      gregorianDay: 11,
      hour: 9,
      minute: 0,
      isAllDay: false,
      recurrence: 'NONE',
      reminderMinutesBefore: 15,
      colorHex: '#E6A817',
      isCompleted: false,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
  }
}
