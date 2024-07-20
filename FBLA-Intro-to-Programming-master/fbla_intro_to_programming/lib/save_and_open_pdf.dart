//Import all needed packages
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

//Used to save and open a document
class SaveAndOpenDocument {
  static Future<File> savePDF({
    //Required variables
    required String name,
    required pw.Document pdf,
  }) async {
    final root = Platform.isAndroid
      ? await getExternalStorageDirectory()
      : await getApplicationDocumentsDirectory();
    final file = File('${root!.path}/$name');
    //Write out the file
    await file.writeAsBytes(await pdf.save());
    //Print out file name for debugging reasons
    debugPrint('${root.path}/$name');
    //Return file
    return file;
  }
    //Method to open PDF
    static Future <void> openPDF(File file) async{
      //Gets PDFs file path
      final path = file.path;
      //Opens file using Open File
      await OpenFile.open(path);
    }
}

//Class to create the PDF
class SimplePdfApi {
  static Future<File> generateSimpleTextPdf(String email, String weighted, String unweighted, List<String> display) async{
    final pdf = pw.Document();
    //Adds a new page to the document
    pdf.addPage(
      pw.Page(
        build: (_) => pw.Center(
          //Uses the pdf package commands to create a layout
          child: pw.Column(
            children: [
              pw.Text(
                'Email: $email', style: const pw.TextStyle(fontSize: 30),
              ),
              pw.Text(
                '     ', style: const pw.TextStyle(fontSize: 15)
              ),
              pw.Text(
                'GPAs: ', style: const pw.TextStyle(fontSize: 48)
              ),
              pw.Text(
                'Unweighted: $unweighted', style: const pw.TextStyle(fontSize: 30)
              ),
              pw.Text(
                'Weighted GPA: $weighted', style: const pw.TextStyle(fontSize: 30)
              ),
              pw.Text(
                '     ', style: const pw.TextStyle(fontSize: 15)
              ),
              pw.Text(
                'Grade Report:', style:  const pw.TextStyle(fontSize: 48),
              ),
              for(int i = 0; i < display.length; i++)
              pw.Text(
                display[i], style: const pw.TextStyle(fontSize: 30),
              ),
            ],
          ),
        ),
      ));
      //Open doucment as the return
      return SaveAndOpenDocument.savePDF(name: 'grade_report.pdf', pdf: pdf);
  }
}