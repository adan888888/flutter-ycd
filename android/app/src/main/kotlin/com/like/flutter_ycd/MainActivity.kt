package com.like.flutter_ycd

import android.graphics.drawable.ColorDrawable
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    // Flutter 首帧已经接管画面，把窗口背景那张全屏启动图换成纯色，避免整个进程一直持有这张大图
    override fun onFlutterUiDisplayed() {
        super.onFlutterUiDisplayed()
        window.setBackgroundDrawable(ColorDrawable(ContextCompat.getColor(this, R.color.launch_background)))
    }
}
