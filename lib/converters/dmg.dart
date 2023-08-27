import 'shared.dart';

const simpleArabLatin = <String, String>{
  "ب": "b",
  "پ": "p",
  "ت": "t",
  "ث": "ṯ",
  "ج": "ǧ",
  "ح": "ḥ",
  "خ": "ḫ",
  "د": "d",
  "ذ": "ḏ",
  "ر": "r",
  "ز": "z",
  "س": "s",
  "ش": "š",
  "ص": "ṣ",
  "ض": "ḍ",
  "ط": "ṭ",
  "ظ": "ẓ",
  "ع": "ʿ",
  "غ": "ġ",
  "ف": "f",
  "ق": "q",
  "ك": "k",
  "ل": "l",
  "م": "m",
  "ن": "n",
  "ه": "h",
  // ?
  "و": "w",
  "ي": "y",
  "ء": "2",
};

final arabToLatin = <String, String>{
  ...arabNums,
  ...arabPunctuation,
  ...simpleArabLatin
};

const simpleLatinArab = <String, String>{
  "b": "ب",
  "p": "پ",
  "t": "ت",
  "ṯ": "ث",
  "ǧ": "ج",
  "ḥ": "ح",
  "ḫ": "خ",
  "d": "د",
  "ḏ": "ذ",
  "r": "ر",
  "z": "ز",
  "s": "س",
  "š": "ش",
  "ṣ": "ص",
  "ḍ": "ض",
  "ṭ": "ط",
  "ẓ": "ظ",
  "ʿ": "ع",
  "ġ": "غ",
  "f": "ف",
  "q": "ق",
  "k": "ك",
  "l": "ل",
  "m": "م",
  "n": "ن",
  "h": "ه",
  // ?
  "w": "و",
  "y": "ي",
  "2": "ء",
};