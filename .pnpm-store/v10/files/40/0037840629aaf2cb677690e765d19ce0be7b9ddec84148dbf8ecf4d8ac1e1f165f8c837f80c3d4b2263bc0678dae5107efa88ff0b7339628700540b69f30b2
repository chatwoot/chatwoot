'use strict';

var GetIntrinsic = require('get-intrinsic');

var $SyntaxError = GetIntrinsic('%SyntaxError%');
var $TypeError = GetIntrinsic('%TypeError%');

var isInteger = require('../helpers/isInteger');

var IsBigIntElementType = require('./IsBigIntElementType');
var IsDetachedBuffer = require('./IsDetachedBuffer');
var NumericToRawBytes = require('./NumericToRawBytes');

var isArrayBuffer = require('is-array-buffer');
var isSharedArrayBuffer = require('is-shared-array-buffer');
var has = require('has');

var table61 = {
	__proto__: null,
	Int8: 1,
	Uint8: 1,
	Uint8C: 1,
	Int16: 2,
	Uint16: 2,
	Int32: 4,
	Uint32: 4,
	BigInt64: 8,
	BigUint64: 8,
	Float32: 4,
	Float64: 8
};

var defaultEndianness = require('../helpers/defaultEndianness');
var forEach = require('../helpers/forEach');

// https://262.ecma-international.org/11.0/#sec-setvalueinbuffer

/* eslint max-params: 0 */

module.exports = function SetValueInBuffer(arrayBuffer, byteIndex, type, value, isTypedArray, order) {
	var isSAB = isSharedArrayBuffer(arrayBuffer);
	if (!isArrayBuffer(arrayBuffer) && !isSAB) {
		throw new $TypeError('Assertion failed: `arrayBuffer` must be an ArrayBuffer or a SharedArrayBuffer');
	}

	if (!isInteger(byteIndex)) {
		throw new $TypeError('Assertion failed: `byteIndex` must be an integer');
	}

	if (typeof type !== 'string' || !has(table61, type)) {
		throw new $TypeError('Assertion failed: `type` must be a Typed Array Element Type');
	}

	if (typeof value !== 'number' && typeof value !== 'bigint') {
		throw new $TypeError('Assertion failed: `value` must be a Number or a BigInt');
	}

	if (typeof isTypedArray !== 'boolean') {
		throw new $TypeError('Assertion failed: `isTypedArray` must be a boolean');
	}
	if (order !== 'SeqCst' && order !== 'Unordered' && order !== 'Init') {
		throw new $TypeError('Assertion failed: `order` must be `"SeqCst"`, `"Unordered"`, or `"Init"`');
	}

	if (arguments.length > 6 && typeof arguments[6] !== 'boolean') {
		throw new $TypeError('Assertion failed: `isLittleEndian` must be a boolean, if present');
	}

	if (IsDetachedBuffer(arrayBuffer)) {
		throw new $TypeError('Assertion failed: ArrayBuffer is detached'); // step 1
	}

	// 2. Assert: There are sufficient bytes in arrayBuffer starting at byteIndex to represent a value of type.

	if (byteIndex < 0) {
		throw new $TypeError('Assertion failed: `byteIndex` must be non-negative'); // step 3
	}

	if (IsBigIntElementType(type) ? typeof value !== 'bigint' : typeof value !== 'number') { // step 4
		throw new $TypeError('Assertion failed: `value` must be a BigInt if type is BigInt64 or BigUint64, otherwise a Number');
	}

	// 5. Let block be arrayBuffer’s [[ArrayBufferData]] internal slot.

	var elementSize = table61[type]; // step 6

	// 8. If isLittleEndian is not present, set isLittleEndian to either true or false. The choice is implementation dependent and should be the alternative that is most efficient for the implementation. An implementation must use the same value each time this step is executed and the same value must be used for the corresponding step in the GetValueFromBuffer abstract operation.
	var isLittleEndian = arguments.length > 6 ? arguments[6] : defaultEndianness === 'little'; // step 8

	var rawBytes = NumericToRawBytes(type, value, isLittleEndian); // step 8

	if (isSAB) { // step 9
		/*
			Let execution be the [[CandidateExecution]] field of the surrounding agent's Agent Record.
			Let eventList be the [[EventList]] field of the element in execution.[[EventsRecords]] whose [[AgentSignifier]] is AgentSignifier().
			If isTypedArray is true and IsNoTearConfiguration(type, order) is true, let noTear be true; otherwise let noTear be false.
			Append WriteSharedMemory { [[Order]]: order, [[NoTear]]: noTear, [[Block]]: block, [[ByteIndex]]: byteIndex, [[ElementSize]]: elementSize, [[Payload]]: rawBytes } to eventList.
		*/
		throw new $SyntaxError('SharedArrayBuffer is not supported by this implementation');
	} else {
		// 10. Store the individual bytes of rawBytes into block, in order, starting at block[byteIndex].
		var arr = new Uint8Array(arrayBuffer, byteIndex, elementSize);
		forEach(rawBytes, function (rawByte, i) {
			arr[i] = rawByte;
		});
	}

	// 11. Return NormalCompletion(undefined).
};
