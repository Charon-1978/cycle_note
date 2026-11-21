// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $WeightLogsTable extends WeightLogs
    with TableInfo<$WeightLogsTable, WeightLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeightLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _recordedAtMeta =
      const VerificationMeta('recordedAt');
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
      'recorded_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _weightKgMeta =
      const VerificationMeta('weightKg');
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
      'weight_kg', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _bodyFatPercentMeta =
      const VerificationMeta('bodyFatPercent');
  @override
  late final GeneratedColumn<double> bodyFatPercent = GeneratedColumn<double>(
      'body_fat_percent', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, recordedAt, weightKg, bodyFatPercent, note, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weight_logs';
  @override
  VerificationContext validateIntegrity(Insertable<WeightLog> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
          _recordedAtMeta,
          recordedAt.isAcceptableOrUnknown(
              data['recorded_at']!, _recordedAtMeta));
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('weight_kg')) {
      context.handle(_weightKgMeta,
          weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta));
    } else if (isInserting) {
      context.missing(_weightKgMeta);
    }
    if (data.containsKey('body_fat_percent')) {
      context.handle(
          _bodyFatPercentMeta,
          bodyFatPercent.isAcceptableOrUnknown(
              data['body_fat_percent']!, _bodyFatPercentMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {recordedAt},
      ];
  @override
  WeightLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeightLog(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      recordedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}recorded_at'])!,
      weightKg: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}weight_kg'])!,
      bodyFatPercent: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}body_fat_percent']),
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $WeightLogsTable createAlias(String alias) {
    return $WeightLogsTable(attachedDatabase, alias);
  }
}

