package kz.milanium.mastera24

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val EPAY_PROXY_REQUEST_CODE = 9901
    }

    private val channelName = "epay_sdk"
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method == "pay") {
                    if (pendingResult != null) {
                        result.error("IN_PROGRESS", "Payment already in progress", null)
                        return@setMethodCallHandler
                    }

                    val args = call.arguments as? Map<*, *>
                    if (args == null) {
                        result.error("BAD_ARGS", "Invalid payment arguments", null)
                        return@setMethodCallHandler
                    }

                    val invoiceId = args["invoiceId"]?.toString().orEmpty()
                    val amount = (args["amount"] as? Number)?.toDouble() ?: 0.0
                    val accountId = args["accountId"]?.toString().orEmpty()
                    val description = args["description"]?.toString().orEmpty()
                    val postLink = args["postLink"]?.toString().orEmpty()
                    val failurePostLink = args["failurePostLink"]?.toString().orEmpty()
                    val email = args["email"]?.toString()

                    if (invoiceId.isBlank() || amount <= 0.0) {
                        result.error("BAD_ARGS", "invoiceId/amount are required", null)
                        return@setMethodCallHandler
                    }

                    pendingResult = result
                    val intent = Intent(this, EpayProxyActivity::class.java).apply {
                        putExtra("invoiceId", invoiceId)
                        putExtra("amount", amount)
                        putExtra("accountId", accountId)
                        putExtra("description", description)
                        putExtra("postLink", postLink)
                        putExtra("failurePostLink", failurePostLink)
                        putExtra("email", email)
                    }
                    startActivityForResult(intent, EPAY_PROXY_REQUEST_CODE)
                } else {
                    result.notImplemented()
                }
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == EPAY_PROXY_REQUEST_CODE) {
            if (data == null) {
                pendingResult?.error("NO_RESULT", "Payment result is empty", null)
                pendingResult = null
                return
            }

            val payload = mapOf(
                "isSuccessful" to data.getBooleanExtra("isSuccessful", false),
                "paymentReference" to data.getStringExtra("paymentReference"),
                "errorCode" to data.getIntExtra("errorCode", 0),
                "errorMessage" to data.getStringExtra("errorMessage"),
                "cardId" to data.getStringExtra("cardId")
            )

            val errorMessage = data.getStringExtra("errorMessage").orEmpty()
            if (errorMessage == "NOT_CONFIGURED") {
                pendingResult?.error("NOT_CONFIGURED", "Платежный модуль не настроен.", null)
                pendingResult = null
                return
            }

            val status = when {
                data.getBooleanExtra("isSuccessful", false) -> "success"
                resultCode == Activity.RESULT_CANCELED -> "cancelled"
                else -> "failed"
            }
            pendingResult?.success(mapOf("status" to status, "payload" to payload))
            pendingResult = null
        }
    }
}
