package com.like.flutter_ycd

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.Process

/**
 * 在独立进程中等待旧 Flutter 进程退出，再从应用的 Launcher Activity 冷启动。
 *
 * 不能在旧进程中先启动新 Activity 再 kill：Android 可能把启动请求交回旧任务，
 * 导致 Shorebird 补丁没有机会由全新 Flutter 引擎加载。
 */
class RestartActivity : Activity() {
    private val handler = Handler(Looper.getMainLooper())

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        handler.postDelayed(
            {
                packageManager.getLaunchIntentForPackage(packageName)?.let { launch ->
                    launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
                    startActivity(launch)
                }
                finishAndRemoveTask()
                Process.killProcess(Process.myPid())
            },
            RESTART_DELAY_MS,
        )
    }

    companion object {
        private const val RESTART_DELAY_MS = 800L
    }
}
