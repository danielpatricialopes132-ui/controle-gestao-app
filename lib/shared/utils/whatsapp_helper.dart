import 'package:url_launcher/url_launcher.dart';

class WhatsAppHelper {
  static Future<void> shareText(String text) async {
    final url = Uri.parse("https://wa.me/?text=${Uri.encodeComponent(text)}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Nǜo foi possvel abrir o WhatsApp.';
    }
  }
}
