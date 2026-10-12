package kz.milanium.mastera24

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import com.ss.halykepay.HalykEpaySDK
import com.ss.halykepay.data.BuildType
import com.ss.halykepay.data.model.AuthConfig
import com.ss.halykepay.data.model.Invoice

class EpayProxyActivity : AppCompatActivity() {
    private lateinit var halykEpaySdk: HalykEpaySDK

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val invoiceId = intent.getStringExtra("invoiceId").orEmpty()
        val amount = intent.getDoubleExtra("amount", 0.0)
        val accountId = intent.getStringExtra("accountId").orEmpty()
        val description = intent.getStringExtra("description").orEmpty()
        val postLink = intent.getStringExtra("postLink").orEmpty()
        val failurePostLink = intent.getStringExtra("failurePostLink").orEmpty()
        val email = intent.getStringExtra("email")

        if (invoiceId.isBlank() || amount <= 0.0) {
            setResult(
                Activity.RESULT_CANCELED,
                Intent().apply {
                    putExtra("isSuccessful", false)
                    putExtra("errorMessage", "Invalid invoice data")
                }
            )
            finish()
            return
        }

        val clientId = getString(R.string.epay_client_id)
        val clientSecret = getString(R.string.epay_client_secret)
        val terminalId = getString(R.string.epay_terminal_id)
        val merchantName = getString(R.string.epay_merchant_name)
        val isTest = resources.getBoolean(R.bool.epay_is_test)

        if (
            clientId.startsWith("__SET_") ||
            clientSecret.startsWith("__SET_") ||
            terminalId.startsWith("__SET_")
        ) {
            setResult(
                Activity.RESULT_CANCELED,
                Intent().apply {
                    putExtra("isSuccessful", false)
                    putExtra("errorMessage", "NOT_CONFIGURED")
                }
            )
            finish()
            return
        }

        val authConfig = AuthConfig(terminalId, merchantName, clientId, clientSecret)
        val buildType = if (isTest) BuildType.DEBUG else BuildType.PROD
        halykEpaySdk = HalykEpaySDK.Companion.instance(this, authConfig, buildType)

        val invoice = Invoice(
            id = invoiceId,
            amount = amount,
            currency = "KZT",
            accountID = accountId,
            description = description,
            postLink = postLink,
            failurePostLink = failurePostLink,
            email = email
        )
        halykEpaySdk.launchEpay(invoice)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == HalykEpaySDK.EPAY_SDK_REQUEST_CODE) {
            val paymentResult = halykEpaySdk.getPaymentResult(requestCode, resultCode, data)
            setResult(
                Activity.RESULT_OK,
                Intent().apply {
                    putExtra("isSuccessful", paymentResult.isSuccessful)
                    putExtra("paymentReference", paymentResult.paymentReference)
                    putExtra("errorCode", paymentResult.errorCode ?: 0)
                    putExtra("errorMessage", paymentResult.errorMessage)
                    putExtra("cardId", paymentResult.cardID)
                }
            )
            finish()
        }
    }
}
