/// Rewritten converter. Unfortunately time is O(n*m)
/// n: number of chars in the text
/// m: number of chars in the mappings
/// The old version was more time efficient (about n*maxlength(m))
/// maxlength(m): The maximum length of any key in the mappings
/// However, the difference isn't really noticable because n and m are pretty small. 
/// Also, the old converter was pretty difficult to understand

import 'dart:collection';

import 'package:arabic_converter/shared.dart';

extension on String {
  String get rev {
    return split("").reversed.join("");
  } 
  String get x2 {
    return this+this;
  }
}

extension on Map<String,String> {
  Map<String,String> get swapKeys {
    return {
      for (final pair in entries) 
        pair.value: pair.key
    };
  }
}

/// This is the converter lib that manages converting between 
/// Arab and Latin chars correctly

// Helper functions are all in a functional style:

/// _compare the length of two strings
int _compareLength (String a, String b){
  return b.length-a.length;
}

/// Sorts a regular map
Map<String, String> _sorted(Map<String,String> map) {
  var sortedKeys = map.keys.toList(growable:false)
    ..sort((k1, k2) => _compareLength(k1,k2));
  return LinkedHashMap
    .fromIterable(sortedKeys, key: (k) => k, value: (k) => map[k]!);
}

/// This joins a tree of posses to a list of possible Strings
/// ```dart
/// final posses = [
///   ["op1","op2"],
///   ["op0","op3"],
/// ];
/// _joinPosses(posses,"->"); 
/// // -> ["op1->op0", "op1->op3", "op2->op0", "op2->op3"]
/// ```
List<String> _joinPosses(List<List<String>> tree, String joinChar) {

  return tree.reduce((currVal,nextLevel) 
    => [
      for (final last in currVal)
        for (final next in nextLevel)
          last+joinChar+next
    ]
  );
}

String _replaceAll(String s, Map<String,String> m) {
  for (final pair in m.entries) {
    s = s.replaceAll(pair.key, pair.value);
  }
  return s;
}

String _replaceAllRev(String s, Map<String,String> m) {
  for (final pair in m.entries) {
    s = s.replaceAll(pair.key.rev, pair.value.rev);
  }
  return s;
}


// Constants

/// The Shaddah is a little glyph that looks a bit like a w and is put on top of a consonant to make it longer.
/// In European languages this is often expressed by doubling the consonant
const _shaddah = "\u0651";

/// Signs that should just be ignored
/// These will be replaced with nothing at the very end
const _arabIgnores = <String>{
  "e",
  "-","_",
  "o"
};

/// Latin characters that should be used in number tokens with there replacements
const _arabNums = <String, String>{
  // We except digits, commas, periods, minusses, and brackets
  ",":"٬",
  ".":"٫",
  "0":"٠",
  "1":"١",
  "2":"٢",
  "3":"٣",
  "4":"٤",
  "5":"٥",
  "6":"٦",
  "7":"٧",
  "8":"٨",
  "9":"٩",
  "-":"-",
  "(":"(",
  ")":")"
};

/// A map from Latin punctuation to Arab punctuation
const _arabPunctuation = <String, String>{
  "!":"!",
  "?":"؟",
  "%":"٪",
  ".":".",
  ";":"\u061B",
};

/// A helper class for the vowel entries:
class _VowelEntry{
  final String short;
  final String long;
  final String nunation;

  const _VowelEntry(this.short, this.long, this.nunation);
}

/// Arab vowels can be expressed in three ways:
/// as a fatHa, kaSra or Damma
/// As an alif, a ya or a waw
/// as a nunation (tanween)
const _arabVowels = <String,_VowelEntry>{
  "a": _VowelEntry("\u064E","ا","\u064B"),
  "i":_VowelEntry("\u0650", "ي", "\u064D"),
  "u":_VowelEntry("\u064F", "و", "\u064C"),
};

/// A map of appendices. These are neither vowels nor consonants.
const _arabAppends = {
  "o":"\u0652",
  "°":"\u0652", // standard
};

