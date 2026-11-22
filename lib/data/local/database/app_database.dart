// lib/data/local/database/app_database.dart
//
// 项目唯一的数据库入口。
//
// 接线方式（INTEGRATION.md §2.5）：
//   openConnection 交给 EncryptedDatabaseOpener，AppDatabase 本身不关心加密细节。
//
// 迁移纪律（AGENTS.md R5 / §9）：
//   · schemaVersion 只增不减
//   · onUpgrade 只允许 createTable / addColumn
//   · 禁止 dropTable / delete / 改列类型
//   · 升级前必须已由 opener 完成备份；失败要打标记并保留备份

import 'package:drift/drift.dart';

import '../../../core/database/db_backup.dart';
import '../../../core/database/encrypted_database_opener.dart';
import '../../../features/period/data/period_tables.dart';
import '../../../features/weight_loss/data/weight_loss_tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    // ---- 减脂模块 ----
    WeightLogs,
    ExerciseLogs,
    MealLogs,
    BodyProfiles,
    CalorieBudgets,
    CustomFoods,
    // ---- 经期模块（v2 新增）----
    PeriodCycles,
    DailyRecords,
    PredictionCaches,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// 迁移版本。**只增不减**；每加一批表就 +1，并在 onUpgrade 里补分支。
  ///
  /// v1: 减脂 5 表
  /// v2: 经期 3 表（PeriodCycles / DailyRecords / PredictionCaches）
  /// v3: 自建食物表（CustomFoods，P2-3）
  /// v4: body_profiles 加 body_fat_percent 列（体脂率 → Katch-McArdle）
  static const int kSchemaVersion = 4;

  /// 生产用：加密开库 + 升级前自动备份。
  AppDatabase()
      : super(EncryptedDatabaseOpener.open(schemaVersion: kSchemaVersion));

  /// 测试用：注入内存库，避免碰真实文件与 Keystore。
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => kSchemaVersion;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (m, from, to) async {
        try {
          if (from < 2) {
            await m.createTable(periodCycles);
            await m.createTable(dailyRecords);
            await m.createTable(predictionCaches);
          }
          if (from < 3) {
            await m.createTable(customFoods);
          }
          if (from < 4) {
            // 只加列，不重建表：老用户已有的档案与体重记录原样保留。
            await m.addColumn(bodyProfiles, bodyProfiles.bodyFatPercent);
          }
        } catch (_) {
          // 打失败标记并保留备份，让下次启动可以提示恢复
          await DbBackup.markUpgradeFailed();
          rethrow;
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
        // 能执行到这里说明迁移成功：记录版本并丢弃本次备份
        await DbBackup.markUpgraded(
          schemaVersion: kSchemaVersion,
          backup: EncryptedDatabaseOpener.pendingBackup,
        );
      },
    );
  }
}
