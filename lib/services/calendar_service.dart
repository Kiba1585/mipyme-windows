import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class CalendarService {
  /// Genera un archivo .ics con un evento de vencimiento de impuestos.
  static Future<void> addTaxDeadlineToCalendar({
    required String period,
    required DateTime dueDate,
    required double taxAmount,
  }) async {
    final icsContent = _buildIcsContent(
      summary: 'Vencimiento de impuestos ($period)',
      description: 'Impuesto a pagar: \$${taxAmount.toStringAsFixed(2)}\nPeríodo: $period',
      dueDate: dueDate,
    );

    // Guardar en la carpeta temporal
    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'impuestos_${DateFormat('yyyyMMdd').format(dueDate)}.ics';
    final file = File(p.join(dir.path, fileName));
    await file.writeAsString(icsContent);

    // Abrir el archivo con la aplicación predeterminada (Calendario de Windows)
    if (await canLaunchUrl(file.uri)) {
      await launchUrl(file.uri);
    }
  }

  /// Construye el contenido de un archivo iCalendar (.ics).
  static String _buildIcsContent({
    required String summary,
    required String description,
    required DateTime dueDate,
  }) {
    final now = DateTime.now();
    final format = DateFormat("yyyyMMdd'T'HHmmss");
    final uid = '${now.millisecondsSinceEpoch}@mipyme';

    return '''
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//MIPYME Suite//ES
CALSCALE:GREGORIAN
METHOD:PUBLISH
BEGIN:VEVENT
DTSTART:${format.format(dueDate)}
DTEND:${format.format(dueDate.add(const Duration(hours: 1)))}
SUMMARY:$summary
DESCRIPTION:$description
UID:$uid
DTSTAMP:${format.format(now)}
END:VEVENT
END:VCALENDAR
''';
  }
}