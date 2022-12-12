'use strict';

var functionsHaveNames = require('functions-have-names')();
var arrows = require('make-arrow-function').list();
var generators = require('make-generator-function')();
var asyncs = require('make-async-function').list();
var forEach = require('for-each');

var foo = Object(function foo() {});
var anon = Object(function () {});
var evalled = Object(Function()); // eslint-disable-line no-new-func

module.exports = function (getName, t) {
	t.test('functions', function (st) {
		if (functionsHaveNames) {
			st.equal(getName(foo), foo.name, 'foo has name "foo"');
			st.equal(getName(anon), anon.name, 'anonymous function has name of empty string');
			st.equal(getName(evalled), evalled.name, 'eval-d function has name "anonymous" (or empty string)');
		}
		st.equal(getName(foo), 'foo', 'foo has name "foo"');
		st.equal(getName(anon), '', 'anonymous function has name of empty string');
		var evalledName = getName(evalled);
		st.equal(evalledName === 'anonymous' || evalledName === '', true, 'eval-d function has name "anonymous" (or empty string');
		st.end();
	});

	t.test('arrow functions', { skip: arrows.length === 0 }, function (st) {
		st.equal(true, functionsHaveNames, 'functions have names in any env with arrow functions');
		forEach(arrows, function (arrowFn) {
			st.equal(getName(arrowFn), arrowFn.name, 'arrow function name matches for ' + arrowFn);
		});
		st.end();
	});

	t.test('generators', { skip: generators.length === 0 }, function (st) {
		st.equal(true, functionsHaveNames, 'functions have names in any env with generator functions');
		forEach(generators, function (genFn) {
			st.equal(getName(genFn), genFn.name, 'generator function name matches for ' + genFn);
		});
		st.end();
	});

	t.test('asyncs', { skip: asyncs.length === 0 }, function (st) {
		st.equal(true, functionsHaveNames, 'functions have names in any env with async functions');
		forEach(asyncs, function (asyncFn) {
			st.equal(getName(asyncFn), asyncFn.name, 'async function name matches for ' + asyncFn);
		});
		st.end();
	});

	t.test('Function.prototype.name', function (st) {
		st.equal(getName(function before() {}), 'before', 'function prior to accessing Function.prototype has the right name');
		var protoName = getName(Function.prototype);
		// on <= node v2.5, this is "Empty" - otherwise, the empty string
		st.equal(protoName === '' || protoName === 'Empty', true, 'Function.prototype has the right name');
		st.equal(getName(function after() {}), 'after', 'function after accessing Function.prototype has the right name');

		st.end();
	});
};
