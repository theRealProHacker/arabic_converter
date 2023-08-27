import 'package:flutter/material.dart';

import 'package:arabic_converter/converters/falaah.dart' as falaah;
import 'package:arabic_converter/converters/shared.dart' as convert_shared;

enum Lang {
  latin,
  arab,
}

/// The conversion mode
enum Mode {
  falaah,
  dmg,
  ijmes;

  @override
  String toString() {
    switch(this) {
        case Mode.falaah: return "Falaah";
        case Mode.dmg: return "DMG";
        case Mode.ijmes: return "IJMES";
      }
  }
}

/// Converter for target language
///
/// Usage:
/// ```dart
/// final text = "ahlan";
/// final to = "arab";
/// convert[to]!(text);
/// ```
final convert = {
  Mode.falaah: {
    Lang.arab: falaah.handleLatinText,
    Lang.latin: falaah.handleArabText,
  },
};

/// directions lookup by lang
const directions = <Lang, TextDirection>{
  Lang.arab: TextDirection.rtl,
  Lang.latin: TextDirection.ltr,
};

const opener = convert_shared.opener;
const closer = convert_shared.closer;
