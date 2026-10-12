import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../config/app_config.dart';

String buildPaymentHtml({
  required Map<String, dynamic> auth,
  required Map<String, dynamic> paymentObject,
  required String paymentScriptUrl,
}) {
  final authJson = jsonEncode(auth);
  final paymentJson = jsonEncode(paymentObject);

  return '''
<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Оплата</title>
  <script src="$paymentScriptUrl"></script>
</head>
<body style="margin:0; font-family: Arial, sans-serif; background:#FDFBF7;">
  <div style="padding:24px;">
    <h3>Подключаем оплату...</h3>
    <p>Пожалуйста, подождите.</p>
  </div>
  <script>
    const auth = $authJson;
    const paymentObject = $paymentJson;
    paymentObject.auth = auth;

    function startPayment() {
      if (window.halyk && typeof window.halyk.pay === 'function') {
        window.halyk.pay(paymentObject);
        return;
      }
      if (window.halykPay && typeof window.halykPay.pay === 'function') {
        window.halykPay.pay(paymentObject);
        return;
      }
      document.body.innerHTML = '<div style="padding:24px;">Ошибка загрузки платежной формы.</div>';
    }

    if (document.readyState === 'complete') {
      startPayment();
    } else {
      window.addEventListener('load', startPayment);
    }
  </script>
</body>
</html>
''';
}

class PaymentWebviewScreen extends StatefulWidget {
  final Map<String, dynamic> auth;
  final Map<String, dynamic> paymentObject;
  final String paymentScriptUrl;

  const PaymentWebviewScreen({
    super.key,
    required this.auth,
    required this.paymentObject,
    required this.paymentScriptUrl,
  });

  @override
  State<PaymentWebviewScreen> createState() => _PaymentWebviewScreenState();
}

class _PaymentWebviewScreenState extends State<PaymentWebviewScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    final html = buildPaymentHtml(
      auth: widget.auth,
      paymentObject: widget.paymentObject,
      paymentScriptUrl: widget.paymentScriptUrl,
    );
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final url = request.url;
            if (url.startsWith(AppConfig.paymentSuccessUrl)) {
              Navigator.of(context).pop(true);
              return NavigationDecision.prevent;
            }
            if (url.startsWith(AppConfig.paymentFailureUrl)) {
              Navigator.of(context).pop(false);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadHtmlString(html);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Оплата заявки')),
      body: WebViewWidget(controller: _controller),
    );
  }
}
