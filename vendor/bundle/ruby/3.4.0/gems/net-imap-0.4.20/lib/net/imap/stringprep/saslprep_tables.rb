# frozen_string_literal: true

#--
# This file is generated from RFC3454, by rake.  Don't edit directly.
#++

module Net::IMAP::StringPrep

  module SASLprep

    # RFC4013 §2.1 Mapping - mapped to space
    # >>>
    #   non-ASCII space characters (\StringPrep\[\"C.1.2\"]) that can
    #   be mapped to SPACE (U+0020)
    #
    # Equal to \StringPrep\[\"C.1.2\"].
    # Redefined here to avoid loading StringPrep::Tables unless necessary.
    MAP_TO_SPACE = /[\u200b\p{Zs}&&[^ ]]/.freeze

    # RFC4013 §2.1 Mapping - mapped to nothing
    # >>>
    #   the "commonly mapped to nothing" characters
    #   (\StringPrep\[\"B.1\"]) that can be mapped to nothing.
    #
    # Equal to \StringPrep\[\"B.1\"].
    # Redefined here to avoid loading StringPrep::Tables unless necessary.
    MAP_TO_NOTHING = /[\u{00ad 034f 1806 2060 feff}\u{180b}-\u{180d}\u{200b}-\u{200d}\u{fe00}-\u{fe0f}]/.freeze

    # RFC4013 §2.3 Prohibited Output
    # >>>
    # * Non-ASCII space characters — \StringPrep\[\"C.1.2\"]
    # * ASCII control characters — \StringPrep\[\"C.2.1\"]
    # * Non-ASCII control characters — \StringPrep\[\"C.2.2\"]
    # * Private Use characters — \StringPrep\[\"C.3\"]
    # * Non-character code points — \StringPrep\[\"C.4\"]
    # * Surrogate code points — \StringPrep\[\"C.5\"]
    # * Inappropriate for plain text characters — \StringPrep\[\"C.6\"]
    # * Inappropriate for canonical representation characters — \StringPrep\[\"C.7\"]
    # * Change display properties or deprecated characters — \StringPrep\[\"C.8\"]
    # * Tagging characters — \StringPrep\[\"C.9\"]
    TABLES_PROHIBITED = ["C.1.2", "C.2.1", "C.2.2", "C.3", "C.4", "C.5", "C.6", "C.7", "C.8", "C.9"].freeze

    # Adds unassigned (by Unicode 3.2) codepoints to TABLES_PROHIBITED.
    #
    # RFC4013 §2.5 Unassigned Code Points
    # >>>
    #   This profile specifies the \StringPrep\[\"A.1\"] table as its
    #   list of unassigned code points.
    TABLES_PROHIBITED_STORED = ["A.1", *TABLES_PROHIBITED].freeze

    # A Regexp matching codepoints prohibited by RFC4013 §2.3.
    #
    # This combines all of the TABLES_PROHIBITED tables.
    PROHIBITED_OUTPUT = /[\u{06dd 070f 1680 180e 3000 feff e0001}\u{0000}-\u{001f}\u{007f}-\u{00a0}\u{0340}-\u{0341}\u{2000}-\u{200f}\u{2028}-\u{202f}\u{205f}-\u{2063}\u{206a}-\u{206f}\u{2ff0}-\u{2ffb}\u{e000}-\u{f8ff}\u{fdd0}-\u{fdef}\u{fff9}-\u{ffff}\u{1d173}-\u{1d17a}\u{1fffe}-\u{1ffff}\u{2fffe}-\u{2ffff}\u{3fffe}-\u{3ffff}\u{4fffe}-\u{4ffff}\u{5fffe}-\u{5ffff}\u{6fffe}-\u{6ffff}\u{7fffe}-\u{7ffff}\u{8fffe}-\u{8ffff}\u{9fffe}-\u{9ffff}\u{afffe}-\u{affff}\u{bfffe}-\u{bffff}\u{cfffe}-\u{cffff}\u{dfffe}-\u{dffff}\u{e0020}-\u{e007f}\u{efffe}-\u{10ffff}\p{Cs}]/.freeze

    # RFC4013 §2.5 Unassigned Code Points
    # >>>
    #   This profile specifies the \StringPrep\[\"A.1\"] table as its
    #   list of unassigned code points.
    #
    # Equal to \StringPrep\[\"A.1\"].
    # Redefined here to avoid loading StringPrep::Tables unless necessary.
    UNASSIGNED = /\p{^AGE=3.2}/.freeze

    # A Regexp matching codepoints prohibited by RFC4013 §2.3 and §2.5.
    #
    # This combines PROHIBITED_OUTPUT and UNASSIGNED.
    PROHIBITED_OUTPUT_STORED = Regexp.union(
      UNASSIGNED, PROHIBITED_OUTPUT
    ).freeze

    # Bidirectional Characters [StringPrep, §6]
    #
    # A Regexp for strings that don't satisfy StringPrep's Bidirectional
    # Characters rules.
    #
    # Equal to StringPrep::Tables::BIDI_FAILURE.
    # Redefined here to avoid loading StringPrep::Tables unless necessary.
    BIDI_FAILURE = /(?-mix:(?m-ix:(?-mix:[\u{05be 05c0 05c3 061b 061f 06dd 0710 07b1 200f fb1d fb3e}\u{05d0}-\u{05ea}\u{05f0}-\u{05f4}\u{0621}-\u{063a}\u{0640}-\u{064a}\u{066d}-\u{066f}\u{0671}-\u{06d5}\u{06e5}-\u{06e6}\u{06fa}-\u{06fe}\u{0700}-\u{070d}\u{0712}-\u{072c}\u{0780}-\u{07a5}\u{fb1f}-\u{fb28}\u{fb2a}-\u{fb36}\u{fb38}-\u{fb3c}\u{fb40}-\u{fb41}\u{fb43}-\u{fb44}\u{fb46}-\u{fbb1}\u{fbd3}-\u{fd3d}\u{fd50}-\u{fd8f}\u{fd92}-\u{fdc7}\u{fdf0}-\u{fdfc}\u{fe70}-\u{fe74}\u{fe76}-\u{fefc}]).*?(?-mix:[\u{00aa 00b5 00ba 02ee 037a 0386 038c 0589 0903 0950 09b2 09d7 0a5e 0a83 0a8d 0ac9 0ad0 0ae0 0b40 0b57 0b83 0b9c 0bd7 0cbe 0cde 0d57 0dbd 0e84 0e8a 0e8d 0ea5 0ea7 0ebd 0ec6 0f36 0f38 0f7f 0f85 0fcf 102c 1031 1038 10fb 1248 1258 1288 12b0 12c0 1310 17dc 1f59 1f5b 1f5d 1fbe 200e 2071 207f 2102 2107 2115 2124 2126 2128 2395 1d4a2 1d4bb 1d546}\u{0041}-\u{005a}\u{0061}-\u{007a}\u{00c0}-\u{00d6}\u{00d8}-\u{00f6}\u{00f8}-\u{0220}\u{0222}-\u{0233}\u{0250}-\u{02ad}\u{02b0}-\u{02b8}\u{02bb}-\u{02c1}\u{02d0}-\u{02d1}\u{02e0}-\u{02e4}\u{0388}-\u{038a}\u{038e}-\u{03a1}\u{03a3}-\u{03ce}\u{03d0}-\u{03f5}\u{0400}-\u{0482}\u{048a}-\u{04ce}\u{04d0}-\u{04f5}\u{04f8}-\u{04f9}\u{0500}-\u{050f}\u{0531}-\u{0556}\u{0559}-\u{055f}\u{0561}-\u{0587}\u{0905}-\u{0939}\u{093d}-\u{0940}\u{0949}-\u{094c}\u{0958}-\u{0961}\u{0964}-\u{0970}\u{0982}-\u{0983}\u{0985}-\u{098c}\u{098f}-\u{0990}\u{0993}-\u{09a8}\u{09aa}-\u{09b0}\u{09b6}-\u{09b9}\u{09be}-\u{09c0}\u{09c7}-\u{09c8}\u{09cb}-\u{09cc}\u{09dc}-\u{09dd}\u{09df}-\u{09e1}\u{09e6}-\u{09f1}\u{09f4}-\u{09fa}\u{0a05}-\u{0a0a}\u{0a0f}-\u{0a10}\u{0a13}-\u{0a28}\u{0a2a}-\u{0a30}\u{0a32}-\u{0a33}\u{0a35}-\u{0a36}\u{0a38}-\u{0a39}\u{0a3e}-\u{0a40}\u{0a59}-\u{0a5c}\u{0a66}-\u{0a6f}\u{0a72}-\u{0a74}\u{0a85}-\u{0a8b}\u{0a8f}-\u{0a91}\u{0a93}-\u{0aa8}\u{0aaa}-\u{0ab0}\u{0ab2}-\u{0ab3}\u{0ab5}-\u{0ab9}\u{0abd}-\u{0ac0}\u{0acb}-\u{0acc}\u{0ae6}-\u{0aef}\u{0b02}-\u{0b03}\u{0b05}-\u{0b0c}\u{0b0f}-\u{0b10}\u{0b13}-\u{0b28}\u{0b2a}-\u{0b30}\u{0b32}-\u{0b33}\u{0b36}-\u{0b39}\u{0b3d}-\u{0b3e}\u{0b47}-\u{0b48}\u{0b4b}-\u{0b4c}\u{0b5c}-\u{0b5d}\u{0b5f}-\u{0b61}\u{0b66}-\u{0b70}\u{0b85}-\u{0b8a}\u{0b8e}-\u{0b90}\u{0b92}-\u{0b95}\u{0b99}-\u{0b9a}\u{0b9e}-\u{0b9f}\u{0ba3}-\u{0ba4}\u{0ba8}-\u{0baa}\u{0bae}-\u{0bb5}\u{0bb7}-\u{0bb9}\u{0bbe}-\u{0bbf}\u{0bc1}-\u{0bc2}\u{0bc6}-\u{0bc8}\u{0bca}-\u{0bcc}\u{0be7}-\u{0bf2}\u{0c01}-\u{0c03}\u{0c05}-\u{0c0c}\u{0c0e}-\u{0c10}\u{0c12}-\u{0c28}\u{0c2a}-\u{0c33}\u{0c35}-\u{0c39}\u{0c41}-\u{0c44}\u{0c60}-\u{0c61}\u{0c66}-\u{0c6f}\u{0c82}-\u{0c83}\u{0c85}-\u{0c8c}\u{0c8e}-\u{0c90}\u{0c92}-\u{0ca8}\u{0caa}-\u{0cb3}\u{0cb5}-\u{0cb9}\u{0cc0}-\u{0cc4}\u{0cc7}-\u{0cc8}\u{0cca}-\u{0ccb}\u{0cd5}-\u{0cd6}\u{0ce0}-\u{0ce1}\u{0ce6}-\u{0cef}\u{0d02}-\u{0d03}\u{0d05}-\u{0d0c}\u{0d0e}-\u{0d10}\u{0d12}-\u{0d28}\u{0d2a}-\u{0d39}\u{0d3e}-\u{0d40}\u{0d46}-\u{0d48}\u{0d4a}-\u{0d4c}\u{0d60}-\u{0d61}\u{0d66}-\u{0d6f}\u{0d82}-\u{0d83}\u{0d85}-\u{0d96}\u{0d9a}-\u{0db1}\u{0db3}-\u{0dbb}\u{0dc0}-\u{0dc6}\u{0dcf}-\u{0dd1}\u{0dd8}-\u{0ddf}\u{0df2}-\u{0df4}\u{0e01}-\u{0e30}\u{0e32}-\u{0e33}\u{0e40}-\u{0e46}\u{0e4f}-\u{0e5b}\u{0e81}-\u{0e82}\u{0e87}-\u{0e88}\u{0e94}-\u{0e97}\u{0e99}-\u{0e9f}\u{0ea1}-\u{0ea3}\u{0eaa}-\u{0eab}\u{0ead}-\u{0eb0}\u{0eb2}-\u{0eb3}\u{0ec0}-\u{0ec4}\u{0ed0}-\u{0ed9}\u{0edc}-\u{0edd}\u{0f00}-\u{0f17}\u{0f1a}-\u{0f34}\u{0f3e}-\u{0f47}\u{0f49}-\u{0f6a}\u{0f88}-\u{0f8b}\u{0fbe}-\u{0fc5}\u{0fc7}-\u{0fcc}\u{1000}-\u{1021}\u{1023}-\u{1027}\u{1029}-\u{102a}\u{1040}-\u{1057}\u{10a0}-\u{10c5}\u{10d0}-\u{10f8}\u{1100}-\u{1159}\u{115f}-\u{11a2}\u{11a8}-\u{11f9}\u{1200}-\u{1206}\u{1208}-\u{1246}\u{124a}-\u{124d}\u{1250}-\u{1256}\u{125a}-\u{125d}\u{1260}-\u{1286}\u{128a}-\u{128d}\u{1290}-\u{12ae}\u{12b2}-\u{12b5}\u{12b8}-\u{12be}\u{12c2}-\u{12c5}\u{12c8}-\u{12ce}\u{12d0}-\u{12d6}\u{12d8}-\u{12ee}\u{12f0}-\u{130e}\u{1312}-\u{1315}\u{1318}-\u{131e}\u{1320}-\u{1346}\u{1348}-\u{135a}\u{1361}-\u{137c}\u{13a0}-\u{13f4}\u{1401}-\u{1676}\u{1681}-\u{169a}\u{16a0}-\u{16f0}\u{1700}-\u{170c}\u{170e}-\u{1711}\u{1720}-\u{1731}\u{1735}-\u{1736}\u{1740}-\u{1751}\u{1760}-\u{176c}\u{176e}-\u{1770}\u{1780}-\u{17b6}\u{17be}-\u{17c5}\u{17c7}-\u{17c8}\u{17d4}-\u{17da}\u{17e0}-\u{17e9}\u{1810}-\u{1819}\u{1820}-\u{1877}\u{1880}-\u{18a8}\u{1e00}-\u{1e9b}\u{1ea0}-\u{1ef9}\u{1f00}-\u{1f15}\u{1f18}-\u{1f1d}\u{1f20}-\u{1f45}\u{1f48}-\u{1f4d}\u{1f50}-\u{1f57}\u{1f5f}-\u{1f7d}\u{1f80}-\u{1fb4}\u{1fb6}-\u{1fbc}\u{1fc2}-\u{1fc4}\u{1fc6}-\u{1fcc}\u{1fd0}-\u{1fd3}\u{1fd6}-\u{1fdb}\u{1fe0}-\u{1fec}\u{1ff2}-\u{1ff4}\u{1ff6}-\u{1ffc}\u{210a}-\u{2113}\u{2119}-\u{211d}\u{212a}-\u{212d}\u{212f}-\u{2131}\u{2133}-\u{2139}\u{213d}-\u{213f}\u{2145}-\u{2149}\u{2160}-\u{2183}\u{2336}-\u{237a}\u{249c}-\u{24e9}\u{3005}-\u{3007}\u{3021}-\u{3029}\u{3031}-\u{3035}\u{3038}-\u{303c}\u{3041}-\u{3096}\u{309d}-\u{309f}\u{30a1}-\u{30fa}\u{30fc}-\u{30ff}\u{3105}-\u{312c}\u{3131}-\u{318e}\u{3190}-\u{31b7}\u{31f0}-\u{321c}\u{3220}-\u{3243}\u{3260}-\u{327b}\u{327f}-\u{32b0}\u{32c0}-\u{32cb}\u{32d0}-\u{32fe}\u{3300}-\u{3376}\u{337b}-\u{33dd}\u{33e0}-\u{33fe}\u{3400}-\u{4db5}\u{4e00}-\u{9fa5}\u{a000}-\u{a48c}\u{ac00}-\u{d7a3}\u{e000}-\u{fa2d}\u{fa30}-\u{fa6a}\u{fb00}-\u{fb06}\u{fb13}-\u{fb17}\u{ff21}-\u{ff3a}\u{ff41}-\u{ff5a}\u{ff66}-\u{ffbe}\u{ffc2}-\u{ffc7}\u{ffca}-\u{ffcf}\u{ffd2}-\u{ffd7}\u{ffda}-\u{ffdc}\u{10300}-\u{1031e}\u{10320}-\u{10323}\u{10330}-\u{1034a}\u{10400}-\u{10425}\u{10428}-\u{1044d}\u{1d000}-\u{1d0f5}\u{1d100}-\u{1d126}\u{1d12a}-\u{1d166}\u{1d16a}-\u{1d172}\u{1d183}-\u{1d184}\u{1d18c}-\u{1d1a9}\u{1d1ae}-\u{1d1dd}\u{1d400}-\u{1d454}\u{1d456}-\u{1d49c}\u{1d49e}-\u{1d49f}\u{1d4a5}-\u{1d4a6}\u{1d4a9}-\u{1d4ac}\u{1d4ae}-\u{1d4b9}\u{1d4bd}-\u{1d4c0}\u{1d4c2}-\u{1d4c3}\u{1d4c5}-\u{1d505}\u{1d507}-\u{1d50a}\u{1d50d}-\u{1d514}\u{1d516}-\u{1d51c}\u{1d51e}-\u{1d539}\u{1d53b}-\u{1d53e}\u{1d540}-\u{1d544}\u{1d54a}-\u{1d550}\u{1d552}-\u{1d6a3}\u{1d6a8}-\u{1d7c9}\u{20000}-\u{2a6d6}\u{2f800}-\u{2fa1d}\u{f0000}-\u{ffffd}\u{100000}-\u{10fffd}\p{Cs}]))|(?m-ix:(?-mix:[\u{00aa 00b5 00ba 02ee 037a 0386 038c 0589 0903 0950 09b2 09d7 0a5e 0a83 0a8d 0ac9 0ad0 0ae0 0b40 0b57 0b83 0b9c 0bd7 0cbe 0cde 0d57 0dbd 0e84 0e8a 0e8d 0ea5 0ea7 0ebd 0ec6 0f36 0f38 0f7f 0f85 0fcf 102c 1031 1038 10fb 1248 1258 1288 12b0 12c0 1310 17dc 1f59 1f5b 1f5d 1fbe 200e 2071 207f 2102 2107 2115 2124 2126 2128 2395 1d4a2 1d4bb 1d546}\u{0041}-\u{005a}\u{0061}-\u{007a}\u{00c0}-\u{00d6}\u{00d8}-\u{00f6}\u{00f8}-\u{0220}\u{0222}-\u{0233}\u{0250}-\u{02ad}\u{02b0}-\u{02b8}\u{02bb}-\u{02c1}\u{02d0}-\u{02d1}\u{02e0}-\u{02e4}\u{0388}-\u{038a}\u{038e}-\u{03a1}\u{03a3}-\u{03ce}\u{03d0}-\u{03f5}\u{0400}-\u{0482}\u{048a}-\u{04ce}\u{04d0}-\u{04f5}\u{04f8}-\u{04f9}\u{0500}-\u{050f}\u{0531}-\u{0556}\u{0559}-\u{055f}\u{0561}-\u{0587}\u{0905}-\u{0939}\u{093d}-\u{0940}\u{0949}-\u{094c}\u{0958}-\u{0961}\u{0964}-\u{0970}\u{0982}-\u{0983}\u{0985}-\u{098c}\u{098f}-\u{0990}\u{0993}-\u{09a8}\u{09aa}-\u{09b0}\u{09b6}-\u{09b9}\u{09be}-\u{09c0}\u{09c7}-\u{09c8}\u{09cb}-\u{09cc}\u{09dc}-\u{09dd}\u{09df}-\u{09e1}\u{09e6}-\u{09f1}\u{09f4}-\u{09fa}\u{0a05}-\u{0a0a}\u{0a0f}-\u{0a10}\u{0a13}-\u{0a28}\u{0a2a}-\u{0a30}\u{0a32}-\u{0a33}\u{0a35}-\u{0a36}\u{0a38}-\u{0a39}\u{0a3e}-\u{0a40}\u{0a59}-\u{0a5c}\u{0a66}-\u{0a6f}\u{0a72}-\u{0a74}\u{0a85}-\u{0a8b}\u{0a8f}-\u{0a91}\u{0a93}-\u{0aa8}\u{0aaa}-\u{0ab0}\u{0ab2}-\u{0ab3}\u{0ab5}-\u{0ab9}\u{0abd}-\u{0ac0}\u{0acb}-\u{0acc}\u{0ae6}-\u{0aef}\u{0b02}-\u{0b03}\u{0b05}-\u{0b0c}\u{0b0f}-\u{0b10}\u{0b13}-\u{0b28}\u{0b2a}-\u{0b30}\u{0b32}-\u{0b33}\u{0b36}-\u{0b39}\u{0b3d}-\u{0b3e}\u{0b47}-\u{0b48}\u{0b4b}-\u{0b4c}\u{0b5c}-\u{0b5d}\u{0b5f}-\u{0b61}\u{0b66}-\u{0b70}\u{0b85}-\u{0b8a}\u{0b8e}-\u{0b90}\u{0b92}-\u{0b95}\u{0b99}-\u{0b9a}\u{0b9e}-\u{0b9f}\u{0ba3}-\u{0ba4}\u{0ba8}-\u{0baa}\u{0bae}-\u{0bb5}\u{0bb7}-\u{0bb9}\u{0bbe}-\u{0bbf}\u{0bc1}-\u{0bc2}\u{0bc6}-\u{0bc8}\u{0bca}-\u{0bcc}\u{0be7}-\u{0bf2}\u{0c01}-\u{0c03}\u{0c05}-\u{0c0c}\u{0c0e}-\u{0c10}\u{0c12}-\u{0c28}\u{0c2a}-\u{0c33}\u{0c35}-\u{0c39}\u{0c41}-\u{0c44}\u{0c60}-\u{0c61}\u{0c66}-\u{0c6f}\u{0c82}-\u{0c83}\u{0c85}-\u{0c8c}\u{0c8e}-\u{0c90}\u{0c92}-\u{0ca8}\u{0caa}-\u{0cb3}\u{0cb5}-\u{0cb9}\u{0cc0}-\u{0cc4}\u{0cc7}-\u{0cc8}\u{0cca}-\u{0ccb}\u{0cd5}-\u{0cd6}\u{0ce0}-\u{0ce1}\u{0ce6}-\u{0cef}\u{0d02}-\u{0d03}\u{0d05}-\u{0d0c}\u{0d0e}-\u{0d10}\u{0d12}-\u{0d28}\u{0d2a}-\u{0d39}\u{0d3e}-\u{0d40}\u{0d46}-\u{0d48}\u{0d4a}-\u{0d4c}\u{0d60}-\u{0d61}\u{0d66}-\u{0d6f}\u{0d82}-\u{0d83}\u{0d85}-\u{0d96}\u{0d9a}-\u{0db1}\u{0db3}-\u{0dbb}\u{0dc0}-\u{0dc6}\u{0dcf}-\u{0dd1}\u{0dd8}-\u{0ddf}\u{0df2}-\u{0df4}\u{0e01}-\u{0e30}\u{0e32}-\u{0e33}\u{0e40}-\u{0e46}\u{0e4f}-\u{0e5b}\u{0e81}-\u{0e82}\u{0e87}-\u{0e88}\u{0e94}-\u{0e97}\u{0e99}-\u{0e9f}\u{0ea1}-\u{0ea3}\u{0eaa}-\u{0eab}\u{0ead}-\u{0eb0}\u{0eb2}-\u{0eb3}\u{0ec0}-\u{0ec4}\u{0ed0}-\u{0ed9}\u{0edc}-\u{0edd}\u{0f00}-\u{0f17}\u{0f1a}-\u{0f34}\u{0f3e}-\u{0f47}\u{0f49}-\u{0f6a}\u{0f88}-\u{0f8b}\u{0fbe}-\u{0fc5}\u{0fc7}-\u{0fcc}\u{1000}-\u{1021}\u{1023}-\u{1027}\u{1029}-\u{102a}\u{1040}-\u{1057}\u{10a0}-\u{10c5}\u{10d0}-\u{10f8}\u{1100}-\u{1159}\u{115f}-\u{11a2}\u{11a8}-\u{11f9}\u{1200}-\u{1206}\u{1208}-\u{1246}\u{124a}-\u{124d}\u{1250}-\u{1256}\u{125a}-\u{125d}\u{1260}-\u{1286}\u{128a}-\u{128d}\u{1290}-\u{12ae}\u{12b2}-\u{12b5}\u{12b8}-\u{12be}\u{12c2}-\u{12c5}\u{12c8}-\u{12ce}\u{12d0}-\u{12d6}\u{12d8}-\u{12ee}\u{12f0}-\u{130e}\u{1312}-\u{1315}\u{1318}-\u{131e}\u{1320}-\u{1346}\u{1348}-\u{135a}\u{1361}-\u{137c}\u{13a0}-\u{13f4}\u{1401}-\u{1676}\u{1681}-\u{169a}\u{16a0}-\u{16f0}\u{1700}-\u{170c}\u{170e}-\u{1711}\u{1720}-\u{1731}\u{1735}-\u{1736}\u{1740}-\u{1751}\u{1760}-\u{176c}\u{176e}-\u{1770}\u{1780}-\u{17b6}\u{17be}-\u{17c5}\u{17c7}-\u{17c8}\u{17d4}-\u{17da}\u{17e0}-\u{17e9}\u{1810}-\u{1819}\u{1820}-\u{1877}\u{1880}-\u{18a8}\u{1e00}-\u{1e9b}\u{1ea0}-\u{1ef9}\u{1f00}-\u{1f15}\u{1f18}-\u{1f1d}\u{1f20}-\u{1f45}\u{1f48}-\u{1f4d}\u{1f50}-\u{1f57}\u{1f5f}-\u{1f7d}\u{1f80}-\u{1fb4}\u{1fb6}-\u{1fbc}\u{1fc2}-\u{1fc4}\u{1fc6}-\u{1fcc}\u{1fd0}-\u{1fd3}\u{1fd6}-\u{1fdb}\u{1fe0}-\u{1fec}\u{1ff2}-\u{1ff4}\u{1ff6}-\u{1ffc}\u{210a}-\u{2113}\u{2119}-\u{211d}\u{212a}-\u{212d}\u{212f}-\u{2131}\u{2133}-\u{2139}\u{213d}-\u{213f}\u{2145}-\u{2149}\u{2160}-\u{2183}\u{2336}-\u{237a}\u{249c}-\u{24e9}\u{3005}-\u{3007}\u{3021}-\u{3029}\u{3031}-\u{3035}\u{3038}-\u{303c}\u{3041}-\u{3096}\u{309d}-\u{309f}\u{30a1}-\u{30fa}\u{30fc}-\u{30ff}\u{3105}-\u{312c}\u{3131}-\u{318e}\u{3190}-\u{31b7}\u{31f0}-\u{321c}\u{3220}-\u{3243}\u{3260}-\u{327b}\u{327f}-\u{32b0}\u{32c0}-\u{32cb}\u{32d0}-\u{32fe}\u{3300}-\u{3376}\u{337b}-\u{33dd}\u{33e0}-\u{33fe}\u{3400}-\u{4db5}\u{4e00}-\u{9fa5}\u{a000}-\u{a48c}\u{ac00}-\u{d7a3}\u{e000}-\u{fa2d}\u{fa30}-\u{fa6a}\u{fb00}-\u{fb06}\u{fb13}-\u{fb17}\u{ff21}-\u{ff3a}\u{ff41}-\u{ff5a}\u{ff66}-\u{ffbe}\u{ffc2}-\u{ffc7}\u{ffca}-\u{ffcf}\u{ffd2}-\u{ffd7}\u{ffda}-\u{ffdc}\u{10300}-\u{1031e}\u{10320}-\u{10323}\u{10330}-\u{1034a}\u{10400}-\u{10425}\u{10428}-\u{1044d}\u{1d000}-\u{1d0f5}\u{1d100}-\u{1d126}\u{1d12a}-\u{1d166}\u{1d16a}-\u{1d172}\u{1d183}-\u{1d184}\u{1d18c}-\u{1d1a9}\u{1d1ae}-\u{1d1dd}\u{1d400}-\u{1d454}\u{1d456}-\u{1d49c}\u{1d49e}-\u{1d49f}\u{1d4a5}-\u{1d4a6}\u{1d4a9}-\u{1d4ac}\u{1d4ae}-\u{1d4b9}\u{1d4bd}-\u{1d4c0}\u{1d4c2}-\u{1d4c3}\u{1d4c5}-\u{1d505}\u{1d507}-\u{1d50a}\u{1d50d}-\u{1d514}\u{1d516}-\u{1d51c}\u{1d51e}-\u{1d539}\u{1d53b}-\u{1d53e}\u{1d540}-\u{1d544}\u{1d54a}-\u{1d550}\u{1d552}-\u{1d6a3}\u{1d6a8}-\u{1d7c9}\u{20000}-\u{2a6d6}\u{2f800}-\u{2fa1d}\u{f0000}-\u{ffffd}\u{100000}-\u{10fffd}\p{Cs}]).*?(?-mix:[\u{05be 05c0 05c3 061b 061f 06dd 0710 07b1 200f fb1d fb3e}\u{05d0}-\u{05ea}\u{05f0}-\u{05f4}\u{0621}-\u{063a}\u{0640}-\u{064a}\u{066d}-\u{066f}\u{0671}-\u{06d5}\u{06e5}-\u{06e6}\u{06fa}-\u{06fe}\u{0700}-\u{070d}\u{0712}-\u{072c}\u{0780}-\u{07a5}\u{fb1f}-\u{fb28}\u{fb2a}-\u{fb36}\u{fb38}-\u{fb3c}\u{fb40}-\u{fb41}\u{fb43}-\u{fb44}\u{fb46}-\u{fbb1}\u{fbd3}-\u{fd3d}\u{fd50}-\u{fd8f}\u{fd92}-\u{fdc7}\u{fdf0}-\u{fdfc}\u{fe70}-\u{fe74}\u{fe76}-\u{fefc}])))|(?-mix:(?m-ix:\A(?-mix:[^\u{05be 05c0 05c3 061b 061f 06dd 0710 07b1 200f fb1d fb3e}\u{05d0}-\u{05ea}\u{05f0}-\u{05f4}\u{0621}-\u{063a}\u{0640}-\u{064a}\u{066d}-\u{066f}\u{0671}-\u{06d5}\u{06e5}-\u{06e6}\u{06fa}-\u{06fe}\u{0700}-\u{070d}\u{0712}-\u{072c}\u{0780}-\u{07a5}\u{fb1f}-\u{fb28}\u{fb2a}-\u{fb36}\u{fb38}-\u{fb3c}\u{fb40}-\u{fb41}\u{fb43}-\u{fb44}\u{fb46}-\u{fbb1}\u{fbd3}-\u{fd3d}\u{fd50}-\u{fd8f}\u{fd92}-\u{fdc7}\u{fdf0}-\u{fdfc}\u{fe70}-\u{fe74}\u{fe76}-\u{fefc}]).*?(?-mix:[\u{05be 05c0 05c3 061b 061f 06dd 0710 07b1 200f fb1d fb3e}\u{05d0}-\u{05ea}\u{05f0}-\u{05f4}\u{0621}-\u{063a}\u{0640}-\u{064a}\u{066d}-\u{066f}\u{0671}-\u{06d5}\u{06e5}-\u{06e6}\u{06fa}-\u{06fe}\u{0700}-\u{070d}\u{0712}-\u{072c}\u{0780}-\u{07a5}\u{fb1f}-\u{fb28}\u{fb2a}-\u{fb36}\u{fb38}-\u{fb3c}\u{fb40}-\u{fb41}\u{fb43}-\u{fb44}\u{fb46}-\u{fbb1}\u{fbd3}-\u{fd3d}\u{fd50}-\u{fd8f}\u{fd92}-\u{fdc7}\u{fdf0}-\u{fdfc}\u{fe70}-\u{fe74}\u{fe76}-\u{fefc}]))|(?m-ix:(?-mix:[\u{05be 05c0 05c3 061b 061f 06dd 0710 07b1 200f fb1d fb3e}\u{05d0}-\u{05ea}\u{05f0}-\u{05f4}\u{0621}-\u{063a}\u{0640}-\u{064a}\u{066d}-\u{066f}\u{0671}-\u{06d5}\u{06e5}-\u{06e6}\u{06fa}-\u{06fe}\u{0700}-\u{070d}\u{0712}-\u{072c}\u{0780}-\u{07a5}\u{fb1f}-\u{fb28}\u{fb2a}-\u{fb36}\u{fb38}-\u{fb3c}\u{fb40}-\u{fb41}\u{fb43}-\u{fb44}\u{fb46}-\u{fbb1}\u{fbd3}-\u{fd3d}\u{fd50}-\u{fd8f}\u{fd92}-\u{fdc7}\u{fdf0}-\u{fdfc}\u{fe70}-\u{fe74}\u{fe76}-\u{fefc}]).*?(?-mix:[^\u{05be 05c0 05c3 061b 061f 06dd 0710 07b1 200f fb1d fb3e}\u{05d0}-\u{05ea}\u{05f0}-\u{05f4}\u{0621}-\u{063a}\u{0640}-\u{064a}\u{066d}-\u{066f}\u{0671}-\u{06d5}\u{06e5}-\u{06e6}\u{06fa}-\u{06fe}\u{0700}-\u{070d}\u{0712}-\u{072c}\u{0780}-\u{07a5}\u{fb1f}-\u{fb28}\u{fb2a}-\u{fb36}\u{fb38}-\u{fb3c}\u{fb40}-\u{fb41}\u{fb43}-\u{fb44}\u{fb46}-\u{fbb1}\u{fbd3}-\u{fd3d}\u{fd50}-\u{fd8f}\u{fd92}-\u{fdc7}\u{fdf0}-\u{fdfc}\u{fe70}-\u{fe74}\u{fe76}-\u{fefc}])\z))/.freeze

    # A Regexp matching strings prohibited by RFC4013 §2.3 and §2.4.
    #
    # This combines PROHIBITED_OUTPUT and BIDI_FAILURE.
    PROHIBITED = Regexp.union(
      PROHIBITED_OUTPUT, BIDI_FAILURE,
    )

    # A Regexp matching strings prohibited by RFC4013 §2.3, §2.4, and §2.5.
    #
    # This combines PROHIBITED_OUTPUT_STORED and BIDI_FAILURE.
    PROHIBITED_STORED = Regexp.union(
      PROHIBITED_OUTPUT_STORED, BIDI_FAILURE,
    )

  end
end
