package sa.fieldcases.field_cases

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

// FlutterFragmentActivity مطلوب لنافذة البصمة (local_auth).
class MainActivity : FlutterFragmentActivity() {
    private var channel: MethodChannel? = null

    // ملف وصل قبل أن تبدأ Dart بالاستماع.
    private var pendingPath: String? = null
    private var dartReady = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "field_cases/incoming_file",
        ).also { ch ->
            ch.setMethodCallHandler { call, result ->
                if (call.method == "getInitialFile") {
                    dartReady = true
                    result.success(pendingPath)
                    pendingPath = null
                } else {
                    result.notImplemented()
                }
            }
        }
        consumeIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        consumeIntent(intent)
    }

    private fun consumeIntent(intent: Intent?) {
        if (intent == null || (intent.action != Intent.ACTION_VIEW && intent.action != Intent.ACTION_SEND)) {
            return
        }
        // لا يُعاد استيراد الملف نفسه عند إعادة إنشاء النشاط (تدوير الشاشة).
        setIntent(Intent())
        // النسخ خارج خيط الواجهة: الحزم قد تكون كبيرة.
        Thread {
            val path = copyIncoming(intent) ?: return@Thread
            runOnUiThread { deliver(path) }
        }.start()
    }

    private fun deliver(path: String) {
        val ch = channel
        if (dartReady && ch != null) {
            ch.invokeMethod("onFile", path)
        } else {
            pendingPath = path
        }
    }

    /** ينسخ الملف المفتوح (content://) إلى مجلد مؤقت داخل التطبيق. */
    private fun copyIncoming(intent: Intent?): String? {
        if (intent == null) return null
        val uri: Uri = when (intent.action) {
            Intent.ACTION_VIEW -> intent.data
            Intent.ACTION_SEND ->
                if (Build.VERSION.SDK_INT >= 33) {
                    intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
                } else {
                    @Suppress("DEPRECATION")
                    intent.getParcelableExtra(Intent.EXTRA_STREAM)
                }
            else -> null
        } ?: return null
        return try {
            val name = (displayName(uri) ?: "incoming")
                .replace(Regex("[^A-Za-z0-9._-]"), "_")
                .takeLast(80)
            val dir = File(cacheDir, "incoming").apply { mkdirs() }
            val target = File(dir, "${System.currentTimeMillis()}_$name")
            val input = contentResolver.openInputStream(uri) ?: return null
            input.use { source -> target.outputStream().use { source.copyTo(it) } }
            target.absolutePath
        } catch (e: Exception) {
            null
        }
    }

    private fun displayName(uri: Uri): String? {
        try {
            contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
                ?.use { cursor ->
                    if (cursor.moveToFirst() && !cursor.isNull(0)) return cursor.getString(0)
                }
        } catch (e: Exception) {
            // بعض التطبيقات لا تسمح بالاستعلام؛ يكفي اسم افتراضي.
        }
        return uri.lastPathSegment
    }
}
