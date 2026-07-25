package com.cuptales.app

import android.content.Intent
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val isRestored = savedInstanceState != null
        val intentAction = intent?.action ?: "null"
        val intentData = intent?.dataString ?: "null"

        Log.d("CupTalesLifecycle", "========================================")
        Log.d("CupTalesLifecycle", "[MainActivity] onCreate called. isRestored=$isRestored")
        Log.d("CupTalesLifecycle", "[MainActivity] Intent Action: $intentAction")
        Log.d("CupTalesLifecycle", "[MainActivity] Intent Data: $intentData")
    }

    override fun onResume() {
        super.onResume()
        Log.d("CupTalesLifecycle", "[MainActivity] onResume called. App is now in foreground.")
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val intentAction = intent.action ?: "null"
        val intentData = intent.dataString ?: "null"
        Log.d("CupTalesLifecycle", "[MainActivity] onNewIntent called. (App was likely resumed via intent)")
        Log.d("CupTalesLifecycle", "[MainActivity] New Intent Action: $intentAction")
        Log.d("CupTalesLifecycle", "[MainActivity] New Intent Data: $intentData")
    }
}
