// ignore_for_file: dead_code

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:universal_io/io.dart' show File, Platform;
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:pdf/pdf.dart' hide PdfDocument, PdfColor;
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:file_saver/file_saver.dart';

import 'package:arabic_converter/shared.dart';
import 'package:arabic_converter/converter.dart';

class DocumentsPage extends StatefulWidget {
  const DocumentsPage({Key? key}) : super(key: key);

  @override
  createState() => DocumentsPageState();
}

class DocumentsPageState extends State<StatefulWidget>{

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.documents_title),
      ),
      body: const DocumentConverter()
    );
  }
}

class DocumentConverter extends StatefulWidget {
  const DocumentConverter({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => DocumentConverterState();
}

class DocumentConverterState extends State<StatefulWidget> {
  static const langs = <Lang>{Lang.arab,Lang.latin};

  bool get _isDesktop => ! kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS);
  String _langName(Lang lang) {
    final lookup = <Lang,String>{
      Lang.arab:locs.languagename_arab,
      Lang.latin:locs.languagename_latin,
    };
    return lookup[lang]!;
  }
  final controller = {
    for (var lang in langs)
      lang:TextEditingController()
  };
  bool toArab = true;
  String errorMessage = "";

  _loadFile () async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: "",
    );
    if (result != null) {
      String text;
      File file = File(result.files.single.path!);
      try {
        if (file.path.endsWith("pdf")) {
          final bytes = await file.readAsBytes();
          final PdfDocument document = PdfDocument(inputBytes: bytes);
          final extractor = PdfTextExtractor(document);
          text = extractor.extractText();
          document.dispose();
        } else {
            text = await file.readAsString();
        }
        controller[from]!.text = text;
        _handler();
      } catch (e) {
        setState(() {
          errorMessage = "Couldn't load text file";
        });
      }
    }
  }

  _saveFile () async {
    final langName = _langName(to);
    String? outputFile;
    final defaultFileName = '$langName.txt';
    String text = controller[to]!.text;
    if (_isDesktop) {
       outputFile = await FilePicker.platform.saveFile(
        dialogTitle: locs.choose_save_file,
        fileName: defaultFileName,
        type: FileType.custom,
        allowedExtensions: ["txt"]
      );
      if (outputFile == null) {
        smallAlert(locs.canceled_save, context);
      } else {
        final file = File(outputFile);
        try {
          if (outputFile.endsWith("pdf")){
            final pdfBytes = await _createPdf(text);
            await file.writeAsBytes(pdfBytes);
          } else {
            await file.writeAsString(text);
          }
          OpenFile.open(outputFile);
        } catch (e) {
          smallAlert(locs.failed_save, context);
          rethrow;
        }
      }
    } else {
      try{
        await FileSaver.instance.saveFile(langName, Uint8List.fromList(utf8.encode(text)), "txt", mimeType: MimeType.TEXT);
      } catch (e) {
        smallAlert("Unfortunately this is not supported on your platform right now", context);
        rethrow;
      }
    }
  }

  Future<List<int>> _createPdf(String text) async {
    const old = false;
    List<int> result;
    if (old){
      final document = PdfDocument();
      final page = document.pages.add();
      const textDirection = PdfTextDirection.none;//toArab ? PdfTextDirection.rightToLeft : PdfTextDirection.leftToRight;
      PdfTextElement(
        text: text,
        font: _lateefFont,
        brush: PdfSolidBrush(PdfColor(0, 0, 0)),
        format: PdfStringFormat(
          textDirection: textDirection
        )
      )
      .draw(
        page: page,
        bounds: Rect.fromLTWH(0, 0, page.getClientSize().width, page.getClientSize().height),
        format: PdfLayoutFormat(layoutType: PdfLayoutType.paginate)
      )!;
      result = document.save();
      document.dispose();
    } else {
      final pdf = pw.Document();

      final font = pw.Font.ttf(await rootBundle.load('fonts/Lateef-Regular.ttf'));
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: 30))
          ); // Center
        })
      ); // Page
      result = await pdf.save();
    }
    return result;
  }

  get _lateefFont async {
    final fontBytes = await rootBundle.load('fonts/Lateef-Regular.ttf');
    final bytesLength = fontBytes.lengthInBytes;
    final _protoList = <int>[];
    for (int i = 0; i<bytesLength; i++){
      final byte = fontBytes.getUint8(i);
      _protoList.add(byte);
    }
    final uintlist = Uint8List.fromList(_protoList);
    final font = PdfTrueTypeFont(uintlist, 14);
    return font;
  }

  Lang get to => toArab ? Lang.arab : Lang.latin;

  Lang get from => !toArab ? Lang.arab : Lang.latin;

  AppLocalizations get locs => AppLocalizations.of(context)!;

  void _handler (){
    setState(() {
      errorMessage = "";
      try {
        controller[to]!.text = convert[to]!(controller[from]!.text)[0];
      } on ParseError catch (e) {
        errorMessage = e.message;
      }
    });
  }

  Widget get input {
    final _errorMessage = errorMessage.isNotEmpty ? locs.parse_error_message.replaceFirst(r"{letter}", errorMessage) : null;
    final fromHintText = toArab ? locs.documents_input_hint : locs.languagename_arab;
    final fromLabelText = toArab ? locs.languagename_latin : null;
    return TextField(
      minLines: 5, 
      maxLines: 10,
      keyboardType: TextInputType.multiline,
      toolbarOptions: fullToolbar,
      textAlignVertical: TextAlignVertical.top,
      textInputAction: TextInputAction.go,

      controller: controller[from]!,
      textDirection: directions[from]!,
      decoration: boxInput.copyWith(
        hintText: fromHintText,
        labelText: fromLabelText,
        errorText: _errorMessage,
        alignLabelWithHint: true,
      ),
    );
  }

  Widget get swapButton {
    Widget elem = IconButton(
      iconSize: 30,
      splashRadius: 30,
      icon: const Icon(Icons.swap_horiz),
      onPressed: () {
        setState(() {
          toArab = !toArab;
        });
      },
      tooltip: locs.swap_languages,
    );
    if (toArab) elem = flip(elem);
    return elem;
  }
  
  Widget get buttonRow {
    return Container(
        height: 100,
        padding: const EdgeInsets.symmetric(vertical: 25),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children:[
              const VerticalDivider(),
              IconButton(
                icon: const Icon(Icons.arrow_downward_rounded),
                onPressed: _handler,
                tooltip: locs.convert,
              ),
              swapButton,
              IconButton(
                icon: const Icon(Icons.delete),
                tooltip: locs.delete,
                onPressed: (){
                  setState(() {
                    errorMessage = "";
                    for (var lang in langs){ controller[lang]!.clear();}
                  });
                },
              ),
              const SizedBox(width:10),
              IconButton(
                icon: const Icon(Icons.upload_file_outlined),
                tooltip: locs.load_file,
                onPressed: _loadFile,
              ),
              IconButton(
                icon: const Icon(Icons.save),
                tooltip: locs.save_file,
                onPressed: _saveFile,
              ),
              const VerticalDivider(),
            ]
          ),
        ),
      );
  }

  Widget get output {
    final toHintText = toArab ? locs.languagename_arab : locs.languagename_latin;
    final toLabelText = !toArab ? locs.languagename_latin : null;
    return TextField(
        minLines: 5, 
        maxLines: 10, 
        keyboardType: TextInputType.multiline,
        toolbarOptions: fullToolbar,
        textAlignVertical: TextAlignVertical.top,
        textInputAction: TextInputAction.go,
        readOnly: true,

        textDirection: directions[to]!,
        controller: controller[to]!,
        decoration: boxInput.copyWith(
          hintText: toHintText,
          labelText: toLabelText,
          alignLabelWithHint: true,
        ),
      );
  }
  
  //https://www.fluttercampus.com/guide/138/how-to-fix-vertical-divider-not-showing-in-flutter-app/#solution-1-wrap-row-with-intrinsicheight
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        children: [
          const Text(""),
          input,
          buttonRow,
          output,
        ]
      ),
    );
  }
}