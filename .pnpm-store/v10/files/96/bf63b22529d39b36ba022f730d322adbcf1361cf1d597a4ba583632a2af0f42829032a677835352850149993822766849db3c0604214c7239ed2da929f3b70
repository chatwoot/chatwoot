/*
* @license Apache-2.0
*
* Copyright (c) 2019 The Stdlib Authors.
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*    http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

/// <reference types="@stdlib/types"/>

import * as array from '@stdlib/types/array';
import * as iter from '@stdlib/types/iter';
import * as ndarray from '@stdlib/types/ndarray';
import * as obj from '@stdlib/types/object';
import * as random from '@stdlib/types/random';

/**
* Returns an iterator protocol-compliant object.
*
* @returns iterator protocol-compliant object
*/
function createIterator1(): iter.Iterator {
	return {
		'next': next1
	};
}

/**
* Implements the iterator protocol `next` method.
*
* @returns iterator protocol-compliant object
*/
function next1(): iter.IteratorResult {
	return {
		'value': true,
		'done': false
	};
}

/**
* Returns an iterator protocol-compliant object.
*
* @returns iterator protocol-compliant object
*/
function createIterator2(): iter.Iterator {
	return {
		'next': next2
	};
}

/**
* Implements the iterator protocol `next` method.
*
* @returns iterator protocol-compliant object
*/
function next2(): iter.IteratorResult {
	return {
		'done': true
	};
}

/**
* Returns an iterable iterator protocol-compliant object.
*
* @returns iterable iterator protocol-compliant object
*/
function createIterableIterator(): iter.IterableIterator {
	return {
		'next': next3,
		[ Symbol.iterator ]: factory
	};
}

/**
* Implements the iterator protocol `next` method.
*
* @returns iterator protocol-compliant object
*/
function next3(): iter.IteratorResult {
	return {
		'done': true
	};
}

/**
* Returns an iterable iterator protocol-compliant object.
*
* @returns iterable iterator protocol-compliant object
*/
function factory(): iter.IterableIterator {
	return createIterableIterator();
}

/**
* Returns a complex number array-like object.
*
* @returns complex number array-like object
*/
function cmplxArray(): array.ComplexArrayLike {
	const buf: array.TypedArray = new Float64Array( 8 );
	const obj: array.ComplexArrayLike = {
		'byteLength': 64,
		'byteOffset': 0,
		'BYTES_PER_ELEMENT': 8,
		'length': 8,
		'get': ( i: number ): obj.ComplexLike => {
			return {
				're': i * 10,
				'im': i * 10
			};
		},
		'set': ( value: obj.ComplexLike, i?: number ) => {
			i = ( i ) ? i : 0;
			buf[ i ] = value.re;
			buf[ i + 1 ] = value.im;
		}
	};
	return obj;
}

/**
* Returns a 64-bit complex number array.
*
* @returns 64-bit complex number array
*/
function cmplx64Array(): array.Complex64Array {
	const buf: array.TypedArray = new Float64Array( 8 );
	const obj: array.Complex64Array = {
		'byteLength': 64,
		'byteOffset': 0,
		'BYTES_PER_ELEMENT': 8,
		'length': 8,
		'get': ( i: number ): obj.Complex64 => {
			return {
				're': i * 10,
				'im': i * 10,
				'byteLength': 8,
				'BYTES_PER_ELEMENT': 4
			};
		},
		'set': ( value: obj.Complex64, i?: number ) => {
			i = ( i ) ? i : 0;
			buf[ i ] = value.re;
			buf[ i + 1 ] = value.im;
		}
	};
	return obj;
}

