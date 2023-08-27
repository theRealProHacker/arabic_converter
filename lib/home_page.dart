import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:arabic_converter/converter.dart';
import 'package:arabic_converter/shared.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.app_title)),
        body: const TextLineConverter(),
        drawer: const HomeDrawer());
  }
}

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final locs = AppLocalizations.of(context)!;
    return Drawer(
        child: ListView(
      padding: EdgeInsets.zero,
      children: [
        DrawerHeader(
            child: Text(locs.menu_title,
                style: const TextStyle(fontSize: 30, color: Colors.white)),
            decoration: BoxDecoration(color: Theme.of(context).primaryColor)),
        ListTile(
          leading: const Icon(Icons.file_copy_rounded),
          title: Text(locs.menu_documents),
          onTap: () {
            final navigator = Navigator.of(context);
            navigator.pushNamed("/documents");
          },
        ),
        AboutListTile(
          icon: const Icon(Icons.info_outline_rounded),
          child: Text(locs.menu_about),
          applicationVersion: "0.0.1",
          aboutBoxChildren: <Widget>[
            SizedBox(
                height: 86,
                child: Text([
                  locs.about_text1,
                  locs.about_text2,
                  locs.about_text3,
                ].join("\n"))),
            const SizedBox(height: 24),
          ],
        )
      ],
    ));
  }
}

class TextLineConverter extends StatefulWidget {
  const TextLineConverter({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => TextLineConverterState();
}

class TextLineConverterState extends State<StatefulWidget> {
  final controller = <Lang, TextEditingController>{
    for (var lang in Lang.values) lang: TextEditingController()
  };

  final errorStreamController = StreamController<String>();

  var mode = Mode.falaah;
  var toArab = true;
  var lastError = "";

  Lang get to => toArab ? Lang.arab : Lang.latin;

  Lang get from => !toArab ? Lang.arab : Lang.latin;

  AppLocalizations get locs => AppLocalizations.of(context)!;

  void _handler({String? text}) {
    // Setup
    String _text = text ?? controller[from]!.text;
    var errorMessage = "";
    // Try the parse
    try {
      controller[to]!.text = convert[mode]![to]!(_text)[0];
    } on ParseError catch (e) {
      errorMessage = e.message;
    }
    // Cleanup with error message and option update if anything changed
    if (errorMessage != lastError) {
      errorStreamController.add(errorMessage);
      lastError = errorMessage;
    }
  }

  void _onFinishedEditing() => _handler;

  void _onChangedValue(String text) => _handler(text: text);

  void _switchInputs() {
    setState(() {
      toArab = !toArab;
    });
  }

  Widget get modeSelect {
    return DropdownButton<Mode>(
      value: mode,
      onChanged: (Mode? newMode) {
        if (newMode != null) {
          mode = newMode;
          _handler();
        }
      },
      items: [
        for (var mode in Mode.values)
          DropdownMenuItem(
            value: mode,
            child: Text(mode.toString()),
          ),
      ],
    );
  }

  Widget get swapButton {
    Widget elem = IconButton(
      iconSize: 50,
      splashRadius: 50,
      icon: const Icon(Icons.swap_horiz),
      onPressed: _switchInputs,
      tooltip: AppLocalizations.of(context)?.swap_languages,
    );
    if (toArab) elem = flip(elem);
    return elem;
  }

  Widget get input {
    return StreamBuilder<String>(
      stream: errorStreamController.stream,
      builder: (context, snapshot) {
        final _errorMessage = snapshot.data ?? "";
        final errorMessage = _errorMessage.isNotEmpty ? _errorMessage : null;
        final String? _hint = !toArab ? "Arabic" : null;
        final String? _label = toArab ? "Latin" : null;
        return Padding(
          padding: const EdgeInsets.only(top: 40, bottom: 20),
          child: TextField(
            controller:
                toArab ? controller[Lang.latin]! : controller[Lang.arab]!,
            onChanged: _onChangedValue,
            onEditingComplete: _onFinishedEditing,
            autofocus: true,
            autocorrect: false,
            decoration: boxInput.copyWith(
                hintText: _hint, labelText: _label, errorText: errorMessage),
            textDirection: toArab ? TextDirection.ltr : TextDirection.rtl,
            textInputAction: TextInputAction.go,
            style: Theme.of(context).textTheme.bodyMedium,
            toolbarOptions: fullToolbar,
          ),
        );
      },
    );
  }

  Widget get output {
    String? _hint = toArab ? "Arabic" : null;
    String? _label = !toArab ? "Latin" : null;

    return Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 30),
        child: TextField(
          controller: toArab ? controller[Lang.arab]! : controller[Lang.latin]!,
          decoration: boxInput.copyWith(hintText: _hint, labelText: _label),
          textDirection: toArab ? TextDirection.rtl : TextDirection.ltr,
          autocorrect: false,
          readOnly: true,
          style: const TextStyle(fontSize: 18),
          toolbarOptions: fullToolbar,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(children: [
        modeSelect,
        input,
        swapButton,
        output,
      ]),
    );
  }
}
