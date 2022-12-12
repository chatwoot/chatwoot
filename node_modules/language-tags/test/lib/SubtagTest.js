/**
 * @author Matthew Caruana Galizia <m@m.cg>
 * @license MIT: http://mattcg.mit-license.org/
 * @copyright Copyright (c) 2013, Matthew Caruana Galizia
 */

/*jshint node:true*/
/*global test, suite*/

'use strict';

var assert = require('assert');
var Subtag = require(process.env.TEST_LIB_PATH + '/Subtag');

suite('Subtag', function() {

	test('subtag.type() returns type', function() {
		assert.equal(new Subtag('zh', 'language').type(), 'language');
		assert.equal(new Subtag('IQ', 'region').type(), 'region');
	});

	test('subtag.descriptions() returns descriptions', function() {
		assert.deepEqual(new Subtag('IQ', 'region').descriptions(), ['Iraq']);
		assert.deepEqual(new Subtag('vsv', 'extlang').descriptions(), ['Valencian Sign Language', 'Llengua de signes valenciana']);
	});

	test('subtag.preferred() returns preferred subtag', function() {
		var subtag, preferred;

		// Extlang
		subtag = new Subtag('vsv', 'extlang');
		preferred = subtag.preferred();
		assert(preferred);
		assert.equal(preferred.type(), 'language');
		assert.equal(preferred.format(), 'vsv');

		// Language
		// Moldovan -> Romanian
		subtag = new Subtag('mo', 'language');
		preferred = subtag.preferred();
		assert(preferred);
		assert.equal(preferred.type(), 'language');
		assert.equal(preferred.format(), 'ro');

		// Region
		// Burma -> Myanmar
		subtag = new Subtag('BU', 'region');
		preferred = subtag.preferred();
		assert(preferred);
		assert.equal(preferred.type(), 'region');
		assert.equal(preferred.format(), 'MM');

		// Variant
		subtag = new Subtag('heploc', 'variant');
		preferred = subtag.preferred();
		assert(preferred);
		assert.equal(preferred.type(), 'variant');
		assert.equal(preferred.format(), 'alalc97');

		// Should return null if no preferred value.
		// Latin America and the Caribbean
		subtag = new Subtag('419', 'region');
		assert.equal(subtag.preferred(), null);
	});

	test('subtag.script() returns suppress-script as subtag', function() {
		var subtag, script;

		subtag = new Subtag('en', 'language');
		script = subtag.script();
		assert(script);
		assert.equal(script.type(), 'script');
		assert.equal(script.format(), 'Latn');

		// Should return null if no script.
		// A macrolanguage like 'zh' should have no suppress-script.
		subtag = new Subtag('zh', 'language');
		script = subtag.script();
		assert.equal(script, null);
	});

	test('subtag.scope() returns scope', function() {
		assert.equal(new Subtag('zh', 'language').scope(), 'macrolanguage');
		assert.equal(new Subtag('nah', 'language').scope(), 'collection');
		assert.equal(new Subtag('en', 'language').scope(), null);
		assert.equal(new Subtag('IQ', 'region').scope(), null);
	});

	test('subtag.deprecated() returns deprecation date if available', function() {

		// German Democratic Republic
		assert.equal(new Subtag('DD', 'region').deprecated(), '1990-10-30');
		assert.equal(new Subtag('DE', 'region').deprecated(), null);
	});

	test('subtag.added() returns date added', function() {
		assert.equal(new Subtag('DD', 'region').added(), '2005-10-16');
		assert.equal(new Subtag('DG', 'region').added(), '2009-07-29');
	});

	test('subtag.comments() returns comments', function() {

		// Yugoslavia
		assert.deepEqual(new Subtag('YU', 'region').comments(), ['see BA, HR, ME, MK, RS, or SI']);
	});

	test('subtag.format() formats subtag according to conventions', function() {

		// Language
		assert.equal(new Subtag('en', 'language').format(), 'en');
		assert.equal(new Subtag('EN', 'language').format(), 'en');

		// Region
		assert.equal(new Subtag('GB', 'region').format(), 'GB');
		assert.equal(new Subtag('gb', 'region').format(), 'GB');

		// Script
		assert.equal(new Subtag('Latn', 'script').format(), 'Latn');
		assert.equal(new Subtag('latn', 'script').format(), 'Latn');
	});
});
