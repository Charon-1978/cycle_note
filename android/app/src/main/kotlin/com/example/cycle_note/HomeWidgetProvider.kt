package com.example.cycle_note

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews

/**
 * 今日小组件（P3-3）。
 *
 * 数据来源：Flutter 侧 TodayWidgetService 通过 home_widget 插件把
 * 三行文本写进 SharedPreferences("HomeWidgetPreferences")，
 * 这里 onUpdate 时读同一份偏好渲染 RemoteViews。
 *
 * key 约定（v1 锁死，与 Dart 端 TodayWidgetData.toWidgetStrings 一致）：
 *   widget_intake  今日摄入 kcal（字符串数字）
 *   widget_budget  每日预算 kcal（"-" = 档案未填）
 *   widget_weight  最新体重（"未记录" 或 "55.8kg"）
 *
 * 刷新时机：
 *   1. Flutter 记录动作后主动 updateWidget；
 *   2. updatePeriodMillis 30 分钟兜底（系统空闲时）；
 *   3. 桌面添加 / 系统重启时 onUpdate 自动走。
 */
class HomeWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val sp = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val intake = sp.getString("widget_intake", "0") ?: "0"
        val budget = sp.getString("widget_budget", "-") ?: "-"
        val weight = sp.getString("widget_weight", "未记录") ?: "未记录"

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_today).apply {
                setTextViewText(R.id.widget_intake, intake)
                setTextViewText(R.id.widget_budget, budget)
                setTextViewText(R.id.widget_weight, weight)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