// Latin to arab consonant mapping
const _arabChars = <String, String>{
  "b":"ب", // standard
  "p":"ب", // alt
  "t":"ت",
  "th":"ث",
  "j":"ج", // standard
  "g":"ج", // alt
  "H":"ح",
  "kh":"خ",
  "d":"د",
  "dh":"ذ",
  "r":"ر",
  "z":"ز",
  "s":"س",
  "sh":"ش",
  "S":"ص",
  "D":"ض",
  "T":"ط",
  "DH":"ظ", // standard
  "Z":"ظ",  // alt
  "3":"ع",
  "gh":"غ",
  "f":"ف", // standard
  "v":"ف", // alt
  "q":"ق",
  "k":"ك", // standard
  "c":"ك", // alt
  "l":"ل",
  "m":"م",
  "n":"ن",
  "h":"ه",
  "w":"و",
  "y":"ي",
  "2":"ء",
  "h:":"ة", // standard
  "ö":"ة",  // alt1
  "ä":"ة",  // alt2
  "'":"أ",
  "y'":"ئ",
  "w'":"ؤ",
};

/// All five latin vowels (a,e,i,o,u)
const _allLatinVowels = <String>{"a","e","i","o","u"};

// Computed (final) maps

/// Map from latin to arabic including all arabic appends 
/// on top of characters (formal diacritical signs) except for shaddah
final _arabGeneralAppends = <String, String>{
  ..._arabAppends,
  for (final pair in _arabVowels.entries)
    ...{
      pair.key:pair.value.short,
      pair.key:pair.value.nunation
    }
};

/// Endings are a Mapping of alternate endings.
final _arabEndings = <String, String>{
  // Alif -> Alif maqsura
  "\u0627":"ى",
  // ta -> ta marbuta
  for (final app in _arabGeneralAppends.values)
  ...{
    "ت"+app:"ة"+app,
    "ت"+_shaddah+app:"ة"+_shaddah+app
  },
  // nunations eg.: `an` at the end of a token may be a nunation
  for (var value in _arabVowels.values)
  ...{
    value.short+"ن":value.nunation,
  }
};

/// Aliases get replaced before anything else happens
final _arabAliases = <String,String>{
  for (final vowel in _allLatinVowels)
    vowel.toUpperCase():vowel.x2
};

/// A sorted map of latin Strings to arab Strings
/// These will be replaced from left to right
var _arabCharsMap = _sorted({
  // First we add the nums to override any doubled signs later on
  ..._arabNums,
  // Then we add the punctuation
  ..._arabPunctuation,
  // Finally the chars in single and double form:
  ..._arabChars,
  for (final pair in _arabChars.entries)
    pair.key.x2:pair.value+_shaddah,
  // Add support for ALLAH
  "aallah":"\uFDF2",
  "allah":"\uFDF2",
});

/// A sorted map of latin Strings to arab Strings
/// These will be replaced from right to left
final _arabExtrasMap = _sorted({
  for (final pair in _arabVowels.entries)
  ...{
    // The double entries (aa->ا)
    pair.key.x2:pair.value.long,
    // The single entries
    pair.key:pair.value.short,
  },
  // This is right now just o and °
  ..._arabAppends,
  "aaaa":"آ",
  "ao":"ٱ",
  "aao":"ٱ",

  "oo":"و",
  "ee":"ي",
  "-_":"ى",
});

final Set<String> _acceptedArabChars = {
  ..._arabCharsMap.values.where((e) => e.length == 1),
  ..._arabExtrasMap.values,
  "\uFDF2",
  _shaddah,
  "ى",
  "ة",
  "إ",
};

// Arab to Latin Maps

final _latinNums = _arabNums.swapKeys;

final _latinMap = {
  ..._arabCharsMap.swapKeys,
  ..._arabExtrasMap.swapKeys
};

final Set<String> _acceptedLatinChars = {
  ..._latinMap.values,
  "_"
};

List<String> Function(String) _handler (List<String> Function(String) next, String split) {
  return (text) {
    if (text.isEmpty) return [""];
    return _joinPosses(
      text
      .split(split)
      .where((token) => token.isNotEmpty)
      .map(next)
      .toList()
    ,split);
  };
}

// Latin to Arab
// ----------------------------------------------------------------

/// Converts any latin text to a list of options of arabic transliteration
final _handleLatinText = _handler(_handleLatinLine, "\n");

/// Converts any latin line to a list of options of arabic transliteration
final _handleLatinLine = _handler(_handleLatinToken, " ");

