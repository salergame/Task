package com.example.mama_taxi

import android.content.Context
import android.view.View
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import com.yandex.mapkit.MapKitFactory
import com.yandex.mapkit.geometry.Point
import com.yandex.mapkit.map.CameraPosition
import com.yandex.mapkit.mapview.MapView
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class YandexMapView(
    private val context: Context,
    private val id: Int,
    private val messenger: BinaryMessenger
) : PlatformView, DefaultLifecycleObserver {
    private val mapView: MapView = MapView(context)
    private val methodChannel: MethodChannel = MethodChannel(messenger, "yandex_mapkit/map_controller")

    init {
        try {
            // Устанавливаем начальную позицию карты (Москва)
            val moscowPoint = Point(55.751244, 37.618423)
            mapView.map.move(
                CameraPosition(moscowPoint, 14.0f, 0.0f, 0.0f)
            )

            // Сообщаем Flutter, что карта готова
            methodChannel.invokeMethod("onMapReady", null)
        } catch (e: Exception) {
            e.printStackTrace()
            methodChannel.invokeMethod("onMapError", e.message)
        }
    }

    override fun getView(): View = mapView

    override fun dispose() {
        try {
            mapView.onStop()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onStart(owner: LifecycleOwner) {
        try {
            MapKitFactory.getInstance().onStart()
            mapView.onStart()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onStop(owner: LifecycleOwner) {
        try {
            mapView.onStop()
            MapKitFactory.getInstance().onStop()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onResume(owner: LifecycleOwner) {
        try {
            mapView.onStart()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onPause(owner: LifecycleOwner) {
        try {
            mapView.onStop()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}

class YandexMapViewFactory(private val messenger: BinaryMessenger) : 
    PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        return YandexMapView(context, viewId, messenger)
    }
} 