class WeightLog extends DataClass implements Insertable<WeightLog> {
  final int id;
  final DateTime recordedAt;
  final double weightKg;
  final double? bodyFatPercent;
  final String note;
  final DateTime createdAt;
  const WeightLog(
      {required this.id,
      required this.recordedAt,
      required this.weightKg,
      this.bodyFatPercent,
      required this.note,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['weight_kg'] = Variable<double>(weightKg);
    if (!nullToAbsent || bodyFatPercent != null) {
      map['body_fat_percent'] = Variable<double>(bodyFatPercent);
    }
    map['note'] = Variable<String>(note);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  WeightLogsCompanion toCompanion(bool nullToAbsent) {
    return WeightLogsCompanion(
      id: Value(id),
      recordedAt: Value(recordedAt),
      weightKg: Value(weightKg),
      bodyFatPercent: bodyFatPercent == null && nullToAbsent
          ? const Value.absent()
          : Value(bodyFatPercent),
      note: Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory WeightLog.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeightLog(
      id: serializer.fromJson<int>(json['id']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      weightKg: serializer.fromJson<double>(json['weightKg']),
      bodyFatPercent: serializer.fromJson<double?>(json['bodyFatPercent']),
      note: serializer.fromJson<String>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'weightKg': serializer.toJson<double>(weightKg),
      'bodyFatPercent': serializer.toJson<double?>(bodyFatPercent),
      'note': serializer.toJson<String>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  WeightLog copyWith(
          {int? id,
          DateTime? recordedAt,
          double? weightKg,
          Value<double?> bodyFatPercent = const Value.absent(),
          String? note,
          DateTime? createdAt}) =>
      WeightLog(
        id: id ?? this.id,
        recordedAt: recordedAt ?? this.recordedAt,
        weightKg: weightKg ?? this.weightKg,
        bodyFatPercent:
            bodyFatPercent.present ? bodyFatPercent.value : this.bodyFatPercent,
        note: note ?? this.note,
        createdAt: createdAt ?? this.createdAt,
      );
  WeightLog copyWithCompanion(WeightLogsCompanion data) {
    return WeightLog(
      id: data.id.present ? data.id.value : this.id,
      recordedAt:
          data.recordedAt.present ? data.recordedAt.value : this.recordedAt,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      bodyFatPercent: data.bodyFatPercent.present
          ? data.bodyFatPercent.value
          : this.bodyFatPercent,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeightLog(')
          ..write('id: $id, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('weightKg: $weightKg, ')
          ..write('bodyFatPercent: $bodyFatPercent, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, recordedAt, weightKg, bodyFatPercent, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeightLog &&
          other.id == this.id &&
          other.recordedAt == this.recordedAt &&
          other.weightKg == this.weightKg &&
          other.bodyFatPercent == this.bodyFatPercent &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class WeightLogsCompanion extends UpdateCompanion<WeightLog> {
  final Value<int> id;
  final Value<DateTime> recordedAt;
  final Value<double> weightKg;
  final Value<double?> bodyFatPercent;
  final Value<String> note;
  final Value<DateTime> createdAt;
  const WeightLogsCompanion({
    this.id = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.bodyFatPercent = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  WeightLogsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime recordedAt,
    required double weightKg,
    this.bodyFatPercent = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : recordedAt = Value(recordedAt),
        weightKg = Value(weightKg);
  static Insertable<WeightLog> custom({
    Expression<int>? id,
    Expression<DateTime>? recordedAt,
    Expression<double>? weightKg,
    Expression<double>? bodyFatPercent,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (weightKg != null) 'weight_kg': weightKg,
      if (bodyFatPercent != null) 'body_fat_percent': bodyFatPercent,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  WeightLogsCompanion copyWith(
      {Value<int>? id,
      Value<DateTime>? recordedAt,
      Value<double>? weightKg,
      Value<double?>? bodyFatPercent,
      Value<String>? note,
      Value<DateTime>? createdAt}) {
    return WeightLogsCompanion(
      id: id ?? this.id,
      recordedAt: recordedAt ?? this.recordedAt,
      weightKg: weightKg ?? this.weightKg,
      bodyFatPercent: bodyFatPercent ?? this.bodyFatPercent,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (bodyFatPercent.present) {
      map['body_fat_percent'] = Variable<double>(bodyFatPercent.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeightLogsCompanion(')
          ..write('id: $id, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('weightKg: $weightKg, ')
          ..write('bodyFatPercent: $bodyFatPercent, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ExerciseLogsTable extends ExerciseLogs
    with TableInfo<$ExerciseLogsTable, ExerciseLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExerciseLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _recordedAtMeta =
      const VerificationMeta('recordedAt');
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
      'recorded_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _exerciseCodeMeta =
      const VerificationMeta('exerciseCode');
  @override
  late final GeneratedColumn<String> exerciseCode = GeneratedColumn<String>(
      'exercise_code', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _exerciseNameMeta =
      const VerificationMeta('exerciseName');
  @override
  late final GeneratedColumn<String> exerciseName = GeneratedColumn<String>(
      'exercise_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _metMeta = const VerificationMeta('met');
  @override
  late final GeneratedColumn<double> met = GeneratedColumn<double>(
      'met', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _minutesMeta =
      const VerificationMeta('minutes');
  @override
  late final GeneratedColumn<int> minutes = GeneratedColumn<int>(
      'minutes', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _weightKgAtTimeMeta =
      const VerificationMeta('weightKgAtTime');
  @override
  late final GeneratedColumn<double> weightKgAtTime = GeneratedColumn<double>(
      'weight_kg_at_time', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _kcalMeta = const VerificationMeta('kcal');
  @override
  late final GeneratedColumn<double> kcal = GeneratedColumn<double>(
      'kcal', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        recordedAt,
        exerciseCode,
        exerciseName,
        met,
        minutes,
        weightKgAtTime,
        kcal,
        note,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercise_logs';
  @override
  VerificationContext validateIntegrity(Insertable<ExerciseLog> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
          _recordedAtMeta,
          recordedAt.isAcceptableOrUnknown(
              data['recorded_at']!, _recordedAtMeta));
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('exercise_code')) {
      context.handle(
          _exerciseCodeMeta,
          exerciseCode.isAcceptableOrUnknown(
              data['exercise_code']!, _exerciseCodeMeta));
    } else if (isInserting) {
      context.missing(_exerciseCodeMeta);
    }
    if (data.containsKey('exercise_name')) {
      context.handle(
          _exerciseNameMeta,
          exerciseName.isAcceptableOrUnknown(
              data['exercise_name']!, _exerciseNameMeta));
    } else if (isInserting) {
      context.missing(_exerciseNameMeta);
    }
    if (data.containsKey('met')) {
      context.handle(
          _metMeta, met.isAcceptableOrUnknown(data['met']!, _metMeta));
    } else if (isInserting) {
      context.missing(_metMeta);
    }
    if (data.containsKey('minutes')) {
      context.handle(_minutesMeta,
          minutes.isAcceptableOrUnknown(data['minutes']!, _minutesMeta));
    } else if (isInserting) {
      context.missing(_minutesMeta);
    }
    if (data.containsKey('weight_kg_at_time')) {
      context.handle(
          _weightKgAtTimeMeta,
          weightKgAtTime.isAcceptableOrUnknown(
              data['weight_kg_at_time']!, _weightKgAtTimeMeta));
    } else if (isInserting) {
      context.missing(_weightKgAtTimeMeta);
    }
    if (data.containsKey('kcal')) {
      context.handle(
          _kcalMeta, kcal.isAcceptableOrUnknown(data['kcal']!, _kcalMeta));
    } else if (isInserting) {
      context.missing(_kcalMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExerciseLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExerciseLog(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      recordedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}recorded_at'])!,
      exerciseCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}exercise_code'])!,
      exerciseName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}exercise_name'])!,
      met: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}met'])!,
      minutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}minutes'])!,
      weightKgAtTime: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}weight_kg_at_time'])!,
      kcal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}kcal'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ExerciseLogsTable createAlias(String alias) {
    return $ExerciseLogsTable(attachedDatabase, alias);
  }
}

class ExerciseLog extends DataClass implements Insertable<ExerciseLog> {
  final int id;
  final DateTime recordedAt;
  final String exerciseCode;
  final String exerciseName;
  final double met;
  final int minutes;

  /// 记录当时的体重，用于复盘"同样运动为什么消耗变了"
  final double weightKgAtTime;

  /// 计算出的消耗（冗余存储，保证历史可复现）
  final double kcal;
  final String note;
  final DateTime createdAt;
  const ExerciseLog(
      {required this.id,
      required this.recordedAt,
      required this.exerciseCode,
      required this.exerciseName,
      required this.met,
      required this.minutes,
      required this.weightKgAtTime,
      required this.kcal,
      required this.note,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['exercise_code'] = Variable<String>(exerciseCode);
    map['exercise_name'] = Variable<String>(exerciseName);
    map['met'] = Variable<double>(met);
    map['minutes'] = Variable<int>(minutes);
    map['weight_kg_at_time'] = Variable<double>(weightKgAtTime);
    map['kcal'] = Variable<double>(kcal);
    map['note'] = Variable<String>(note);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ExerciseLogsCompanion toCompanion(bool nullToAbsent) {
    return ExerciseLogsCompanion(
      id: Value(id),
      recordedAt: Value(recordedAt),
      exerciseCode: Value(exerciseCode),
      exerciseName: Value(exerciseName),
      met: Value(met),
      minutes: Value(minutes),
      weightKgAtTime: Value(weightKgAtTime),
      kcal: Value(kcal),
      note: Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory ExerciseLog.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExerciseLog(
      id: serializer.fromJson<int>(json['id']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      exerciseCode: serializer.fromJson<String>(json['exerciseCode']),
      exerciseName: serializer.fromJson<String>(json['exerciseName']),
      met: serializer.fromJson<double>(json['met']),
      minutes: serializer.fromJson<int>(json['minutes']),
      weightKgAtTime: serializer.fromJson<double>(json['weightKgAtTime']),
      kcal: serializer.fromJson<double>(json['kcal']),
      note: serializer.fromJson<String>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'exerciseCode': serializer.toJson<String>(exerciseCode),
      'exerciseName': serializer.toJson<String>(exerciseName),
      'met': serializer.toJson<double>(met),
      'minutes': serializer.toJson<int>(minutes),
      'weightKgAtTime': serializer.toJson<double>(weightKgAtTime),
      'kcal': serializer.toJson<double>(kcal),
      'note': serializer.toJson<String>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ExerciseLog copyWith(
          {int? id,
          DateTime? recordedAt,
          String? exerciseCode,
          String? exerciseName,
          double? met,
          int? minutes,
          double? weightKgAtTime,
          double? kcal,
          String? note,
          DateTime? createdAt}) =>
      ExerciseLog(
        id: id ?? this.id,
        recordedAt: recordedAt ?? this.recordedAt,
        exerciseCode: exerciseCode ?? this.exerciseCode,
        exerciseName: exerciseName ?? this.exerciseName,
        met: met ?? this.met,
        minutes: minutes ?? this.minutes,
        weightKgAtTime: weightKgAtTime ?? this.weightKgAtTime,
        kcal: kcal ?? this.kcal,
        note: note ?? this.note,
        createdAt: createdAt ?? this.createdAt,
      );
  ExerciseLog copyWithCompanion(ExerciseLogsCompanion data) {
    return ExerciseLog(
      id: data.id.present ? data.id.value : this.id,
      recordedAt:
          data.recordedAt.present ? data.recordedAt.value : this.recordedAt,
      exerciseCode: data.exerciseCode.present
          ? data.exerciseCode.value
          : this.exerciseCode,
      exerciseName: data.exerciseName.present
          ? data.exerciseName.value
          : this.exerciseName,
      met: data.met.present ? data.met.value : this.met,
      minutes: data.minutes.present ? data.minutes.value : this.minutes,
      weightKgAtTime: data.weightKgAtTime.present
          ? data.weightKgAtTime.value
          : this.weightKgAtTime,
      kcal: data.kcal.present ? data.kcal.value : this.kcal,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseLog(')
          ..write('id: $id, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('exerciseCode: $exerciseCode, ')
          ..write('exerciseName: $exerciseName, ')
          ..write('met: $met, ')
          ..write('minutes: $minutes, ')
          ..write('weightKgAtTime: $weightKgAtTime, ')
          ..write('kcal: $kcal, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, recordedAt, exerciseCode, exerciseName,
      met, minutes, weightKgAtTime, kcal, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExerciseLog &&
          other.id == this.id &&
          other.recordedAt == this.recordedAt &&
          other.exerciseCode == this.exerciseCode &&
          other.exerciseName == this.exerciseName &&
          other.met == this.met &&
          other.minutes == this.minutes &&
          other.weightKgAtTime == this.weightKgAtTime &&
          other.kcal == this.kcal &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class ExerciseLogsCompanion extends UpdateCompanion<ExerciseLog> {
  final Value<int> id;
  final Value<DateTime> recordedAt;
  final Value<String> exerciseCode;
  final Value<String> exerciseName;
  final Value<double> met;
  final Value<int> minutes;
  final Value<double> weightKgAtTime;
  final Value<double> kcal;
  final Value<String> note;
  final Value<DateTime> createdAt;
  const ExerciseLogsCompanion({
    this.id = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.exerciseCode = const Value.absent(),
    this.exerciseName = const Value.absent(),
    this.met = const Value.absent(),
    this.minutes = const Value.absent(),
    this.weightKgAtTime = const Value.absent(),
    this.kcal = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ExerciseLogsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime recordedAt,
    required String exerciseCode,
    required String exerciseName,
    required double met,
    required int minutes,
    required double weightKgAtTime,
    required double kcal,
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : recordedAt = Value(recordedAt),
        exerciseCode = Value(exerciseCode),
        exerciseName = Value(exerciseName),
        met = Value(met),
        minutes = Value(minutes),
        weightKgAtTime = Value(weightKgAtTime),
        kcal = Value(kcal);
  static Insertable<ExerciseLog> custom({
    Expression<int>? id,
    Expression<DateTime>? recordedAt,
    Expression<String>? exerciseCode,
    Expression<String>? exerciseName,
    Expression<double>? met,
    Expression<int>? minutes,
    Expression<double>? weightKgAtTime,
    Expression<double>? kcal,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (exerciseCode != null) 'exercise_code': exerciseCode,
      if (exerciseName != null) 'exercise_name': exerciseName,
      if (met != null) 'met': met,
      if (minutes != null) 'minutes': minutes,
      if (weightKgAtTime != null) 'weight_kg_at_time': weightKgAtTime,
      if (kcal != null) 'kcal': kcal,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ExerciseLogsCompanion copyWith(
      {Value<int>? id,
      Value<DateTime>? recordedAt,
      Value<String>? exerciseCode,
      Value<String>? exerciseName,
      Value<double>? met,
      Value<int>? minutes,
      Value<double>? weightKgAtTime,
      Value<double>? kcal,
      Value<String>? note,
      Value<DateTime>? createdAt}) {
    return ExerciseLogsCompanion(
      id: id ?? this.id,
      recordedAt: recordedAt ?? this.recordedAt,
      exerciseCode: exerciseCode ?? this.exerciseCode,
      exerciseName: exerciseName ?? this.exerciseName,
      met: met ?? this.met,
      minutes: minutes ?? this.minutes,
      weightKgAtTime: weightKgAtTime ?? this.weightKgAtTime,
      kcal: kcal ?? this.kcal,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (exerciseCode.present) {
      map['exercise_code'] = Variable<String>(exerciseCode.value);
    }
    if (exerciseName.present) {
      map['exercise_name'] = Variable<String>(exerciseName.value);
    }
    if (met.present) {
      map['met'] = Variable<double>(met.value);
    }
    if (minutes.present) {
      map['minutes'] = Variable<int>(minutes.value);
    }
    if (weightKgAtTime.present) {
      map['weight_kg_at_time'] = Variable<double>(weightKgAtTime.value);
    }
    if (kcal.present) {
      map['kcal'] = Variable<double>(kcal.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseLogsCompanion(')
          ..write('id: $id, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('exerciseCode: $exerciseCode, ')
          ..write('exerciseName: $exerciseName, ')
          ..write('met: $met, ')
          ..write('minutes: $minutes, ')
          ..write('weightKgAtTime: $weightKgAtTime, ')
          ..write('kcal: $kcal, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $MealLogsTable extends MealLogs with TableInfo<$MealLogsTable, MealLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _recordedAtMeta =
      const VerificationMeta('recordedAt');
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
      'recorded_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _mealTypeMeta =
      const VerificationMeta('mealType');
  @override
  late final GeneratedColumn<String> mealType = GeneratedColumn<String>(
      'meal_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _foodCodeMeta =
      const VerificationMeta('foodCode');
  @override
  late final GeneratedColumn<String> foodCode = GeneratedColumn<String>(
      'food_code', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _foodNameMeta =
      const VerificationMeta('foodName');
  @override
  late final GeneratedColumn<String> foodName = GeneratedColumn<String>(
      'food_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _gramsMeta = const VerificationMeta('grams');
  @override
  late final GeneratedColumn<double> grams = GeneratedColumn<double>(
      'grams', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _kcalMeta = const VerificationMeta('kcal');
  @override
  late final GeneratedColumn<double> kcal = GeneratedColumn<double>(
      'kcal', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _proteinGMeta =
      const VerificationMeta('proteinG');
  @override
  late final GeneratedColumn<double> proteinG = GeneratedColumn<double>(
      'protein_g', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _fatGMeta = const VerificationMeta('fatG');
  @override
  late final GeneratedColumn<double> fatG = GeneratedColumn<double>(
      'fat_g', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _carbGMeta = const VerificationMeta('carbG');
  @override
  late final GeneratedColumn<double> carbG = GeneratedColumn<double>(
      'carb_g', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        recordedAt,
        mealType,
        foodCode,
        foodName,
        grams,
        kcal,
        proteinG,
        fatG,
        carbG,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meal_logs';
  @override
  VerificationContext validateIntegrity(Insertable<MealLog> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
          _recordedAtMeta,
          recordedAt.isAcceptableOrUnknown(
              data['recorded_at']!, _recordedAtMeta));
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('meal_type')) {
      context.handle(_mealTypeMeta,
          mealType.isAcceptableOrUnknown(data['meal_type']!, _mealTypeMeta));
    } else if (isInserting) {
      context.missing(_mealTypeMeta);
    }
    if (data.containsKey('food_code')) {
      context.handle(_foodCodeMeta,
          foodCode.isAcceptableOrUnknown(data['food_code']!, _foodCodeMeta));
    } else if (isInserting) {
      context.missing(_foodCodeMeta);
    }
    if (data.containsKey('food_name')) {
      context.handle(_foodNameMeta,
          foodName.isAcceptableOrUnknown(data['food_name']!, _foodNameMeta));
    } else if (isInserting) {
      context.missing(_foodNameMeta);
    }
    if (data.containsKey('grams')) {
      context.handle(
          _gramsMeta, grams.isAcceptableOrUnknown(data['grams']!, _gramsMeta));
    } else if (isInserting) {
      context.missing(_gramsMeta);
    }
    if (data.containsKey('kcal')) {
      context.handle(
          _kcalMeta, kcal.isAcceptableOrUnknown(data['kcal']!, _kcalMeta));
    } else if (isInserting) {
      context.missing(_kcalMeta);
    }
    if (data.containsKey('protein_g')) {
      context.handle(_proteinGMeta,
          proteinG.isAcceptableOrUnknown(data['protein_g']!, _proteinGMeta));
    }
    if (data.containsKey('fat_g')) {
      context.handle(
          _fatGMeta, fatG.isAcceptableOrUnknown(data['fat_g']!, _fatGMeta));
    }
    if (data.containsKey('carb_g')) {
      context.handle(
          _carbGMeta, carbG.isAcceptableOrUnknown(data['carb_g']!, _carbGMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MealLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MealLog(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      recordedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}recorded_at'])!,
      mealType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}meal_type'])!,
      foodCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}food_code'])!,
      foodName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}food_name'])!,
      grams: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}grams'])!,
      kcal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}kcal'])!,
      proteinG: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}protein_g'])!,
      fatG: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}fat_g'])!,
      carbG: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}carb_g'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $MealLogsTable createAlias(String alias) {
    return $MealLogsTable(attachedDatabase, alias);
  }
}

class MealLog extends DataClass implements Insertable<MealLog> {
  final int id;
  final DateTime recordedAt;

  /// breakfast / lunch / dinner / snack
  final String mealType;
  final String foodCode;
  final String foodName;
  final double grams;
  final double kcal;
  final double proteinG;
  final double fatG;
  final double carbG;
  final DateTime createdAt;
  const MealLog(
      {required this.id,
      required this.recordedAt,
      required this.mealType,
      required this.foodCode,
      required this.foodName,
      required this.grams,
      required this.kcal,
      required this.proteinG,
      required this.fatG,
      required this.carbG,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['meal_type'] = Variable<String>(mealType);
    map['food_code'] = Variable<String>(foodCode);
    map['food_name'] = Variable<String>(foodName);
    map['grams'] = Variable<double>(grams);
    map['kcal'] = Variable<double>(kcal);
    map['protein_g'] = Variable<double>(proteinG);
    map['fat_g'] = Variable<double>(fatG);
    map['carb_g'] = Variable<double>(carbG);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MealLogsCompanion toCompanion(bool nullToAbsent) {
    return MealLogsCompanion(
      id: Value(id),
      recordedAt: Value(recordedAt),
      mealType: Value(mealType),
      foodCode: Value(foodCode),
      foodName: Value(foodName),
      grams: Value(grams),
      kcal: Value(kcal),
      proteinG: Value(proteinG),
      fatG: Value(fatG),
      carbG: Value(carbG),
      createdAt: Value(createdAt),
    );
  }

  factory MealLog.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MealLog(
      id: serializer.fromJson<int>(json['id']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      mealType: serializer.fromJson<String>(json['mealType']),
      foodCode: serializer.fromJson<String>(json['foodCode']),
      foodName: serializer.fromJson<String>(json['foodName']),
      grams: serializer.fromJson<double>(json['grams']),
      kcal: serializer.fromJson<double>(json['kcal']),
      proteinG: serializer.fromJson<double>(json['proteinG']),
      fatG: serializer.fromJson<double>(json['fatG']),
      carbG: serializer.fromJson<double>(json['carbG']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'mealType': serializer.toJson<String>(mealType),
      'foodCode': serializer.toJson<String>(foodCode),
      'foodName': serializer.toJson<String>(foodName),
      'grams': serializer.toJson<double>(grams),
      'kcal': serializer.toJson<double>(kcal),
      'proteinG': serializer.toJson<double>(proteinG),
      'fatG': serializer.toJson<double>(fatG),
      'carbG': serializer.toJson<double>(carbG),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  MealLog copyWith(
          {int? id,
          DateTime? recordedAt,
          String? mealType,
          String? foodCode,
          String? foodName,
          double? grams,
          double? kcal,
          double? proteinG,
          double? fatG,
          double? carbG,
          DateTime? createdAt}) =>
      MealLog(
        id: id ?? this.id,
        recordedAt: recordedAt ?? this.recordedAt,
        mealType: mealType ?? this.mealType,
        foodCode: foodCode ?? this.foodCode,
        foodName: foodName ?? this.foodName,
        grams: grams ?? this.grams,
        kcal: kcal ?? this.kcal,
        proteinG: proteinG ?? this.proteinG,
        fatG: fatG ?? this.fatG,
        carbG: carbG ?? this.carbG,
        createdAt: createdAt ?? this.createdAt,
      );
  MealLog copyWithCompanion(MealLogsCompanion data) {
    return MealLog(
      id: data.id.present ? data.id.value : this.id,
      recordedAt:
          data.recordedAt.present ? data.recordedAt.value : this.recordedAt,
      mealType: data.mealType.present ? data.mealType.value : this.mealType,
      foodCode: data.foodCode.present ? data.foodCode.value : this.foodCode,
      foodName: data.foodName.present ? data.foodName.value : this.foodName,
      grams: data.grams.present ? data.grams.value : this.grams,
      kcal: data.kcal.present ? data.kcal.value : this.kcal,
      proteinG: data.proteinG.present ? data.proteinG.value : this.proteinG,
      fatG: data.fatG.present ? data.fatG.value : this.fatG,
      carbG: data.carbG.present ? data.carbG.value : this.carbG,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MealLog(')
          ..write('id: $id, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('mealType: $mealType, ')
          ..write('foodCode: $foodCode, ')
          ..write('foodName: $foodName, ')
          ..write('grams: $grams, ')
          ..write('kcal: $kcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('fatG: $fatG, ')
          ..write('carbG: $carbG, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, recordedAt, mealType, foodCode, foodName,
      grams, kcal, proteinG, fatG, carbG, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MealLog &&
          other.id == this.id &&
          other.recordedAt == this.recordedAt &&
          other.mealType == this.mealType &&
          other.foodCode == this.foodCode &&
          other.foodName == this.foodName &&
          other.grams == this.grams &&
          other.kcal == this.kcal &&
          other.proteinG == this.proteinG &&
          other.fatG == this.fatG &&
          other.carbG == this.carbG &&
          other.createdAt == this.createdAt);
}

class MealLogsCompanion extends UpdateCompanion<MealLog> {
  final Value<int> id;
  final Value<DateTime> recordedAt;
  final Value<String> mealType;
  final Value<String> foodCode;
  final Value<String> foodName;
  final Value<double> grams;
  final Value<double> kcal;
  final Value<double> proteinG;
  final Value<double> fatG;
  final Value<double> carbG;
  final Value<DateTime> createdAt;
  const MealLogsCompanion({
    this.id = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.mealType = const Value.absent(),
    this.foodCode = const Value.absent(),
    this.foodName = const Value.absent(),
    this.grams = const Value.absent(),
    this.kcal = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.carbG = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  MealLogsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime recordedAt,
    required String mealType,
    required String foodCode,
    required String foodName,
    required double grams,
    required double kcal,
    this.proteinG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.carbG = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : recordedAt = Value(recordedAt),
        mealType = Value(mealType),
        foodCode = Value(foodCode),
        foodName = Value(foodName),
        grams = Value(grams),
        kcal = Value(kcal);
  static Insertable<MealLog> custom({
    Expression<int>? id,
    Expression<DateTime>? recordedAt,
    Expression<String>? mealType,
    Expression<String>? foodCode,
    Expression<String>? foodName,
    Expression<double>? grams,
    Expression<double>? kcal,
    Expression<double>? proteinG,
    Expression<double>? fatG,
    Expression<double>? carbG,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (mealType != null) 'meal_type': mealType,
      if (foodCode != null) 'food_code': foodCode,
      if (foodName != null) 'food_name': foodName,
      if (grams != null) 'grams': grams,
      if (kcal != null) 'kcal': kcal,
      if (proteinG != null) 'protein_g': proteinG,
      if (fatG != null) 'fat_g': fatG,
      if (carbG != null) 'carb_g': carbG,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  MealLogsCompanion copyWith(
      {Value<int>? id,
      Value<DateTime>? recordedAt,
      Value<String>? mealType,
      Value<String>? foodCode,
      Value<String>? foodName,
      Value<double>? grams,
      Value<double>? kcal,
      Value<double>? proteinG,
      Value<double>? fatG,
      Value<double>? carbG,
      Value<DateTime>? createdAt}) {
    return MealLogsCompanion(
      id: id ?? this.id,
      recordedAt: recordedAt ?? this.recordedAt,
      mealType: mealType ?? this.mealType,
      foodCode: foodCode ?? this.foodCode,
      foodName: foodName ?? this.foodName,
      grams: grams ?? this.grams,
      kcal: kcal ?? this.kcal,
      proteinG: proteinG ?? this.proteinG,
      fatG: fatG ?? this.fatG,
      carbG: carbG ?? this.carbG,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (mealType.present) {
      map['meal_type'] = Variable<String>(mealType.value);
    }
    if (foodCode.present) {
      map['food_code'] = Variable<String>(foodCode.value);
    }
    if (foodName.present) {
      map['food_name'] = Variable<String>(foodName.value);
    }
    if (grams.present) {
      map['grams'] = Variable<double>(grams.value);
    }
    if (kcal.present) {
      map['kcal'] = Variable<double>(kcal.value);
    }
    if (proteinG.present) {
      map['protein_g'] = Variable<double>(proteinG.value);
    }
    if (fatG.present) {
      map['fat_g'] = Variable<double>(fatG.value);
    }
    if (carbG.present) {
      map['carb_g'] = Variable<double>(carbG.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealLogsCompanion(')
          ..write('id: $id, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('mealType: $mealType, ')
          ..write('foodCode: $foodCode, ')
          ..write('foodName: $foodName, ')
          ..write('grams: $grams, ')
          ..write('kcal: $kcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('fatG: $fatG, ')
          ..write('carbG: $carbG, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $BodyProfilesTable extends BodyProfiles
    with TableInfo<$BodyProfilesTable, BodyProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BodyProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _sexMeta = const VerificationMeta('sex');
  @override
  late final GeneratedColumn<String> sex = GeneratedColumn<String>(
      'sex', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ageMeta = const VerificationMeta('age');
  @override
  late final GeneratedColumn<int> age = GeneratedColumn<int>(
      'age', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _heightCmMeta =
      const VerificationMeta('heightCm');
  @override
  late final GeneratedColumn<double> heightCm = GeneratedColumn<double>(
      'height_cm', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _startWeightKgMeta =
      const VerificationMeta('startWeightKg');
  @override
  late final GeneratedColumn<double> startWeightKg = GeneratedColumn<double>(
      'start_weight_kg', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _activityLevelMeta =
      const VerificationMeta('activityLevel');
  @override
  late final GeneratedColumn<String> activityLevel = GeneratedColumn<String>(
      'activity_level', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _targetWeightKgMeta =
      const VerificationMeta('targetWeightKg');
  @override
  late final GeneratedColumn<double> targetWeightKg = GeneratedColumn<double>(
      'target_weight_kg', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _goalMeta = const VerificationMeta('goal');
  @override
  late final GeneratedColumn<String> goal = GeneratedColumn<String>(
      'goal', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('lose'));
  static const VerificationMeta _paceMeta = const VerificationMeta('pace');
  @override
  late final GeneratedColumn<String> pace = GeneratedColumn<String>(
      'pace', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('standard'));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        sex,
        age,
        heightCm,
        startWeightKg,
        activityLevel,
        targetWeightKg,
        goal,
        pace,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'body_profiles';
  @override
  VerificationContext validateIntegrity(Insertable<BodyProfile> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sex')) {
      context.handle(
          _sexMeta, sex.isAcceptableOrUnknown(data['sex']!, _sexMeta));
    } else if (isInserting) {
      context.missing(_sexMeta);
    }
    if (data.containsKey('age')) {
      context.handle(
          _ageMeta, age.isAcceptableOrUnknown(data['age']!, _ageMeta));
    } else if (isInserting) {
      context.missing(_ageMeta);
    }
    if (data.containsKey('height_cm')) {
      context.handle(_heightCmMeta,
          heightCm.isAcceptableOrUnknown(data['height_cm']!, _heightCmMeta));
    } else if (isInserting) {
      context.missing(_heightCmMeta);
    }
    if (data.containsKey('start_weight_kg')) {
      context.handle(
          _startWeightKgMeta,
          startWeightKg.isAcceptableOrUnknown(
              data['start_weight_kg']!, _startWeightKgMeta));
    } else if (isInserting) {
      context.missing(_startWeightKgMeta);
    }
    if (data.containsKey('activity_level')) {
      context.handle(
          _activityLevelMeta,
          activityLevel.isAcceptableOrUnknown(
              data['activity_level']!, _activityLevelMeta));
    } else if (isInserting) {
      context.missing(_activityLevelMeta);
    }
    if (data.containsKey('target_weight_kg')) {
      context.handle(
          _targetWeightKgMeta,
          targetWeightKg.isAcceptableOrUnknown(
              data['target_weight_kg']!, _targetWeightKgMeta));
    }
    if (data.containsKey('goal')) {
      context.handle(
          _goalMeta, goal.isAcceptableOrUnknown(data['goal']!, _goalMeta));
    }
    if (data.containsKey('pace')) {
      context.handle(
          _paceMeta, pace.isAcceptableOrUnknown(data['pace']!, _paceMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BodyProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BodyProfile(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      sex: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sex'])!,
      age: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}age'])!,
      heightCm: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}height_cm'])!,
      startWeightKg: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}start_weight_kg'])!,
      activityLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}activity_level'])!,
      targetWeightKg: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}target_weight_kg']),
      goal: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}goal'])!,
      pace: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pace'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $BodyProfilesTable createAlias(String alias) {
    return $BodyProfilesTable(attachedDatabase, alias);
  }
}

class BodyProfile extends DataClass implements Insertable<BodyProfile> {
  final int id;

  /// male / female
  final String sex;
  final int age;
  final double heightCm;
  final double startWeightKg;

  /// sedentary / light / moderate / active / veryActive
  final String activityLevel;
  final double? targetWeightKg;

  /// lose / maintain / gain
  final String goal;

  /// gentle / standard / aggressive
  final String pace;
  final DateTime updatedAt;
  const BodyProfile(
      {required this.id,
      required this.sex,
      required this.age,
      required this.heightCm,
      required this.startWeightKg,
      required this.activityLevel,
      this.targetWeightKg,
      required this.goal,
      required this.pace,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sex'] = Variable<String>(sex);
    map['age'] = Variable<int>(age);
    map['height_cm'] = Variable<double>(heightCm);
    map['start_weight_kg'] = Variable<double>(startWeightKg);
    map['activity_level'] = Variable<String>(activityLevel);
    if (!nullToAbsent || targetWeightKg != null) {
      map['target_weight_kg'] = Variable<double>(targetWeightKg);
    }
    map['goal'] = Variable<String>(goal);
    map['pace'] = Variable<String>(pace);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BodyProfilesCompanion toCompanion(bool nullToAbsent) {
    return BodyProfilesCompanion(
      id: Value(id),
      sex: Value(sex),
      age: Value(age),
      heightCm: Value(heightCm),
      startWeightKg: Value(startWeightKg),
      activityLevel: Value(activityLevel),
      targetWeightKg: targetWeightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(targetWeightKg),
      goal: Value(goal),
      pace: Value(pace),
      updatedAt: Value(updatedAt),
    );
  }

  factory BodyProfile.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BodyProfile(
      id: serializer.fromJson<int>(json['id']),
      sex: serializer.fromJson<String>(json['sex']),
      age: serializer.fromJson<int>(json['age']),
      heightCm: serializer.fromJson<double>(json['heightCm']),
      startWeightKg: serializer.fromJson<double>(json['startWeightKg']),
      activityLevel: serializer.fromJson<String>(json['activityLevel']),
      targetWeightKg: serializer.fromJson<double?>(json['targetWeightKg']),
      goal: serializer.fromJson<String>(json['goal']),
      pace: serializer.fromJson<String>(json['pace']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sex': serializer.toJson<String>(sex),
      'age': serializer.toJson<int>(age),
      'heightCm': serializer.toJson<double>(heightCm),
      'startWeightKg': serializer.toJson<double>(startWeightKg),
      'activityLevel': serializer.toJson<String>(activityLevel),
      'targetWeightKg': serializer.toJson<double?>(targetWeightKg),
      'goal': serializer.toJson<String>(goal),
      'pace': serializer.toJson<String>(pace),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BodyProfile copyWith(
          {int? id,
          String? sex,
          int? age,
          double? heightCm,
          double? startWeightKg,
          String? activityLevel,
          Value<double?> targetWeightKg = const Value.absent(),
          String? goal,
          String? pace,
          DateTime? updatedAt}) =>
      BodyProfile(
        id: id ?? this.id,
        sex: sex ?? this.sex,
        age: age ?? this.age,
        heightCm: heightCm ?? this.heightCm,
        startWeightKg: startWeightKg ?? this.startWeightKg,
        activityLevel: activityLevel ?? this.activityLevel,
        targetWeightKg:
            targetWeightKg.present ? targetWeightKg.value : this.targetWeightKg,
        goal: goal ?? this.goal,
        pace: pace ?? this.pace,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  BodyProfile copyWithCompanion(BodyProfilesCompanion data) {
    return BodyProfile(
      id: data.id.present ? data.id.value : this.id,
      sex: data.sex.present ? data.sex.value : this.sex,
      age: data.age.present ? data.age.value : this.age,
      heightCm: data.heightCm.present ? data.heightCm.value : this.heightCm,
      startWeightKg: data.startWeightKg.present
          ? data.startWeightKg.value
          : this.startWeightKg,
      activityLevel: data.activityLevel.present
          ? data.activityLevel.value
          : this.activityLevel,
      targetWeightKg: data.targetWeightKg.present
          ? data.targetWeightKg.value
          : this.targetWeightKg,
      goal: data.goal.present ? data.goal.value : this.goal,
      pace: data.pace.present ? data.pace.value : this.pace,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BodyProfile(')
          ..write('id: $id, ')
          ..write('sex: $sex, ')
          ..write('age: $age, ')
          ..write('heightCm: $heightCm, ')
          ..write('startWeightKg: $startWeightKg, ')
          ..write('activityLevel: $activityLevel, ')
          ..write('targetWeightKg: $targetWeightKg, ')
          ..write('goal: $goal, ')
          ..write('pace: $pace, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sex, age, heightCm, startWeightKg,
      activityLevel, targetWeightKg, goal, pace, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BodyProfile &&
          other.id == this.id &&
          other.sex == this.sex &&
          other.age == this.age &&
          other.heightCm == this.heightCm &&
          other.startWeightKg == this.startWeightKg &&
          other.activityLevel == this.activityLevel &&
          other.targetWeightKg == this.targetWeightKg &&
          other.goal == this.goal &&
          other.pace == this.pace &&
          other.updatedAt == this.updatedAt);
}

class BodyProfilesCompanion extends UpdateCompanion<BodyProfile> {
  final Value<int> id;
  final Value<String> sex;
  final Value<int> age;
  final Value<double> heightCm;
  final Value<double> startWeightKg;
  final Value<String> activityLevel;
  final Value<double?> targetWeightKg;
  final Value<String> goal;
  final Value<String> pace;
  final Value<DateTime> updatedAt;
  const BodyProfilesCompanion({
    this.id = const Value.absent(),
    this.sex = const Value.absent(),
    this.age = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.startWeightKg = const Value.absent(),
    this.activityLevel = const Value.absent(),
    this.targetWeightKg = const Value.absent(),
    this.goal = const Value.absent(),
    this.pace = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  BodyProfilesCompanion.insert({
    this.id = const Value.absent(),
    required String sex,
    required int age,
    required double heightCm,
    required double startWeightKg,
    required String activityLevel,
    this.targetWeightKg = const Value.absent(),
    this.goal = const Value.absent(),
    this.pace = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : sex = Value(sex),
        age = Value(age),
        heightCm = Value(heightCm),
        startWeightKg = Value(startWeightKg),
        activityLevel = Value(activityLevel);
  static Insertable<BodyProfile> custom({
    Expression<int>? id,
    Expression<String>? sex,
    Expression<int>? age,
    Expression<double>? heightCm,
    Expression<double>? startWeightKg,
    Expression<String>? activityLevel,
    Expression<double>? targetWeightKg,
    Expression<String>? goal,
    Expression<String>? pace,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sex != null) 'sex': sex,
      if (age != null) 'age': age,
      if (heightCm != null) 'height_cm': heightCm,
      if (startWeightKg != null) 'start_weight_kg': startWeightKg,
      if (activityLevel != null) 'activity_level': activityLevel,
      if (targetWeightKg != null) 'target_weight_kg': targetWeightKg,
      if (goal != null) 'goal': goal,
      if (pace != null) 'pace': pace,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  BodyProfilesCompanion copyWith(
      {Value<int>? id,
      Value<String>? sex,
      Value<int>? age,
      Value<double>? heightCm,
      Value<double>? startWeightKg,
      Value<String>? activityLevel,
      Value<double?>? targetWeightKg,
      Value<String>? goal,
      Value<String>? pace,
      Value<DateTime>? updatedAt}) {
    return BodyProfilesCompanion(
      id: id ?? this.id,
      sex: sex ?? this.sex,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      startWeightKg: startWeightKg ?? this.startWeightKg,
      activityLevel: activityLevel ?? this.activityLevel,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      goal: goal ?? this.goal,
      pace: pace ?? this.pace,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sex.present) {
      map['sex'] = Variable<String>(sex.value);
    }
    if (age.present) {
      map['age'] = Variable<int>(age.value);
    }
    if (heightCm.present) {
      map['height_cm'] = Variable<double>(heightCm.value);
    }
    if (startWeightKg.present) {
      map['start_weight_kg'] = Variable<double>(startWeightKg.value);
    }
    if (activityLevel.present) {
      map['activity_level'] = Variable<String>(activityLevel.value);
    }
    if (targetWeightKg.present) {
      map['target_weight_kg'] = Variable<double>(targetWeightKg.value);
    }
    if (goal.present) {
      map['goal'] = Variable<String>(goal.value);
    }
    if (pace.present) {
      map['pace'] = Variable<String>(pace.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BodyProfilesCompanion(')
          ..write('id: $id, ')
          ..write('sex: $sex, ')
          ..write('age: $age, ')
          ..write('heightCm: $heightCm, ')
          ..write('startWeightKg: $startWeightKg, ')
          ..write('activityLevel: $activityLevel, ')
          ..write('targetWeightKg: $targetWeightKg, ')
          ..write('goal: $goal, ')
          ..write('pace: $pace, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $CalorieBudgetsTable extends CalorieBudgets
    with TableInfo<$CalorieBudgetsTable, CalorieBudgetRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CalorieBudgetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _bmrMeta = const VerificationMeta('bmr');
  @override
  late final GeneratedColumn<double> bmr = GeneratedColumn<double>(
      'bmr', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _tdeeMeta = const VerificationMeta('tdee');
  @override
  late final GeneratedColumn<double> tdee = GeneratedColumn<double>(
      'tdee', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _intakeTargetMeta =
      const VerificationMeta('intakeTarget');
  @override
  late final GeneratedColumn<double> intakeTarget = GeneratedColumn<double>(
      'intake_target', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _proteinGMeta =
      const VerificationMeta('proteinG');
  @override
  late final GeneratedColumn<double> proteinG = GeneratedColumn<double>(
      'protein_g', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _fatGMeta = const VerificationMeta('fatG');
  @override
  late final GeneratedColumn<double> fatG = GeneratedColumn<double>(
      'fat_g', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _carbGMeta = const VerificationMeta('carbG');
  @override
  late final GeneratedColumn<double> carbG = GeneratedColumn<double>(
      'carb_g', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _formulaMeta =
      const VerificationMeta('formula');
  @override
  late final GeneratedColumn<String> formula = GeneratedColumn<String>(
      'formula', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Mifflin-St Jeor'));
  @override
  List<GeneratedColumn> get $columns =>
      [id, date, bmr, tdee, intakeTarget, proteinG, fatG, carbG, formula];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'calorie_budgets';
  @override
  VerificationContext validateIntegrity(Insertable<CalorieBudgetRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('bmr')) {
      context.handle(
          _bmrMeta, bmr.isAcceptableOrUnknown(data['bmr']!, _bmrMeta));
    } else if (isInserting) {
      context.missing(_bmrMeta);
    }
    if (data.containsKey('tdee')) {
      context.handle(
          _tdeeMeta, tdee.isAcceptableOrUnknown(data['tdee']!, _tdeeMeta));
    } else if (isInserting) {
      context.missing(_tdeeMeta);
    }
    if (data.containsKey('intake_target')) {
      context.handle(
          _intakeTargetMeta,
          intakeTarget.isAcceptableOrUnknown(
              data['intake_target']!, _intakeTargetMeta));
    } else if (isInserting) {
      context.missing(_intakeTargetMeta);
    }
    if (data.containsKey('protein_g')) {
      context.handle(_proteinGMeta,
          proteinG.isAcceptableOrUnknown(data['protein_g']!, _proteinGMeta));
    } else if (isInserting) {
      context.missing(_proteinGMeta);
    }
    if (data.containsKey('fat_g')) {
      context.handle(
          _fatGMeta, fatG.isAcceptableOrUnknown(data['fat_g']!, _fatGMeta));
    } else if (isInserting) {
      context.missing(_fatGMeta);
    }
    if (data.containsKey('carb_g')) {
      context.handle(
          _carbGMeta, carbG.isAcceptableOrUnknown(data['carb_g']!, _carbGMeta));
    } else if (isInserting) {
      context.missing(_carbGMeta);
    }
    if (data.containsKey('formula')) {
      context.handle(_formulaMeta,
          formula.isAcceptableOrUnknown(data['formula']!, _formulaMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {date},
      ];
  @override
  CalorieBudgetRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CalorieBudgetRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      bmr: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}bmr'])!,
      tdee: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}tdee'])!,
      intakeTarget: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}intake_target'])!,
      proteinG: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}protein_g'])!,
      fatG: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}fat_g'])!,
      carbG: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}carb_g'])!,
      formula: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}formula'])!,
    );
  }

  @override
  $CalorieBudgetsTable createAlias(String alias) {
    return $CalorieBudgetsTable(attachedDatabase, alias);
  }
}

class CalorieBudgetRow extends DataClass
    implements Insertable<CalorieBudgetRow> {
  final int id;
  final DateTime date;
  final double bmr;
  final double tdee;
  final double intakeTarget;
  final double proteinG;
  final double fatG;
  final double carbG;
  final String formula;
  const CalorieBudgetRow(
      {required this.id,
      required this.date,
      required this.bmr,
      required this.tdee,
      required this.intakeTarget,
      required this.proteinG,
      required this.fatG,
      required this.carbG,
      required this.formula});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    map['bmr'] = Variable<double>(bmr);
    map['tdee'] = Variable<double>(tdee);
    map['intake_target'] = Variable<double>(intakeTarget);
    map['protein_g'] = Variable<double>(proteinG);
    map['fat_g'] = Variable<double>(fatG);
    map['carb_g'] = Variable<double>(carbG);
    map['formula'] = Variable<String>(formula);
    return map;
  }

  CalorieBudgetsCompanion toCompanion(bool nullToAbsent) {
    return CalorieBudgetsCompanion(
      id: Value(id),
      date: Value(date),
      bmr: Value(bmr),
      tdee: Value(tdee),
      intakeTarget: Value(intakeTarget),
      proteinG: Value(proteinG),
      fatG: Value(fatG),
      carbG: Value(carbG),
      formula: Value(formula),
    );
  }

  factory CalorieBudgetRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CalorieBudgetRow(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      bmr: serializer.fromJson<double>(json['bmr']),
      tdee: serializer.fromJson<double>(json['tdee']),
      intakeTarget: serializer.fromJson<double>(json['intakeTarget']),
      proteinG: serializer.fromJson<double>(json['proteinG']),
      fatG: serializer.fromJson<double>(json['fatG']),
      carbG: serializer.fromJson<double>(json['carbG']),
      formula: serializer.fromJson<String>(json['formula']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'bmr': serializer.toJson<double>(bmr),
      'tdee': serializer.toJson<double>(tdee),
      'intakeTarget': serializer.toJson<double>(intakeTarget),
      'proteinG': serializer.toJson<double>(proteinG),
      'fatG': serializer.toJson<double>(fatG),
      'carbG': serializer.toJson<double>(carbG),
      'formula': serializer.toJson<String>(formula),
    };
  }

  CalorieBudgetRow copyWith(
          {int? id,
          DateTime? date,
          double? bmr,
          double? tdee,
          double? intakeTarget,
          double? proteinG,
          double? fatG,
          double? carbG,
          String? formula}) =>
      CalorieBudgetRow(
        id: id ?? this.id,
        date: date ?? this.date,
        bmr: bmr ?? this.bmr,
        tdee: tdee ?? this.tdee,
        intakeTarget: intakeTarget ?? this.intakeTarget,
        proteinG: proteinG ?? this.proteinG,
        fatG: fatG ?? this.fatG,
        carbG: carbG ?? this.carbG,
        formula: formula ?? this.formula,
      );
  CalorieBudgetRow copyWithCompanion(CalorieBudgetsCompanion data) {
    return CalorieBudgetRow(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      bmr: data.bmr.present ? data.bmr.value : this.bmr,
      tdee: data.tdee.present ? data.tdee.value : this.tdee,
      intakeTarget: data.intakeTarget.present
          ? data.intakeTarget.value
          : this.intakeTarget,
      proteinG: data.proteinG.present ? data.proteinG.value : this.proteinG,
      fatG: data.fatG.present ? data.fatG.value : this.fatG,
      carbG: data.carbG.present ? data.carbG.value : this.carbG,
      formula: data.formula.present ? data.formula.value : this.formula,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CalorieBudgetRow(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('bmr: $bmr, ')
          ..write('tdee: $tdee, ')
          ..write('intakeTarget: $intakeTarget, ')
          ..write('proteinG: $proteinG, ')
          ..write('fatG: $fatG, ')
          ..write('carbG: $carbG, ')
          ..write('formula: $formula')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, date, bmr, tdee, intakeTarget, proteinG, fatG, carbG, formula);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CalorieBudgetRow &&
          other.id == this.id &&
          other.date == this.date &&
          other.bmr == this.bmr &&
          other.tdee == this.tdee &&
          other.intakeTarget == this.intakeTarget &&
          other.proteinG == this.proteinG &&
          other.fatG == this.fatG &&
          other.carbG == this.carbG &&
          other.formula == this.formula);
}

class CalorieBudgetsCompanion extends UpdateCompanion<CalorieBudgetRow> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<double> bmr;
  final Value<double> tdee;
  final Value<double> intakeTarget;
  final Value<double> proteinG;
  final Value<double> fatG;
  final Value<double> carbG;
  final Value<String> formula;
  const CalorieBudgetsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.bmr = const Value.absent(),
    this.tdee = const Value.absent(),
    this.intakeTarget = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.carbG = const Value.absent(),
    this.formula = const Value.absent(),
  });
  CalorieBudgetsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    required double bmr,
    required double tdee,
    required double intakeTarget,
    required double proteinG,
    required double fatG,
    required double carbG,
    this.formula = const Value.absent(),
  })  : date = Value(date),
        bmr = Value(bmr),
        tdee = Value(tdee),
        intakeTarget = Value(intakeTarget),
        proteinG = Value(proteinG),
        fatG = Value(fatG),
        carbG = Value(carbG);
  static Insertable<CalorieBudgetRow> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<double>? bmr,
    Expression<double>? tdee,
    Expression<double>? intakeTarget,
    Expression<double>? proteinG,
    Expression<double>? fatG,
    Expression<double>? carbG,
    Expression<String>? formula,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (bmr != null) 'bmr': bmr,
      if (tdee != null) 'tdee': tdee,
      if (intakeTarget != null) 'intake_target': intakeTarget,
      if (proteinG != null) 'protein_g': proteinG,
      if (fatG != null) 'fat_g': fatG,
      if (carbG != null) 'carb_g': carbG,
      if (formula != null) 'formula': formula,
    });
  }

  CalorieBudgetsCompanion copyWith(
      {Value<int>? id,
      Value<DateTime>? date,
      Value<double>? bmr,
      Value<double>? tdee,
      Value<double>? intakeTarget,
      Value<double>? proteinG,
      Value<double>? fatG,
      Value<double>? carbG,
      Value<String>? formula}) {
    return CalorieBudgetsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      bmr: bmr ?? this.bmr,
      tdee: tdee ?? this.tdee,
      intakeTarget: intakeTarget ?? this.intakeTarget,
      proteinG: proteinG ?? this.proteinG,
      fatG: fatG ?? this.fatG,
      carbG: carbG ?? this.carbG,
      formula: formula ?? this.formula,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (bmr.present) {
      map['bmr'] = Variable<double>(bmr.value);
    }
    if (tdee.present) {
      map['tdee'] = Variable<double>(tdee.value);
    }
    if (intakeTarget.present) {
      map['intake_target'] = Variable<double>(intakeTarget.value);
    }
    if (proteinG.present) {
      map['protein_g'] = Variable<double>(proteinG.value);
    }
    if (fatG.present) {
      map['fat_g'] = Variable<double>(fatG.value);
    }
    if (carbG.present) {
      map['carb_g'] = Variable<double>(carbG.value);
    }
    if (formula.present) {
      map['formula'] = Variable<String>(formula.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CalorieBudgetsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('bmr: $bmr, ')
          ..write('tdee: $tdee, ')
          ..write('intakeTarget: $intakeTarget, ')
          ..write('proteinG: $proteinG, ')
          ..write('fatG: $fatG, ')
          ..write('carbG: $carbG, ')
          ..write('formula: $formula')
          ..write(')'))
        .toString();
  }
}

class $CustomFoodsTable extends CustomFoods
    with TableInfo<$CustomFoodsTable, CustomFood> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomFoodsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
      'code', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 30),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _kcalPer100gMeta =
      const VerificationMeta('kcalPer100g');
  @override
  late final GeneratedColumn<double> kcalPer100g = GeneratedColumn<double>(
      'kcal_per100g', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _proteinPer100gMeta =
      const VerificationMeta('proteinPer100g');
  @override
  late final GeneratedColumn<double> proteinPer100g = GeneratedColumn<double>(
      'protein_per100g', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _fatPer100gMeta =
      const VerificationMeta('fatPer100g');
  @override
  late final GeneratedColumn<double> fatPer100g = GeneratedColumn<double>(
      'fat_per100g', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _carbPer100gMeta =
      const VerificationMeta('carbPer100g');
  @override
  late final GeneratedColumn<double> carbPer100g = GeneratedColumn<double>(
      'carb_per100g', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _unitGramsMeta =
      const VerificationMeta('unitGrams');
  @override
  late final GeneratedColumn<double> unitGrams = GeneratedColumn<double>(
      'unit_grams', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(100));
  static const VerificationMeta _unitNameMeta =
      const VerificationMeta('unitName');
  @override
  late final GeneratedColumn<String> unitName = GeneratedColumn<String>(
      'unit_name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('份'));
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('custom'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        code,
        name,
        kcalPer100g,
        proteinPer100g,
        fatPer100g,
        carbPer100g,
        unitGrams,
        unitName,
        category,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_foods';
  @override
  VerificationContext validateIntegrity(Insertable<CustomFood> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('code')) {
      context.handle(
          _codeMeta, code.isAcceptableOrUnknown(data['code']!, _codeMeta));
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('kcal_per100g')) {
      context.handle(
          _kcalPer100gMeta,
          kcalPer100g.isAcceptableOrUnknown(
              data['kcal_per100g']!, _kcalPer100gMeta));
    } else if (isInserting) {
      context.missing(_kcalPer100gMeta);
    }
    if (data.containsKey('protein_per100g')) {
      context.handle(
          _proteinPer100gMeta,
          proteinPer100g.isAcceptableOrUnknown(
              data['protein_per100g']!, _proteinPer100gMeta));
    }
    if (data.containsKey('fat_per100g')) {
      context.handle(
          _fatPer100gMeta,
          fatPer100g.isAcceptableOrUnknown(
              data['fat_per100g']!, _fatPer100gMeta));
    }
    if (data.containsKey('carb_per100g')) {
      context.handle(
          _carbPer100gMeta,
          carbPer100g.isAcceptableOrUnknown(
              data['carb_per100g']!, _carbPer100gMeta));
    }
    if (data.containsKey('unit_grams')) {
      context.handle(_unitGramsMeta,
          unitGrams.isAcceptableOrUnknown(data['unit_grams']!, _unitGramsMeta));
    }
    if (data.containsKey('unit_name')) {
      context.handle(_unitNameMeta,
          unitName.isAcceptableOrUnknown(data['unit_name']!, _unitNameMeta));
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomFood map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomFood(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      code: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}code'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      kcalPer100g: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}kcal_per100g'])!,
      proteinPer100g: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}protein_per100g'])!,
      fatPer100g: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}fat_per100g'])!,
      carbPer100g: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}carb_per100g'])!,
      unitGrams: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}unit_grams'])!,
      unitName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit_name'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $CustomFoodsTable createAlias(String alias) {
    return $CustomFoodsTable(attachedDatabase, alias);
  }
}

class CustomFood extends DataClass implements Insertable<CustomFood> {
  final int id;

  /// 全局唯一标识，格式 custom_<毫秒时间戳>
  final String code;
  final String name;
  final double kcalPer100g;
  final double proteinPer100g;
  final double fatPer100g;
  final double carbPer100g;

  /// 一份的克数与名称（如 1 个 ≈ 50 g），默认 100 g / 份
  final double unitGrams;
  final String unitName;

  /// staple / protein / vegetable / fruit / dairy / fat / custom
  final String category;
  final DateTime createdAt;
  const CustomFood(
      {required this.id,
      required this.code,
      required this.name,
      required this.kcalPer100g,
      required this.proteinPer100g,
      required this.fatPer100g,
      required this.carbPer100g,
      required this.unitGrams,
      required this.unitName,
      required this.category,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['code'] = Variable<String>(code);
    map['name'] = Variable<String>(name);
    map['kcal_per100g'] = Variable<double>(kcalPer100g);
    map['protein_per100g'] = Variable<double>(proteinPer100g);
    map['fat_per100g'] = Variable<double>(fatPer100g);
    map['carb_per100g'] = Variable<double>(carbPer100g);
    map['unit_grams'] = Variable<double>(unitGrams);
    map['unit_name'] = Variable<String>(unitName);
    map['category'] = Variable<String>(category);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CustomFoodsCompanion toCompanion(bool nullToAbsent) {
    return CustomFoodsCompanion(
      id: Value(id),
      code: Value(code),
      name: Value(name),
      kcalPer100g: Value(kcalPer100g),
      proteinPer100g: Value(proteinPer100g),
      fatPer100g: Value(fatPer100g),
      carbPer100g: Value(carbPer100g),
      unitGrams: Value(unitGrams),
      unitName: Value(unitName),
      category: Value(category),
      createdAt: Value(createdAt),
    );
  }

  factory CustomFood.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomFood(
      id: serializer.fromJson<int>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      name: serializer.fromJson<String>(json['name']),
      kcalPer100g: serializer.fromJson<double>(json['kcalPer100g']),
      proteinPer100g: serializer.fromJson<double>(json['proteinPer100g']),
      fatPer100g: serializer.fromJson<double>(json['fatPer100g']),
      carbPer100g: serializer.fromJson<double>(json['carbPer100g']),
      unitGrams: serializer.fromJson<double>(json['unitGrams']),
      unitName: serializer.fromJson<String>(json['unitName']),
      category: serializer.fromJson<String>(json['category']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'code': serializer.toJson<String>(code),
      'name': serializer.toJson<String>(name),
      'kcalPer100g': serializer.toJson<double>(kcalPer100g),
      'proteinPer100g': serializer.toJson<double>(proteinPer100g),
      'fatPer100g': serializer.toJson<double>(fatPer100g),
      'carbPer100g': serializer.toJson<double>(carbPer100g),
      'unitGrams': serializer.toJson<double>(unitGrams),
      'unitName': serializer.toJson<String>(unitName),
      'category': serializer.toJson<String>(category),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CustomFood copyWith(
          {int? id,
          String? code,
          String? name,
          double? kcalPer100g,
          double? proteinPer100g,
          double? fatPer100g,
          double? carbPer100g,
          double? unitGrams,
          String? unitName,
          String? category,
          DateTime? createdAt}) =>
      CustomFood(
        id: id ?? this.id,
        code: code ?? this.code,
        name: name ?? this.name,
        kcalPer100g: kcalPer100g ?? this.kcalPer100g,
        proteinPer100g: proteinPer100g ?? this.proteinPer100g,
        fatPer100g: fatPer100g ?? this.fatPer100g,
        carbPer100g: carbPer100g ?? this.carbPer100g,
        unitGrams: unitGrams ?? this.unitGrams,
        unitName: unitName ?? this.unitName,
        category: category ?? this.category,
        createdAt: createdAt ?? this.createdAt,
      );
  CustomFood copyWithCompanion(CustomFoodsCompanion data) {
    return CustomFood(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      name: data.name.present ? data.name.value : this.name,
      kcalPer100g:
          data.kcalPer100g.present ? data.kcalPer100g.value : this.kcalPer100g,
      proteinPer100g: data.proteinPer100g.present
          ? data.proteinPer100g.value
          : this.proteinPer100g,
      fatPer100g:
          data.fatPer100g.present ? data.fatPer100g.value : this.fatPer100g,
      carbPer100g:
          data.carbPer100g.present ? data.carbPer100g.value : this.carbPer100g,
      unitGrams: data.unitGrams.present ? data.unitGrams.value : this.unitGrams,
      unitName: data.unitName.present ? data.unitName.value : this.unitName,
      category: data.category.present ? data.category.value : this.category,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomFood(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('kcalPer100g: $kcalPer100g, ')
          ..write('proteinPer100g: $proteinPer100g, ')
          ..write('fatPer100g: $fatPer100g, ')
          ..write('carbPer100g: $carbPer100g, ')
          ..write('unitGrams: $unitGrams, ')
          ..write('unitName: $unitName, ')
          ..write('category: $category, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, code, name, kcalPer100g, proteinPer100g,
      fatPer100g, carbPer100g, unitGrams, unitName, category, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomFood &&
          other.id == this.id &&
          other.code == this.code &&
          other.name == this.name &&
          other.kcalPer100g == this.kcalPer100g &&
          other.proteinPer100g == this.proteinPer100g &&
          other.fatPer100g == this.fatPer100g &&
          other.carbPer100g == this.carbPer100g &&
          other.unitGrams == this.unitGrams &&
          other.unitName == this.unitName &&
          other.category == this.category &&
          other.createdAt == this.createdAt);
}

class CustomFoodsCompanion extends UpdateCompanion<CustomFood> {
  final Value<int> id;
  final Value<String> code;
  final Value<String> name;
  final Value<double> kcalPer100g;
  final Value<double> proteinPer100g;
  final Value<double> fatPer100g;
  final Value<double> carbPer100g;
  final Value<double> unitGrams;
  final Value<String> unitName;
  final Value<String> category;
  final Value<DateTime> createdAt;
  const CustomFoodsCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.name = const Value.absent(),
    this.kcalPer100g = const Value.absent(),
    this.proteinPer100g = const Value.absent(),
    this.fatPer100g = const Value.absent(),
    this.carbPer100g = const Value.absent(),
    this.unitGrams = const Value.absent(),
    this.unitName = const Value.absent(),
    this.category = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CustomFoodsCompanion.insert({
    this.id = const Value.absent(),
    required String code,
    required String name,
    required double kcalPer100g,
    this.proteinPer100g = const Value.absent(),
    this.fatPer100g = const Value.absent(),
    this.carbPer100g = const Value.absent(),
    this.unitGrams = const Value.absent(),
    this.unitName = const Value.absent(),
    this.category = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : code = Value(code),
        name = Value(name),
        kcalPer100g = Value(kcalPer100g);
  static Insertable<CustomFood> custom({
    Expression<int>? id,
    Expression<String>? code,
    Expression<String>? name,
    Expression<double>? kcalPer100g,
    Expression<double>? proteinPer100g,
    Expression<double>? fatPer100g,
    Expression<double>? carbPer100g,
    Expression<double>? unitGrams,
    Expression<String>? unitName,
    Expression<String>? category,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (kcalPer100g != null) 'kcal_per100g': kcalPer100g,
      if (proteinPer100g != null) 'protein_per100g': proteinPer100g,
      if (fatPer100g != null) 'fat_per100g': fatPer100g,
      if (carbPer100g != null) 'carb_per100g': carbPer100g,
      if (unitGrams != null) 'unit_grams': unitGrams,
      if (unitName != null) 'unit_name': unitName,
      if (category != null) 'category': category,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CustomFoodsCompanion copyWith(
      {Value<int>? id,
      Value<String>? code,
      Value<String>? name,
      Value<double>? kcalPer100g,
      Value<double>? proteinPer100g,
      Value<double>? fatPer100g,
      Value<double>? carbPer100g,
      Value<double>? unitGrams,
      Value<String>? unitName,
      Value<String>? category,
      Value<DateTime>? createdAt}) {
    return CustomFoodsCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      kcalPer100g: kcalPer100g ?? this.kcalPer100g,
      proteinPer100g: proteinPer100g ?? this.proteinPer100g,
      fatPer100g: fatPer100g ?? this.fatPer100g,
      carbPer100g: carbPer100g ?? this.carbPer100g,
      unitGrams: unitGrams ?? this.unitGrams,
      unitName: unitName ?? this.unitName,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kcalPer100g.present) {
      map['kcal_per100g'] = Variable<double>(kcalPer100g.value);
    }
    if (proteinPer100g.present) {
      map['protein_per100g'] = Variable<double>(proteinPer100g.value);
    }
    if (fatPer100g.present) {
      map['fat_per100g'] = Variable<double>(fatPer100g.value);
    }
    if (carbPer100g.present) {
      map['carb_per100g'] = Variable<double>(carbPer100g.value);
    }
    if (unitGrams.present) {
      map['unit_grams'] = Variable<double>(unitGrams.value);
    }
    if (unitName.present) {
      map['unit_name'] = Variable<String>(unitName.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomFoodsCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('kcalPer100g: $kcalPer100g, ')
          ..write('proteinPer100g: $proteinPer100g, ')
          ..write('fatPer100g: $fatPer100g, ')
          ..write('carbPer100g: $carbPer100g, ')
          ..write('unitGrams: $unitGrams, ')
          ..write('unitName: $unitName, ')
          ..write('category: $category, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $PeriodCyclesTable extends PeriodCycles
    with TableInfo<$PeriodCyclesTable, PeriodCycle> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PeriodCyclesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _startDateMeta =
      const VerificationMeta('startDate');
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
      'start_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endDateMeta =
      const VerificationMeta('endDate');
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
      'end_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _cycleLengthMeta =
      const VerificationMeta('cycleLength');
  @override
  late final GeneratedColumn<int> cycleLength = GeneratedColumn<int>(
      'cycle_length', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _periodLengthMeta =
      const VerificationMeta('periodLength');
  @override
  late final GeneratedColumn<int> periodLength = GeneratedColumn<int>(
      'period_length', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _isClosedMeta =
      const VerificationMeta('isClosed');
  @override
  late final GeneratedColumn<bool> isClosed = GeneratedColumn<bool>(
      'is_closed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_closed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        startDate,
        endDate,
        cycleLength,
        periodLength,
        isClosed,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'period_cycles';
  @override
  VerificationContext validateIntegrity(Insertable<PeriodCycle> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('start_date')) {
      context.handle(_startDateMeta,
          startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta));
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(_endDateMeta,
          endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta));
    }
    if (data.containsKey('cycle_length')) {
      context.handle(
          _cycleLengthMeta,
          cycleLength.isAcceptableOrUnknown(
              data['cycle_length']!, _cycleLengthMeta));
    }
    if (data.containsKey('period_length')) {
      context.handle(
          _periodLengthMeta,
          periodLength.isAcceptableOrUnknown(
              data['period_length']!, _periodLengthMeta));
    }
    if (data.containsKey('is_closed')) {
      context.handle(_isClosedMeta,
          isClosed.isAcceptableOrUnknown(data['is_closed']!, _isClosedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PeriodCycle map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PeriodCycle(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      startDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_date'])!,
      endDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_date']),
      cycleLength: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}cycle_length']),
      periodLength: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}period_length']),
      isClosed: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_closed'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $PeriodCyclesTable createAlias(String alias) {
    return $PeriodCyclesTable(attachedDatabase, alias);
  }
}

class PeriodCycle extends DataClass implements Insertable<PeriodCycle> {
  final int id;

  /// 周期内经期的第一天。
  final DateTime startDate;

  /// 经期最后一天（未结束为 null）。
  final DateTime? endDate;

  /// 本周期长度（天）；周期结束后回填。
  final int? cycleLength;

  /// 本周期经期天数；结束前为 null。
  final int? periodLength;

  /// 周期是否已结束。对应原库 is_closed。
  final bool isClosed;
  final DateTime createdAt;
  final DateTime updatedAt;
  const PeriodCycle(
      {required this.id,
      required this.startDate,
      this.endDate,
      this.cycleLength,
      this.periodLength,
      required this.isClosed,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['start_date'] = Variable<DateTime>(startDate);
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<DateTime>(endDate);
    }
    if (!nullToAbsent || cycleLength != null) {
      map['cycle_length'] = Variable<int>(cycleLength);
    }
    if (!nullToAbsent || periodLength != null) {
      map['period_length'] = Variable<int>(periodLength);
    }
    map['is_closed'] = Variable<bool>(isClosed);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PeriodCyclesCompanion toCompanion(bool nullToAbsent) {
    return PeriodCyclesCompanion(
      id: Value(id),
      startDate: Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      cycleLength: cycleLength == null && nullToAbsent
          ? const Value.absent()
          : Value(cycleLength),
      periodLength: periodLength == null && nullToAbsent
          ? const Value.absent()
          : Value(periodLength),
      isClosed: Value(isClosed),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PeriodCycle.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PeriodCycle(
      id: serializer.fromJson<int>(json['id']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      endDate: serializer.fromJson<DateTime?>(json['endDate']),
      cycleLength: serializer.fromJson<int?>(json['cycleLength']),
      periodLength: serializer.fromJson<int?>(json['periodLength']),
      isClosed: serializer.fromJson<bool>(json['isClosed']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'startDate': serializer.toJson<DateTime>(startDate),
      'endDate': serializer.toJson<DateTime?>(endDate),
      'cycleLength': serializer.toJson<int?>(cycleLength),
      'periodLength': serializer.toJson<int?>(periodLength),
      'isClosed': serializer.toJson<bool>(isClosed),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PeriodCycle copyWith(
          {int? id,
          DateTime? startDate,
          Value<DateTime?> endDate = const Value.absent(),
          Value<int?> cycleLength = const Value.absent(),
          Value<int?> periodLength = const Value.absent(),
          bool? isClosed,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      PeriodCycle(
        id: id ?? this.id,
        startDate: startDate ?? this.startDate,
        endDate: endDate.present ? endDate.value : this.endDate,
        cycleLength: cycleLength.present ? cycleLength.value : this.cycleLength,
        periodLength:
            periodLength.present ? periodLength.value : this.periodLength,
        isClosed: isClosed ?? this.isClosed,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  PeriodCycle copyWithCompanion(PeriodCyclesCompanion data) {
    return PeriodCycle(
      id: data.id.present ? data.id.value : this.id,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      cycleLength:
          data.cycleLength.present ? data.cycleLength.value : this.cycleLength,
      periodLength: data.periodLength.present
          ? data.periodLength.value
          : this.periodLength,
      isClosed: data.isClosed.present ? data.isClosed.value : this.isClosed,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PeriodCycle(')
          ..write('id: $id, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('cycleLength: $cycleLength, ')
          ..write('periodLength: $periodLength, ')
          ..write('isClosed: $isClosed, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, startDate, endDate, cycleLength,
      periodLength, isClosed, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PeriodCycle &&
          other.id == this.id &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.cycleLength == this.cycleLength &&
          other.periodLength == this.periodLength &&
          other.isClosed == this.isClosed &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PeriodCyclesCompanion extends UpdateCompanion<PeriodCycle> {
  final Value<int> id;
  final Value<DateTime> startDate;
  final Value<DateTime?> endDate;
  final Value<int?> cycleLength;
  final Value<int?> periodLength;
  final Value<bool> isClosed;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const PeriodCyclesCompanion({
    this.id = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.cycleLength = const Value.absent(),
    this.periodLength = const Value.absent(),
    this.isClosed = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  PeriodCyclesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime startDate,
    this.endDate = const Value.absent(),
    this.cycleLength = const Value.absent(),
    this.periodLength = const Value.absent(),
    this.isClosed = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : startDate = Value(startDate);
  static Insertable<PeriodCycle> custom({
    Expression<int>? id,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<int>? cycleLength,
    Expression<int>? periodLength,
    Expression<bool>? isClosed,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (cycleLength != null) 'cycle_length': cycleLength,
      if (periodLength != null) 'period_length': periodLength,
      if (isClosed != null) 'is_closed': isClosed,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  PeriodCyclesCompanion copyWith(
      {Value<int>? id,
      Value<DateTime>? startDate,
      Value<DateTime?>? endDate,
      Value<int?>? cycleLength,
      Value<int?>? periodLength,
      Value<bool>? isClosed,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return PeriodCyclesCompanion(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      cycleLength: cycleLength ?? this.cycleLength,
      periodLength: periodLength ?? this.periodLength,
      isClosed: isClosed ?? this.isClosed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (cycleLength.present) {
      map['cycle_length'] = Variable<int>(cycleLength.value);
    }
    if (periodLength.present) {
      map['period_length'] = Variable<int>(periodLength.value);
    }
    if (isClosed.present) {
      map['is_closed'] = Variable<bool>(isClosed.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PeriodCyclesCompanion(')
          ..write('id: $id, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('cycleLength: $cycleLength, ')
          ..write('periodLength: $periodLength, ')
          ..write('isClosed: $isClosed, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $DailyRecordsTable extends DailyRecords
    with TableInfo<$DailyRecordsTable, DailyRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _flowLevelMeta =
      const VerificationMeta('flowLevel');
  @override
  late final GeneratedColumn<int> flowLevel = GeneratedColumn<int>(
      'flow_level', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _painLevelMeta =
      const VerificationMeta('painLevel');
  @override
  late final GeneratedColumn<int> painLevel = GeneratedColumn<int>(
      'pain_level', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _moodMeta = const VerificationMeta('mood');
  @override
  late final GeneratedColumn<String> mood = GeneratedColumn<String>(
      'mood', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _symptomsMeta =
      const VerificationMeta('symptoms');
  @override
  late final GeneratedColumn<String> symptoms = GeneratedColumn<String>(
      'symptoms', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _weightKgMeta =
      const VerificationMeta('weightKg');
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
      'weight_kg', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _sexualActivityMeta =
      const VerificationMeta('sexualActivity');
  @override
  late final GeneratedColumn<bool> sexualActivity = GeneratedColumn<bool>(
      'sexual_activity', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("sexual_activity" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isPeriodDayMeta =
      const VerificationMeta('isPeriodDay');
  @override
  late final GeneratedColumn<bool> isPeriodDay = GeneratedColumn<bool>(
      'is_period_day', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_period_day" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _bloodColorMeta =
      const VerificationMeta('bloodColor');
  @override
  late final GeneratedColumn<String> bloodColor = GeneratedColumn<String>(
      'blood_color', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sleepHoursMeta =
      const VerificationMeta('sleepHours');
  @override
  late final GeneratedColumn<double> sleepHours = GeneratedColumn<double>(
      'sleep_hours', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _cycleIdMeta =
      const VerificationMeta('cycleId');
  @override
  late final GeneratedColumn<int> cycleId = GeneratedColumn<int>(
      'cycle_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        date,
        flowLevel,
        painLevel,
        mood,
        symptoms,
        note,
        weightKg,
        sexualActivity,
        isPeriodDay,
        bloodColor,
        sleepHours,
        cycleId,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_records';
  @override
  VerificationContext validateIntegrity(Insertable<DailyRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('flow_level')) {
      context.handle(_flowLevelMeta,
          flowLevel.isAcceptableOrUnknown(data['flow_level']!, _flowLevelMeta));
    }
    if (data.containsKey('pain_level')) {
      context.handle(_painLevelMeta,
          painLevel.isAcceptableOrUnknown(data['pain_level']!, _painLevelMeta));
    }
    if (data.containsKey('mood')) {
      context.handle(
          _moodMeta, mood.isAcceptableOrUnknown(data['mood']!, _moodMeta));
    }
    if (data.containsKey('symptoms')) {
      context.handle(_symptomsMeta,
          symptoms.isAcceptableOrUnknown(data['symptoms']!, _symptomsMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('weight_kg')) {
      context.handle(_weightKgMeta,
          weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta));
    }
    if (data.containsKey('sexual_activity')) {
      context.handle(
          _sexualActivityMeta,
          sexualActivity.isAcceptableOrUnknown(
              data['sexual_activity']!, _sexualActivityMeta));
    }
    if (data.containsKey('is_period_day')) {
      context.handle(
          _isPeriodDayMeta,
          isPeriodDay.isAcceptableOrUnknown(
              data['is_period_day']!, _isPeriodDayMeta));
    }
    if (data.containsKey('blood_color')) {
      context.handle(
          _bloodColorMeta,
          bloodColor.isAcceptableOrUnknown(
              data['blood_color']!, _bloodColorMeta));
    }
    if (data.containsKey('sleep_hours')) {
      context.handle(
          _sleepHoursMeta,
          sleepHours.isAcceptableOrUnknown(
              data['sleep_hours']!, _sleepHoursMeta));
    }
    if (data.containsKey('cycle_id')) {
      context.handle(_cycleIdMeta,
          cycleId.isAcceptableOrUnknown(data['cycle_id']!, _cycleIdMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date};
  @override
  DailyRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyRecord(
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      flowLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}flow_level']),
      painLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}pain_level']),
      mood: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mood']),
      symptoms: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}symptoms']),
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      weightKg: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}weight_kg']),
      sexualActivity: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}sexual_activity'])!,
      isPeriodDay: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_period_day'])!,
      bloodColor: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}blood_color']),
      sleepHours: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}sleep_hours']),
      cycleId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}cycle_id']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $DailyRecordsTable createAlias(String alias) {
    return $DailyRecordsTable(attachedDatabase, alias);
  }
}

class DailyRecord extends DataClass implements Insertable<DailyRecord> {
  /// 记录日期（本地时区零点）。主键。
  final DateTime date;

  /// 经量等级（0=无 1=少 2=中 3=多），见 FlowLevel。
  final int? flowLevel;

  /// 痛经等级（0–3），见 PainLevel。
  final int? painLevel;

  /// 心情代码，对应 assets 的 feelings.json 的 id。
  final String? mood;

  /// 症状代码数组，JSON 字符串。对应 all_symptom_data.json 的 id。
  final String? symptoms;
  final String? note;
  final double? weightKg;

  /// 是否有性生活（原库 CHECK 0/1）。**敏感字段，禁止写日志。**
  final bool sexualActivity;

  /// 是否经期日。日状态判定的关键字段。
  final bool isPeriodDay;

  /// 血色（褐色 / 鲜红 / 暗红），存枚举名。
  final String? bloodColor;
  final double? sleepHours;

  /// 归属周期。为空表示尚未归入任何周期。
  final int? cycleId;
  final DateTime updatedAt;
  const DailyRecord(
      {required this.date,
      this.flowLevel,
      this.painLevel,
      this.mood,
      this.symptoms,
      this.note,
      this.weightKg,
      required this.sexualActivity,
      required this.isPeriodDay,
      this.bloodColor,
      this.sleepHours,
      this.cycleId,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || flowLevel != null) {
      map['flow_level'] = Variable<int>(flowLevel);
    }
    if (!nullToAbsent || painLevel != null) {
      map['pain_level'] = Variable<int>(painLevel);
    }
    if (!nullToAbsent || mood != null) {
      map['mood'] = Variable<String>(mood);
    }
    if (!nullToAbsent || symptoms != null) {
      map['symptoms'] = Variable<String>(symptoms);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || weightKg != null) {
      map['weight_kg'] = Variable<double>(weightKg);
    }
    map['sexual_activity'] = Variable<bool>(sexualActivity);
    map['is_period_day'] = Variable<bool>(isPeriodDay);
    if (!nullToAbsent || bloodColor != null) {
      map['blood_color'] = Variable<String>(bloodColor);
    }
    if (!nullToAbsent || sleepHours != null) {
      map['sleep_hours'] = Variable<double>(sleepHours);
    }
    if (!nullToAbsent || cycleId != null) {
      map['cycle_id'] = Variable<int>(cycleId);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DailyRecordsCompanion toCompanion(bool nullToAbsent) {
    return DailyRecordsCompanion(
      date: Value(date),
      flowLevel: flowLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(flowLevel),
      painLevel: painLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(painLevel),
      mood: mood == null && nullToAbsent ? const Value.absent() : Value(mood),
      symptoms: symptoms == null && nullToAbsent
          ? const Value.absent()
          : Value(symptoms),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      weightKg: weightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(weightKg),
      sexualActivity: Value(sexualActivity),
      isPeriodDay: Value(isPeriodDay),
      bloodColor: bloodColor == null && nullToAbsent
          ? const Value.absent()
          : Value(bloodColor),
      sleepHours: sleepHours == null && nullToAbsent
          ? const Value.absent()
          : Value(sleepHours),
      cycleId: cycleId == null && nullToAbsent
          ? const Value.absent()
          : Value(cycleId),
      updatedAt: Value(updatedAt),
    );
  }

  factory DailyRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyRecord(
      date: serializer.fromJson<DateTime>(json['date']),
      flowLevel: serializer.fromJson<int?>(json['flowLevel']),
      painLevel: serializer.fromJson<int?>(json['painLevel']),
      mood: serializer.fromJson<String?>(json['mood']),
      symptoms: serializer.fromJson<String?>(json['symptoms']),
      note: serializer.fromJson<String?>(json['note']),
      weightKg: serializer.fromJson<double?>(json['weightKg']),
      sexualActivity: serializer.fromJson<bool>(json['sexualActivity']),
      isPeriodDay: serializer.fromJson<bool>(json['isPeriodDay']),
      bloodColor: serializer.fromJson<String?>(json['bloodColor']),
      sleepHours: serializer.fromJson<double?>(json['sleepHours']),
      cycleId: serializer.fromJson<int?>(json['cycleId']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<DateTime>(date),
      'flowLevel': serializer.toJson<int?>(flowLevel),
      'painLevel': serializer.toJson<int?>(painLevel),
      'mood': serializer.toJson<String?>(mood),
      'symptoms': serializer.toJson<String?>(symptoms),
      'note': serializer.toJson<String?>(note),
      'weightKg': serializer.toJson<double?>(weightKg),
      'sexualActivity': serializer.toJson<bool>(sexualActivity),
      'isPeriodDay': serializer.toJson<bool>(isPeriodDay),
      'bloodColor': serializer.toJson<String?>(bloodColor),
      'sleepHours': serializer.toJson<double?>(sleepHours),
      'cycleId': serializer.toJson<int?>(cycleId),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DailyRecord copyWith(
          {DateTime? date,
          Value<int?> flowLevel = const Value.absent(),
          Value<int?> painLevel = const Value.absent(),
          Value<String?> mood = const Value.absent(),
          Value<String?> symptoms = const Value.absent(),
          Value<String?> note = const Value.absent(),
          Value<double?> weightKg = const Value.absent(),
          bool? sexualActivity,
          bool? isPeriodDay,
          Value<String?> bloodColor = const Value.absent(),
          Value<double?> sleepHours = const Value.absent(),
          Value<int?> cycleId = const Value.absent(),
          DateTime? updatedAt}) =>
      DailyRecord(
        date: date ?? this.date,
        flowLevel: flowLevel.present ? flowLevel.value : this.flowLevel,
        painLevel: painLevel.present ? painLevel.value : this.painLevel,
        mood: mood.present ? mood.value : this.mood,
        symptoms: symptoms.present ? symptoms.value : this.symptoms,
        note: note.present ? note.value : this.note,
        weightKg: weightKg.present ? weightKg.value : this.weightKg,
        sexualActivity: sexualActivity ?? this.sexualActivity,
        isPeriodDay: isPeriodDay ?? this.isPeriodDay,
        bloodColor: bloodColor.present ? bloodColor.value : this.bloodColor,
        sleepHours: sleepHours.present ? sleepHours.value : this.sleepHours,
        cycleId: cycleId.present ? cycleId.value : this.cycleId,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  DailyRecord copyWithCompanion(DailyRecordsCompanion data) {
    return DailyRecord(
      date: data.date.present ? data.date.value : this.date,
      flowLevel: data.flowLevel.present ? data.flowLevel.value : this.flowLevel,
      painLevel: data.painLevel.present ? data.painLevel.value : this.painLevel,
      mood: data.mood.present ? data.mood.value : this.mood,
      symptoms: data.symptoms.present ? data.symptoms.value : this.symptoms,
      note: data.note.present ? data.note.value : this.note,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      sexualActivity: data.sexualActivity.present
          ? data.sexualActivity.value
          : this.sexualActivity,
      isPeriodDay:
          data.isPeriodDay.present ? data.isPeriodDay.value : this.isPeriodDay,
      bloodColor:
          data.bloodColor.present ? data.bloodColor.value : this.bloodColor,
      sleepHours:
          data.sleepHours.present ? data.sleepHours.value : this.sleepHours,
      cycleId: data.cycleId.present ? data.cycleId.value : this.cycleId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyRecord(')
          ..write('date: $date, ')
          ..write('flowLevel: $flowLevel, ')
          ..write('painLevel: $painLevel, ')
          ..write('mood: $mood, ')
          ..write('symptoms: $symptoms, ')
          ..write('note: $note, ')
          ..write('weightKg: $weightKg, ')
          ..write('sexualActivity: $sexualActivity, ')
          ..write('isPeriodDay: $isPeriodDay, ')
          ..write('bloodColor: $bloodColor, ')
          ..write('sleepHours: $sleepHours, ')
          ..write('cycleId: $cycleId, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      date,
      flowLevel,
      painLevel,
      mood,
      symptoms,
      note,
      weightKg,
      sexualActivity,
      isPeriodDay,
      bloodColor,
      sleepHours,
      cycleId,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyRecord &&
          other.date == this.date &&
          other.flowLevel == this.flowLevel &&
          other.painLevel == this.painLevel &&
          other.mood == this.mood &&
          other.symptoms == this.symptoms &&
          other.note == this.note &&
          other.weightKg == this.weightKg &&
          other.sexualActivity == this.sexualActivity &&
          other.isPeriodDay == this.isPeriodDay &&
          other.bloodColor == this.bloodColor &&
          other.sleepHours == this.sleepHours &&
          other.cycleId == this.cycleId &&
          other.updatedAt == this.updatedAt);
}

class DailyRecordsCompanion extends UpdateCompanion<DailyRecord> {
  final Value<DateTime> date;
  final Value<int?> flowLevel;
  final Value<int?> painLevel;
  final Value<String?> mood;
  final Value<String?> symptoms;
  final Value<String?> note;
  final Value<double?> weightKg;
  final Value<bool> sexualActivity;
  final Value<bool> isPeriodDay;
  final Value<String?> bloodColor;
  final Value<double?> sleepHours;
  final Value<int?> cycleId;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DailyRecordsCompanion({
    this.date = const Value.absent(),
    this.flowLevel = const Value.absent(),
    this.painLevel = const Value.absent(),
    this.mood = const Value.absent(),
    this.symptoms = const Value.absent(),
    this.note = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.sexualActivity = const Value.absent(),
    this.isPeriodDay = const Value.absent(),
    this.bloodColor = const Value.absent(),
    this.sleepHours = const Value.absent(),
    this.cycleId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyRecordsCompanion.insert({
    required DateTime date,
    this.flowLevel = const Value.absent(),
    this.painLevel = const Value.absent(),
    this.mood = const Value.absent(),
    this.symptoms = const Value.absent(),
    this.note = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.sexualActivity = const Value.absent(),
    this.isPeriodDay = const Value.absent(),
    this.bloodColor = const Value.absent(),
    this.sleepHours = const Value.absent(),
    this.cycleId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : date = Value(date);
  static Insertable<DailyRecord> custom({
    Expression<DateTime>? date,
    Expression<int>? flowLevel,
    Expression<int>? painLevel,
    Expression<String>? mood,
    Expression<String>? symptoms,
    Expression<String>? note,
    Expression<double>? weightKg,
    Expression<bool>? sexualActivity,
    Expression<bool>? isPeriodDay,
    Expression<String>? bloodColor,
    Expression<double>? sleepHours,
    Expression<int>? cycleId,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (flowLevel != null) 'flow_level': flowLevel,
      if (painLevel != null) 'pain_level': painLevel,
      if (mood != null) 'mood': mood,
      if (symptoms != null) 'symptoms': symptoms,
      if (note != null) 'note': note,
      if (weightKg != null) 'weight_kg': weightKg,
      if (sexualActivity != null) 'sexual_activity': sexualActivity,
      if (isPeriodDay != null) 'is_period_day': isPeriodDay,
      if (bloodColor != null) 'blood_color': bloodColor,
      if (sleepHours != null) 'sleep_hours': sleepHours,
      if (cycleId != null) 'cycle_id': cycleId,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyRecordsCompanion copyWith(
      {Value<DateTime>? date,
      Value<int?>? flowLevel,
      Value<int?>? painLevel,
      Value<String?>? mood,
      Value<String?>? symptoms,
      Value<String?>? note,
      Value<double?>? weightKg,
      Value<bool>? sexualActivity,
      Value<bool>? isPeriodDay,
      Value<String?>? bloodColor,
      Value<double?>? sleepHours,
      Value<int?>? cycleId,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return DailyRecordsCompanion(
      date: date ?? this.date,
      flowLevel: flowLevel ?? this.flowLevel,
      painLevel: painLevel ?? this.painLevel,
      mood: mood ?? this.mood,
      symptoms: symptoms ?? this.symptoms,
      note: note ?? this.note,
      weightKg: weightKg ?? this.weightKg,
      sexualActivity: sexualActivity ?? this.sexualActivity,
      isPeriodDay: isPeriodDay ?? this.isPeriodDay,
      bloodColor: bloodColor ?? this.bloodColor,
      sleepHours: sleepHours ?? this.sleepHours,
      cycleId: cycleId ?? this.cycleId,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (flowLevel.present) {
      map['flow_level'] = Variable<int>(flowLevel.value);
    }
    if (painLevel.present) {
      map['pain_level'] = Variable<int>(painLevel.value);
    }
    if (mood.present) {
      map['mood'] = Variable<String>(mood.value);
    }
    if (symptoms.present) {
      map['symptoms'] = Variable<String>(symptoms.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (sexualActivity.present) {
      map['sexual_activity'] = Variable<bool>(sexualActivity.value);
    }
    if (isPeriodDay.present) {
      map['is_period_day'] = Variable<bool>(isPeriodDay.value);
    }
    if (bloodColor.present) {
      map['blood_color'] = Variable<String>(bloodColor.value);
    }
    if (sleepHours.present) {
      map['sleep_hours'] = Variable<double>(sleepHours.value);
    }
    if (cycleId.present) {
      map['cycle_id'] = Variable<int>(cycleId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyRecordsCompanion(')
          ..write('date: $date, ')
          ..write('flowLevel: $flowLevel, ')
          ..write('painLevel: $painLevel, ')
          ..write('mood: $mood, ')
          ..write('symptoms: $symptoms, ')
          ..write('note: $note, ')
          ..write('weightKg: $weightKg, ')
          ..write('sexualActivity: $sexualActivity, ')
          ..write('isPeriodDay: $isPeriodDay, ')
          ..write('bloodColor: $bloodColor, ')
          ..write('sleepHours: $sleepHours, ')
          ..write('cycleId: $cycleId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PredictionCachesTable extends PredictionCaches
    with TableInfo<$PredictionCachesTable, PredictionCache> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PredictionCachesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _predictedPeriodStartMeta =
      const VerificationMeta('predictedPeriodStart');
  @override
  late final GeneratedColumn<DateTime> predictedPeriodStart =
      GeneratedColumn<DateTime>('predicted_period_start', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _predictedPeriodEndMeta =
      const VerificationMeta('predictedPeriodEnd');
  @override
  late final GeneratedColumn<DateTime> predictedPeriodEnd =
      GeneratedColumn<DateTime>('predicted_period_end', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _predictedOvulationDateMeta =
      const VerificationMeta('predictedOvulationDate');
  @override
  late final GeneratedColumn<DateTime> predictedOvulationDate =
      GeneratedColumn<DateTime>('predicted_ovulation_date', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _fertileStartMeta =
      const VerificationMeta('fertileStart');
  @override
  late final GeneratedColumn<DateTime> fertileStart = GeneratedColumn<DateTime>(
      'fertile_start', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _fertileEndMeta =
      const VerificationMeta('fertileEnd');
  @override
  late final GeneratedColumn<DateTime> fertileEnd = GeneratedColumn<DateTime>(
      'fertile_end', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _confidenceLevelMeta =
      const VerificationMeta('confidenceLevel');
  @override
  late final GeneratedColumn<int> confidenceLevel = GeneratedColumn<int>(
      'confidence_level', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _basedOnCyclesMeta =
      const VerificationMeta('basedOnCycles');
  @override
  late final GeneratedColumn<int> basedOnCycles = GeneratedColumn<int>(
      'based_on_cycles', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _generatedAtMeta =
      const VerificationMeta('generatedAt');
  @override
  late final GeneratedColumn<DateTime> generatedAt = GeneratedColumn<DateTime>(
      'generated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        predictedPeriodStart,
        predictedPeriodEnd,
        predictedOvulationDate,
        fertileStart,
        fertileEnd,
        confidenceLevel,
        basedOnCycles,
        generatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prediction_caches';
  @override
  VerificationContext validateIntegrity(Insertable<PredictionCache> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('predicted_period_start')) {
      context.handle(
          _predictedPeriodStartMeta,
          predictedPeriodStart.isAcceptableOrUnknown(
              data['predicted_period_start']!, _predictedPeriodStartMeta));
    } else if (isInserting) {
      context.missing(_predictedPeriodStartMeta);
    }
    if (data.containsKey('predicted_period_end')) {
      context.handle(
          _predictedPeriodEndMeta,
          predictedPeriodEnd.isAcceptableOrUnknown(
              data['predicted_period_end']!, _predictedPeriodEndMeta));
    } else if (isInserting) {
      context.missing(_predictedPeriodEndMeta);
    }
    if (data.containsKey('predicted_ovulation_date')) {
      context.handle(
          _predictedOvulationDateMeta,
          predictedOvulationDate.isAcceptableOrUnknown(
              data['predicted_ovulation_date']!, _predictedOvulationDateMeta));
    }
    if (data.containsKey('fertile_start')) {
      context.handle(
          _fertileStartMeta,
          fertileStart.isAcceptableOrUnknown(
              data['fertile_start']!, _fertileStartMeta));
    }
    if (data.containsKey('fertile_end')) {
      context.handle(
          _fertileEndMeta,
          fertileEnd.isAcceptableOrUnknown(
              data['fertile_end']!, _fertileEndMeta));
    }
    if (data.containsKey('confidence_level')) {
      context.handle(
          _confidenceLevelMeta,
          confidenceLevel.isAcceptableOrUnknown(
              data['confidence_level']!, _confidenceLevelMeta));
    } else if (isInserting) {
      context.missing(_confidenceLevelMeta);
    }
    if (data.containsKey('based_on_cycles')) {
      context.handle(
          _basedOnCyclesMeta,
          basedOnCycles.isAcceptableOrUnknown(
              data['based_on_cycles']!, _basedOnCyclesMeta));
    } else if (isInserting) {
      context.missing(_basedOnCyclesMeta);
    }
    if (data.containsKey('generated_at')) {
      context.handle(
          _generatedAtMeta,
          generatedAt.isAcceptableOrUnknown(
              data['generated_at']!, _generatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PredictionCache map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PredictionCache(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      predictedPeriodStart: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}predicted_period_start'])!,
      predictedPeriodEnd: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}predicted_period_end'])!,
      predictedOvulationDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}predicted_ovulation_date']),
      fertileStart: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}fertile_start']),
      fertileEnd: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}fertile_end']),
      confidenceLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}confidence_level'])!,
      basedOnCycles: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}based_on_cycles'])!,
      generatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}generated_at'])!,
    );
  }

  @override
  $PredictionCachesTable createAlias(String alias) {
    return $PredictionCachesTable(attachedDatabase, alias);
  }
}

class PredictionCache extends DataClass implements Insertable<PredictionCache> {
  final int id;
  final DateTime predictedPeriodStart;
  final DateTime predictedPeriodEnd;
  final DateTime? predictedOvulationDate;
  final DateTime? fertileStart;
  final DateTime? fertileEnd;

  /// 置信度 0–100。样本越少、波动越大，值越低。
  final int confidenceLevel;

  /// 本次预测基于多少个历史周期。
  final int basedOnCycles;
  final DateTime generatedAt;
  const PredictionCache(
      {required this.id,
      required this.predictedPeriodStart,
      required this.predictedPeriodEnd,
      this.predictedOvulationDate,
      this.fertileStart,
      this.fertileEnd,
      required this.confidenceLevel,
      required this.basedOnCycles,
      required this.generatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['predicted_period_start'] = Variable<DateTime>(predictedPeriodStart);
    map['predicted_period_end'] = Variable<DateTime>(predictedPeriodEnd);
    if (!nullToAbsent || predictedOvulationDate != null) {
      map['predicted_ovulation_date'] =
          Variable<DateTime>(predictedOvulationDate);
    }
    if (!nullToAbsent || fertileStart != null) {
      map['fertile_start'] = Variable<DateTime>(fertileStart);
    }
    if (!nullToAbsent || fertileEnd != null) {
      map['fertile_end'] = Variable<DateTime>(fertileEnd);
    }
    map['confidence_level'] = Variable<int>(confidenceLevel);
    map['based_on_cycles'] = Variable<int>(basedOnCycles);
    map['generated_at'] = Variable<DateTime>(generatedAt);
    return map;
  }

  PredictionCachesCompanion toCompanion(bool nullToAbsent) {
    return PredictionCachesCompanion(
      id: Value(id),
      predictedPeriodStart: Value(predictedPeriodStart),
      predictedPeriodEnd: Value(predictedPeriodEnd),
      predictedOvulationDate: predictedOvulationDate == null && nullToAbsent
          ? const Value.absent()
          : Value(predictedOvulationDate),
      fertileStart: fertileStart == null && nullToAbsent
          ? const Value.absent()
          : Value(fertileStart),
      fertileEnd: fertileEnd == null && nullToAbsent
          ? const Value.absent()
          : Value(fertileEnd),
      confidenceLevel: Value(confidenceLevel),
      basedOnCycles: Value(basedOnCycles),
      generatedAt: Value(generatedAt),
    );
  }

  factory PredictionCache.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PredictionCache(
      id: serializer.fromJson<int>(json['id']),
      predictedPeriodStart:
          serializer.fromJson<DateTime>(json['predictedPeriodStart']),
      predictedPeriodEnd:
          serializer.fromJson<DateTime>(json['predictedPeriodEnd']),
      predictedOvulationDate:
          serializer.fromJson<DateTime?>(json['predictedOvulationDate']),
      fertileStart: serializer.fromJson<DateTime?>(json['fertileStart']),
      fertileEnd: serializer.fromJson<DateTime?>(json['fertileEnd']),
      confidenceLevel: serializer.fromJson<int>(json['confidenceLevel']),
      basedOnCycles: serializer.fromJson<int>(json['basedOnCycles']),
      generatedAt: serializer.fromJson<DateTime>(json['generatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'predictedPeriodStart': serializer.toJson<DateTime>(predictedPeriodStart),
      'predictedPeriodEnd': serializer.toJson<DateTime>(predictedPeriodEnd),
      'predictedOvulationDate':
          serializer.toJson<DateTime?>(predictedOvulationDate),
      'fertileStart': serializer.toJson<DateTime?>(fertileStart),
      'fertileEnd': serializer.toJson<DateTime?>(fertileEnd),
      'confidenceLevel': serializer.toJson<int>(confidenceLevel),
      'basedOnCycles': serializer.toJson<int>(basedOnCycles),
      'generatedAt': serializer.toJson<DateTime>(generatedAt),
    };
  }

  PredictionCache copyWith(
          {int? id,
          DateTime? predictedPeriodStart,
          DateTime? predictedPeriodEnd,
          Value<DateTime?> predictedOvulationDate = const Value.absent(),
          Value<DateTime?> fertileStart = const Value.absent(),
          Value<DateTime?> fertileEnd = const Value.absent(),
          int? confidenceLevel,
          int? basedOnCycles,
          DateTime? generatedAt}) =>
      PredictionCache(
        id: id ?? this.id,
        predictedPeriodStart: predictedPeriodStart ?? this.predictedPeriodStart,
        predictedPeriodEnd: predictedPeriodEnd ?? this.predictedPeriodEnd,
        predictedOvulationDate: predictedOvulationDate.present
            ? predictedOvulationDate.value
            : this.predictedOvulationDate,
        fertileStart:
            fertileStart.present ? fertileStart.value : this.fertileStart,
        fertileEnd: fertileEnd.present ? fertileEnd.value : this.fertileEnd,
        confidenceLevel: confidenceLevel ?? this.confidenceLevel,
        basedOnCycles: basedOnCycles ?? this.basedOnCycles,
        generatedAt: generatedAt ?? this.generatedAt,
      );
  PredictionCache copyWithCompanion(PredictionCachesCompanion data) {
    return PredictionCache(
      id: data.id.present ? data.id.value : this.id,
      predictedPeriodStart: data.predictedPeriodStart.present
          ? data.predictedPeriodStart.value
          : this.predictedPeriodStart,
      predictedPeriodEnd: data.predictedPeriodEnd.present
          ? data.predictedPeriodEnd.value
          : this.predictedPeriodEnd,
      predictedOvulationDate: data.predictedOvulationDate.present
          ? data.predictedOvulationDate.value
          : this.predictedOvulationDate,
      fertileStart: data.fertileStart.present
          ? data.fertileStart.value
          : this.fertileStart,
      fertileEnd:
          data.fertileEnd.present ? data.fertileEnd.value : this.fertileEnd,
      confidenceLevel: data.confidenceLevel.present
          ? data.confidenceLevel.value
          : this.confidenceLevel,
      basedOnCycles: data.basedOnCycles.present
          ? data.basedOnCycles.value
          : this.basedOnCycles,
      generatedAt:
          data.generatedAt.present ? data.generatedAt.value : this.generatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PredictionCache(')
          ..write('id: $id, ')
          ..write('predictedPeriodStart: $predictedPeriodStart, ')
          ..write('predictedPeriodEnd: $predictedPeriodEnd, ')
          ..write('predictedOvulationDate: $predictedOvulationDate, ')
          ..write('fertileStart: $fertileStart, ')
          ..write('fertileEnd: $fertileEnd, ')
          ..write('confidenceLevel: $confidenceLevel, ')
          ..write('basedOnCycles: $basedOnCycles, ')
          ..write('generatedAt: $generatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      predictedPeriodStart,
      predictedPeriodEnd,
      predictedOvulationDate,
      fertileStart,
      fertileEnd,
      confidenceLevel,
      basedOnCycles,
      generatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PredictionCache &&
          other.id == this.id &&
          other.predictedPeriodStart == this.predictedPeriodStart &&
          other.predictedPeriodEnd == this.predictedPeriodEnd &&
          other.predictedOvulationDate == this.predictedOvulationDate &&
          other.fertileStart == this.fertileStart &&
          other.fertileEnd == this.fertileEnd &&
          other.confidenceLevel == this.confidenceLevel &&
          other.basedOnCycles == this.basedOnCycles &&
          other.generatedAt == this.generatedAt);
}

class PredictionCachesCompanion extends UpdateCompanion<PredictionCache> {
  final Value<int> id;
  final Value<DateTime> predictedPeriodStart;
  final Value<DateTime> predictedPeriodEnd;
  final Value<DateTime?> predictedOvulationDate;
  final Value<DateTime?> fertileStart;
  final Value<DateTime?> fertileEnd;
  final Value<int> confidenceLevel;
  final Value<int> basedOnCycles;
  final Value<DateTime> generatedAt;
  const PredictionCachesCompanion({
    this.id = const Value.absent(),
    this.predictedPeriodStart = const Value.absent(),
    this.predictedPeriodEnd = const Value.absent(),
    this.predictedOvulationDate = const Value.absent(),
    this.fertileStart = const Value.absent(),
    this.fertileEnd = const Value.absent(),
    this.confidenceLevel = const Value.absent(),
    this.basedOnCycles = const Value.absent(),
    this.generatedAt = const Value.absent(),
  });
  PredictionCachesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime predictedPeriodStart,
    required DateTime predictedPeriodEnd,
    this.predictedOvulationDate = const Value.absent(),
    this.fertileStart = const Value.absent(),
    this.fertileEnd = const Value.absent(),
    required int confidenceLevel,
    required int basedOnCycles,
    this.generatedAt = const Value.absent(),
  })  : predictedPeriodStart = Value(predictedPeriodStart),
        predictedPeriodEnd = Value(predictedPeriodEnd),
        confidenceLevel = Value(confidenceLevel),
        basedOnCycles = Value(basedOnCycles);
  static Insertable<PredictionCache> custom({
    Expression<int>? id,
    Expression<DateTime>? predictedPeriodStart,
    Expression<DateTime>? predictedPeriodEnd,
    Expression<DateTime>? predictedOvulationDate,
    Expression<DateTime>? fertileStart,
    Expression<DateTime>? fertileEnd,
    Expression<int>? confidenceLevel,
    Expression<int>? basedOnCycles,
    Expression<DateTime>? generatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (predictedPeriodStart != null)
        'predicted_period_start': predictedPeriodStart,
      if (predictedPeriodEnd != null)
        'predicted_period_end': predictedPeriodEnd,
      if (predictedOvulationDate != null)
        'predicted_ovulation_date': predictedOvulationDate,
      if (fertileStart != null) 'fertile_start': fertileStart,
      if (fertileEnd != null) 'fertile_end': fertileEnd,
      if (confidenceLevel != null) 'confidence_level': confidenceLevel,
      if (basedOnCycles != null) 'based_on_cycles': basedOnCycles,
      if (generatedAt != null) 'generated_at': generatedAt,
    });
  }

  PredictionCachesCompanion copyWith(
      {Value<int>? id,
      Value<DateTime>? predictedPeriodStart,
      Value<DateTime>? predictedPeriodEnd,
      Value<DateTime?>? predictedOvulationDate,
      Value<DateTime?>? fertileStart,
      Value<DateTime?>? fertileEnd,
      Value<int>? confidenceLevel,
      Value<int>? basedOnCycles,
      Value<DateTime>? generatedAt}) {
    return PredictionCachesCompanion(
      id: id ?? this.id,
      predictedPeriodStart: predictedPeriodStart ?? this.predictedPeriodStart,
      predictedPeriodEnd: predictedPeriodEnd ?? this.predictedPeriodEnd,
      predictedOvulationDate:
          predictedOvulationDate ?? this.predictedOvulationDate,
      fertileStart: fertileStart ?? this.fertileStart,
      fertileEnd: fertileEnd ?? this.fertileEnd,
      confidenceLevel: confidenceLevel ?? this.confidenceLevel,
      basedOnCycles: basedOnCycles ?? this.basedOnCycles,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (predictedPeriodStart.present) {
      map['predicted_period_start'] =
          Variable<DateTime>(predictedPeriodStart.value);
    }
    if (predictedPeriodEnd.present) {
      map['predicted_period_end'] =
          Variable<DateTime>(predictedPeriodEnd.value);
    }
    if (predictedOvulationDate.present) {
      map['predicted_ovulation_date'] =
          Variable<DateTime>(predictedOvulationDate.value);
    }
    if (fertileStart.present) {
      map['fertile_start'] = Variable<DateTime>(fertileStart.value);
    }
    if (fertileEnd.present) {
      map['fertile_end'] = Variable<DateTime>(fertileEnd.value);
    }
    if (confidenceLevel.present) {
      map['confidence_level'] = Variable<int>(confidenceLevel.value);
    }
    if (basedOnCycles.present) {
      map['based_on_cycles'] = Variable<int>(basedOnCycles.value);
    }
    if (generatedAt.present) {
      map['generated_at'] = Variable<DateTime>(generatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PredictionCachesCompanion(')
          ..write('id: $id, ')
          ..write('predictedPeriodStart: $predictedPeriodStart, ')
          ..write('predictedPeriodEnd: $predictedPeriodEnd, ')
          ..write('predictedOvulationDate: $predictedOvulationDate, ')
          ..write('fertileStart: $fertileStart, ')
          ..write('fertileEnd: $fertileEnd, ')
          ..write('confidenceLevel: $confidenceLevel, ')
          ..write('basedOnCycles: $basedOnCycles, ')
          ..write('generatedAt: $generatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $WeightLogsTable weightLogs = $WeightLogsTable(this);
  late final $ExerciseLogsTable exerciseLogs = $ExerciseLogsTable(this);
  late final $MealLogsTable mealLogs = $MealLogsTable(this);
  late final $BodyProfilesTable bodyProfiles = $BodyProfilesTable(this);
  late final $CalorieBudgetsTable calorieBudgets = $CalorieBudgetsTable(this);
  late final $CustomFoodsTable customFoods = $CustomFoodsTable(this);
  late final $PeriodCyclesTable periodCycles = $PeriodCyclesTable(this);
  late final $DailyRecordsTable dailyRecords = $DailyRecordsTable(this);
  late final $PredictionCachesTable predictionCaches =
      $PredictionCachesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        weightLogs,
        exerciseLogs,
        mealLogs,
        bodyProfiles,
        calorieBudgets,
        customFoods,
        periodCycles,
        dailyRecords,
        predictionCaches
      ];
}

typedef $$WeightLogsTableCreateCompanionBuilder = WeightLogsCompanion Function({
  Value<int> id,
  required DateTime recordedAt,
  required double weightKg,
  Value<double?> bodyFatPercent,
  Value<String> note,
  Value<DateTime> createdAt,
});
typedef $$WeightLogsTableUpdateCompanionBuilder = WeightLogsCompanion Function({
  Value<int> id,
  Value<DateTime> recordedAt,
  Value<double> weightKg,
  Value<double?> bodyFatPercent,
  Value<String> note,
  Value<DateTime> createdAt,
});

class $$WeightLogsTableFilterComposer
    extends Composer<_$AppDatabase, $WeightLogsTable> {
  $$WeightLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get weightKg => $composableBuilder(
      column: $table.weightKg, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get bodyFatPercent => $composableBuilder(
      column: $table.bodyFatPercent,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$WeightLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $WeightLogsTable> {
  $$WeightLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get weightKg => $composableBuilder(
      column: $table.weightKg, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get bodyFatPercent => $composableBuilder(
      column: $table.bodyFatPercent,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$WeightLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeightLogsTable> {
  $$WeightLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => column);

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<double> get bodyFatPercent => $composableBuilder(
      column: $table.bodyFatPercent, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$WeightLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WeightLogsTable,
    WeightLog,
    $$WeightLogsTableFilterComposer,
    $$WeightLogsTableOrderingComposer,
    $$WeightLogsTableAnnotationComposer,
    $$WeightLogsTableCreateCompanionBuilder,
    $$WeightLogsTableUpdateCompanionBuilder,
    (WeightLog, BaseReferences<_$AppDatabase, $WeightLogsTable, WeightLog>),
    WeightLog,
    PrefetchHooks Function()> {
  $$WeightLogsTableTableManager(_$AppDatabase db, $WeightLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeightLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeightLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeightLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime> recordedAt = const Value.absent(),
            Value<double> weightKg = const Value.absent(),
            Value<double?> bodyFatPercent = const Value.absent(),
            Value<String> note = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              WeightLogsCompanion(
            id: id,
            recordedAt: recordedAt,
            weightKg: weightKg,
            bodyFatPercent: bodyFatPercent,
            note: note,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required DateTime recordedAt,
            required double weightKg,
            Value<double?> bodyFatPercent = const Value.absent(),
            Value<String> note = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              WeightLogsCompanion.insert(
            id: id,
            recordedAt: recordedAt,
            weightKg: weightKg,
            bodyFatPercent: bodyFatPercent,
            note: note,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$WeightLogsTable, WeightLog>(table),
                    BaseReferences<_$AppDatabase, $WeightLogsTable, WeightLog>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$WeightLogsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WeightLogsTable,
    WeightLog,
    $$WeightLogsTableFilterComposer,
    $$WeightLogsTableOrderingComposer,
    $$WeightLogsTableAnnotationComposer,
    $$WeightLogsTableCreateCompanionBuilder,
    $$WeightLogsTableUpdateCompanionBuilder,
    (WeightLog, BaseReferences<_$AppDatabase, $WeightLogsTable, WeightLog>),
    WeightLog,
    PrefetchHooks Function()>;
typedef $$ExerciseLogsTableCreateCompanionBuilder = ExerciseLogsCompanion
    Function({
  Value<int> id,
  required DateTime recordedAt,
  required String exerciseCode,
  required String exerciseName,
  required double met,
  required int minutes,
  required double weightKgAtTime,
  required double kcal,
  Value<String> note,
  Value<DateTime> createdAt,
});
typedef $$ExerciseLogsTableUpdateCompanionBuilder = ExerciseLogsCompanion
    Function({
  Value<int> id,
  Value<DateTime> recordedAt,
  Value<String> exerciseCode,
  Value<String> exerciseName,
  Value<double> met,
  Value<int> minutes,
  Value<double> weightKgAtTime,
  Value<double> kcal,
  Value<String> note,
  Value<DateTime> createdAt,
});

class $$ExerciseLogsTableFilterComposer
    extends Composer<_$AppDatabase, $ExerciseLogsTable> {
  $$ExerciseLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get exerciseCode => $composableBuilder(
      column: $table.exerciseCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get exerciseName => $composableBuilder(
      column: $table.exerciseName, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get met => $composableBuilder(
      column: $table.met, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get minutes => $composableBuilder(
      column: $table.minutes, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get weightKgAtTime => $composableBuilder(
      column: $table.weightKgAtTime,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get kcal => $composableBuilder(
      column: $table.kcal, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$ExerciseLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $ExerciseLogsTable> {
  $$ExerciseLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get exerciseCode => $composableBuilder(
      column: $table.exerciseCode,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get exerciseName => $composableBuilder(
      column: $table.exerciseName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get met => $composableBuilder(
      column: $table.met, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get minutes => $composableBuilder(
      column: $table.minutes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get weightKgAtTime => $composableBuilder(
      column: $table.weightKgAtTime,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get kcal => $composableBuilder(
      column: $table.kcal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$ExerciseLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExerciseLogsTable> {
  $$ExerciseLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => column);

  GeneratedColumn<String> get exerciseCode => $composableBuilder(
      column: $table.exerciseCode, builder: (column) => column);

  GeneratedColumn<String> get exerciseName => $composableBuilder(
      column: $table.exerciseName, builder: (column) => column);

  GeneratedColumn<double> get met =>
      $composableBuilder(column: $table.met, builder: (column) => column);

  GeneratedColumn<int> get minutes =>
      $composableBuilder(column: $table.minutes, builder: (column) => column);

  GeneratedColumn<double> get weightKgAtTime => $composableBuilder(
      column: $table.weightKgAtTime, builder: (column) => column);

  GeneratedColumn<double> get kcal =>
      $composableBuilder(column: $table.kcal, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ExerciseLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ExerciseLogsTable,
    ExerciseLog,
    $$ExerciseLogsTableFilterComposer,
    $$ExerciseLogsTableOrderingComposer,
    $$ExerciseLogsTableAnnotationComposer,
    $$ExerciseLogsTableCreateCompanionBuilder,
    $$ExerciseLogsTableUpdateCompanionBuilder,
    (
      ExerciseLog,
      BaseReferences<_$AppDatabase, $ExerciseLogsTable, ExerciseLog>
    ),
    ExerciseLog,
    PrefetchHooks Function()> {
  $$ExerciseLogsTableTableManager(_$AppDatabase db, $ExerciseLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExerciseLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExerciseLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExerciseLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime> recordedAt = const Value.absent(),
            Value<String> exerciseCode = const Value.absent(),
            Value<String> exerciseName = const Value.absent(),
            Value<double> met = const Value.absent(),
            Value<int> minutes = const Value.absent(),
            Value<double> weightKgAtTime = const Value.absent(),
            Value<double> kcal = const Value.absent(),
            Value<String> note = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              ExerciseLogsCompanion(
            id: id,
            recordedAt: recordedAt,
            exerciseCode: exerciseCode,
            exerciseName: exerciseName,
            met: met,
            minutes: minutes,
            weightKgAtTime: weightKgAtTime,
            kcal: kcal,
            note: note,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required DateTime recordedAt,
            required String exerciseCode,
            required String exerciseName,
            required double met,
            required int minutes,
            required double weightKgAtTime,
            required double kcal,
            Value<String> note = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              ExerciseLogsCompanion.insert(
            id: id,
            recordedAt: recordedAt,
            exerciseCode: exerciseCode,
            exerciseName: exerciseName,
            met: met,
            minutes: minutes,
            weightKgAtTime: weightKgAtTime,
            kcal: kcal,
            note: note,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$ExerciseLogsTable, ExerciseLog>(table),
                    BaseReferences<_$AppDatabase, $ExerciseLogsTable,
                        ExerciseLog>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ExerciseLogsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ExerciseLogsTable,
    ExerciseLog,
    $$ExerciseLogsTableFilterComposer,
    $$ExerciseLogsTableOrderingComposer,
    $$ExerciseLogsTableAnnotationComposer,
    $$ExerciseLogsTableCreateCompanionBuilder,
    $$ExerciseLogsTableUpdateCompanionBuilder,
    (
      ExerciseLog,
      BaseReferences<_$AppDatabase, $ExerciseLogsTable, ExerciseLog>
    ),
    ExerciseLog,
    PrefetchHooks Function()>;
typedef $$MealLogsTableCreateCompanionBuilder = MealLogsCompanion Function({
  Value<int> id,
  required DateTime recordedAt,
  required String mealType,
  required String foodCode,
  required String foodName,
  required double grams,
  required double kcal,
  Value<double> proteinG,
  Value<double> fatG,
  Value<double> carbG,
  Value<DateTime> createdAt,
});
typedef $$MealLogsTableUpdateCompanionBuilder = MealLogsCompanion Function({
  Value<int> id,
  Value<DateTime> recordedAt,
  Value<String> mealType,
  Value<String> foodCode,
  Value<String> foodName,
  Value<double> grams,
  Value<double> kcal,
  Value<double> proteinG,
  Value<double> fatG,
  Value<double> carbG,
  Value<DateTime> createdAt,
});

class $$MealLogsTableFilterComposer
    extends Composer<_$AppDatabase, $MealLogsTable> {
  $$MealLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mealType => $composableBuilder(
      column: $table.mealType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get foodCode => $composableBuilder(
      column: $table.foodCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get foodName => $composableBuilder(
      column: $table.foodName, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get grams => $composableBuilder(
      column: $table.grams, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get kcal => $composableBuilder(
      column: $table.kcal, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get proteinG => $composableBuilder(
      column: $table.proteinG, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get fatG => $composableBuilder(
      column: $table.fatG, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get carbG => $composableBuilder(
      column: $table.carbG, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$MealLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $MealLogsTable> {
  $$MealLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mealType => $composableBuilder(
      column: $table.mealType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get foodCode => $composableBuilder(
      column: $table.foodCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get foodName => $composableBuilder(
      column: $table.foodName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get grams => $composableBuilder(
      column: $table.grams, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get kcal => $composableBuilder(
      column: $table.kcal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get proteinG => $composableBuilder(
      column: $table.proteinG, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get fatG => $composableBuilder(
      column: $table.fatG, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get carbG => $composableBuilder(
      column: $table.carbG, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$MealLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MealLogsTable> {
  $$MealLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => column);

  GeneratedColumn<String> get mealType =>
      $composableBuilder(column: $table.mealType, builder: (column) => column);

  GeneratedColumn<String> get foodCode =>
      $composableBuilder(column: $table.foodCode, builder: (column) => column);

  GeneratedColumn<String> get foodName =>
      $composableBuilder(column: $table.foodName, builder: (column) => column);

  GeneratedColumn<double> get grams =>
      $composableBuilder(column: $table.grams, builder: (column) => column);

  GeneratedColumn<double> get kcal =>
      $composableBuilder(column: $table.kcal, builder: (column) => column);

  GeneratedColumn<double> get proteinG =>
      $composableBuilder(column: $table.proteinG, builder: (column) => column);

  GeneratedColumn<double> get fatG =>
      $composableBuilder(column: $table.fatG, builder: (column) => column);

  GeneratedColumn<double> get carbG =>
      $composableBuilder(column: $table.carbG, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$MealLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MealLogsTable,
    MealLog,
    $$MealLogsTableFilterComposer,
    $$MealLogsTableOrderingComposer,
    $$MealLogsTableAnnotationComposer,
    $$MealLogsTableCreateCompanionBuilder,
    $$MealLogsTableUpdateCompanionBuilder,
    (MealLog, BaseReferences<_$AppDatabase, $MealLogsTable, MealLog>),
    MealLog,
    PrefetchHooks Function()> {
  $$MealLogsTableTableManager(_$AppDatabase db, $MealLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime> recordedAt = const Value.absent(),
            Value<String> mealType = const Value.absent(),
            Value<String> foodCode = const Value.absent(),
            Value<String> foodName = const Value.absent(),
            Value<double> grams = const Value.absent(),
            Value<double> kcal = const Value.absent(),
            Value<double> proteinG = const Value.absent(),
            Value<double> fatG = const Value.absent(),
            Value<double> carbG = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              MealLogsCompanion(
            id: id,
            recordedAt: recordedAt,
            mealType: mealType,
            foodCode: foodCode,
            foodName: foodName,
            grams: grams,
            kcal: kcal,
            proteinG: proteinG,
            fatG: fatG,
            carbG: carbG,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required DateTime recordedAt,
            required String mealType,
            required String foodCode,
            required String foodName,
            required double grams,
            required double kcal,
            Value<double> proteinG = const Value.absent(),
            Value<double> fatG = const Value.absent(),
            Value<double> carbG = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              MealLogsCompanion.insert(
            id: id,
            recordedAt: recordedAt,
            mealType: mealType,
            foodCode: foodCode,
            foodName: foodName,
            grams: grams,
            kcal: kcal,
            proteinG: proteinG,
            fatG: fatG,
            carbG: carbG,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$MealLogsTable, MealLog>(table),
                    BaseReferences<_$AppDatabase, $MealLogsTable, MealLog>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MealLogsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MealLogsTable,
    MealLog,
    $$MealLogsTableFilterComposer,
    $$MealLogsTableOrderingComposer,
    $$MealLogsTableAnnotationComposer,
    $$MealLogsTableCreateCompanionBuilder,
    $$MealLogsTableUpdateCompanionBuilder,
    (MealLog, BaseReferences<_$AppDatabase, $MealLogsTable, MealLog>),
    MealLog,
    PrefetchHooks Function()>;
typedef $$BodyProfilesTableCreateCompanionBuilder = BodyProfilesCompanion
    Function({
  Value<int> id,
  required String sex,
  required int age,
  required double heightCm,
  required double startWeightKg,
  required String activityLevel,
  Value<double?> targetWeightKg,
  Value<String> goal,
  Value<String> pace,
  Value<DateTime> updatedAt,
});
typedef $$BodyProfilesTableUpdateCompanionBuilder = BodyProfilesCompanion
    Function({
  Value<int> id,
  Value<String> sex,
  Value<int> age,
  Value<double> heightCm,
  Value<double> startWeightKg,
  Value<String> activityLevel,
  Value<double?> targetWeightKg,
  Value<String> goal,
  Value<String> pace,
  Value<DateTime> updatedAt,
});

class $$BodyProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $BodyProfilesTable> {
  $$BodyProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sex => $composableBuilder(
      column: $table.sex, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get age => $composableBuilder(
      column: $table.age, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get heightCm => $composableBuilder(
      column: $table.heightCm, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get startWeightKg => $composableBuilder(
      column: $table.startWeightKg, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get activityLevel => $composableBuilder(
      column: $table.activityLevel, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get targetWeightKg => $composableBuilder(
      column: $table.targetWeightKg,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get goal => $composableBuilder(
      column: $table.goal, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pace => $composableBuilder(
      column: $table.pace, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$BodyProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $BodyProfilesTable> {
  $$BodyProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sex => $composableBuilder(
      column: $table.sex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get age => $composableBuilder(
      column: $table.age, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get heightCm => $composableBuilder(
      column: $table.heightCm, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get startWeightKg => $composableBuilder(
      column: $table.startWeightKg,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get activityLevel => $composableBuilder(
      column: $table.activityLevel,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get targetWeightKg => $composableBuilder(
      column: $table.targetWeightKg,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get goal => $composableBuilder(
      column: $table.goal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pace => $composableBuilder(
      column: $table.pace, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$BodyProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BodyProfilesTable> {
  $$BodyProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sex =>
      $composableBuilder(column: $table.sex, builder: (column) => column);

  GeneratedColumn<int> get age =>
      $composableBuilder(column: $table.age, builder: (column) => column);

  GeneratedColumn<double> get heightCm =>
      $composableBuilder(column: $table.heightCm, builder: (column) => column);

  GeneratedColumn<double> get startWeightKg => $composableBuilder(
      column: $table.startWeightKg, builder: (column) => column);

  GeneratedColumn<String> get activityLevel => $composableBuilder(
      column: $table.activityLevel, builder: (column) => column);

  GeneratedColumn<double> get targetWeightKg => $composableBuilder(
      column: $table.targetWeightKg, builder: (column) => column);

  GeneratedColumn<String> get goal =>
      $composableBuilder(column: $table.goal, builder: (column) => column);

  GeneratedColumn<String> get pace =>
      $composableBuilder(column: $table.pace, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$BodyProfilesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BodyProfilesTable,
    BodyProfile,
    $$BodyProfilesTableFilterComposer,
    $$BodyProfilesTableOrderingComposer,
    $$BodyProfilesTableAnnotationComposer,
    $$BodyProfilesTableCreateCompanionBuilder,
    $$BodyProfilesTableUpdateCompanionBuilder,
    (
      BodyProfile,
      BaseReferences<_$AppDatabase, $BodyProfilesTable, BodyProfile>
    ),
    BodyProfile,
    PrefetchHooks Function()> {
  $$BodyProfilesTableTableManager(_$AppDatabase db, $BodyProfilesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BodyProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BodyProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BodyProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> sex = const Value.absent(),
            Value<int> age = const Value.absent(),
            Value<double> heightCm = const Value.absent(),
            Value<double> startWeightKg = const Value.absent(),
            Value<String> activityLevel = const Value.absent(),
            Value<double?> targetWeightKg = const Value.absent(),
            Value<String> goal = const Value.absent(),
            Value<String> pace = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              BodyProfilesCompanion(
            id: id,
            sex: sex,
            age: age,
            heightCm: heightCm,
            startWeightKg: startWeightKg,
            activityLevel: activityLevel,
            targetWeightKg: targetWeightKg,
            goal: goal,
            pace: pace,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String sex,
            required int age,
            required double heightCm,
            required double startWeightKg,
            required String activityLevel,
            Value<double?> targetWeightKg = const Value.absent(),
            Value<String> goal = const Value.absent(),
            Value<String> pace = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              BodyProfilesCompanion.insert(
            id: id,
            sex: sex,
            age: age,
            heightCm: heightCm,
            startWeightKg: startWeightKg,
            activityLevel: activityLevel,
            targetWeightKg: targetWeightKg,
            goal: goal,
            pace: pace,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$BodyProfilesTable, BodyProfile>(table),
                    BaseReferences<_$AppDatabase, $BodyProfilesTable,
                        BodyProfile>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$BodyProfilesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BodyProfilesTable,
    BodyProfile,
    $$BodyProfilesTableFilterComposer,
    $$BodyProfilesTableOrderingComposer,
    $$BodyProfilesTableAnnotationComposer,
    $$BodyProfilesTableCreateCompanionBuilder,
    $$BodyProfilesTableUpdateCompanionBuilder,
    (
      BodyProfile,
      BaseReferences<_$AppDatabase, $BodyProfilesTable, BodyProfile>
    ),
    BodyProfile,
    PrefetchHooks Function()>;
typedef $$CalorieBudgetsTableCreateCompanionBuilder = CalorieBudgetsCompanion
    Function({
  Value<int> id,
  required DateTime date,
  required double bmr,
  required double tdee,
  required double intakeTarget,
  required double proteinG,
  required double fatG,
  required double carbG,
  Value<String> formula,
});
typedef $$CalorieBudgetsTableUpdateCompanionBuilder = CalorieBudgetsCompanion
    Function({
  Value<int> id,
  Value<DateTime> date,
  Value<double> bmr,
  Value<double> tdee,
  Value<double> intakeTarget,
  Value<double> proteinG,
  Value<double> fatG,
  Value<double> carbG,
  Value<String> formula,
});

class $$CalorieBudgetsTableFilterComposer
    extends Composer<_$AppDatabase, $CalorieBudgetsTable> {
  $$CalorieBudgetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get bmr => $composableBuilder(
      column: $table.bmr, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get tdee => $composableBuilder(
      column: $table.tdee, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get intakeTarget => $composableBuilder(
      column: $table.intakeTarget, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get proteinG => $composableBuilder(
      column: $table.proteinG, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get fatG => $composableBuilder(
      column: $table.fatG, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get carbG => $composableBuilder(
      column: $table.carbG, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get formula => $composableBuilder(
      column: $table.formula, builder: (column) => ColumnFilters(column));
}

class $$CalorieBudgetsTableOrderingComposer
    extends Composer<_$AppDatabase, $CalorieBudgetsTable> {
  $$CalorieBudgetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get bmr => $composableBuilder(
      column: $table.bmr, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get tdee => $composableBuilder(
      column: $table.tdee, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get intakeTarget => $composableBuilder(
      column: $table.intakeTarget,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get proteinG => $composableBuilder(
      column: $table.proteinG, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get fatG => $composableBuilder(
      column: $table.fatG, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get carbG => $composableBuilder(
      column: $table.carbG, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get formula => $composableBuilder(
      column: $table.formula, builder: (column) => ColumnOrderings(column));
}

class $$CalorieBudgetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CalorieBudgetsTable> {
  $$CalorieBudgetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get bmr =>
      $composableBuilder(column: $table.bmr, builder: (column) => column);

  GeneratedColumn<double> get tdee =>
      $composableBuilder(column: $table.tdee, builder: (column) => column);

  GeneratedColumn<double> get intakeTarget => $composableBuilder(
      column: $table.intakeTarget, builder: (column) => column);

  GeneratedColumn<double> get proteinG =>
      $composableBuilder(column: $table.proteinG, builder: (column) => column);

  GeneratedColumn<double> get fatG =>
      $composableBuilder(column: $table.fatG, builder: (column) => column);

  GeneratedColumn<double> get carbG =>
      $composableBuilder(column: $table.carbG, builder: (column) => column);

  GeneratedColumn<String> get formula =>
      $composableBuilder(column: $table.formula, builder: (column) => column);
}

class $$CalorieBudgetsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CalorieBudgetsTable,
    CalorieBudgetRow,
    $$CalorieBudgetsTableFilterComposer,
    $$CalorieBudgetsTableOrderingComposer,
    $$CalorieBudgetsTableAnnotationComposer,
    $$CalorieBudgetsTableCreateCompanionBuilder,
    $$CalorieBudgetsTableUpdateCompanionBuilder,
    (
      CalorieBudgetRow,
      BaseReferences<_$AppDatabase, $CalorieBudgetsTable, CalorieBudgetRow>
    ),
    CalorieBudgetRow,
    PrefetchHooks Function()> {
  $$CalorieBudgetsTableTableManager(
      _$AppDatabase db, $CalorieBudgetsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CalorieBudgetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CalorieBudgetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CalorieBudgetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<double> bmr = const Value.absent(),
            Value<double> tdee = const Value.absent(),
            Value<double> intakeTarget = const Value.absent(),
            Value<double> proteinG = const Value.absent(),
            Value<double> fatG = const Value.absent(),
            Value<double> carbG = const Value.absent(),
            Value<String> formula = const Value.absent(),
          }) =>
              CalorieBudgetsCompanion(
            id: id,
            date: date,
            bmr: bmr,
            tdee: tdee,
            intakeTarget: intakeTarget,
            proteinG: proteinG,
            fatG: fatG,
            carbG: carbG,
            formula: formula,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required DateTime date,
            required double bmr,
            required double tdee,
            required double intakeTarget,
            required double proteinG,
            required double fatG,
            required double carbG,
            Value<String> formula = const Value.absent(),
          }) =>
              CalorieBudgetsCompanion.insert(
            id: id,
            date: date,
            bmr: bmr,
            tdee: tdee,
            intakeTarget: intakeTarget,
            proteinG: proteinG,
            fatG: fatG,
            carbG: carbG,
            formula: formula,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$CalorieBudgetsTable, CalorieBudgetRow>(table),
                    BaseReferences<_$AppDatabase, $CalorieBudgetsTable,
                        CalorieBudgetRow>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CalorieBudgetsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CalorieBudgetsTable,
    CalorieBudgetRow,
    $$CalorieBudgetsTableFilterComposer,
    $$CalorieBudgetsTableOrderingComposer,
    $$CalorieBudgetsTableAnnotationComposer,
    $$CalorieBudgetsTableCreateCompanionBuilder,
    $$CalorieBudgetsTableUpdateCompanionBuilder,
    (
      CalorieBudgetRow,
      BaseReferences<_$AppDatabase, $CalorieBudgetsTable, CalorieBudgetRow>
    ),
    CalorieBudgetRow,
    PrefetchHooks Function()>;
typedef $$CustomFoodsTableCreateCompanionBuilder = CustomFoodsCompanion
    Function({
  Value<int> id,
  required String code,
  required String name,
  required double kcalPer100g,
  Value<double> proteinPer100g,
  Value<double> fatPer100g,
  Value<double> carbPer100g,
  Value<double> unitGrams,
  Value<String> unitName,
  Value<String> category,
  Value<DateTime> createdAt,
});
typedef $$CustomFoodsTableUpdateCompanionBuilder = CustomFoodsCompanion
    Function({
  Value<int> id,
  Value<String> code,
  Value<String> name,
  Value<double> kcalPer100g,
  Value<double> proteinPer100g,
  Value<double> fatPer100g,
  Value<double> carbPer100g,
  Value<double> unitGrams,
  Value<String> unitName,
  Value<String> category,
  Value<DateTime> createdAt,
});

class $$CustomFoodsTableFilterComposer
    extends Composer<_$AppDatabase, $CustomFoodsTable> {
  $$CustomFoodsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get kcalPer100g => $composableBuilder(
      column: $table.kcalPer100g, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get proteinPer100g => $composableBuilder(
      column: $table.proteinPer100g,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get fatPer100g => $composableBuilder(
      column: $table.fatPer100g, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get carbPer100g => $composableBuilder(
      column: $table.carbPer100g, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get unitGrams => $composableBuilder(
      column: $table.unitGrams, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unitName => $composableBuilder(
      column: $table.unitName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$CustomFoodsTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomFoodsTable> {
  $$CustomFoodsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get kcalPer100g => $composableBuilder(
      column: $table.kcalPer100g, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get proteinPer100g => $composableBuilder(
      column: $table.proteinPer100g,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get fatPer100g => $composableBuilder(
      column: $table.fatPer100g, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get carbPer100g => $composableBuilder(
      column: $table.carbPer100g, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get unitGrams => $composableBuilder(
      column: $table.unitGrams, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unitName => $composableBuilder(
      column: $table.unitName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$CustomFoodsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomFoodsTable> {
  $$CustomFoodsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get kcalPer100g => $composableBuilder(
      column: $table.kcalPer100g, builder: (column) => column);

  GeneratedColumn<double> get proteinPer100g => $composableBuilder(
      column: $table.proteinPer100g, builder: (column) => column);

  GeneratedColumn<double> get fatPer100g => $composableBuilder(
      column: $table.fatPer100g, builder: (column) => column);

  GeneratedColumn<double> get carbPer100g => $composableBuilder(
      column: $table.carbPer100g, builder: (column) => column);

  GeneratedColumn<double> get unitGrams =>
      $composableBuilder(column: $table.unitGrams, builder: (column) => column);

  GeneratedColumn<String> get unitName =>
      $composableBuilder(column: $table.unitName, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$CustomFoodsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CustomFoodsTable,
    CustomFood,
    $$CustomFoodsTableFilterComposer,
    $$CustomFoodsTableOrderingComposer,
    $$CustomFoodsTableAnnotationComposer,
    $$CustomFoodsTableCreateCompanionBuilder,
    $$CustomFoodsTableUpdateCompanionBuilder,
    (CustomFood, BaseReferences<_$AppDatabase, $CustomFoodsTable, CustomFood>),
    CustomFood,
    PrefetchHooks Function()> {
  $$CustomFoodsTableTableManager(_$AppDatabase db, $CustomFoodsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomFoodsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomFoodsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomFoodsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> code = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<double> kcalPer100g = const Value.absent(),
            Value<double> proteinPer100g = const Value.absent(),
            Value<double> fatPer100g = const Value.absent(),
            Value<double> carbPer100g = const Value.absent(),
            Value<double> unitGrams = const Value.absent(),
            Value<String> unitName = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              CustomFoodsCompanion(
            id: id,
            code: code,
            name: name,
            kcalPer100g: kcalPer100g,
            proteinPer100g: proteinPer100g,
            fatPer100g: fatPer100g,
            carbPer100g: carbPer100g,
            unitGrams: unitGrams,
            unitName: unitName,
            category: category,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String code,
            required String name,
            required double kcalPer100g,
            Value<double> proteinPer100g = const Value.absent(),
            Value<double> fatPer100g = const Value.absent(),
            Value<double> carbPer100g = const Value.absent(),
            Value<double> unitGrams = const Value.absent(),
            Value<String> unitName = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              CustomFoodsCompanion.insert(
            id: id,
            code: code,
            name: name,
            kcalPer100g: kcalPer100g,
            proteinPer100g: proteinPer100g,
            fatPer100g: fatPer100g,
            carbPer100g: carbPer100g,
            unitGrams: unitGrams,
            unitName: unitName,
            category: category,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$CustomFoodsTable, CustomFood>(table),
                    BaseReferences<_$AppDatabase, $CustomFoodsTable,
                        CustomFood>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CustomFoodsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CustomFoodsTable,
    CustomFood,
    $$CustomFoodsTableFilterComposer,
    $$CustomFoodsTableOrderingComposer,
    $$CustomFoodsTableAnnotationComposer,
    $$CustomFoodsTableCreateCompanionBuilder,
    $$CustomFoodsTableUpdateCompanionBuilder,
    (CustomFood, BaseReferences<_$AppDatabase, $CustomFoodsTable, CustomFood>),
    CustomFood,
    PrefetchHooks Function()>;
typedef $$PeriodCyclesTableCreateCompanionBuilder = PeriodCyclesCompanion
    Function({
  Value<int> id,
  required DateTime startDate,
  Value<DateTime?> endDate,
  Value<int?> cycleLength,
  Value<int?> periodLength,
  Value<bool> isClosed,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$PeriodCyclesTableUpdateCompanionBuilder = PeriodCyclesCompanion
    Function({
  Value<int> id,
  Value<DateTime> startDate,
  Value<DateTime?> endDate,
  Value<int?> cycleLength,
  Value<int?> periodLength,
  Value<bool> isClosed,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$PeriodCyclesTableFilterComposer
    extends Composer<_$AppDatabase, $PeriodCyclesTable> {
  $$PeriodCyclesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get cycleLength => $composableBuilder(
      column: $table.cycleLength, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get periodLength => $composableBuilder(
      column: $table.periodLength, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isClosed => $composableBuilder(
      column: $table.isClosed, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$PeriodCyclesTableOrderingComposer
    extends Composer<_$AppDatabase, $PeriodCyclesTable> {
  $$PeriodCyclesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get cycleLength => $composableBuilder(
      column: $table.cycleLength, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get periodLength => $composableBuilder(
      column: $table.periodLength,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isClosed => $composableBuilder(
      column: $table.isClosed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$PeriodCyclesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PeriodCyclesTable> {
  $$PeriodCyclesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<int> get cycleLength => $composableBuilder(
      column: $table.cycleLength, builder: (column) => column);

  GeneratedColumn<int> get periodLength => $composableBuilder(
      column: $table.periodLength, builder: (column) => column);

  GeneratedColumn<bool> get isClosed =>
      $composableBuilder(column: $table.isClosed, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PeriodCyclesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PeriodCyclesTable,
    PeriodCycle,
    $$PeriodCyclesTableFilterComposer,
    $$PeriodCyclesTableOrderingComposer,
    $$PeriodCyclesTableAnnotationComposer,
    $$PeriodCyclesTableCreateCompanionBuilder,
    $$PeriodCyclesTableUpdateCompanionBuilder,
    (
      PeriodCycle,
      BaseReferences<_$AppDatabase, $PeriodCyclesTable, PeriodCycle>
    ),
    PeriodCycle,
    PrefetchHooks Function()> {
  $$PeriodCyclesTableTableManager(_$AppDatabase db, $PeriodCyclesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PeriodCyclesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PeriodCyclesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PeriodCyclesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime> startDate = const Value.absent(),
            Value<DateTime?> endDate = const Value.absent(),
            Value<int?> cycleLength = const Value.absent(),
            Value<int?> periodLength = const Value.absent(),
            Value<bool> isClosed = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              PeriodCyclesCompanion(
            id: id,
            startDate: startDate,
            endDate: endDate,
            cycleLength: cycleLength,
            periodLength: periodLength,
            isClosed: isClosed,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required DateTime startDate,
            Value<DateTime?> endDate = const Value.absent(),
            Value<int?> cycleLength = const Value.absent(),
            Value<int?> periodLength = const Value.absent(),
            Value<bool> isClosed = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              PeriodCyclesCompanion.insert(
            id: id,
            startDate: startDate,
            endDate: endDate,
            cycleLength: cycleLength,
            periodLength: periodLength,
            isClosed: isClosed,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$PeriodCyclesTable, PeriodCycle>(table),
                    BaseReferences<_$AppDatabase, $PeriodCyclesTable,
                        PeriodCycle>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PeriodCyclesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PeriodCyclesTable,
    PeriodCycle,
    $$PeriodCyclesTableFilterComposer,
    $$PeriodCyclesTableOrderingComposer,
    $$PeriodCyclesTableAnnotationComposer,
    $$PeriodCyclesTableCreateCompanionBuilder,
    $$PeriodCyclesTableUpdateCompanionBuilder,
    (
      PeriodCycle,
      BaseReferences<_$AppDatabase, $PeriodCyclesTable, PeriodCycle>
    ),
    PeriodCycle,
    PrefetchHooks Function()>;
typedef $$DailyRecordsTableCreateCompanionBuilder = DailyRecordsCompanion
    Function({
  required DateTime date,
  Value<int?> flowLevel,
  Value<int?> painLevel,
  Value<String?> mood,
  Value<String?> symptoms,
  Value<String?> note,
  Value<double?> weightKg,
  Value<bool> sexualActivity,
  Value<bool> isPeriodDay,
  Value<String?> bloodColor,
  Value<double?> sleepHours,
  Value<int?> cycleId,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$DailyRecordsTableUpdateCompanionBuilder = DailyRecordsCompanion
    Function({
  Value<DateTime> date,
  Value<int?> flowLevel,
  Value<int?> painLevel,
  Value<String?> mood,
  Value<String?> symptoms,
  Value<String?> note,
  Value<double?> weightKg,
  Value<bool> sexualActivity,
  Value<bool> isPeriodDay,
  Value<String?> bloodColor,
  Value<double?> sleepHours,
  Value<int?> cycleId,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$DailyRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $DailyRecordsTable> {
  $$DailyRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get flowLevel => $composableBuilder(
      column: $table.flowLevel, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get painLevel => $composableBuilder(
      column: $table.painLevel, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mood => $composableBuilder(
      column: $table.mood, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get symptoms => $composableBuilder(
      column: $table.symptoms, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get weightKg => $composableBuilder(
      column: $table.weightKg, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get sexualActivity => $composableBuilder(
      column: $table.sexualActivity,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPeriodDay => $composableBuilder(
      column: $table.isPeriodDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bloodColor => $composableBuilder(
      column: $table.bloodColor, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get sleepHours => $composableBuilder(
      column: $table.sleepHours, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get cycleId => $composableBuilder(
      column: $table.cycleId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$DailyRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyRecordsTable> {
  $$DailyRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get flowLevel => $composableBuilder(
      column: $table.flowLevel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get painLevel => $composableBuilder(
      column: $table.painLevel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mood => $composableBuilder(
      column: $table.mood, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get symptoms => $composableBuilder(
      column: $table.symptoms, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get weightKg => $composableBuilder(
      column: $table.weightKg, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get sexualActivity => $composableBuilder(
      column: $table.sexualActivity,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPeriodDay => $composableBuilder(
      column: $table.isPeriodDay, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bloodColor => $composableBuilder(
      column: $table.bloodColor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get sleepHours => $composableBuilder(
      column: $table.sleepHours, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get cycleId => $composableBuilder(
      column: $table.cycleId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$DailyRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyRecordsTable> {
  $$DailyRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get flowLevel =>
      $composableBuilder(column: $table.flowLevel, builder: (column) => column);

  GeneratedColumn<int> get painLevel =>
      $composableBuilder(column: $table.painLevel, builder: (column) => column);

  GeneratedColumn<String> get mood =>
      $composableBuilder(column: $table.mood, builder: (column) => column);

  GeneratedColumn<String> get symptoms =>
      $composableBuilder(column: $table.symptoms, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<bool> get sexualActivity => $composableBuilder(
      column: $table.sexualActivity, builder: (column) => column);

  GeneratedColumn<bool> get isPeriodDay => $composableBuilder(
      column: $table.isPeriodDay, builder: (column) => column);

  GeneratedColumn<String> get bloodColor => $composableBuilder(
      column: $table.bloodColor, builder: (column) => column);

  GeneratedColumn<double> get sleepHours => $composableBuilder(
      column: $table.sleepHours, builder: (column) => column);

  GeneratedColumn<int> get cycleId =>
      $composableBuilder(column: $table.cycleId, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DailyRecordsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DailyRecordsTable,
    DailyRecord,
    $$DailyRecordsTableFilterComposer,
    $$DailyRecordsTableOrderingComposer,
    $$DailyRecordsTableAnnotationComposer,
    $$DailyRecordsTableCreateCompanionBuilder,
    $$DailyRecordsTableUpdateCompanionBuilder,
    (
      DailyRecord,
      BaseReferences<_$AppDatabase, $DailyRecordsTable, DailyRecord>
    ),
    DailyRecord,
    PrefetchHooks Function()> {
  $$DailyRecordsTableTableManager(_$AppDatabase db, $DailyRecordsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<DateTime> date = const Value.absent(),
            Value<int?> flowLevel = const Value.absent(),
            Value<int?> painLevel = const Value.absent(),
            Value<String?> mood = const Value.absent(),
            Value<String?> symptoms = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<double?> weightKg = const Value.absent(),
            Value<bool> sexualActivity = const Value.absent(),
            Value<bool> isPeriodDay = const Value.absent(),
            Value<String?> bloodColor = const Value.absent(),
            Value<double?> sleepHours = const Value.absent(),
            Value<int?> cycleId = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DailyRecordsCompanion(
            date: date,
            flowLevel: flowLevel,
            painLevel: painLevel,
            mood: mood,
            symptoms: symptoms,
            note: note,
            weightKg: weightKg,
            sexualActivity: sexualActivity,
            isPeriodDay: isPeriodDay,
            bloodColor: bloodColor,
            sleepHours: sleepHours,
            cycleId: cycleId,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required DateTime date,
            Value<int?> flowLevel = const Value.absent(),
            Value<int?> painLevel = const Value.absent(),
            Value<String?> mood = const Value.absent(),
            Value<String?> symptoms = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<double?> weightKg = const Value.absent(),
            Value<bool> sexualActivity = const Value.absent(),
            Value<bool> isPeriodDay = const Value.absent(),
            Value<String?> bloodColor = const Value.absent(),
            Value<double?> sleepHours = const Value.absent(),
            Value<int?> cycleId = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DailyRecordsCompanion.insert(
            date: date,
            flowLevel: flowLevel,
            painLevel: painLevel,
            mood: mood,
            symptoms: symptoms,
            note: note,
            weightKg: weightKg,
            sexualActivity: sexualActivity,
            isPeriodDay: isPeriodDay,
            bloodColor: bloodColor,
            sleepHours: sleepHours,
            cycleId: cycleId,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$DailyRecordsTable, DailyRecord>(table),
                    BaseReferences<_$AppDatabase, $DailyRecordsTable,
                        DailyRecord>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DailyRecordsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DailyRecordsTable,
    DailyRecord,
    $$DailyRecordsTableFilterComposer,
    $$DailyRecordsTableOrderingComposer,
    $$DailyRecordsTableAnnotationComposer,
    $$DailyRecordsTableCreateCompanionBuilder,
    $$DailyRecordsTableUpdateCompanionBuilder,
    (
      DailyRecord,
      BaseReferences<_$AppDatabase, $DailyRecordsTable, DailyRecord>
    ),
    DailyRecord,
    PrefetchHooks Function()>;
typedef $$PredictionCachesTableCreateCompanionBuilder
    = PredictionCachesCompanion Function({
  Value<int> id,
  required DateTime predictedPeriodStart,
  required DateTime predictedPeriodEnd,
  Value<DateTime?> predictedOvulationDate,
  Value<DateTime?> fertileStart,
  Value<DateTime?> fertileEnd,
  required int confidenceLevel,
  required int basedOnCycles,
  Value<DateTime> generatedAt,
});
typedef $$PredictionCachesTableUpdateCompanionBuilder
    = PredictionCachesCompanion Function({
  Value<int> id,
  Value<DateTime> predictedPeriodStart,
  Value<DateTime> predictedPeriodEnd,
  Value<DateTime?> predictedOvulationDate,
  Value<DateTime?> fertileStart,
  Value<DateTime?> fertileEnd,
  Value<int> confidenceLevel,
  Value<int> basedOnCycles,
  Value<DateTime> generatedAt,
});

class $$PredictionCachesTableFilterComposer
    extends Composer<_$AppDatabase, $PredictionCachesTable> {
  $$PredictionCachesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get predictedPeriodStart => $composableBuilder(
      column: $table.predictedPeriodStart,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get predictedPeriodEnd => $composableBuilder(
      column: $table.predictedPeriodEnd,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get predictedOvulationDate => $composableBuilder(
      column: $table.predictedOvulationDate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get fertileStart => $composableBuilder(
      column: $table.fertileStart, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get fertileEnd => $composableBuilder(
      column: $table.fertileEnd, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get confidenceLevel => $composableBuilder(
      column: $table.confidenceLevel,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get basedOnCycles => $composableBuilder(
      column: $table.basedOnCycles, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get generatedAt => $composableBuilder(
      column: $table.generatedAt, builder: (column) => ColumnFilters(column));
}

class $$PredictionCachesTableOrderingComposer
    extends Composer<_$AppDatabase, $PredictionCachesTable> {
  $$PredictionCachesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get predictedPeriodStart => $composableBuilder(
      column: $table.predictedPeriodStart,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get predictedPeriodEnd => $composableBuilder(
      column: $table.predictedPeriodEnd,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get predictedOvulationDate => $composableBuilder(
      column: $table.predictedOvulationDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get fertileStart => $composableBuilder(
      column: $table.fertileStart,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get fertileEnd => $composableBuilder(
      column: $table.fertileEnd, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get confidenceLevel => $composableBuilder(
      column: $table.confidenceLevel,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get basedOnCycles => $composableBuilder(
      column: $table.basedOnCycles,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get generatedAt => $composableBuilder(
      column: $table.generatedAt, builder: (column) => ColumnOrderings(column));
}

class $$PredictionCachesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PredictionCachesTable> {
  $$PredictionCachesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get predictedPeriodStart => $composableBuilder(
      column: $table.predictedPeriodStart, builder: (column) => column);

  GeneratedColumn<DateTime> get predictedPeriodEnd => $composableBuilder(
      column: $table.predictedPeriodEnd, builder: (column) => column);

  GeneratedColumn<DateTime> get predictedOvulationDate => $composableBuilder(
      column: $table.predictedOvulationDate, builder: (column) => column);

  GeneratedColumn<DateTime> get fertileStart => $composableBuilder(
      column: $table.fertileStart, builder: (column) => column);

  GeneratedColumn<DateTime> get fertileEnd => $composableBuilder(
      column: $table.fertileEnd, builder: (column) => column);

  GeneratedColumn<int> get confidenceLevel => $composableBuilder(
      column: $table.confidenceLevel, builder: (column) => column);

  GeneratedColumn<int> get basedOnCycles => $composableBuilder(
      column: $table.basedOnCycles, builder: (column) => column);

  GeneratedColumn<DateTime> get generatedAt => $composableBuilder(
      column: $table.generatedAt, builder: (column) => column);
}

class $$PredictionCachesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PredictionCachesTable,
    PredictionCache,
    $$PredictionCachesTableFilterComposer,
    $$PredictionCachesTableOrderingComposer,
    $$PredictionCachesTableAnnotationComposer,
    $$PredictionCachesTableCreateCompanionBuilder,
    $$PredictionCachesTableUpdateCompanionBuilder,
    (
      PredictionCache,
      BaseReferences<_$AppDatabase, $PredictionCachesTable, PredictionCache>
    ),
    PredictionCache,
    PrefetchHooks Function()> {
  $$PredictionCachesTableTableManager(
      _$AppDatabase db, $PredictionCachesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PredictionCachesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PredictionCachesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PredictionCachesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime> predictedPeriodStart = const Value.absent(),
            Value<DateTime> predictedPeriodEnd = const Value.absent(),
            Value<DateTime?> predictedOvulationDate = const Value.absent(),
            Value<DateTime?> fertileStart = const Value.absent(),
            Value<DateTime?> fertileEnd = const Value.absent(),
            Value<int> confidenceLevel = const Value.absent(),
            Value<int> basedOnCycles = const Value.absent(),
            Value<DateTime> generatedAt = const Value.absent(),
          }) =>
              PredictionCachesCompanion(
            id: id,
            predictedPeriodStart: predictedPeriodStart,
            predictedPeriodEnd: predictedPeriodEnd,
            predictedOvulationDate: predictedOvulationDate,
            fertileStart: fertileStart,
            fertileEnd: fertileEnd,
            confidenceLevel: confidenceLevel,
            basedOnCycles: basedOnCycles,
            generatedAt: generatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required DateTime predictedPeriodStart,
            required DateTime predictedPeriodEnd,
            Value<DateTime?> predictedOvulationDate = const Value.absent(),
            Value<DateTime?> fertileStart = const Value.absent(),
            Value<DateTime?> fertileEnd = const Value.absent(),
            required int confidenceLevel,
            required int basedOnCycles,
            Value<DateTime> generatedAt = const Value.absent(),
          }) =>
              PredictionCachesCompanion.insert(
            id: id,
            predictedPeriodStart: predictedPeriodStart,
            predictedPeriodEnd: predictedPeriodEnd,
            predictedOvulationDate: predictedOvulationDate,
            fertileStart: fertileStart,
            fertileEnd: fertileEnd,
            confidenceLevel: confidenceLevel,
            basedOnCycles: basedOnCycles,
            generatedAt: generatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$PredictionCachesTable, PredictionCache>(table),
                    BaseReferences<_$AppDatabase, $PredictionCachesTable,
                        PredictionCache>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PredictionCachesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PredictionCachesTable,
    PredictionCache,
    $$PredictionCachesTableFilterComposer,
    $$PredictionCachesTableOrderingComposer,
    $$PredictionCachesTableAnnotationComposer,
    $$PredictionCachesTableCreateCompanionBuilder,
    $$PredictionCachesTableUpdateCompanionBuilder,
    (
      PredictionCache,
      BaseReferences<_$AppDatabase, $PredictionCachesTable, PredictionCache>
    ),
    PredictionCache,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$WeightLogsTableTableManager get weightLogs =>
      $$WeightLogsTableTableManager(_db, _db.weightLogs);
  $$ExerciseLogsTableTableManager get exerciseLogs =>
      $$ExerciseLogsTableTableManager(_db, _db.exerciseLogs);
  $$MealLogsTableTableManager get mealLogs =>
      $$MealLogsTableTableManager(_db, _db.mealLogs);
  $$BodyProfilesTableTableManager get bodyProfiles =>
      $$BodyProfilesTableTableManager(_db, _db.bodyProfiles);
  $$CalorieBudgetsTableTableManager get calorieBudgets =>
      $$CalorieBudgetsTableTableManager(_db, _db.calorieBudgets);
  $$CustomFoodsTableTableManager get customFoods =>
      $$CustomFoodsTableTableManager(_db, _db.customFoods);
  $$PeriodCyclesTableTableManager get periodCycles =>
      $$PeriodCyclesTableTableManager(_db, _db.periodCycles);
  $$DailyRecordsTableTableManager get dailyRecords =>
      $$DailyRecordsTableTableManager(_db, _db.dailyRecords);
  $$PredictionCachesTableTableManager get predictionCaches =>
      $$PredictionCachesTableTableManager(_db, _db.predictionCaches);
}
