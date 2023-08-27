// Constants

/// The Shaddah is a little glyph that looks a bit like a w and is put on top of a consonant to make it longer.
/// In European languages this is often expressed by doubling the consonant
const shaddah = "\u0651";

/// Signs that should just be ignored
/// These will be replaced with nothing at the very end
const arabIgnores = <String>{"e", "-", "_", "o"};

/// Latin characters that should be used in number tokens with there replacements
const arabNums = <String, String>{
  // We except digits, commas, periods, minusses, and brackets
  ",": "٬",
  ".": "٫",
  "0": "٠",
  "1": "١",
  "2": "٢",
  "3": "٣",
  "4": "٤",
  "5": "٥",
  "6": "٦",
  "7": "٧",
  "8": "٨",
  "9": "٩",
  "-": "-",
  "+": "+",
  "(": "(",
  ")": ")"
};

/// A map from Latin punctuation to Arab punctuation
const arabPunctuation = <String, String>{
  "!": "!",
  "?": "؟",
  "%": "٪",
  ".": ".",
  ";": "\u061B",
};

/// A helper class for the vowel entries:
class VowelEntry {
  final String short;
  final String long;
  final String nunation;

  const VowelEntry(this.short, this.long, this.nunation);
}

/// Arab vowels can be expressed in three ways:
/// as a fatHa, kaSra or Damma
/// As an alif, a ya or a waw
/// as a nunation (tanween)
const arabVowels = <String, VowelEntry>{
  "a": VowelEntry("\u064E", "ا", "\u064B"),
  "i": VowelEntry("\u0650", "ي", "\u064D"),
  "u": VowelEntry("\u064F", "و", "\u064C"),
};

/// A map of appendices. These are neither vowels nor consonants.
const arabAppends = {
  "o": "\u0652",
  "°": "\u0652", // standard
};

const opener = "{";
const closer = "}";
