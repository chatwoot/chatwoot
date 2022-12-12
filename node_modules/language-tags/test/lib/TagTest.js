/**
 * @author Matthew Caruana Galizia <m@m.cg>
 * @license MIT: http://mattcg.mit-license.org/
 * @copyright Copyright (c) 2013, Matthew Caruana Galizia
 */

/*jshint node:true*/
/*global test, suite*/

'use strict';

var assert = require('assert');
var Tag = require(process.env.TEST_LIB_PATH + '/Tag');

suite('Tag', function() {

	test('tag.type() returns \'grandfathered\'', function() {

		// Classified as grandfathered in the registry.
		assert.equal(new Tag('en-GB-oed').type(), 'grandfathered');
	});

	test('tag.type() returns \'redundant\'', function() {

		// Classified as redundant in the registry.
		assert.equal(new Tag('az-Arab').type(), 'redundant');
		assert.equal(new Tag('uz-Cyrl').type(), 'redundant');
		assert.equal(new Tag('zh-cmn-Hant').type(), 'redundant');
	});

	test('tag.type() returns \'tag\'', function() {

		// Maltese (mt) is a subtag but valid as a standalone tag.
		assert.equal(new Tag('mt').type(), 'tag');
	});

	test('tag.subtags() returns subtags with correct type', function() {
		var tag, subtags;

		tag = new Tag('en');
		subtags = tag.subtags();
		assert.equal(subtags.length, 1);
		assert.equal(subtags[0].type(), 'language');
		assert.equal(subtags[0].format(), 'en');

		// Lowercase - lookup should be case insensitive.
		tag = new Tag('en-mt');
		subtags = tag.subtags();
		assert.equal(subtags.length, 2);
		assert.equal(subtags[0].type(), 'language');
		assert.equal(subtags[0].format(), 'en');
		assert.equal(subtags[1].type(), 'region');
		assert.equal(subtags[1].format(), 'MT');

		tag = new Tag('en-mt-arab');
		subtags = tag.subtags();
		assert.equal(subtags.length, 3);
		assert.equal(subtags[0].type(), 'language');
		assert.equal(subtags[0].format(), 'en');
		assert.equal(subtags[1].type(), 'region');
		assert.equal(subtags[1].format(), 'MT');
		assert.equal(subtags[2].type(), 'script');
		assert.equal(subtags[2].format(), 'Arab');
	});

	test('tag.subtags() returns only existent subtags', function() {
		var tag, subtags;

		tag = new Tag('hello');
		assert.deepEqual(tag.subtags(), []);

		tag = new Tag('en-hello');
		subtags = tag.subtags();
		assert.equal(subtags.length, 1);
		assert.equal(subtags[0].type(), 'language');
		assert.equal(subtags[0].format(), 'en');
	});

	test('tag.subtags() handles private tags', function() {
		var tag, subtags;

		tag = new Tag('en-GB-x-Beano');
		subtags = tag.subtags();
		assert.equal(subtags.length, 2);
		assert.equal(subtags[0].type(), 'language');
		assert.equal(subtags[0].format(), 'en');
		assert.equal(subtags[1].type(), 'region');
		assert.equal(subtags[1].format(), 'GB');
	});

	test('tag.subtags() returns empty array for grandfathered tag', function() {
		var tag, subtags;

		tag = new Tag('en-GB-oed');
		assert.equal(tag.type(), 'grandfathered');
		subtags = tag.subtags();
		assert.deepEqual(subtags, []);
		assert.equal(undefined, tag.region());
		assert.equal(undefined, tag.language());
	});

	test('tag.subtags() returns array for redundant tag', function() {
		var tag, subtags;

		tag = new Tag('az-Arab');
		assert.equal(tag.type(), 'redundant');
		subtags = tag.subtags();
		assert.equal(2, subtags.length);
		assert.equal(subtags[0].format(), 'az');
		assert.equal(subtags[1].format(), 'Arab');
	});

	test('tag.errors() returns error for deprecated grandfathered tag', function() {
		var tag, errs, err;

		// Grandfathered and deprecated, therefore invalid.
		tag = new Tag('art-lojban');
		assert.equal(tag.type(), 'grandfathered');
		assert(tag.deprecated());
		errs = tag.errors();
		assert.equal(errs.length, 1);
		err = errs[0];
		assert.equal(err.code, Tag.ERR_DEPRECATED);
		assert.equal(err.tag, 'art-lojban');
	});

	test('tag.errors() returns error for deprecated redundant tag', function() {
		var tag, errs, err;

		// Redundant and deprecated, therefore invalid.
		tag = new Tag('zh-cmn');
		assert.equal(tag.type(), 'redundant');
		assert(tag.deprecated());
		errs = tag.errors();
		assert.equal(errs.length, 1);
		err = errs[0];
		assert.equal(err.code, Tag.ERR_DEPRECATED);
		assert.equal(err.tag, 'zh-cmn');
	});

	test('tag.errors() returns error if contains deprecated subtags', function() {
		var errs, err;

		// Moldovan (mo) is deprecated as a language.
		errs = new Tag('mo').errors();
		assert.equal(errs.length, 1);
		err = errs[0];
		assert.equal(err.code, Tag.ERR_SUBTAG_DEPRECATED);
		assert.equal(err.message, 'The subtag \'mo\' is deprecated.');

		// Neutral Zone (NT) is deprecated as a region.
		errs = new Tag('en-NT').errors();
		assert.equal(errs.length, 1);
		err = errs[0];
		assert.equal(err.code, Tag.ERR_SUBTAG_DEPRECATED);
		assert.equal(err.message, 'The subtag \'NT\' is deprecated.');
	});

	test('tag.errors() returns empty array for valid tag', function() {
		assert.equal(new Tag('en').errors().length, 0);
	});

	test('tag.errors() returns error if no language tag and not grandfathered or redundant', function() {
		var errs, err;

		// Test with empty tag.
		errs = new Tag('').errors();
		assert.equal(errs.length, 1);
		err = errs[0];
		assert.equal(err.code, Tag.ERR_NO_LANGUAGE);
		assert.equal(err.message, 'Empty tag.');

		errs = new Tag('IQ-Arab').errors();
		assert.equal(errs.length, 1);
		err = errs[0];
		assert.equal(err.code, Tag.ERR_NO_LANGUAGE);
		assert.equal(err.message, 'Missing language tag in \'iq-arab\'.');

		errs = new Tag('419').errors();
		assert.equal(errs.length, 1);
		err = errs[0];
		assert.equal(err.code, Tag.ERR_NO_LANGUAGE);
		assert.equal(err.message, 'Missing language tag in \'419\'.');
	});

	test('tag.errors() returns error if language subtag not at front of tag', function() {
		var errs, err;

		errs = new Tag('GB-en').errors();
		assert.equal(errs.length, 1);
		err = errs[0];
		assert.equal(err.code, Tag.ERR_NO_LANGUAGE);
		assert.equal(err.message, 'Missing language tag in \'gb-en\'.');
	});

	test('tag.errors() returns error if more than one language subtag appears', function() {
		var errs, err;

		errs = new Tag('en-en').errors();
		assert.equal(errs.length, 1);
		err = errs[0];
		assert.equal(err.code, Tag.ERR_EXTRA_LANGUAGE);
		assert.equal(err.message, 'Extra language subtag \'en\' found.');

		errs = new Tag('en-en-GB').errors();
		assert.equal(errs.length, 1);
		err = errs[0];
		assert.equal(err.code, Tag.ERR_EXTRA_LANGUAGE);
		assert.equal(err.message, 'Extra language subtag \'en\' found.');

		errs = new Tag('ko-en').errors();
		assert.equal(errs.length, 1);
		err = errs[0];
		assert.equal(err.code, Tag.ERR_EXTRA_LANGUAGE);
		assert.equal(err.message, 'Extra language subtag \'en\' found.');
	});

	test('tag.errors() returns error if more than one region subtag appears', function() {
		var errs, err;

		errs = new Tag('en-GB-GB').errors();
		assert.equal(errs.length, 1);
		err = errs[0];
		assert.equal(err.code, Tag.ERR_EXTRA_REGION);
		assert.equal(err.message, 'Extra region subtag \'GB\' found.');

		errs = new Tag('ko-mt-mt').errors();
		assert.equal(errs.length, 1);
		err = errs[0];
		assert.equal(err.code, Tag.ERR_EXTRA_REGION);
		assert.equal(err.message, 'Extra region subtag \'MT\' found.');
	});

	test('tag.errors() returns error if more than one script subtag appears', function() {
		var errs, err;

		errs = new Tag('mt-Arab-Arab').errors();
		assert.equal(errs.length, 1);
		err = errs[0];
		assert.equal(err.code, Tag.ERR_EXTRA_SCRIPT);
		assert.equal(err.message, 'Extra script subtag \'Arab\' found.');

		errs = new Tag('en-Cyrl-Latn').errors();
		assert.equal(errs.length, 1);
		err = errs[0];
		assert.equal(err.code, Tag.ERR_EXTRA_SCRIPT);
		assert.equal(err.message, 'Extra script subtag \'Latn\' found.');

		// First error should be regarding suppress-script, second should be regarding extra script.
		errs = new Tag('en-Latn-Cyrl').errors();
		assert.equal(errs.length, 2);
		err = errs[0];
		assert.equal(err.code, Tag.ERR_SUPPRESS_SCRIPT);
		assert.equal(err.message, 'The script subtag \'Latn\' is the same as the language suppress-script.');
		err = errs[1];
		assert.equal(err.code, Tag.ERR_EXTRA_SCRIPT);
		assert.equal(err.message, 'Extra script subtag \'Cyrl\' found.');
	},

	'tag.errors() returns error if more than one extlang subtag appears', function() {
		var errs, err;

		errs = new Tag('en-asp-bog').errors();
		assert.equal(errs.length, 1);
		err = errs[0];
		assert.equal(err.code, Tag.ERR_EXTRA_EXTLANG);
		assert.equal(err.message, 'Extra extlang subtag \'bog\' found.');
	});

	test('tag.errors() returns error if a duplicate variant subtag appears', function() {
		var errs, err;

		errs = new Tag('ca-valencia-valencia').errors();
		assert.equal(errs.length, 1);
		err = errs[0];
		assert.equal(err.code, Tag.ERR_DUPLICATE_VARIANT);
		assert.equal(err.message, 'Duplicate variant subtag \'valencia\' found.');
	});

	test('tag.errors() returns error if private-use subtag contains more than 8 characters', function() {
		var errs, err;

		// i.e. more than 8 in each component, not in total.
		errs = new Tag('en-x-more-than-eight-chars').errors();
		assert.equal(errs.length, 0);

		errs = new Tag('en-x-morethaneightchars').errors();
		assert.equal(errs.length, 1);
		err = errs[0];
		assert.equal(err.code, Tag.ERR_TOO_LONG);
		assert.equal(err.message, 'The private-use subtag \'morethaneightchars\' is too long.');
	});

	test('tag.errors() returns error if script subtag is same as language suppress-script', function() {
		var errs, err;

		errs = new Tag('gsw-Latn').errors();
		assert.equal(errs.length, 1);
		err = errs[0];
		assert.equal(err.code, Tag.ERR_SUPPRESS_SCRIPT);
		assert.equal(err.message, 'The script subtag \'Latn\' is the same as the language suppress-script.');

		errs = new Tag('en-Latn-GB').errors();
		assert.equal(errs.length, 1);
		err = errs[0];
		assert.equal(err.code, Tag.ERR_SUPPRESS_SCRIPT);
		assert.equal(err.message, 'The script subtag \'Latn\' is the same as the language suppress-script.');
	});

	test('tag.errors() returns error if subtags are in wrong order', function() {
		var errs, err;

		errs = new Tag('mt-MT-Arab').errors();
		assert.equal(errs.length, 1);
		err = errs[0];
		assert.equal(err.code, Tag.ERR_WRONG_ORDER);
		assert.equal(err.message, 'The subtag \'MT\' should not appear before \'Arab\'.');
	});

	test('tag.valid() returns true for valid tag', function() {
		assert(new Tag('en').valid());
		assert(new Tag('en-GB').valid());
		assert(new Tag('gsw').valid());
		assert(new Tag('de-CH').valid());
	});

	test('tag.valid() returns true for subtag followed by private tag', function() {
		assert(new Tag('en-x-whatever').valid());
	});

	test('tag.valid() returns true for non-deprecated grandfathered tag', function() {
		var tag;

		// Grandfathered but not deprecated, therefore valid.
		tag = new Tag('i-default');
		assert.equal(tag.type(), 'grandfathered');
		assert(!tag.deprecated());
		assert(tag.valid());
	});

	test('tag.valid() returns true for non-deprecated redundant tag', function() {
		var tag;

		// Redundant but not deprecated, therefore valid.
		tag = new Tag('zh-Hans');
		assert.equal(tag.type(), 'redundant');
		assert(!tag.deprecated());
		assert(tag.valid());
		tag = new Tag('es-419');
		assert.equal(tag.type(), 'redundant');
		assert(!tag.deprecated());
		assert(tag.valid());
	});

	test('tag.valid() returns false for non-existent tag', function() {
		assert(!new Tag('zzz').valid());
		assert(!new Tag('zzz-Latn').valid());
		assert(!new Tag('en-Lzzz').valid());
	});

	test('tag.valid() returns false for deprecated grandfathered tag', function() {
		var tag;

		// Grandfathered and deprecated, therefore invalid.
		tag = new Tag('art-lojban');
		assert.equal(tag.type(), 'grandfathered');
		assert(tag.deprecated());
		assert(!tag.valid());
	});

	test('tag.valid() returns false for deprecated redundant tag', function() {
		var tag;

		// Redundant and deprecated, therefore invalid.
		tag = new Tag('zh-cmn');
		assert.equal(tag.type(), 'redundant');
		assert(tag.deprecated());
		assert(!tag.valid());
		tag = new Tag('zh-cmn-Hans');
		assert.equal(tag.type(), 'redundant');
		assert(tag.deprecated());
		assert(!tag.valid());
	});

	test('tag.valid() returns false if contains deprecated subtags', function() {

		// Moldovan (mo) is deprecated as a language.
		assert(!new Tag('mo').valid());

		// Neutral Zone (NT) is deprecated as a region.
		assert(!new Tag('en-NT').valid());
	});

	test('tag.valid() returns false for tag with redundant script subtag', function() {

		// Swiss German (gsw) has a suppress script of Latn.
		assert(!new Tag('gsw-Latn').valid());
	});

	test('tag.valid() returns false if tag contains no language tag and is not grandfathered or redundant', function() {
		assert(!new Tag('IQ-Arab').valid());
		assert(!new Tag('419').valid());
	});

	test('tag.valid() returns false if language subtag is not front of tag', function() {
		assert(!new Tag('GB-en').valid());
	});

	test('tag.valid() returns false if more than one language subtag appears', function() {
		assert(!new Tag('en-en').valid());
		assert(!new Tag('ko-en').valid());
	});

	test('tag.valid() returns false if more than one region subtag appears', function() {
		assert(!new Tag('en-001-gb').valid());
		assert(!new Tag('gb-001').valid());
	});

	test('tag.valid() returns false if more than one extlang subtag appears', function() {
		assert(!new Tag('en-asp-bog').valid());
	});

	test('tag.valid() returns false if more than one script subtag appears', function() {
		assert(!new Tag('arb-Latn-Cyrl').valid());
	});

	test('tag.valid() returns false if a duplicate variant subtag appears', function() {
		assert(!new Tag('ca-valencia-valencia').valid());
	});

	test('tag.valid() returns false if private-use subtag contains more than 8 characters', function() {

		// i.e. more than 8 in each component, not in total.
		assert(new Tag('en-x-more-than-eight-chars').valid());
		assert(!new Tag('en-x-morethaneightchars').valid());
	});

	test('tag.valid() returns false if script subtag is same as language suppress-script', function() {
		assert(!new Tag('en-Latn').valid());
		assert(!new Tag('en-GB-Latn').valid());
		assert(!new Tag('gsw-Latn').valid());
	});

	test('tag.deprecated() returns deprecation date when available', function() {
		var tag;

		// Redundant and deprecated.
		tag = new Tag('zh-cmn-Hant');
		assert.equal(tag.type(), 'redundant');
		assert.equal(tag.deprecated(), '2009-07-29');

		// Redundant but not deprecated.
		tag = new Tag('zh-Hans');
		assert.equal(tag.type(), 'redundant');
		assert(!tag.deprecated());

		// Grandfathered and deprecated.
		tag = new Tag('zh-xiang');
		assert.equal(tag.type(), 'grandfathered');
		assert.equal(tag.deprecated(), '2009-07-29');

		// Grandfathered but not deprecated.
		tag = new Tag('i-default');
		assert.equal(tag.type(), 'grandfathered');
		assert(!tag.deprecated());
	});

	test('tag.added() returns add date when available', function() {
		var tag;

		// Redundant and deprecated.
		tag = new Tag('zh-cmn-Hant');
		assert.equal(tag.type(), 'redundant');
		assert.equal(tag.added(), '2005-07-15');

		// Redundant but not deprecated.
		tag = new Tag('zh-Hans');
		assert.equal(tag.type(), 'redundant');
		assert(!tag.deprecated());
		assert.equal(tag.added(), '2003-05-30');

		// Grandfathered and deprecated.
		tag = new Tag('zh-xiang');
		assert.equal(tag.type(), 'grandfathered');
		assert.equal(tag.added(), '1999-12-18');

		// Grandfathered but not deprecated.
		tag = new Tag('i-default');
		assert.equal(tag.type(), 'grandfathered');
		assert(!tag.deprecated());
		assert.equal(tag.added(), '1998-03-10');
	});

	test('tag.descriptions() returns descriptions when available', function() {
		var tag;

		tag = new Tag('i-default');
		assert.equal(tag.type(), 'grandfathered');
		assert(!tag.deprecated());
		assert.deepEqual(tag.descriptions(), ['Default Language']);

		// Otherwise returns an empty array.
		assert.deepEqual(new Tag('en').descriptions(), []);
	});

	test('tag.format() formats tag according to conventions', function() {
		assert.equal(new Tag('en').format(), 'en');
		assert.equal(new Tag('En').format(), 'en');
		assert.equal(new Tag('EN').format(), 'en');
		assert.equal(new Tag('eN').format(), 'en');
		assert.equal(new Tag('en-gb').format(), 'en-GB');
		assert.equal(new Tag('en-gb-oed').format(), 'en-GB-oed');
		assert.equal(new Tag('az-latn').format(), 'az-Latn');
		assert.equal(new Tag('ZH-hant-hK').format(), 'zh-Hant-HK');
	});

	test('tag.preferred() returns preferred tag if available', function() {
		var tag = new Tag('zh-cmn-Hant');

		assert.equal(tag.type(), 'redundant');
		assert(tag.deprecated());
		assert(tag.preferred());
		assert.equal(tag.preferred().format(), 'cmn-Hant');

		assert.equal(new Tag('zh-Hans').preferred(), null);
	});

	test('tag.region() and tag.language() return subtags for redundant tags', function() {
		var tag;

		tag = new Tag('es-419');
		assert.deepEqual(tag.region().descriptions(), ['Latin America and the Caribbean']);
		assert.deepEqual(tag.language().descriptions(), ['Spanish', 'Castilian']);

		tag = new Tag('sgn-NL');
		assert.deepEqual(tag.region().descriptions(), ['Netherlands']);
		assert.deepEqual(tag.language().descriptions(), ['Sign languages']);
	});
});
