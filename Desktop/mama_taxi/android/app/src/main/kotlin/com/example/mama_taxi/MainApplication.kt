package com.example.mama_taxi

import android.app.Application
import com.yandex.mapkit.MapKitFactory

class MainApplication: Application() {
    override fun onCreate() {
        super.onCreate()
        try {
            // Инициализация Yandex MapKit с API ключом
            MapKitFactory.setApiKey("18fb32f9-5ace-46c2-a283-8c60c38131a0")
            // Инициализируем MapKit
            MapKitFactory.initialize(this)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
} 