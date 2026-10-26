package com.shipyardapps.bloom

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundReceiver
import es.antonborri.home_widget.HomeWidgetProvider

class TodoWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.todo_widget).apply {
                val title = widgetData.getString("todo_title", "My Todo List")
                val entryId = widgetData.getString("todo_entry_id", null)
                val taskCount = widgetData.getInt("todo_count", 0)

                setTextViewText(R.id.widget_title, title)

                // Populate up to 5 rows
                for (i in 1..5) {
                    val rowId = context.resources.getIdentifier("row$i", "id", context.packageName)
                    val checkId = context.resources.getIdentifier("row${i}_check", "id", context.packageName)
                    val textId = context.resources.getIdentifier("row${i}_text", "id", context.packageName)

                    if (i <= taskCount) {
                        val taskText = widgetData.getString("todo_${i}_text", "")
                        val isChecked = widgetData.getBoolean("todo_${i}_checked", false)
                        val taskId = widgetData.getString("todo_${i}_id", "")

                        setViewVisibility(rowId, View.VISIBLE)
                        setTextViewText(checkId, if (isChecked) "☑" else "☐")
                        setTextViewText(textId, taskText)

                        // Intent to toggle this specific item
                        if (entryId != null && !taskId.isNullOrEmpty()) {
                            val backgroundIntent = Intent(context, HomeWidgetBackgroundReceiver::class.java).apply {
                                action = "es.antonborri.home_widget.action.BACKGROUND"
                                data = Uri.parse("bloom://toggle?id=$entryId&task=$taskId")
                            }
                            val backgroundPendingIntent = PendingIntent.getBroadcast(
                                context,
                                i, // Use index as requestCode to avoid intent collision
                                backgroundIntent,
                                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                            )
                            setOnClickPendingIntent(rowId, backgroundPendingIntent)
                        }
                    } else {
                        setViewVisibility(rowId, View.GONE)
                    }
                }

                // Show footer if more than 5 tasks
                setViewVisibility(R.id.widget_footer, if (taskCount > 5) View.VISIBLE else View.GONE)

                // Refresh button click
                val refreshIntent = Intent(context, HomeWidgetBackgroundReceiver::class.java).apply {
                    action = "es.antonborri.home_widget.action.BACKGROUND"
                    data = Uri.parse("bloom://refresh")
                }
                val refreshPendingIntent = PendingIntent.getBroadcast(
                    context,
                    100, // Unique request code for refresh
                    refreshIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_refresh, refreshPendingIntent)

                // Title click opens app
                val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                val pendingIntent = PendingIntent.getActivity(
                    context, 
                    0, 
                    intent, 
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_title, pendingIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