/// Converts any latin token to a list of options of arabic transliterations
List<String> _handleLatinToken(String token) {
  try{
    // There is only ever a single option to parse a number token
    return [_latinNumToArab(token)]; 
  } catch (e) { // The num parsing failed
    return _latinWordToArab(token);
  }
}

/// Tries to parse a token. Fails as sonn as it sees a number it doesn't recognize
String _latinNumToArab (String token) {
  return token
    .split("")
    .map((char) => _arabNums[char]!) 
      // This fails if the character is not found in the number map
    .join("");
}

/// Makes the biggest part of the work and converts a single word from latin to arabic.
/// It then gives several options depending on the endings
List<String> _latinWordToArab (String token) {
  // Replace aliases and then consonants normally
  token = _replaceAll(token,_arabAliases);
  token = _replaceAll(token,_arabCharsMap);

  // Reversed vowel replace
  token = token.rev; // Reverse the token. To replace from behind
  token = _replaceAllRev(token,_arabExtrasMap);
  token = token.rev;

  // Ignores
  for (final ignore in _arabIgnores) {
    token = token.replaceAll(ignore, "");
  }
  
  // Artifacts
  final newToken = token.split("");
  token.split("").asMap().forEach((i, value) {
    for (final pair in _arabVowels.entries) {
      if (pair.value.short == value) {
        if (i == 0 || _arabVowels.values.any((vowel) => vowel.short == newToken[i-1]) || _arabAppends.containsValue(token[i-1])){
          newToken[i] = pair.value.long;
        }
      }
    }
  });
  token = newToken.join("");
  token = token.replaceAll("أِ", // This break has a reason. If you don't believe my then try
    "إ\u0650");

  // error raising
  final error = token.split("").where((char) => !_acceptedArabChars.contains(char)).join("");
  if (error.isNotEmpty) throw ParseError(error);

  // endings
  final result = <String>[token];
  for (final ending in _arabEndings.entries) {
    if(token.endsWith(ending.key)) {
      result.add(token.substring(0, token.length-ending.key.length)+opener+ending.value+closer);
    }
  }
  return result;
}

// Arab to Latin
// ----------------------------------------------------------------

/// Converts any arab text to a list of options of reversed transliteration
final _handleArabText = _handler(_handleArabLine, "\n");

/// Converts any arab line to a list of options of reversed transliteration
final _handleArabLine = _handler(_handleArabToken, " ");

/// Converts any arab token to a list of options of reversed transliterations
List<String> _handleArabToken(String token) => [_arabNumToLatin(token) ?? _arabWordToLatin(token)];

/// Tries to parse a token. Fails as soon as it sees a number it doesn't recognize
String? _arabNumToLatin (String token) {
  List<String> result = [];
  for (final char in token.split("")) {
    final value = _latinNums[char];
    if (value == null) return null;
    result.add(value);
  }
  return result.join("");
}

/// Makes the biggest part of the work and reverts a single word from arabic to latin.
String _arabWordToLatin (String token) {

  const escapeBeforeh = {"d","s","t","k","g"};
  const couldBeVowel = <String,String>{
    "y":"ii",
    "w":"uu"
  };

  final beforeNotVowel = {
    _allLatinVowels,
    "°"
  };

  // Replacemnts
  final newToken = token.split("");
  token.split("").asMap().forEach((i, arab) {
    String? latin = _latinMap[arab];
    if (latin != null) {
      if(i>0){
        // Escape two letters that could be misinterpreted as one
        if (latin=="h" && escapeBeforeh.contains(newToken[i-1]) || latin=="H" && newToken[i-1]=="D"){
          latin = "_"+latin;
        // Convert semiconsonants to their vowel part
        } else if (couldBeVowel.containsKey(latin) && !beforeNotVowel.contains(newToken[i-1])) {
          latin = couldBeVowel[latin]!;
        }
      }
      newToken[i] = latin;
    }
  });
  token = newToken.join("");

  // error raising
  final error = token.split("").where((char) => !_acceptedLatinChars.contains(char)).join("");
  if (error.isNotEmpty) throw ParseError(error);

  return token;
}

const opener = "{";
const closer = "}";

/// Converter for target language
/// 
/// Usage:  
/// ```dart
/// final text = "ahlan";
/// final to = "arab";
/// convert[to]!(text);
/// ```
final convert = {
  Lang.arab: _handleLatinText,
  Lang.latin: _handleArabText,
};