/**
* Returns a 128-bit complex number array.
*
* @returns 128-bit complex number array
*/
function cmplx128Array(): array.Complex128Array {
	const buf: array.TypedArray = new Float64Array( 16 );
	const obj: array.Complex128Array = {
		'byteLength': 128,
		'byteOffset': 0,
		'BYTES_PER_ELEMENT': 16,
		'length': 8,
		'get': ( i: number ): obj.Complex128 => {
			return {
				're': i * 10,
				'im': i * 10,
				'byteLength': 16,
				'BYTES_PER_ELEMENT': 8
			};
		},
		'set': ( value: obj.Complex128, i?: number ) => {
			i = ( i ) ? i : 0;
			buf[ i ] = value.re;
			buf[ i + 1 ] = value.im;
		}
	};
	return obj;
}


// TESTS //

// The compiler should not throw an error when using array type aliases...
{
	const x: array.TypedArray = new Float64Array( 10 );
	if ( x[ 0 ] !== 0.0 ) {
		throw new Error( 'something went wrong' );
	}

	const y: array.IntegerTypedArray = new Int32Array( 10 );
	if ( y[ 0 ] !== 0 ) {
		throw new Error( 'something went wrong' );
	}

	const z: array.NumericArray = new Float64Array( 10 );
	if ( z[ 0 ] !== 0.0 ) {
		throw new Error( 'something went wrong' );
	}

	const w: array.ArrayLike<string> = 'beep';
	if ( w[ 0 ] !== 'b' ) {
		throw new Error( 'something went wrong' );
	}

	const v: array.ArrayLike<number> = [ 1, 2, 3 ];
	if ( v[ 0 ] !== 1 ) {
		throw new Error( 'something went wrong' );
	}

	const t: array.ArrayLike<number> = new Int8Array( 10 );
	if ( t[ 0 ] !== 1 ) {
		throw new Error( 'something went wrong' );
	}

	const zz: array.ComplexArrayLike = cmplxArray();
	if ( zz.byteOffset !== 0 ) {
		throw new Error( 'something went wrong' );
	}

	const z64: array.Complex64Array = cmplx64Array();
	if ( z64.byteOffset !== 0 ) {
		throw new Error( 'something went wrong' );
	}

	const z128: array.Complex128Array = cmplx128Array();
	if ( z128.byteOffset !== 0 ) {
		throw new Error( 'something went wrong' );
	}

	const zzz: array.ComplexTypedArray = cmplx64Array();
	if ( zzz.byteOffset !== 0 ) {
		throw new Error( 'something went wrong' );
	}

	const v1: array.ArrayOrTypedArray = new Float64Array( 10 );
	if ( v1[ 0 ] !== 0.0 ) {
		throw new Error( 'something went wrong' );
	}

	const v2: array.FloatTypedArray = new Float64Array( 10 );
	if ( v2[ 0 ] !== 0.0 ) {
		throw new Error( 'something went wrong' );
	}

	const v3: array.RealOrComplexArray = new Float64Array( 10 );
	if ( v3[ 0 ] !== 0.0 ) {
		throw new Error( 'something went wrong' );
	}

	const v4: array.RealOrComplexTypedArray = new Float64Array( 10 );
	if ( v4[ 0 ] !== 0.0 ) {
		throw new Error( 'something went wrong' );
	}

	const v5buf: array.ArrayLike<number> = new Float64Array( 10 );
	const v5: array.AccessorArrayLike<number> = {
		'length': 10,
		'data': v5buf,
		'get': ( i: number ): number => v5buf[ i ],
		'set': ( value: number, i?: number ): void => {
			v5buf[ i || 0 ] = value;
			return;
		}
	};
	if ( v5.length !== 10 ) {
		throw new Error( 'something went wrong' );
	}

	const v6: array.IntegerTypedArray = new Int32Array( 10 );
	if ( v6[ 0 ] !== 0 ) {
		throw new Error( 'something went wrong' );
	}

	const v7: array.SignedIntegerTypedArray = new Int32Array( 10 );
	if ( v7[ 0 ] !== 0 ) {
		throw new Error( 'something went wrong' );
	}

	const v8: array.UnsignedIntegerTypedArray = new Uint32Array( 10 );
	if ( v8[ 0 ] !== 0 ) {
		throw new Error( 'something went wrong' );
	}

	const v9: array.AnyArray = new Uint32Array( 10 );
	if ( v9[ 0 ] !== 0 ) {
		throw new Error( 'something went wrong' );
	}

	const v10: array.RealTypedArray = new Uint32Array( 10 );
	if ( v10[ 0 ] !== 0 ) {
		throw new Error( 'something went wrong' );
	}

	const v11: array.FloatOrComplexTypedArray = new Float64Array( 10 );
	if ( v11[ 0 ] !== 0.0 ) {
		throw new Error( 'something went wrong' );
	}
}

