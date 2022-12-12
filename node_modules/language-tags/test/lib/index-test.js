/**
 * @author Matthew Caruana Galizia <m@m.cg>
 * @license MIT: http://mattcg.mit-license.org/
 * @copyright Copyright (c) 2013, Matthew Caruana Galizia
 */

/*jshint node:true*/
/*global test, suite*/

'use strict';

var assert = require('assert');
var tags = require(process.env.TEST_LIB_PATH);

suite('tags', function() {

	test('date() returns file date', function() {
		assert(/\d{4}\-\d{2}\-\d{2}/.test(tags.date()));
	});

	test('type() returns subtag by type', function() {
		var subtag;

		subtag = tags.type('Latn', 'script');
		assert(subtag);
		assert.equal(subtag.format(), 'Latn');
		assert.equal(subtag.type(), 'script');

		assert.equal(tags.type('en', 'script'), null);
	});

	test('region() returns subtag by region', function() {
		var subtag;

		subtag = tags.region('IQ');
		assert(subtag);
		assert.equal(subtag.format(), 'IQ');
		assert.equal(subtag.type(), 'region');

		assert.equal(tags.region('en'), null);
	});

	test('language() returns subtag by language', function() {
		var subtag;

		subtag = tags.language('en');
		assert(subtag);
		assert.equal(subtag.format(), 'en');
		assert.equal(subtag.type(), 'language');

		assert.equal(tags.language('GB'), null);
	});

	test('languages() returns all languages for macrolanguage', function() {
		var subtags, err;

		subtags = tags.languages('zh');
		assert(subtags.length > 0);

		try {
			assert.equal(tags.languages('en'));
		} catch (e) {
			err = e;
		}

		assert(err);
		assert.equal(err.message, '\'en\' is not a macrolanguage.');
	});

	test('search() matches descriptions', function() {
		var subtags;

		subtags = tags.search('Maltese');
		assert(subtags.length > 0);

		assert.equal(subtags[0].type(), 'language');
		assert.equal(subtags[0].format(), 'mt');
		assert.equal(subtags[1].type(), 'language');
		assert.equal(subtags[1].format(), 'mdl');
		assert.equal(subtags[2].type(), 'extlang');
		assert.equal(subtags[2].format(), 'mdl');

		subtags = tags.search('Gibberish');
		assert.deepEqual(subtags, []);
	});

	test('search() puts exact match at the top', function() {
		var subtags;

		subtags = tags.search('Dari');
		assert(subtags.length > 0);

		assert.equal(subtags[0].type(), 'language');
		assert.equal(subtags[0].format(), 'prs');
	});

	test('subtags() returns subtags', function() {
		var subtags;

		subtags = tags.subtags('whatever');
		assert.deepEqual(subtags, []);

		subtags = tags.subtags('mt');
		assert.equal(subtags.length, 2);
		assert.equal(subtags[0].type(), 'language');
		assert.equal(subtags[0].format(), 'mt');
		assert.equal(subtags[1].type(), 'region');
		assert.equal(subtags[1].format(), 'MT');
	});

	test('check() checks tag validity', function() {
		assert(tags.check('en'));
		assert(!tags.check('mo'));
	});

	test('gets tag', function() {
		var tag;

		tag = tags('en');
		assert(tag);

		tag = tags('en-gb');
		assert(tag);
		assert.equal(tag.format(), 'en-GB');
	});
});
