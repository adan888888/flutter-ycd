package com.like.flutter_ycd

import android.content.Intent
import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import androidx.core.content.ContextCompat
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var nativeLaunchImage: ImageView? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ycd/app_restart")
            .setMethodCallHandler { call, result ->
                if (call.method != "restart") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val launch = packageManager.getLaunchIntentForPackage(packageName)
                if (launch == null) {
                    result.error("restart_failed", "找不到启动页", null)
                    return@setMethodCallHandler
                }
                launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
                result.success(null)
                // 先让通道结果回到 Dart，再清掉当前任务并结束进程。
                // 系统会按启动页重新拉起进程，Shorebird 补丁在新进程里生效。
                Handler(Looper.getMainLooper()).postDelayed({
                    startActivity(launch)
                    Runtime.getRuntime().exit(0)
                }, 300)
            }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Flutter 画到系统栏下面，SafeArea / WindowInsets 只负责把可交互内容让开。
        // 这样底部手势导航区域显示的是当前页面背景，而不是启动主题的绿色窗口背景。
        WindowCompat.setDecorFitsSystemWindows(window, false)
        window.statusBarColor = Color.TRANSPARENT
        window.navigationBarColor = Color.TRANSPARENT

        // 从 SplashActivity 切进来后继续用原生 View 覆盖整张启动图，
        // 直到 Flutter 画出同一张图，Activity 切换期间不会闪出空白或纯色。
        nativeLaunchImage = ImageView(this).apply {
            setBackgroundColor(
                ContextCompat.getColor(this@MainActivity, R.color.launch_background),
            )
            setImageResource(R.drawable.launch_image)
            scaleType = ImageView.ScaleType.FIT_XY
            importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO_HIDE_DESCENDANTS
        }
        addContentView(
            nativeLaunchImage,
            ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            ),
        )
    }

    // Flutter 首帧已经接管画面后释放原生全屏启动图；透明背景不会再从导航栏底部漏出绿色。
    override fun onFlutterUiDisplayed() {
        super.onFlutterUiDisplayed()
        nativeLaunchImage?.let { image ->
            (image.parent as? ViewGroup)?.removeView(image)
            image.setImageDrawable(null)
        }
        nativeLaunchImage = null
        window.setBackgroundDrawable(ColorDrawable(Color.TRANSPARENT))
    }
}
