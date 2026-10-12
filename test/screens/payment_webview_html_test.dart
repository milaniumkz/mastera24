import 'package:flutter_test/flutter_test.dart';
import 'package:mastera24/screens/payments/payment_webview_screen.dart';

void main() {
  test('buildPaymentHtml embeds script url and payload JSON', () {
    final html = buildPaymentHtml(
      auth: const {'accessToken': 'token-1'},
      paymentObject: const {'invoiceId': 'inv-1', 'amount': 1000},
      paymentScriptUrl: 'https://pay.example/sdk.js',
    );

    expect(html, contains('https://pay.example/sdk.js'));
    expect(html, contains('"accessToken":"token-1"'));
    expect(html, contains('"invoiceId":"inv-1"'));
    expect(html, contains('window.halyk'));
    expect(html, contains('Ошибка загрузки платежной формы.'));
  });
}
