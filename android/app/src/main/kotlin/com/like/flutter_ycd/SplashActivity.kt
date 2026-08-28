package com.like.flutter_ycd

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.view.View
import android.view.ViewTreeObserver
import android.widget.ImageView
import androidx.core.content.ContextCompat
import androidx.core.view.WindowCompat

/**
 * 原生启动图承接页。
 *
 * Android 12+ 的系统启动层只接受纯色背景；这个轻量 Activity 在第一帧立即画出整张图，
 * 再无动画切到 Flutter。这样系统纯色只存在于进程真正启动的极短阶段，不必等待 Flutter 引擎。
 */
class SplashActivity : Activity() {
    private var isOpeningFlutter = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // 已有任务时再次点桌面图标，只恢复原任务，不叠加新的 Flutter 页面。
        if (
            !isTaskRoot &&
            intent.action == Intent.ACTION_MAIN &&
            intent.hasCategory(Intent.CATEGORY_LAUNCHER)
        ) {
            finish()
            return
        }

        WindowCompat.setDecorFitsSystemWindows(window, false)
        window.statusBarColor = android.graphics.Color.TRANSPARENT
        window.navigationBarColor = android.graphics.Color.TRANSPARENT

        val launchImage = ImageView(this).apply {
            setBackgroundColor(
                ContextCompat.getColor(this@SplashActivity, R.color.launch_background),
            )
            setImageResource(R.drawable.launch_image)
            scaleType = ImageView.ScaleType.FIT_XY
            importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO_HIDE_DESCENDANTS
        }
        setContentView(launchImage)

        // 先允许原生启动图真实绘制一帧，再启动 Flutter；避免纯色系统层一直等 Flutter 首帧。
        launchImage.viewTreeObserver.addOnPreDrawListener(
            object : ViewTreeObserver.OnPreDrawListener {
                override fun onPreDraw(): Boolean {
                    if (launchImage.viewTreeObserver.isAlive) {
                        launchImage.viewTreeObserver.removeOnPreDrawListener(this)
                    }
                    launchImage.post(::openFlutter)
                    return true
                }
            },
        )
    }

    private fun openFlutter() {
        if (isOpeningFlutter || isFinishing || isDestroyed) return
        isOpeningFlutter = true

        startActivity(
            Intent(this, MainActivity::class.java).apply {
                flags =
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_NO_ANIMATION
                this@SplashActivity.intent.extras?.let(::putExtras)
            },
        )
        overridePendingTransition(0, 0)
        finish()
        overridePendingTransition(0, 0)
    }
}
