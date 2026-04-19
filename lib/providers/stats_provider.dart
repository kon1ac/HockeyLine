import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hockeyline/models/player.dart';
import 'package:hockeyline/services/storage_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class StatsProvider extends ChangeNotifier {
  StatsProvider(this._storageService);

  final StorageService _storageService;

  Future<String> exportStatsAsCsv(List<Player> players) async {
    final List<List<dynamic>> rows = <List<dynamic>>[
      <dynamic>[
        'id',
        'firstName',
        'lastName',
        'number',
        'position',
        'games',
        'goals',
        'assists',
        'points',
        'penaltyMinutes',
        'plusMinus',
      ],
      ...players.map(
        (Player p) => <dynamic>[
          p.id,
          p.firstName,
          p.lastName,
          p.number,
          p.position.name,
          p.statistics.games,
          p.statistics.goals,
          p.statistics.assists,
          p.statistics.points,
          p.statistics.penaltyMinutes,
          p.statistics.plusMinus,
        ],
      ),
    ];
    final String csvText = const ListToCsvConverter().convert(rows);
    final String fileName = 'hockeyline_stats_${DateTime.now().millisecondsSinceEpoch}.csv';
    final Uint8List bytes = Uint8List.fromList(utf8.encode(csvText));
    final Directory preferredDirectory = await _storageService.getExportDirectory();
    final File file = File('${preferredDirectory.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<String> exportStatsAsPdf(List<Player> players) async {
    final String fileName = 'hockeyline_stats_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final ByteData fontBytes = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final pw.Font font = pw.Font.ttf(fontBytes);
    final pw.Document pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: font, bold: font, italic: font),
    );
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) => <pw.Widget>[
          pw.Text(
            'HockeyLine — отчёт по статистике',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Сформировано: ${DateTime.now().toIso8601String()}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 16),
          ...players.map(
            (Player p) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Text(
                '${p.lastName} ${p.firstName} #${p.number} | '
                'Г:${p.statistics.goals} П:${p.statistics.assists} '
                'О:${p.statistics.points} Штр:${p.statistics.penaltyMinutes} '
                'Плюс/минус:${p.statistics.plusMinus}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
          ),
        ],
      ),
    );
    final Uint8List bytes = Uint8List.fromList(await pdf.save());
    final Directory preferredDirectory = await _storageService.getExportDirectory();
    final File file = File('${preferredDirectory.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}
