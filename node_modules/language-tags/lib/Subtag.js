/**
 * @author Matthew Caruana Galizia <m@m.cg>
 * @license MIT: http://mattcg.mit-license.org/
 * @copyright Copyright (c) 2013, Matthew Caruana Galizia
 */

/*jshint node:true*/

'use strict';

var index = require('language-subtag-registry/data/json/index');
var registry = require('language-subtag-registry/data/json/registry');

module.exports = Subtag;

Subtag.ERR_NONEXISTENT = 1;
Subtag.ERR_TAG = 2;

function Subtag(subtag, type) {
	var types, i, record, error;

	// Lowercase for consistency (case is only a formatting convention, not a standard requirement).
	subtag = subtag.toLowerCase();
	type = type.toLowerCase();

	error = function(code, message) {
		var err;

		err = new Error(message);
		err.code = code;
		err.subtag = subtag;
		throw err;
	};

	types = index[subtag];
	if (!types) {
		error(Subtag.ERR_NONEXISTENT, 'Non-existent subtag \'' + subtag + '\'.');
	}

	i = types[type];
	if (!i && 0 !== i) {
		error(Subtag.ERR_NONEXISTENT, 'Non-existent subtag \'' + subtag + '\' of type \'' + type + '\'.');
	}

	record = registry[i];
	if (!record.Subtag) {
		error(Subtag.ERR_TAG, '\'' + subtag + '\' is a \'' + type + '\' tag.');
	}

	this.data = {};
	this.data.subtag = subtag;
	this.data.record = record;
	this.data.type = type;
}

Subtag.prototype.type = function() {
	return this.data.type;
};

Subtag.prototype.descriptions = function() {

	// Every record has one or more descriptions (stored as an array).
	return this.data.record.Description;
};

Subtag.prototype.preferred = function() {
	var type, preferred = this.data.record['Preferred-Value'];

	if (preferred) {
		type = this.data.type;
		if (type === 'extlang') {
			type = 'language';
		}

		return new Subtag(preferred, type);
	}

	return null;
};

Subtag.prototype.script = function() {
	var script = this.data.record['Suppress-Script'];

	if (script) {
		return new Subtag(script, 'script');
	}

	return null;
};

Subtag.prototype.scope = function() {
	return this.data.record.Scope || null;
};

Subtag.prototype.deprecated = function() {
	return this.data.record.Deprecated || null;
};

Subtag.prototype.added = function() {
	return this.data.record.Added;
};

Subtag.prototype.comments = function() {

	// Comments don't always occur for records, so switch to an empty array if missing.
	return this.data.record.Comments || [];
};

Subtag.prototype.format = function() {
	var subtag = this.data.subtag;

	switch (this.data.type) {
	case 'region':
		return subtag.toUpperCase();
	case 'script':
		return subtag[0].toUpperCase() + subtag.substr(1);
	}

	return subtag;
};

Subtag.prototype.toString = function() {
	return this.format();
};
