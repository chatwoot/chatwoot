'use strict';

var GetIntrinsic = require('get-intrinsic');

var $TypeError = GetIntrinsic('%TypeError%');
var $SyntaxError = GetIntrinsic('%SyntaxError%');

var has = require('has');
var isInteger = require('./isInteger');

var isMatchRecord = require('./isMatchRecord');

var predicates = {
	// https://262.ecma-international.org/6.0/#sec-property-descriptor-specification-type
	'Property Descriptor': function isPropertyDescriptor(Desc) {
		var allowed = {
			'[[Configurable]]': true,
			'[[Enumerable]]': true,
			'[[Get]]': true,
			'[[Set]]': true,
			'[[Value]]': true,
			'[[Writable]]': true
		};

		if (!Desc) {
			return false;
		}
		for (var key in Desc) { // eslint-disable-line
			if (has(Desc, key) && !allowed[key]) {
				return false;
			}
		}

		var isData = has(Desc, '[[Value]]');
		var IsAccessor = has(Desc, '[[Get]]') || has(Desc, '[[Set]]');
		if (isData && IsAccessor) {
			throw new $TypeError('Property Descriptors may not be both accessor and data descriptors');
		}
		return true;
	},
	// https://262.ecma-international.org/13.0/#sec-match-records
	'Match Record': isMatchRecord,
	'Iterator Record': function isIteratorRecord(value) {
		return has(value, '[[Iterator]]') && has(value, '[[NextMethod]]') && has(value, '[[Done]]');
	},
	'PromiseCapability Record': function isPromiseCapabilityRecord(value) {
		return !!value
			&& has(value, '[[Resolve]]')
			&& typeof value['[[Resolve]]'] === 'function'
			&& has(value, '[[Reject]]')
			&& typeof value['[[Reject]]'] === 'function'
			&& has(value, '[[Promise]]')
			&& value['[[Promise]]']
			&& typeof value['[[Promise]]'].then === 'function';
	},
	'AsyncGeneratorRequest Record': function isAsyncGeneratorRequestRecord(value) {
		return !!value
			&& has(value, '[[Completion]]') // TODO: confirm is a completion record
			&& has(value, '[[Capability]]')
			&& predicates['PromiseCapability Record'](value['[[Capability]]']);
	},
	'RegExp Record': function isRegExpRecord(value) {
		return value
			&& has(value, '[[IgnoreCase]]')
			&& typeof value['[[IgnoreCase]]'] === 'boolean'
			&& has(value, '[[Multiline]]')
			&& typeof value['[[Multiline]]'] === 'boolean'
			&& has(value, '[[DotAll]]')
			&& typeof value['[[DotAll]]'] === 'boolean'
			&& has(value, '[[Unicode]]')
			&& typeof value['[[Unicode]]'] === 'boolean'
			&& has(value, '[[CapturingGroupsCount]]')
			&& typeof value['[[CapturingGroupsCount]]'] === 'number'
			&& isInteger(value['[[CapturingGroupsCount]]'])
			&& value['[[CapturingGroupsCount]]'] >= 0;
	}
};

module.exports = function assertRecord(Type, recordType, argumentName, value) {
	var predicate = predicates[recordType];
	if (typeof predicate !== 'function') {
		throw new $SyntaxError('unknown record type: ' + recordType);
	}
	if (Type(value) !== 'Object' || !predicate(value)) {
		throw new $TypeError(argumentName + ' must be a ' + recordType);
	}
};
