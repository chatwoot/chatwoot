# Encoding

When parsing a Ruby file, there are times when the parser must parse identifiers. Identifiers are names of variables, methods, classes, etc. To determine the start of an identifier, the parser must be able to tell if the subsequent bytes form an alphabetic character. To determine the rest of the identifier, the parser must look forward through all alphanumeric characters.

Determining if a set of bytes comprise an alphabetic or alphanumeric character is encoding-dependent. By default, the parser assumes that all source files are encoded UTF-8. If the file is not encoded in UTF-8, it must be encoded using an encoding that is "ASCII compatible" (i.e., all of the codepoints below 128 match the corresponding codepoints in ASCII and the minimum number of bytes required to represent a codepoint is 1 byte).

If the file is not encoded in UTF-8, the user must specify the encoding in a "magic" comment at the top of the file. The comment looks like:

```ruby
# encoding: iso-8859-9
```

The key of the comment can be either "encoding" or "coding". The value of the comment must be a string that is a valid encoding name. The encodings that prism supports by default are:

* `ASCII-8BIT`
* `Big5`
* `Big5-HKSCS`
* `Big5-UAO`
* `CESU-8`
* `CP51932`
* `CP850`
* `CP852`
* `CP855`
* `CP949`
* `CP950`
* `CP951`
* `Emacs-Mule`
* `EUC-JP`
* `eucJP-ms`
* `EUC-JIS-2004`
* `EUC-KR`
* `EUC-TW`
* `GB12345`
* `GB18030`
* `GB1988`
* `GB2312`
* `GBK`
* `IBM437`
* `IBM720`
* `IBM737`
* `IBM775`
* `IBM852`
* `IBM855`
* `IBM857`
* `IBM860`
* `IBM861`
* `IBM862`
* `IBM863`
* `IBM864`
* `IBM865`
* `IBM866`
* `IBM869`
* `ISO-8859-1`
* `ISO-8859-2`
* `ISO-8859-3`
* `ISO-8859-4`
* `ISO-8859-5`
* `ISO-8859-6`
* `ISO-8859-7`
* `ISO-8859-8`
* `ISO-8859-9`
* `ISO-8859-10`
* `ISO-8859-11`
* `ISO-8859-13`
* `ISO-8859-14`
* `ISO-8859-15`
* `ISO-8859-16`
* `KOI8-R`
* `KOI8-U`
* `macCentEuro`
* `macCroatian`
* `macCyrillic`
* `macGreek`
* `macIceland`
* `MacJapanese`
* `macRoman`
* `macRomania`
* `macThai`
* `macTurkish`
* `macUkraine`
* `Shift_JIS`
* `SJIS-DoCoMo`
* `SJIS-KDDI`
* `SJIS-SoftBank`
* `stateless-ISO-2022-JP`
* `stateless-ISO-2022-JP-KDDI`
* `TIS-620`
* `US-ASCII`
* `UTF-8`
* `UTF8-MAC`
* `UTF8-DoCoMo`
* `UTF8-KDDI`
* `UTF8-SoftBank`
* `Windows-1250`
* `Windows-1251`
* `Windows-1252`
* `Windows-1253`
* `Windows-1254`
* `Windows-1255`
* `Windows-1256`
* `Windows-1257`
* `Windows-1258`
* `Windows-31J`
* `Windows-874`

For each of these encodings, prism provides functions for checking if the subsequent bytes can be interpreted as a character, and then if that character is alphabetic, alphanumeric, or uppercase.

## Getting notified when the encoding changes

You may want to get notified when the encoding changes based on the result of parsing an encoding comment. We use this internally for our `lex` function in order to provide the correct encodings for the tokens that are returned. For that you can register a callback with `pm_parser_register_encoding_changed_callback`. The callback will be called with a pointer to the parser. The encoding can be accessed through `parser->encoding`.

```c
// When the encoding that is being used to parse the source is changed by prism,
// we provide the ability here to call out to a user-defined function.
typedef void (*pm_encoding_changed_callback_t)(pm_parser_t *parser);

// Register a callback that will be called whenever prism changes the encoding
// it is using to parse based on the magic comment.
PRISM_EXPORTED_FUNCTION void
pm_parser_register_encoding_changed_callback(pm_parser_t *parser, pm_encoding_changed_callback_t callback);
```
