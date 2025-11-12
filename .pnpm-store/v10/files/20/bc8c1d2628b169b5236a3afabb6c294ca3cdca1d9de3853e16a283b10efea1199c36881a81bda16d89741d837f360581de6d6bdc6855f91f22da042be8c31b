// Various examples

import { strict as assert } from "assert";
import { isLangCode } from "../dist/is-language-code.esm.js";

assert.equal(isLangCode("de").res, true);
// => true because it's a German language code

assert.equal(isLangCode("fr").res, true);
// => true because it's a French language code

assert.equal(isLangCode("ja").res, true);
// => true because it's a Japanese language code

assert.equal(isLangCode("zzz").res, false);
// => false - unrecognised. npm package "ietf-language-tag-regex" would fail this

assert.equal(isLangCode("1").res, false);
// => false - not recognised language code

assert.equal(isLangCode("x-klingon").res, true);
// => true - private use

assert.equal(isLangCode("x-whatever").res, true);
// => true - private use

assert.equal(isLangCode("zh-Hant").res, true);
// => true - Chinese written using the Traditional Chinese script

assert.equal(isLangCode("zh-cmn-Hans-CN").res, true);
// => true - Chinese, Mandarin, Simplified script, as used in China

assert.equal(isLangCode("zh-Hans-CN").res, true);
// => true - Chinese written using the Simplified script as used in mainland China

assert.equal(isLangCode("sr-Latn-RS").res, true);
// => true - Serbian written using the Latin script as used in Serbia

assert.equal(isLangCode("sl-rozaj").res, true);
// => true - Resian dialect of Slovenian

assert.equal(isLangCode("sl-nedis").res, true);
// => true - Nadiza dialect of Slovenian

assert.equal(isLangCode("de-CH-1901").res, true);
// => true - German as used in Switzerland using the 1901 variant [orthography]

assert.equal(isLangCode("sl-IT-nedis").res, true);
// => true - Slovenian as used in Italy, Nadiza dialect

assert.equal(isLangCode("hy-Latn-IT-arevela").res, true);
// => true - Eastern Armenian written in Latin script, as used in Italy

assert.equal(isLangCode("en-US").res, true);
// => true - English as used in the United States

assert.equal(isLangCode("de-CH-x-phonebk").res, true);
// => true - private use subtag (x-)

assert.equal(isLangCode("az-Arab-x-AZE-derbend").res, true);
// => true - private use subtag

assert.equal(isLangCode("x-whatever").res, true);
// => true - private use subtag using singleton x-

assert.equal(isLangCode("qaa-Qaaa-QM-x-southern").res, true);
// => true

assert.equal(isLangCode("de-Qaaa").res, true);
// => true - private use script subtag (Qaaa)

assert.equal(isLangCode("sr-Latn-QM").res, true);
// => true - Serbian, Latin script, private region QM

assert.equal(isLangCode("en-US-u-islamcal").res, true);
// => true - tag with extension

assert.equal(isLangCode("zh-CN-a-myext-x-private").res, true);
// => true - tag with extension

assert.equal(isLangCode("en-a-myext-b-another").res, true);
// => true - tag with extension

assert.equal(isLangCode("de-419-DE").res, false);
// => false - two region tags

assert.equal(isLangCode("a-DE").res, false);
// => false - use of a single-character subtag in primary position

assert.equal(isLangCode("ar-a-aaa-b-bbb-a-ccc").res, false);
// => false - two extensions with same single-letter prefix
