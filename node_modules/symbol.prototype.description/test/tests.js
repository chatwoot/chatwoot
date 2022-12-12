'use strict';

var hasSymbols = require('has-symbols')();
var getInferredName = require('es-abstract/helpers/getInferredName');

module.exports = function (description, t) {
	t.test('Symbol description', { skip: !hasSymbols }, function (st) {
		st.equal(description(Symbol()), undefined, 'Symbol() description is undefined');
		st.equal(description(Symbol(undefined)), undefined, 'Symbol(undefined) description is undefined');
		st.equal(description(Symbol(null)), 'null', 'Symbol(null) description is string null');
		st.equal(description(Symbol(false)), 'false', 'Symbol(false) description is string false');
		st.equal(description(Symbol(true)), 'true', 'Symbol(true) description is string true');
		st.equal(description(Symbol('foo')), 'foo', 'Symbol("foo") description is string foo');

		st.end();
	});

	t.test('only possible when inference is supported', { skip: !getInferredName }, function (st) {
		st.equal(description(Symbol('')), '', 'Symbol("") description is empty string');
		st.end();
	});

};
