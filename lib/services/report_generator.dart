// lib/services/report_generator.dart

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/patient_input.dart';
import '../models/prediction_result.dart';

class ReportGenerator {
  static Future<void> generateAndPreviewPdf(PatientInput input, PredictionResult result, List<String> recommendations) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            _buildHeader(),
            pw.SizedBox(height: 20),
            _buildPatientInfo(input),
            pw.SizedBox(height: 20),
            _buildRiskScore(result),
            pw.SizedBox(height: 20),
            _buildContributingFactors(result),
            pw.SizedBox(height: 20),
            _buildRecommendations(recommendations),
            pw.SizedBox(height: 30),
            _buildFooter(),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Disease_Risk_Assessment_Report.pdf',
    );
  }

  static pw.Widget _buildHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blue900, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Personalized Health Assessment',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
              ),
              pw.SizedBox(height: 4),
              pw.Text('Disease Risk Stratification Report', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
            ],
          ),
          pw.Text(
            'Date: ${DateTime.now().toString().split(' ')[0]}',
            style: const pw.TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPatientInfo(PatientInput input) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Patient Demographics & Metrics', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
             color: PdfColors.grey100,
             borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
             border: pw.Border.all(color: PdfColors.grey300),
          ),
          child: pw.Column(
            children: [
               _buildInfoRow('Patient Name:', input.name, 'Age:', '${input.age} yrs'),
               pw.SizedBox(height: 12),
               _buildInfoRow('Gender:', input.gender.toUpperCase(), 'BMI:', '${input.bmi} kg/m2'),
               pw.SizedBox(height: 12),
               _buildInfoRow('Blood Pressure:', '${input.bloodPressure} mmHg', 'Heart Rate:', '${input.heartRate} bpm'),
               pw.SizedBox(height: 12),
               _buildInfoRow('Cholesterol:', '${input.cholesterol} mg/dL', 'Glucose:', '${input.glucose} mg/dL'),
               pw.SizedBox(height: 12),
               pw.Row(children: [pw.Text('Smoker: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)), pw.Text(input.smoking ? 'Yes' : 'No')]),
            ]
          )
        )
      ],
    );
  }
  
  static pw.Widget _buildInfoRow(String label1, String val1, String label2, String val2) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
         pw.Expanded(child: pw.Row(children: [pw.Text(label1, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)), pw.SizedBox(width: 5), pw.Text(val1)])),
         pw.Expanded(child: pw.Row(children: [pw.Text(label2, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)), pw.SizedBox(width: 5), pw.Text(val2)])),
      ]
    );
  }

  static pw.Widget _buildRiskScore(PredictionResult result) {
    final scoreStr = (result.riskScore * 100).toStringAsFixed(1);
    PdfColor badgeColor;
    if (result.prediction.toLowerCase().contains('high')) {
      badgeColor = PdfColors.red700;
    } else if (result.prediction.toLowerCase().contains('medium')) {
      badgeColor = PdfColors.orange700;
    } else {
      badgeColor = PdfColors.green700;
    }

    // use lighter shade
    PdfColor bgColor;
    if (result.prediction.toLowerCase().contains('high')) {
      bgColor = PdfColors.red50;
    } else if (result.prediction.toLowerCase().contains('medium')) {
      bgColor = PdfColors.orange50;
    } else {
      bgColor = PdfColors.green50;
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Risk Assessment', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
             color: bgColor,
             borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
             border: pw.Border.all(color: badgeColor),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
               pw.Column(
                 crossAxisAlignment: pw.CrossAxisAlignment.start,
                 children: [
                   pw.Text('Overall Risk Class:', style: const pw.TextStyle(fontSize: 14)),
                   pw.Text(result.prediction.toUpperCase(), style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: badgeColor)),
                 ]
               ),
               pw.Column(
                 crossAxisAlignment: pw.CrossAxisAlignment.end,
                 children: [
                   pw.Text('Risk Score:', style: const pw.TextStyle(fontSize: 14)),
                   pw.Text('$scoreStr%', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: badgeColor)),
                 ]
               )
            ]
          )
        )
      ],
    );
  }

  static pw.Widget _buildContributingFactors(PredictionResult result) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Top Contributing Factors', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
        pw.SizedBox(height: 10),
        ...result.sortedExplanation.map((entry) {
          return pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            child: pw.Row(
              children: [
                pw.Container(
                  width: 6,
                  height: 6,
                  decoration: const pw.BoxDecoration(color: PdfColors.blue800, shape: pw.BoxShape.circle),
                ),
                pw.SizedBox(width: 10),
                pw.Text('${entry.key}: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(entry.value),
              ]
            )
          );
        }).toList()
      ],
    );
  }

  static pw.Widget _buildRecommendations(List<String> recs) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Actionable Recommendations', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
        pw.SizedBox(height: 10),
        ...recs.map((rec) {
          return pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('• ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                pw.Expanded(child: pw.Text(rec, style: const pw.TextStyle(lineSpacing: 1.5))),
              ]
            )
          );
        }).toList()
      ],
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Divider(color: PdfColors.grey400),
        pw.SizedBox(height: 10),
        pw.Text(
          'Disclaimer: This report is generated by an AI model for educational and informational purposes only '
          'and is NOT a substitute for professional medical advice, diagnosis, or treatment.',
          textAlign: pw.TextAlign.center,
          style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 10),
        ),
      ]
    );
  }
}
