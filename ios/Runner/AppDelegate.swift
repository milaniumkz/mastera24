import Flutter
import UIKit
import EpaySDK

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let channelName = "epay_sdk"
  private var pendingResult: FlutterResult?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: controller.binaryMessenger)

    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return }
      if call.method == "pay" {
        if self.pendingResult != nil {
          result(FlutterError(code: "IN_PROGRESS", message: "Payment already in progress", details: nil))
          return
        }

        guard let args = call.arguments as? [String: Any] else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
          return
        }

        self.pendingResult = result
        self.startPayment(args: args, controller: controller)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handlePaymentNotification(_:)),
      name: Notification.Name("sdk_response"),
      object: nil
    )

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func startPayment(args: [String: Any], controller: FlutterViewController) {
    let clientId = Bundle.main.object(forInfoDictionaryKey: "EPayClientID") as? String ?? ""
    let clientSecret = Bundle.main.object(forInfoDictionaryKey: "EPayClientSecret") as? String ?? ""
    let terminalId = Bundle.main.object(forInfoDictionaryKey: "EPayTerminalID") as? String ?? ""
    let merchantName = Bundle.main.object(forInfoDictionaryKey: "EPayMerchantName") as? String ?? "Mastera24"
    let isTest = (Bundle.main.object(forInfoDictionaryKey: "EPayIsTest") as? Bool) ?? true

    if clientId.hasPrefix("__SET_") || clientSecret.hasPrefix("__SET_") || terminalId.hasPrefix("__SET_") {
      pendingResult?(FlutterError(code: "NOT_CONFIGURED", message: "Платёжный модуль не настроен.", details: nil))
      pendingResult = nil
      return
    }

    let authConfig = AuthConfig(
      merchantId: terminalId,
      merchantName: merchantName,
      clientId: clientId,
      clientSecret: clientSecret
    )

    let invoiceId = args["invoiceId"] as? String ?? ""
    let amount = args["amount"] as? Int ?? 0
    let accountId = args["accountId"] as? String ?? ""
    let description = args["description"] as? String ?? ""
    let postLink = args["postLink"] as? String ?? ""
    let failurePostLink = args["failurePostLink"] as? String ?? ""

    let invoice = Invoice(
      id: invoiceId,
      amount: amount,
      currency: "KZT",
      accountID: accountId,
      description: description,
      postLink: postLink,
      failurePostLink: failurePostLink,
      isRecurrent: false
    )

    let paymentModel = PaymentModel(authConfig: authConfig, invoice: invoice)
    let launchScreenVC = LaunchScreenViewController(paymentModel: paymentModel)
    launchScreenVC.setEnvironmetType(type: isTest ? .dev : .prod)
    launchScreenVC.modalPresentationStyle = .fullScreen

    let navController = UINavigationController(rootViewController: launchScreenVC)
    navController.modalPresentationStyle = .fullScreen
    controller.present(navController, animated: true)
  }

  @objc private func handlePaymentNotification(_ notification: Notification) {
    guard let payload = notification.userInfo else { return }
    let isSuccessful = payload["isSuccessful"] as? Bool ?? false
    let status = isSuccessful ? "success" : "failed"

    pendingResult?(["status": status, "payload": payload])
    pendingResult = nil
  }
}
