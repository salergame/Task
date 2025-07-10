package com.example.mama_taxi

import android.os.Bundle
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import com.yandex.mapkit.MapKitFactory

class MainActivity : FlutterActivity() {
    private var mapViewFactory: YandexMapViewFactory? = null
    
    override fun onCreate(savedInstanceState: Bundle?) {
        // MapKit инициализируется в MainApplication
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        
        // Создаем фабрику с привязкой к жизненному циклу активности
        mapViewFactory = YandexMapViewFactory(flutterEngine.dartExecutor.binaryMessenger)
        
        // Регистрируем нашу кастомную реализацию YandexMap
        flutterEngine
            .platformViewsController
            .registry
            .registerViewFactory(
                "yandex_mapkit/yandex_map", 
                mapViewFactory!!
            )
    }

    override fun onStart() {
        super.onStart()
        MapKitFactory.getInstance().onStart()
    }

    override fun onStop() {
        MapKitFactory.getInstance().onStop()
        super.onStop()
    }

    override fun onResume() {
        super.onResume()
        // Дополнительные действия при возобновлении активности
    }

    override fun onPause() {
        // Дополнительные действия при паузе активности
        super.onPause()
    }
} 