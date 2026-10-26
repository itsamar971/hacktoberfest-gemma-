package com.shipyardapps.bloom

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundReceiver
import es.antonborri.home_widget.HomeWidgetProvider
import java.io.File

class TravelWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.travel_widget).apply {
                val mapPath = widgetData.getString("travel_map_path", null)

                if (mapPath != null && File(mapPath).exists()) {
                    // Load and display map image
                    try {
                        val bitmap = BitmapFactory.decodeFile(mapPath)
                        if (bitmap != null) {
                            setImageViewBitmap(R.id.travel_map_image, bitmap)
                            setViewVisibility(R.id.travel_map_image, View.VISIBLE)
                            setViewVisibility(R.id.travel_empty_message, View.GONE)
                        } else {
                            setViewVisibility(R.id.travel_map_image, View.GONE)
                            setViewVisibility(R.id.travel_empty_message, View.VISIBLE)
                        }
                    } catch (e: Exception) {
                        setViewVisibility(R.id.travel_map_image, View.GONE)
                        setViewVisibility(R.id.travel_empty_message, View.VISIBLE)
                    }
                } else {
                    setViewVisibility(R.id.travel_map_image, View.GONE)
                    setViewVisibility(R.id.travel_empty_message, View.VISIBLE)
                }

                // Refresh button click
                val refreshIntent = Intent(context, HomeWidgetBackgroundReceiver::class.java).apply {
                    action = "es.antonborri.home_widget.action.BACKGROUND"
                    data = Uri.parse("bloom://refresh_travel")
                }
                val refreshPendingIntent = PendingIntent.getBroadcast(
                    context,
                    200,
                    refreshIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.travel_widget_refresh, refreshPendingIntent)

                // Title click opens app
                val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.travel_widget_title, pendingIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
