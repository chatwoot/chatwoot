# IANA Language Tags #

[![Open Data](https://assets.okfn.org/images/ok_buttons/od_80x15_blue.png)](http://opendefinition.org/)

IANA's [official repository](http://www.iana.org/assignments/language-subtag-registry/language-subtag-registry) is in [record-jar](http://www.inter-locale.com/ID/draft-phillips-record-jar-01.html) format and is hard to parse. This project provides neatly organized JSON files representing that data.

See `data/` for all the JSON files available. The `registry.json` file contains all records in a flat array and `meta.json` contains its metadata. There's a separate JSON file for each 'scope' (e.g. `macrolanguage.json`) and 'type' (e.g. `language.json`). These files contain JSON objects keyed by tag or subtag and with the index integer for the corresponding entry in `registry.json` as a value. This makes lookups fast.

## Updates ##

This project will be updated as the registry changes. Non-breaking updates will result in the patch version number being bumped.

Run `make update` to force an update from the latest official IANA-hosted version. The registry file format is converted to JSON automatically and the files in `data/` are updated.

If there are changes, please make a pull request.

## Usage ##

See [language-tags](https://github.com/mattcg/language-tags) for a Javascript API.

## Credits and collaboration ##

The JSON database is licensed an [Open Data Commons Attribution License (ODC-BY)](http://opendatacommons.org/licenses/by/1.0/).

Comments, feedback and suggestions are welcome. Please feel free to raise an issue or pull request. Enjoy.
