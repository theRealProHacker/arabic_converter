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
      drawer: const HomeDrawer()
    );
  }
}

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final locs = AppLocalizations.of(context)!; 
    return Drawer(
      child: ListView(padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            child: Text(locs.menu_title, style: const TextStyle(fontSize: 30, color: Colors.white)),
            decoration: BoxDecoration(color: Theme.of(context).primaryColor)
          ),
          ListTile(
            leading: const Icon(Icons.file_copy_rounded),
            title: Text(locs.menu_documents),
            onTap: (){
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
                height:86,
                child: Text([
                  locs.about_text1,
                  locs.about_text2,
                  locs.about_text3,
                ].join("\n"))
              ),
              const SizedBox(height: 24),
            ],
          )
        ],
      )
    );
  }
}

class TextLineConverter extends StatefulWidget {
  const TextLineConverter({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState()=>TextLineConverterState();
}

class TextLineConverterState extends State<StatefulWidget> {
  static const langs = {Lang.arab, Lang.latin};
  final options = <Lang, List<String>>{for (var lang in langs) lang: [""]};
  final controller = <Lang, TextEditingController> {for (var lang in langs) lang:TextEditingController()};
  
  final streamController = StreamController<List<String>>();
  void setOptions(Lang name, List<String> value, {chosen = false}) {
    options[name] = value;
    if (name == Lang.arab) {
      streamController.add(value);
    }
  }

  final errorStreamController = StreamController<String>();

  var toArab = true;
  var lastError = "";

  Lang get to => toArab ? Lang.arab : Lang.latin;

  Lang get from => !toArab ? Lang.arab : Lang.latin;

  AppLocalizations get locs => AppLocalizations.of(context)!;

  void _handler({String? text}) {
    // Setup
    String _text = text ?? controller[from]!.text;
    var errorMessage = "";
    final lastOptions = options[Lang.arab];
    // Try the parse
    try {
      setOptions(to, convert[to]!(_text));
      controller[to]!.text = options[to]![0];
    } on ParseError catch (e) {
      errorMessage = e.message;
    }
    // Cleanup with error message and option update if anything changed
    if (errorMessage!=lastError) {
      errorStreamController.add(errorMessage);
      lastError = errorMessage;
    }
    if (lastOptions != options[Lang.arab]!) {
      streamController.add(options[Lang.arab]!);
    }
  }

  void _onFinishedEditing() => _handler;

  void _onChangedValue(String text) => _handler(text:text);

  void _switchInputs() {
    setState(() {
      toArab = !toArab;
      setOptions(Lang.arab, [""]);
    });
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
              controller: toArab ? controller[Lang.latin]! : controller[Lang.arab]!,
              onChanged: _onChangedValue,
              onEditingComplete: _onFinishedEditing,
              autofocus: true,
              autocorrect: false,
              decoration: boxInput.copyWith(hintText: _hint, labelText: _label, errorText: errorMessage),
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
      )
    );
  }

  late final OptionsView<String> optionsView = OptionsView<String>(streamController.stream, (var value) {
    
    controller[Lang.arab]!.text = value.replaceAll(RegExp("[${RegExp.escape(opener)},${RegExp.escape(closer)}]"), "");
    setOptions(Lang.arab, [value], chosen: true);
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          input,
          swapButton,
          output,
          optionsView
        ]
      ),
    );
  }
}


class OptionsView<T> extends StatefulWidget {
  final Stream<List<T>> stream;
  final void Function(T) choseOption;

  const OptionsView(this.stream, this.choseOption, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => OptionsViewState<T>();
}

class OptionsViewState<T> extends State<OptionsView<T>> {
  
  void Function() _onChoseOptionCreator(T option) {
    return (){
      setState(() {
        options = [option];
      });
      widget.choseOption(option);
    };
  }
  List<T> options = [];

  @override
  void initState() {
    super.initState();
    widget.stream.listen((newOptions) {
      setState(() {
        options = newOptions;
      });
    });
  }


  @override
  Widget build(BuildContext context) {
    if (options.length<=1) return const SizedBox.shrink();
    return Expanded(
      child: ListView(
        children: [
          const Divider(height: 1),
          ...ListTile.divideTiles(
              context:context, 
              tiles: [
                for (var option in options) 
                  OptionsListTile(option.toString(), 
                    Icons.keyboard_arrow_right_sharp, 
                    _onChoseOptionCreator(option)
                  )
              ]
            ),
          const Divider(),
        ], 
        shrinkWrap: true, // extremely important
      ),
    );
  }
}

class OptionsListTile extends StatelessWidget {

  final String text;
  final IconData icon;
  final void Function() onTap;

  const OptionsListTile(this.text, this.icon, this.onTap, {Key? key}) : super(key: key);

  List<TextSpan> get _richText {
    final retVal = <TextSpan>[];
    bool tagOpen = false;
    var currVal = <String>[];
    void appendIfNotEmpty() {
      if (currVal.isNotEmpty) {
        retVal.add(TextSpan(
          text:currVal.join(""),
          style: tagOpen 
            ? const TextStyle(fontSize: 20, color: Colors.red) 
            : const TextStyle(fontSize: 20, color: Colors.black54)
        ));
        currVal.clear();
      }
    }
    for (final char in text.split("")){
      if (char == opener){
        appendIfNotEmpty();
        tagOpen = true;
      } else if (char == closer){
        appendIfNotEmpty();
        tagOpen = false;
      } else {
        currVal.add(char);
      }
    }
    appendIfNotEmpty();
    return retVal;
  }

  @override
  Widget build(BuildContext context) {
    return ListTile (
      title : RichText(
        text:TextSpan(
          children: _richText,
        ), 
      ),
      trailing : Icon(
        icon, 
        color: Colors.black12
      ),
      onTap: onTap,
      dense: true
    );
  }
  
}