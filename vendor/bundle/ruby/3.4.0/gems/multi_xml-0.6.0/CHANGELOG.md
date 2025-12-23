0.5.5
-----
* [Fix symbolize_keys function](https://github.com/sferik/multi_xml/commit/a4cae3aeb690999287cd30206399abaa5ce1ae81)
* [Fix Nokogiri parser for the same attr and inner element name](https://github.com/sferik/multi_xml/commit/a28ed86e2d7826b2edeed98552736b4c7ca52726)

0.5.4
-----
* [Add option to not cast parsed values](https://github.com/sferik/multi_xml/commit/44fc05fbcfd60cc8b555b75212471fab29fa8cd0)
* [Use message instead of to_s](https://github.com/sferik/multi_xml/commit/b06f0114434ffe1957dd7bc2712cb5b76c1b45fe)

0.5.3
-----
* [Add cryptographic signature](https://github.com/sferik/multi_xml/commit/f39f0c74308090737816c622dbb7d7aa28c646c0)

0.5.2
-----
* [Remove ability to parse symbols and YAML](https://github.com/sferik/multi_xml/pull/34)

0.5.1
-----
* [Revert "Reset @@parser in between specs"](https://github.com/sferik/multi_xml/issues/28)

0.5.0
-----
* [Reset @@parser in between specs](https://github.com/sferik/multi_xml/commit/b562bed265918b43ac1c4c638ae3a7ffe95ecd83)
* [Add attributes being passed through on content nodes](https://github.com/sferik/multi_xml/commit/631a8bb3c2253db0024f77f47c16d5a53b8128fd)

0.4.4
-----
* [Fix regression in MultiXml.parse](https://github.com/sferik/multi_xml/commit/45ae597d9a35cbd89cc7f5518c85bac30199fc06)

0.4.3
-----
* [Make parser a class variable](https://github.com/sferik/multi_xml/commit/6804ffc8680ed6466c66f2472f5e016c412c2c24)
* [Add TYPE_NAMES constant](https://github.com/sferik/multi_xml/commit/72a21f2e86c8e3ac9689cee5f3a62102cfb98028)

0.4.2
-----
* [Fix bug in dealing with xml element attributes for both REXML and Ox](https://github.com/sferik/multi_xml/commit/ba3c1ac427ff0268abaf8186fb4bd81100c99559)
* [Make Ox the preferred XML parser](https://github.com/sferik/multi_xml/commit/0a718d740c30fba426f300a929cda9ee8250d238)

0.4.1
-----
* [Use the SAX like parser with Ox](https://github.com/sferik/multi_xml/commit/d289d42817a32e48483c00d5361c76fbea62a166)

0.4.0
-----
* [Add support for Ox](https://github.com/sferik/multi_xml/pull/14)

0.3.0
-----
* [Remove core class monkeypatches](https://github.com/sferik/multi_xml/commit/f7cc3ce4d2924c0e0adc6935d1fba5ec79282938)
* [Sort out some class / singleton class issues](https://github.com/sferik/multi_xml/commit/a5dac06bcf658facaaf7afa295f1291c7be15a44)
* [Have parsers refer to toplevel CONTENT_ROOT instead of defining it](https://github.com/sferik/multi_xml/commit/94e6fa49e69b2a2467a0e6d3558f7d9815cae47e)
* [Move redundant input sanitizing to top-level](https://github.com/sferik/multi_xml/commit/4874148214dbbd2e5a4b877734e2519af42d6132)
* [Refactor libxml and nokogiri parsers to inherit from a common ancestor](https://github.com/sferik/multi_xml/commit/e0fdffcbfe641b6aaa3952ffa0570a893de325c2)

0.2.2
-----
* [Respect the global load path](https://github.com/sferik/multi_xml/commit/68eb3011b37f0e0222bb842abd2a78e1285a97c1)

0.2.1
-----
* [Add BlueCloth gem as development dependency for Markdown formatting](https://github.com/sferik/multi_xml/commit/18195cd1789176709f68f0d7f8df7fc944fe4d24)
* [Replace BlueCloth with Maruku for JRuby compatibility](https://github.com/sferik/multi_xml/commit/bad5516a5ec5e7ef7fc5a35c411721522357fa19)

0.2.0
-----
* [Do not automatically load all library files](https://github.com/sferik/multi_xml/commit/dbd0447e062e8930118573c5453150e9371e5955)

0.1.4
-----
* [Preserve backtrace when catching/throwing exceptions](https://github.com/sferik/multi_xml/commit/7475ee90201c2701fddd524082832d16ca62552d)

0.1.3
-----
* [Common error handling for all parsers](https://github.com/sferik/multi_xml/commit/5357c28eddc14e921fd1be1f445db602a8dddaf2)

0.1.2
-----
* [Make wrap an Array class method](https://github.com/sferik/multi_xml/commit/28307b69bd1d9460353c861466e425c2afadcf56)

0.1.1
-----
* [Fix parsing for strings that contain newlines](https://github.com/sferik/multi_xml/commit/68087a4ce50b5d63cfa60d6f1fcbc2f6d689e43f)

0.1.0
-----
* [Add support for LibXML and Nokogiri](https://github.com/sferik/multi_xml/commit/856bb17fce66601e0b3d3eb3b64dbeb25aed3bca)

0.0.1
-----
* [REXML support](https://github.com/sferik/multi_xml/commit/2a848384a7b90fb3e26b5a8d4dc3fa3e3f2db5fc)
