package com.deepumanager.app

import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        window.setBackgroundDrawable(ColorDrawable(Color.rgb(37, 99, 235)))
        window.statusBarColor = Color.rgb(37, 99, 235)
        window.navigationBarColor = Color.rgb(37, 99, 235)
        super.onCreate(savedInstanceState)
    }
}