// The compiler should not throw an error when using iterator or iterable types...
{
	createIterator1();
	createIterator2();
	createIterableIterator();
}

// The compiler should not throw an error when using ndarray types...
{
	const data = [ 1, 2, 3 ];
	const arr: ndarray.ndarray = {
		'byteLength': null,
		'BYTES_PER_ELEMENT': null,
		'data': data,
		'dtype': 'generic',
		'flags': {
			'ROW_MAJOR_CONTIGUOUS': true,
			'COLUMN_MAJOR_CONTIGUOUS': false
		},
		'length': 3,
		'ndims': 1,
		'offset': 0,
		'order': 'row-major',
		'shape': [ 3 ],
		'strides': [ 1 ],
		'get': ( i: number ): number => {
			return data[ i ];
		},
		'set': ( i: number, v: number ): ndarray.ndarray => {
			data[ i ] = v;
			return arr;
		}
	};
	if ( arr.length !== 3 ) {
		throw new Error( 'something went wrong' );
	}
}

// The compiler should not throw an error when using object types...
{
	const desc1: obj.DataPropertyDescriptor = {
		'configurable': true,
		'enumerable': false,
		'writable': false,
		'value': 'beep'
	};
	if ( desc1.value !== 'beep' ) {
		throw new Error( 'something went wrong' );
	}

	const desc2: obj.DataPropertyDescriptor = {
		'enumerable': false,
		'writable': false,
		'value': 'beep'
	};
	if ( desc2.value !== 'beep' ) {
		throw new Error( 'something went wrong' );
	}

	const desc3: obj.DataPropertyDescriptor = {
		'configurable': true,
		'writable': false,
		'value': 'beep'
	};
	if ( desc3.value !== 'beep' ) {
		throw new Error( 'something went wrong' );
	}

	const desc4: obj.DataPropertyDescriptor = {
		'configurable': true,
		'enumerable': false,
		'writable': false
	};
	if ( desc4.value ) {
		throw new Error( 'something went wrong' );
	}

	const desc5: obj.DataPropertyDescriptor = {
		'writable': false,
		'value': 'beep'
	};
	if ( desc5.value !== 'beep' ) {
		throw new Error( 'something went wrong' );
	}

	const desc6: obj.DataPropertyDescriptor = {
		'configurable': true,
		'value': 'beep'
	};
	if ( desc6.value !== 'beep' ) {
		throw new Error( 'something went wrong' );
	}

	const desc7: obj.DataPropertyDescriptor = {
		'enumerable': false,
		'value': 'beep'
	};
	if ( desc7.value !== 'beep' ) {
		throw new Error( 'something went wrong' );
	}

	const desc8: obj.DataPropertyDescriptor = {
		'enumerable': false,
		'writable': false
	};
	if ( desc8.value ) {
		throw new Error( 'something went wrong' );
	}

	const desc9: obj.AccessorPropertyDescriptor = {
		'configurable': true,
		'enumerable': false,
		'get': (): string => 'beep',
		'set': () => { throw new Error( 'beep' ); }
	};
	if ( desc9.enumerable !== false ) {
		throw new Error( 'something went wrong' );
	}

	const desc10: obj.AccessorPropertyDescriptor = {
		'enumerable': false,
		'get': (): string => 'beep',
		'set': () => { throw new Error( 'beep' ); }
	};
	if ( desc10.enumerable !== false ) {
		throw new Error( 'something went wrong' );
	}

	const desc11: obj.AccessorPropertyDescriptor = {
		'configurable': true,
		'get': (): string => 'beep',
		'set': () => { throw new Error( 'beep' ); }
	};
	if ( desc11.enumerable !== false ) {
		throw new Error( 'something went wrong' );
	}

	const desc12: obj.AccessorPropertyDescriptor = {
		'configurable': true,
		'enumerable': false,
		'set': () => { throw new Error( 'beep' ); }
	};
	if ( desc12.enumerable !== false ) {
		throw new Error( 'something went wrong' );
	}

	const desc13: obj.AccessorPropertyDescriptor = {
		'configurable': true,
		'enumerable': false,
		'get': (): string => 'beep'
	};
	if ( desc13.enumerable !== false ) {
		throw new Error( 'something went wrong' );
	}

	const desc14: obj.AccessorPropertyDescriptor = {
		'get': (): string => 'beep',
		'set': () => { throw new Error( 'beep' ); }
	};
	if ( desc14.enumerable !== false ) {
		throw new Error( 'something went wrong' );
	}

	const desc15: obj.PropertyDescriptor = {
		'configurable': true,
		'enumerable': false,
		'writable': false,
		'value': 'beep'
	};
	if ( desc15.value !== 'beep' ) {
		throw new Error( 'something went wrong' );
	}

	const prop: obj.PropertyName = 'foo';
	if ( prop !== 'foo' ) {
		throw new Error( 'something went wrong' );
	}

	const arr: obj.Collection = [ 1, 2, 3 ];
	if ( arr.length !== 3 ) {
		throw new Error( 'something went wrong' );
	}

	const z: obj.ComplexLike = {
		're': 1.0,
		'im': 1.0
	};
	if ( z.re !== 1.0 ) {
		throw new Error( 'something went wrong' );
	}

	const z64: obj.Complex64 = {
		're': 1.0,
		'im': 1.0,
		'byteLength': 8,
		'BYTES_PER_ELEMENT': 4
	};
	if ( z64.re !== 1.0 ) {
		throw new Error( 'something went wrong' );
	}

	const z128: obj.Complex128 = {
		're': 1.0,
		'im': 1.0,
		'byteLength': 16,
		'BYTES_PER_ELEMENT': 8
	};
	if ( z128.re !== 1.0 ) {
		throw new Error( 'something went wrong' );
	}
}

// The compiler should not throw an error when using PRNG types...
{
	const rand: random.PRNG = (): number => 3.14;
	if ( rand() !== 3.14 ) {
		throw new Error( 'something went wrong' );
	}

	const s1: random.PRNGSeedMT19937 = 12345;
	if ( s1 !== 12345 ) {
		throw new Error( 'something went wrong' );
	}

	const s2: random.PRNGSeedMT19937 = new Uint32Array( 10 );
	if ( s2[ 0 ] !== 0 ) {
		throw new Error( 'something went wrong' );
	}

	const s3: random.PRNGSeedMINSTD = 12345;
	if ( s3 !== 12345 ) {
		throw new Error( 'something went wrong' );
	}

	const s4: random.PRNGSeedMINSTD = new Int32Array( 10 );
	if ( s4[ 0 ] !== 0 ) {
		throw new Error( 'something went wrong' );
	}

	const s5: random.PRNGStateMT19937 = new Uint32Array( 10 );
	if ( s5[ 0 ] !== 0 ) {
		throw new Error( 'something went wrong' );
	}

	const s6: random.PRNGStateMINSTD = new Int32Array( 10 );
	if ( s6[ 0 ] !== 0 ) {
		throw new Error( 'something went wrong' );
	}
}
