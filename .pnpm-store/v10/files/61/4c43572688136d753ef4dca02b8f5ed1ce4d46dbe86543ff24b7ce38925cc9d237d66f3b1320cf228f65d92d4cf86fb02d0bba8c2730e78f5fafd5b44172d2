/* tslint:disable:max-file-line-count */

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

// TypeScript Version: 2.0

/**
* Module containing array definitions.
*
* @example
* import * as array from `@stdlib/types/array`;
*
* const x: array.ArrayLike<number> = [ 1, 2, 3 ];
*
* @example
* import { ArrayLike } from `@stdlib/types/array`;
*
* const x: ArrayLike<number> = [ 1, 2, 3 ];
*/
declare module '@stdlib/types/array' {
	import { ComplexLike, Complex64, Complex128 } from '@stdlib/types/object';

	/**
	* Data type.
	*/
	type DataType = RealOrComplexDataType | 'generic';

	/**
	* Data type for real-valued typed arrays.
	*/
	type RealDataType = FloatDataType | IntegerDataType;

	/**
	* Data type for floating-point typed arrays.
	*/
	type FloatDataType = 'float64' | 'float32';

	/**
	* Data type for integer typed arrays.
	*/
	type IntegerDataType = SignedIntegerDataType | UnsignedIntegerDataType;

	/**
	* Data type for signed integer typed arrays.
	*/
	type SignedIntegerDataType = 'int32' | 'int16' | 'int8';

	/**
	* Data type for unsigned integer typed arrays.
	*/
	type UnsignedIntegerDataType = 'uint32' | 'uint16' | 'uint8' | 'uint8c';

	/**
	* Data type for complex number typed arrays.
	*/
	type ComplexDataType = 'complex64' | 'complex128';

	/**
	* Data type for floating-point real or complex typed arrays.
	*/
	type FloatOrComplexDataType = FloatDataType | ComplexDataType;

	/**
	* Data type for real-valued or complex number typed arrays.
	*/
	type RealOrComplexDataType = RealDataType | ComplexDataType;

	/**
	* An array-like value.
	*
	* @example
	* const x: ArrayLike<number> = [ 1, 2, 3 ];
	* const y: ArrayLike<number> = new Float64Array( 10 );
	* const z: ArrayLike<string> = 'beep';
	*/
	interface ArrayLike<T> {
		/**
		* Numeric properties.
		*/
		[key: number]: T;

		/**
		* Number of elements.
		*/
		length: number;
	}

	/**
	* An array-like value which exposes accessors for getting and setting array elements.
	*
	* @example
	* const xbuf: Array = [ 1, 2, 3 ];
	* const x: AccessorArrayLike<number> = {
	*     'length': 3,
	*     'data': xbuf,
	*     'get': ( i: number ): number => xbuf[ i ],
	*     'set': ( value: number, i?: number ): void => {
	*         xbuf[ i || 0 ] = value;
	*         return;
	*      }
	* };
	*/
	interface AccessorArrayLike<T> {
		/**
		* Properties.
		*/
		[key: string]: any;

		/**
		* Number of elements.
		*/
		length: number;

		/**
		* Returns an array element.
		*
		* @param i - element index
		* @returns array element
		*/
		get( i: number ): T | void;

		/**
		* Sets an array element.
		*
		* @param value - value(s)
		* @param i - element index at which to start writing values (default: 0)
		*/
		set( value: T, i?: number ): void;
	}

	/**
	* A numeric array.
	*
	* @example
	* const x: NumericArray = [ 1, 2, 3 ];
	* const y: NumericArray = new Float64Array( 10 );
	*/
	type NumericArray = Array<number> | TypedArray;

	/**
	* Any array.
	*
	* @example
	* const x: AnyArray = [ 1, 2, 3 ];
	* const y: AnyArray = new Float64Array( 10 );
	*/
	type AnyArray = Array<any> | RealOrComplexTypedArray;

	/**
	* An array or typed array.
	*
	* @example
	* const x: ArrayOrTypedArray = [ 1, 2, 3 ];
	* const y: ArrayOrTypedArray = new Float64Array( 10 );
	*/
	type ArrayOrTypedArray = Array<any> | TypedArray;

	/**
	* A typed array.
	*
	* ## Notes
	*
	* -   This is a strict definition of a typed array. Namely, the type is limited to only built-in typed arrays.
	*
	* @example
	* const x: TypedArray = new Float64Array( 10 );
	* const y: TypedArray = new Uint32Array( 10 );
	*/
	type TypedArray = FloatTypedArray | IntegerTypedArray;

	/**
	* A real-valued typed array.
	*
	* @example
	* const x: RealTypedArray = new Float64Array( 10 );
	* const y: RealTypedArray = new Uint32Array( 10 );
	*/
	type RealTypedArray = TypedArray;

	/**
	* An integer typed array.
	*
	* @example
	* const x: IntegerTypedArray = new Uint32Array( 10 );
	* const y: IntegerTypedArray = new Int32Array( 10 );
	*/
	type IntegerTypedArray = SignedIntegerTypedArray | UnsignedIntegerTypedArray; // tslint:disable-line:max-line-length

	/**
	* A signed integer typed array.
	*
	* @example
	* const x: SignedIntegerTypedArray = new Int32Array( 10 );
	*/
	type SignedIntegerTypedArray = Int8Array | Int16Array | Int32Array;

	/**
	* An unsigned integer typed array.
	*
	* @example
	* const x: UnsignedIntegerTypedArray = new Uint32Array( 10 );
	*/
	type UnsignedIntegerTypedArray = Uint8Array | Uint8ClampedArray | Uint16Array | Uint32Array; // tslint:disable-line:max-line-length

	/**
	* A floating-point typed array.
	*
	* @example
	* const x: FloatTypedArray = new Float64Array( 10 );
	* const y: FloatTypedArray = new Float32Array( 10 );
	*/
	type FloatTypedArray = Float32Array | Float64Array;

	/**
	* A complex number typed array.
	*
	* @example
	* const x: ComplexTypedArray = new Complex64Array( 10 );
	*/
	type ComplexTypedArray = Complex64Array | Complex128Array;

	/**
	* A real or complex array.
	*
	* @example
	* const x: RealOrComplexArray = new Float64Array( 10 );
	* const y: RealOrComplexArray = [ 1, 2, 3 ];
	*/
	type RealOrComplexArray = NumericArray | ComplexTypedArray;

	/**
	* A floating-point real or complex typed array.
	*
	* @example
	* const x: FloatOrComplexTypedArray = new Float64Array( 10 );
	*/
	type FloatOrComplexTypedArray = FloatTypedArray | ComplexTypedArray;

	/**
	* A real or complex typed array.
	*
	* @example
	* const x: RealOrComplexTypedArray = new Float64Array( 10 );
	*/
	type RealOrComplexTypedArray = RealTypedArray | ComplexTypedArray;

	/**
	* A complex number array-like value.
	*
	* @example
	* const buf = new Float64Array( 8 );
	*
	* const z: ComplexArrayLike = {
	*     'byteLength': 64,
	*     'byteOffset': 0,
	*     'BYTES_PER_ELEMENT': 8,
	*     'length': 8
	*     'get': ( i: number ): obj.ComplexLike => {
	*         return {
	*             're': i * 10,
	*             'im': i * 10
	*         };
	*     },
	*     'set': ( value: obj.ComplexLike, i?: number ) => {
	*         i = ( i ) ? i : 0;
	*         buf[ i ] = value.re;
	*         buf[ i + 1 ] = value.im;
	*     }
	* };
	*/
	interface ComplexArrayLike extends AccessorArrayLike<ComplexLike> {
		/**
		* Length (in bytes) of the array.
		*/
		byteLength: number;

		/**
		* Offset (in bytes) of the array from the start of its underlying `ArrayBuffer`.
		*/
		byteOffset: number;

		/**
		* Size (in bytes) of each array element.
		*/
		BYTES_PER_ELEMENT: number;

		/**
		* Number of array elements.
		*/
		length: number;

		/**
		* Returns an array element.
		*
		* @param i - element index
		* @returns array element
		*/
		get( i: number ): ComplexLike | void;

		/**
		* Sets an array element.
		*
		* @param value - value(s)
		* @param i - element index at which to start writing values (default: 0)
		*/
		set( value: ArrayLike<number | ComplexLike> | ComplexArrayLike | ComplexLike, i?: number ): void; // tslint:disable-line:max-line-length
	}

	/**
	* 64-bit complex number array.
	*
	* @example
	* const buf = new Float32Array( 8 );
	*
	* const z: Complex64Array = {
	*     'byteLength': 32,
	*     'byteOffset': 0,
	*     'BYTES_PER_ELEMENT': 4,
	*     'length': 8
	*     'get': ( i: number ): obj.Complex64 => {
	*         return {
	*             're': i * 10,
	*             'im': i * 10,
	*             'byteLength': 8,
	*             'BYTES_PER_ELEMENT': 4
	*         };
	*     },
	*     'set': ( value: obj.ComplexLike, i?: number ) => {
	*         i = ( i ) ? i : 0;
	*         buf[ i ] = value.re;
	*         buf[ i + 1 ] = value.im;
	*     }
	* };
	*/
	interface Complex64Array extends ComplexArrayLike {
		/**
		* Returns an array element.
		*
		* @param i - element index
		* @returns array element
		*/
		get( i: number ): Complex64 | void;

		/**
		* Sets an array element.
		*
		* @param value - value(s)
		* @param i - element index at which to start writing values (default: 0)
		*/
		set( value: ArrayLike<number | ComplexLike> | Complex64Array | ComplexLike, i?: number ): void; // tslint:disable-line:max-line-length
	}

	/**
	* 128-bit complex number array.
	*
	* @example
	* const buf = new Float64Array( 8 );
	*
	* const z: Complex128Array = {
	*     'byteLength': 64,
	*     'byteOffset': 0,
	*     'BYTES_PER_ELEMENT': 8,
	*     'length': 8
	*     'get': ( i: number ): obj.Complex128 => {
	*         return {
	*             're': i * 10,
	*             'im': i * 10,
	*             'byteLength': 16,
	*             'BYTES_PER_ELEMENT': 8
	*         };
	*     },
	*     'set': ( value: obj.ComplexLike, i?: number ) => {
	*         i = ( i ) ? i : 0;
	*         buf[ i ] = value.re;
	*         buf[ i + 1 ] = value.im;
	*     }
	* };
	*/
	interface Complex128Array extends ComplexArrayLike {
		/**
		* Returns an array element.
		*
		* @param i - element index
		* @returns array element
		*/
		get( i: number ): Complex128 | void;

		/**
		* Sets an array element.
		*
		* @param value - value(s)
		* @param i - element index at which to start writing values (default: 0)
		*/
		set( value: ArrayLike<number | ComplexLike> | Complex128Array | ComplexLike, i?: number ): void; // tslint:disable-line:max-line-length
	}
}

/**
* Module containing iterator definitions.
*
* @example
* import * as iter from `@stdlib/types/iter`;
*
* const it: iter.Iterator = {
*     'next': () => { return { 'value': 0, 'done': false }; }
* };
*
* @example
* import { Iterator } from `@stdlib/types/iter`;
*
* const it: Iterator = {
*     'next': () => { return { 'value': 0, 'done': false }; }
* };
*/
declare module '@stdlib/types/iter' {
	/**
	* Interface describing an iterator protocol-compliant object.
	*
	* @example
	* const it: Iterator = {
	*     'next': () => { return { 'value': 0, 'done': false }; }
	* };
	*/
	interface Iterator {
		/**
		* Returns an iterator protocol-compliant object containing the next iterated value (if one exists) and a boolean flag indicating whether the iterator is finished.
		*
		* @returns iterator protocol-compliant object
		*/
		next(): IteratorResult;

		/**
		* Finishes an iterator.
		*
		* @param value - value to return
		* @returns iterator protocol-compliant object
		*/
		return?( value?: any ): IteratorResult;
	}

	/**
	* Interface describing an iterable iterator protocol-compliant object.
	*
	* @example
	* const it: IterableIterator = {
	*     'next': () => { return { 'value': 0, 'done': false }; },
	*     [Symbol.iterator]: () => { return this; }
	* };
	*/
	interface IterableIterator extends Iterator {
		/**
		* Returns a new iterable iterator.
		*
		* @returns iterable iterator
		*/
		[Symbol.iterator](): IterableIterator;
	}

	/**
	* Interface describing an iterator protocol-compliant results object.
	*
	* @example
	* const o: IteratorResult = {
	*     'value': 3.14,
	*     'done': false
	* };
	*/
	interface IteratorResult {
		/**
		* Iterated value (if one exists).
		*/
		value?: any;

		/**
		* Boolean flag indicating whether an iterator is finished.
		*/
		done: boolean;
	}

	/**
	* Interface describing an iterator protocol-compliant object.
	*
	* @example
	* const it: TypedIterator<number> = {
	*     'next': () => { return { 'value': 0, 'done': false }; }
	* };
	*/
	interface TypedIterator<T> {
		/**
		* Returns an iterator protocol-compliant object containing the next iterated value (if one exists) and a boolean flag indicating whether the iterator is finished.
		*
		* @returns iterator protocol-compliant object
		*/
		next(): TypedIteratorResult<T>;

		/**
		* Finishes an iterator.
		*
		* @param value - value to return
		* @returns iterator protocol-compliant object
		*/
		return?( value?: T ): TypedIteratorResult<T>;
	}

	/**
	* Interface describing an iterable iterator protocol-compliant object.
	*
	* @example
	* const it: IterableIterator = {
	*     'next': () => { return { 'value': 0, 'done': false }; },
	*     [Symbol.iterator]: () => { return this; }
	* };
	*/
	interface TypedIterableIterator<T> extends TypedIterator<T> {
		/**
		* Returns a new iterable iterator.
		*
		* @returns iterable iterator
		*/
		[Symbol.iterator](): TypedIterableIterator<T>;
	}

	/**
	* Interface describing an iterator protocol-compliant results object.
	*
	* @example
	* const o: TypedIteratorResult<number> = {
	*     'value': 3.14,
	*     'done': false
	* };
	*/
	interface TypedIteratorResult<T> {
		/**
		* Iterated value (if one exists).
		*/
		value?: T;

		/**
		* Boolean flag indicating whether an iterator is finished.
		*/
		done: boolean;
	}
}

/**
* Module containing ndarray definitions.
*
* @example
* import * as ndarray from `@stdlib/types/ndarray`;
*
* const arr: ndarray.ndarray = {
*     'byteLength': null,
*     'BYTES_PER_ELEMENT': null,
*     'data': [ 1, 2, 3 ],
*     'dtype': 'generic',
*     'flags': {
*         'ROW_MAJOR_CONTIGUOUS': true,
*         'COLUMN_MAJOR_CONTIGUOUS': false
*     },
*     'length': 3,
*     'ndims': 1,
*     'offset': 0,
*     'order': 'row-major',
*     'shape': [ 3 ],
*     'strides': [ 1 ],
*     'get': function get( i ) {
*         return this.data[ i ];
*     },
*     'set': function set( i, v ) {
*         this.data[ i ] = v;
*         return this;
*     }
* };
*
* @example
* import { ndarray } from `@stdlib/types/ndarray`;
*
* const arr: ndarray = {
*     'byteLength': null,
*     'BYTES_PER_ELEMENT': null,
*     'data': [ 1, 2, 3 ],
*     'dtype': 'generic',
*     'flags': {
*         'ROW_MAJOR_CONTIGUOUS': true,
*         'COLUMN_MAJOR_CONTIGUOUS': false
*     },
*     'length': 3,
*     'ndims': 1,
*     'offset': 0,
*     'order': 'row-major',
*     'shape': [ 3 ],
*     'strides': [ 1 ],
*     'get': function get( i ) {
*         return this.data[ i ];
*     },
*     'set': function set( i, v ) {
*         this.data[ i ] = v;
*         return this;
*     }
* };
*/
declare module '@stdlib/types/ndarray' {
	import { ArrayLike, AccessorArrayLike, Complex128Array, Complex64Array, RealOrComplexTypedArray, FloatOrComplexTypedArray, RealTypedArray, ComplexTypedArray, IntegerTypedArray, FloatTypedArray, SignedIntegerTypedArray, UnsignedIntegerTypedArray } from '@stdlib/types/array'; // tslint:disable-line:max-line-length
	import { ComplexLike, Complex128, Complex64 } from '@stdlib/types/object';

	/**
	* Data type.
	*/
	type DataType = RealOrComplexDataType | 'binary' | 'generic';

	/**
	* Data type for real-valued ndarrays.
	*/
	type RealDataType = FloatDataType | IntegerDataType;

	/**
	* Data type for floating-point ndarrays.
	*/
	type FloatDataType = 'float64' | 'float32';

	/**
	* Data type for integer ndarrays.
	*/
	type IntegerDataType = SignedIntegerDataType | UnsignedIntegerDataType;

	/**
	* Data type for signed integer ndarrays.
	*/
	type SignedIntegerDataType = 'int32' | 'int16' | 'int8';

	/**
	* Data type for unsigned integer ndarrays.
	*/
	type UnsignedIntegerDataType = 'uint32' | 'uint16' | 'uint8' | 'uint8c';

	/**
	* Data type for complex number ndarrays.
	*/
	type ComplexDataType = 'complex64' | 'complex128';

	/**
	* Data type for floating-point real or complex ndarrays.
	*/
	type FloatOrComplexDataType = FloatDataType | ComplexDataType;

	/**
	* Data type for real-valued or complex number ndarrays.
	*/
	type RealOrComplexDataType = RealDataType | ComplexDataType;

	/**
	* Array order.
	*
	* ## Notes
	*
	* -   The array order is either row-major (C-style) or column-major (Fortran-style).
	*/
	type Order = 'row-major' | 'column-major';

	/**
	* Array index mode.
	*
	* ## Notes
	*
	* -   The following index modes are supported:
	*
	*     -   `throw`: specifies that a function should throw an error when an index is outside a restricted interval.
	*     -   `wrap`: specifies that a function should wrap around an index using modulo arithmetic.
	*     -   `clamp`: specifies that a function should set an index less than zero to zero (minimum index) and set an index greater than a maximum index value to the maximum possible index.
	*/
	type Mode = 'throw' | 'clamp' | 'wrap';

	/**
	* Array shape.
	*
	* ## Notes
	*
	* -   Each element of the array shape (i.e., dimension size) should be a nonnegative integer.
	*/
	type Shape = ArrayLike<number>;

	/**
	* Array strides.
	*
	* ## Notes
	*
	* -   Each stride (i.e., index increment along a respective dimension) should be an integer.
	*/
	type Strides = ArrayLike<number>;

	/**
	* Interface describing an ndarray.
	*
	* @example
	* const arr: ndarray = {
	*     'byteLength': null,
	*     'BYTES_PER_ELEMENT': null,
	*     'data': [ 1, 2, 3 ],
	*     'dtype': 'generic',
	*     'flags': {
	*         'ROW_MAJOR_CONTIGUOUS': true,
	*         'COLUMN_MAJOR_CONTIGUOUS': false
	*     },
	*     'length': 3,
	*     'ndims': 1,
	*     'offset': 0,
	*     'order': 'row-major',
	*     'shape': [ 3 ],
	*     'strides': [ 1 ],
	*     'get': function get( i ) {
	*         return this.data[ i ];
	*     },
	*     'set': function set( i, v ) {
	*         this.data[ i ] = v;
	*         return this;
	*     }
	* };
	*/
	interface ndarray { // tslint:disable-line:class-name
		/**
		* Size (in bytes) of the array (if known).
		*/
		byteLength: number | null;

		/**
		* Size (in bytes) of each array element (if known).
		*/
		BYTES_PER_ELEMENT: number | null;

		/**
		* A reference to the underlying data buffer.
		*/
		data: ArrayLike<any> | AccessorArrayLike<any>;

		/**
		* Underlying data type.
		*/
		dtype: string;

		/**
		* Flags and other meta information (e.g., memory layout of the array).
		*/
		flags: {
			/**
			* Boolean indicating if an array is row-major contiguous.
			*/
			ROW_MAJOR_CONTIGUOUS: boolean;

			/**
			* Boolean indicating if an array is column-major contiguous.
			*/
			COLUMN_MAJOR_CONTIGUOUS: boolean;

			/**
			* Boolean indicating if an array is read-only.
			*/
			READONLY?: boolean;
		};

		/**
		* Number of array elements.
		*/
		length: number;

		/**
		* Number of dimensions.
		*/
		ndims: number;

		/**
		* Index offset which specifies the `buffer` index at which to start iterating over array elements.
		*/
		offset: number;

		/**
		* Array order.
		*
		* ## Notes
		*
		* -   The array order is either row-major (C-style) or column-major (Fortran-style).
		*/
		order: Order;

		/**
		* Array shape.
		*/
		shape: Shape;

		/**
		* Array strides.
		*/
		strides: Strides;

		/**
		* Returns an array element specified according to provided subscripts.
		*
		* ## Notes
		*
		* -   The number of provided subscripts should equal the number of dimensions.
		*
		* @param args - subscripts
		* @returns array element
		*/
		get( ...args: Array<number> ): any;

		/**
		* Sets an array element specified according to provided subscripts.
		*
		* ## Notes
		*
		* -   The number of provided subscripts should equal the number of dimensions.
		*
		* @param args - subscripts and value to set
		* @returns ndarray instance
		*/
		set( ...args: Array<any> ): ndarray;
	}

	/**
	* Interface describing an ndarray having a generic data type.
	*
	* @example
	* const arr: genericndarray = {
	*     'byteLength': null,
	*     'BYTES_PER_ELEMENT': null,
	*     'data': [ 1, 2, 3 ],
	*     'dtype': 'generic',
	*     'flags': {
	*         'ROW_MAJOR_CONTIGUOUS': true,
	*         'COLUMN_MAJOR_CONTIGUOUS': false
	*     },
	*     'length': 3,
	*     'ndims': 1,
	*     'offset': 0,
	*     'order': 'row-major',
	*     'shape': [ 3 ],
	*     'strides': [ 1 ],
	*     'get': function get( i ) {
	*         return this.data[ i ];
	*     },
	*     'set': function set( i, v ) {
	*         this.data[ i ] = v;
	*         return this;
	*     }
	* };
	*/
	interface genericndarray extends ndarray { // tslint:disable-line:class-name
		/**
		* Size (in bytes) of the array.
		*/
		byteLength: null;

		/**
		* Size (in bytes) of each array element.
		*/
		BYTES_PER_ELEMENT: null;

		/**
		* Underlying data type.
		*/
		dtype: 'generic';

		/**
		* A reference to the underlying data buffer.
		*/
		data: ArrayLike<any>;

		/**
		* Returns an array element specified according to provided subscripts.
		*
		* ## Notes
		*
		* -   The number of provided subscripts should equal the number of dimensions.
		*
		* @param args - subscripts
		* @returns array element
		*/
		get( ...args: Array<number> ): any;

		/**
		* Sets an array element specified according to provided subscripts.
		*
		* ## Notes
		*
		* -   The number of provided subscripts should equal the number of dimensions.
		*
		* @param args - subscripts and value to set
		* @returns ndarray instance
		*/
		set( ...args: Array<any> ): genericndarray;
	}

	/**
	* Interface describing an ndarray having a homogeneous data type.
	*
	* @example
	* const arr: typedndarray<number> = {
	*     'byteLength': null,
	*     'BYTES_PER_ELEMENT': null,
	*     'data': [ 1, 2, 3 ],
	*     'dtype': 'generic',
	*     'flags': {
	*         'ROW_MAJOR_CONTIGUOUS': true,
	*         'COLUMN_MAJOR_CONTIGUOUS': false
	*     },
	*     'length': 3,
	*     'ndims': 1,
	*     'offset': 0,
	*     'order': 'row-major',
	*     'shape': [ 3 ],
	*     'strides': [ 1 ],
	*     'get': function get( i ) {
	*         return this.data[ i ];
	*     },
	*     'set': function set( i, v ) {
	*         this.data[ i ] = v;
	*         return this;
	*     }
	* };
	*/
	interface typedndarray<T> extends ndarray { // tslint:disable-line:class-name
		/**
		* A reference to the underlying data buffer.
		*/
		data: ArrayLike<T>;

		/**
		* Returns an array element specified according to provided subscripts.
		*
		* ## Notes
		*
		* -   The number of provided subscripts should equal the number of dimensions.
		*
		* @param args - subscripts
		* @returns array element
		*/
		get( ...args: Array<number> ): T;

		/**
		* Sets an array element specified according to provided subscripts.
		*
		* ## Notes
		*
		* -   The number of provided subscripts should equal the number of dimensions.
		*
		* @param args - subscripts and value to set
		* @returns ndarray instance
		*/
		set( ...args: Array<number | T> ): typedndarray<T>;
	}

	/**
	* Interface describing an ndarray having a floating-point data type.
	*
	* @example
	* const arr: floatndarray = {
	*     'byteLength': 24,
	*     'BYTES_PER_ELEMENT': 8,
	*     'data': new Float64Array( [ 1, 2, 3 ] ),
	*     'dtype': 'float64',
	*     'flags': {
	*         'ROW_MAJOR_CONTIGUOUS': true,
	*         'COLUMN_MAJOR_CONTIGUOUS': false
	*     },
	*     'length': 3,
	*     'ndims': 1,
	*     'offset': 0,
	*     'order': 'row-major',
	*     'shape': [ 3 ],
	*     'strides': [ 1 ],
	*     'get': function get( i ) {
	*         return this.data[ i ];
	*     },
	*     'set': function set( i, v ) {
	*         this.data[ i ] = v;
	*         return this;
	*     }
	* };
	*/
	interface floatndarray extends typedndarray<number> { // tslint:disable-line:class-name
		/**
		* Size (in bytes) of the array.
		*/
		byteLength: number;

		/**
		* Size (in bytes) of each array element.
		*/
		BYTES_PER_ELEMENT: number;

		/**
		* A reference to the underlying data buffer.
		*/
		data: FloatTypedArray;

		/**
		* Underlying data type.
		*/
		dtype: FloatDataType;

		/**
		* Sets an array element specified according to provided subscripts.
		*
		* ## Notes
		*
		* -   The number of provided subscripts should equal the number of dimensions.
		*
		* @param args - subscripts and value to set
		* @returns ndarray instance
		*/
		set( ...args: Array<number> ): floatndarray;
	}

	/**
	* Interface describing an ndarray having a double-precision floating-point data type.
	*
	* @example
	* const arr: float64ndarray = {
	*     'byteLength': 24,
	*     'BYTES_PER_ELEMENT': 8,
	*     'data': new Float64Array( [ 1, 2, 3 ] ),
	*     'dtype': 'float64',
	*     'flags': {
	*         'ROW_MAJOR_CONTIGUOUS': true,
	*         'COLUMN_MAJOR_CONTIGUOUS': false
	*     },
	*     'length': 3,
	*     'ndims': 1,
	*     'offset': 0,
	*     'order': 'row-major',
	*     'shape': [ 3 ],
	*     'strides': [ 1 ],
	*     'get': function get( i ) {
	*         return this.data[ i ];
	*     },
	*     'set': function set( i, v ) {
	*         this.data[ i ] = v;
	*         return this;
	*     }
	* };
	*/
	interface float64ndarray extends floatndarray { // tslint:disable-line:class-name
		/**
		* Size (in bytes) of each array element.
		*/
		BYTES_PER_ELEMENT: 8;

		/**
		* A reference to the underlying data buffer.
		*/
		data: Float64Array;

		/**
		* Underlying data type.
		*/
		dtype: 'float64';

		/**
		* Sets an array element specified according to provided subscripts.
		*
		* ## Notes
		*
		* -   The number of provided subscripts should equal the number of dimensions.
		*
		* @param args - subscripts and value to set
		* @returns ndarray instance
		*/
		set( ...args: Array<number> ): float64ndarray;
	}

	/**
	* Interface describing an ndarray having a single-precision floating-point data type.
	*
	* @example
	* const arr: float32ndarray = {
	*     'byteLength': 12,
	*     'BYTES_PER_ELEMENT': 4,
	*     'data': new Float32Array( [ 1, 2, 3 ] ),
	*     'dtype': 'float32',
	*     'flags': {
	*         'ROW_MAJOR_CONTIGUOUS': true,
	*         'COLUMN_MAJOR_CONTIGUOUS': false
	*     },
	*     'length': 3,
	*     'ndims': 1,
	*     'offset': 0,
	*     'order': 'row-major',
	*     'shape': [ 3 ],
	*     'strides': [ 1 ],
	*     'get': function get( i ) {
	*         return this.data[ i ];
	*     },
	*     'set': function set( i, v ) {
	*         this.data[ i ] = v;
	*         return this;
	*     }
	* };
	*/
	interface float32ndarray extends floatndarray { // tslint:disable-line:class-name
		/**
		* Size (in bytes) of each array element.
		*/
		BYTES_PER_ELEMENT: 4;

		/**
		* A reference to the underlying data buffer.
		*/
		data: Float32Array;

		/**
		* Underlying data type.
		*/
		dtype: 'float32';

		/**
		* Sets an array element specified according to provided subscripts.
		*
		* ## Notes
		*
		* -   The number of provided subscripts should equal the number of dimensions.
		*
		* @param args - subscripts and value to set
		* @returns ndarray instance
		*/
		set( ...args: Array<number> ): float32ndarray;
	}

	/**
	* Interface describing an ndarray having an integer data type.
	*
	* @example
	* const arr: integerndarray = {
	*     'byteLength': 12,
	*     'BYTES_PER_ELEMENT': 4,
	*     'data': new Int32Array( [ 1, 2, 3 ] ),
	*     'dtype': 'int32',
	*     'flags': {
	*         'ROW_MAJOR_CONTIGUOUS': true,
	*         'COLUMN_MAJOR_CONTIGUOUS': false
	*     },
	*     'length': 3,
	*     'ndims': 1,
	*     'offset': 0,
	*     'order': 'row-major',
	*     'shape': [ 3 ],
	*     'strides': [ 1 ],
	*     'get': function get( i ) {
	*         return this.data[ i ];
	*     },
	*     'set': function set( i, v ) {
	*         this.data[ i ] = v;
	*         return this;
	*     }
	* };
	*/
	interface integerndarray extends typedndarray<number> { // tslint:disable-line:class-name
		/**
		* Size (in bytes) of the array.
		*/
		byteLength: number;

		/**
		* Size (in bytes) of each array element.
		*/
		BYTES_PER_ELEMENT: number;

		/**
		* A reference to the underlying data buffer.
		*/
		data: IntegerTypedArray;

		/**
		* Underlying data type.
		*/
		dtype: IntegerDataType;

		/**
		* Sets an array element specified according to provided subscripts.
		*
		* ## Notes
		*
		* -   The number of provided subscripts should equal the number of dimensions.
		*
		* @param args - subscripts and value to set
		* @returns ndarray instance
		*/
		set( ...args: Array<number> ): integerndarray;
	}

	/**
	* Interface describing an ndarray having a signed integer data type.
	*
	* @example
	* const arr: signedintegerndarray = {
	*     'byteLength': 12,
	*     'BYTES_PER_ELEMENT': 4,
	*     'data': new Int32Array( [ 1, 2, 3 ] ),
	*     'dtype': 'int32',
	*     'flags': {
	*         'ROW_MAJOR_CONTIGUOUS': true,
	*         'COLUMN_MAJOR_CONTIGUOUS': false
	*     },
	*     'length': 3,
	*     'ndims': 1,
	*     'offset': 0,
	*     'order': 'row-major',
	*     'shape': [ 3 ],
	*     'strides': [ 1 ],
	*     'get': function get( i ) {
	*         return this.data[ i ];
	*     },
	*     'set': function set( i, v ) {
	*         this.data[ i ] = v;
	*         return this;
	*     }
	* };
	*/
	interface signedintegerndarray extends typedndarray<number> { // tslint:disable-line:class-name
		/**
		* Size (in bytes) of the array.
		*/
		byteLength: number;

		/**
		* Size (in bytes) of each array element.
		*/
		BYTES_PER_ELEMENT: number;

		/**
		* A reference to the underlying data buffer.
		*/
		data: SignedIntegerTypedArray;

		/**
		* Underlying data type.
		*/
		dtype: SignedIntegerDataType;

		/**
		* Sets an array element specified according to provided subscripts.
		*
		* ## Notes
		*
		* -   The number of provided subscripts should equal the number of dimensions.
		*
		* @param args - subscripts and value to set
		* @returns ndarray instance
		*/
		set( ...args: Array<number> ): signedintegerndarray;
	}

	/**
	* Interface describing an ndarray having a signed 32-bit integer data type.
	*
	* @example
	* const arr: int32ndarray = {
	*     'byteLength': 12,
	*     'BYTES_PER_ELEMENT': 4,
	*     'data': new Int32Array( [ 1, 2, 3 ] ),
	*     'dtype': 'int32',
	*     'flags': {
	*         'ROW_MAJOR_CONTIGUOUS': true,
	*         'COLUMN_MAJOR_CONTIGUOUS': false
	*     },
	*     'length': 3,
	*     'ndims': 1,
	*     'offset': 0,
	*     'order': 'row-major',
	*     'shape': [ 3 ],
	*     'strides': [ 1 ],
	*     'get': function get( i ) {
	*         return this.data[ i ];
	*     },
	*     'set': function set( i, v ) {
	*         this.data[ i ] = v;
	*         return this;
	*     }
	* };
	*/
	interface int32ndarray extends signedintegerndarray { // tslint:disable-line:class-name
		/**
		* Size (in bytes) of each array element.
		*/
		BYTES_PER_ELEMENT: 4;

		/**
		* A reference to the underlying data buffer.
		*/
		data: Int32Array;

		/**
		* Underlying data type.
		*/
		dtype: 'int32';

		/**
		* Sets an array element specified according to provided subscripts.
		*
		* ## Notes
		*
		* -   The number of provided subscripts should equal the number of dimensions.
		*
		* @param args - subscripts and value to set
		* @returns ndarray instance
		*/
		set( ...args: Array<number> ): int32ndarray;
	}

	/**
	* Interface describing an ndarray having a signed 16-bit integer data type.
	*
	* @example
	* const arr: int16ndarray = {
	*     'byteLength': 6,
	*     'BYTES_PER_ELEMENT': 2,
	*     'data': new Int16Array( [ 1, 2, 3 ] ),
	*     'dtype': 'int16',
	*     'flags': {
	*         'ROW_MAJOR_CONTIGUOUS': true,
	*         'COLUMN_MAJOR_CONTIGUOUS': false
	*     },
	*     'length': 3,
	*     'ndims': 1,
	*     'offset': 0,
	*     'order': 'row-major',
	*     'shape': [ 3 ],
	*     'strides': [ 1 ],
	*     'get': function get( i ) {
	*         return this.data[ i ];
	*     },
	*     'set': function set( i, v ) {
	*         this.data[ i ] = v;
	*         return this;
	*     }
	* };
	*/
	interface int16ndarray extends signedintegerndarray { // tslint:disable-line:class-name
		/**
		* Size (in bytes) of each array element.
		*/
		BYTES_PER_ELEMENT: 2;

		/**
		* A reference to the underlying data buffer.
		*/
		data: Int16Array;

		/**
		* Underlying data type.
		*/
		dtype: 'int16';

		/**
		* Sets an array element specified according to provided subscripts.
		*
		* ## Notes
		*
		* -   The number of provided subscripts should equal the number of dimensions.
		*
		* @param args - subscripts and value to set
		* @returns ndarray instance
		*/
		set( ...args: Array<number> ): int16ndarray;
	}

	/**
	* Interface describing an ndarray having a signed 8-bit integer data type.
	*
	* @example
	* const arr: int8ndarray = {
	*     'byteLength': 3,
	*     'BYTES_PER_ELEMENT': 1,
	*     'data': new Int8Array( [ 1, 2, 3 ] ),
	*     'dtype': 'int8',
	*     'flags': {
	*         'ROW_MAJOR_CONTIGUOUS': true,
	*         'COLUMN_MAJOR_CONTIGUOUS': false
	*     },
	*     'length': 3,
	*     'ndims': 1,
	*     'offset': 0,
	*     'order': 'row-major',
	*     'shape': [ 3 ],
	*     'strides': [ 1 ],
	*     'get': function get( i ) {
	*         return this.data[ i ];
	*     },
	*     'set': function set( i, v ) {
	*         this.data[ i ] = v;
	*         return this;
	*     }
	* };
	*/
	interface int8ndarray extends signedintegerndarray { // tslint:disable-line:class-name
		/**
		* Size (in bytes) of each array element.
		*/
		BYTES_PER_ELEMENT: 1;

		/**
		* A reference to the underlying data buffer.
		*/
		data: Int8Array;

		/**
		* Underlying data type.
		*/
		dtype: 'int8';

		/**
		* Sets an array element specified according to provided subscripts.
		*
		* ## Notes
		*
		* -   The number of provided subscripts should equal the number of dimensions.
		*
		* @param args - subscripts and value to set
		* @returns ndarray instance
		*/
		set( ...args: Array<number> ): int8ndarray;
	}

	/**
	* Interface describing an ndarray having an unsigned integer data type.
	*
	* @example
	* const arr: unsignedintegerndarray = {
	*     'byteLength': 12,
	*     'BYTES_PER_ELEMENT': 4,
	*     'data': new Uint32Array( [ 1, 2, 3 ] ),
	*     'dtype': 'uint32',
	*     'flags': {
	*         'ROW_MAJOR_CONTIGUOUS': true,
	*         'COLUMN_MAJOR_CONTIGUOUS': false
	*     },
	*     'length': 3,
	*     'ndims': 1,
	*     'offset': 0,
	*     'order': 'row-major',
	*     'shape': [ 3 ],
	*     'strides': [ 1 ],
	*     'get': function get( i ) {
	*         return this.data[ i ];
	*     },
	*     'set': function set( i, v ) {
	*         this.data[ i ] = v;
	*         return this;
	*     }
	* };
	*/
	interface unsignedintegerndarray extends typedndarray<number> { // tslint:disable-line:class-name
		/**
		* Size (in bytes) of the array.
		*/
		byteLength: number;

		/**
		* Size (in bytes) of each array element.
		*/
		BYTES_PER_ELEMENT: number;

		/**
		* A reference to the underlying data buffer.
		*/
		data: UnsignedIntegerTypedArray;

		/**
		* Underlying data type.
		*/
		dtype: UnsignedIntegerDataType;

		/**
		* Sets an array element specified according to provided subscripts.
		*
		* ## Notes
		*
		* -   The number of provided subscripts should equal the number of dimensions.
		*
		* @param args - subscripts and value to set
		* @returns ndarray instance
		*/
		set( ...args: Array<number> ): unsignedintegerndarray;
	}

	/**
	* Interface describing an ndarray having an unsigned 32-bit integer data type.
	*
	* @example
	* const arr: uint32ndarray = {
	*     'byteLength': 12,
	*     'BYTES_PER_ELEMENT': 4,
	*     'data': new Uint32Array( [ 1, 2, 3 ] ),
	*     'dtype': 'uint32',
	*     'flags': {
	*         'ROW_MAJOR_CONTIGUOUS': true,
	*         'COLUMN_MAJOR_CONTIGUOUS': false
	*     },
	*     'length': 3,
	*     'ndims': 1,
	*     'offset': 0,
	*     'order': 'row-major',
	*     'shape': [ 3 ],
	*     'strides': [ 1 ],
	*     'get': function get( i ) {
	*         return this.data[ i ];
	*     },
	*     'set': function set( i, v ) {
	*         this.data[ i ] = v;
	*         return this;
	*     }
	* };
	*/
	interface uint32ndarray extends unsignedintegerndarray { // tslint:disable-line:class-name
		/**
		* Size (in bytes) of each array element.
		*/
		BYTES_PER_ELEMENT: 4;

		/**
		* A reference to the underlying data buffer.
		*/
		data: Uint32Array;

		/**
		* Underlying data type.
		*/
		dtype: 'uint32';

		/**
		* Sets an array element specified according to provided subscripts.
		*
		* ## Notes
		*
		* -   The number of provided subscripts should equal the number of dimensions.
		*
		* @param args - subscripts and value to set
		* @returns ndarray instance
		*/
		set( ...args: Array<number> ): uint32ndarray;
	}

	/**
	* Interface describing an ndarray having an unsigned 16-bit integer data type.
	*
	* @example
	* const arr: uint16ndarray = {
	*     'byteLength': 6,
	*     'BYTES_PER_ELEMENT': 2,
	*     'data': new Uint16Array( [ 1, 2, 3 ] ),
	*     'dtype': 'uint16',
	*     'flags': {
	*         'ROW_MAJOR_CONTIGUOUS': true,
	*         'COLUMN_MAJOR_CONTIGUOUS': false
	*     },
	*     'length': 3,
	*     'ndims': 1,
	*     'offset': 0,
	*     'order': 'row-major',
	*     'shape': [ 3 ],
	*     'strides': [ 1 ],
	*     'get': function get( i ) {
	*         return this.data[ i ];
	*     },
	*     'set': function set( i, v ) {
	*         this.data[ i ] = v;
	*         return this;
	*     }
	* };
	*/
	interface uint16ndarray extends unsignedintegerndarray { // tslint:disable-line:class-name
		/**
		* Size (in bytes) of each array element.
		*/
		BYTES_PER_ELEMENT: 2;

		/**
		* A reference to the underlying data buffer.
		*/
		data: Uint16Array;

		/**
		* Underlying data type.
		*/
		dtype: 'uint16';

		/**
		* Sets an array element specified according to provided subscripts.
		*
		* ## Notes
		*
		* -   The number of provided subscripts should equal the number of dimensions.
		*
		* @param args - subscripts and value to set
		* @returns ndarray instance
		*/
		set( ...args: Array<number> ): uint16ndarray;
	}

	/**
	* Interface describing an ndarray having an unsigned 8-bit integer data type.
	*
	* @example
	* const arr: uint8ndarray = {
	*     'byteLength': 3,
	*     'BYTES_PER_ELEMENT': 1,
	*     'data': new Uint8Array( [ 1, 2, 3 ] ),
	*     'dtype': 'uint8',
	*     'flags': {
	*         'ROW_MAJOR_CONTIGUOUS': true,
	*         'COLUMN_MAJOR_CONTIGUOUS': false
	*     },
	*     'length': 3,
	*     'ndims': 1,
	*     'offset': 0,
	*     'order': 'row-major',
	*     'shape': [ 3 ],
	*     'strides': [ 1 ],
	*     'get': function get( i ) {
	*         return this.data[ i ];
	*     },
	*     'set': function set( i, v ) {
	*         this.data[ i ] = v;
	*         return this;
	*     }
	* };
	*/
	interface uint8ndarray extends unsignedintegerndarray { // tslint:disable-line:class-name
		/**
		* Size (in bytes) of each array element.
		*/
		BYTES_PER_ELEMENT: 1;

		/**
		* A reference to the underlying data buffer.
		*/
		data: Uint8Array;

		/**
		* Underlying data type.
		*/
		dtype: 'uint8';

		/**
		* Sets an array element specified according to provided subscripts.
		*
		* ## Notes
		*
		* -   The number of provided subscripts should equal the number of dimensions.
		*
		* @param args - subscripts and value to set
		* @returns ndarray instance
		*/
		set( ...args: Array<number> ): uint8ndarray;
	}

	/**
	* Interface describing an ndarray having a clamped unsigned 8-bit integer data type.
	*
	* @example
	* const arr: uint8cndarray = {
	*     'byteLength': 12,
	*     'BYTES_PER_ELEMENT': 4,
	*     'data': new Uint8ClampedArray( [ 1, 2, 3 ] ),
	*     'dtype': 'uint8c',
	*     'flags': {
	*         'ROW_MAJOR_CONTIGUOUS': true,
	*         'COLUMN_MAJOR_CONTIGUOUS': false
	*     },
	*     'length': 3,
	*     'ndims': 1,
	*     'offset': 0,
	*     'order': 'row-major',
	*     'shape': [ 3 ],
	*     'strides': [ 1 ],
	*     'get': function get( i ) {
	*         return this.data[ i ];
	*     },
	*     'set': function set( i, v ) {
	*         this.data[ i ] = v;
	*         return this;
	*     }
	* };
	*/
	interface uint8cndarray extends unsignedintegerndarray { // tslint:disable-line:class-name
		/**
		* Size (in bytes) of each array element.
		*/
		BYTES_PER_ELEMENT: 1;

		/**
		* A reference to the underlying data buffer.
		*/
		data: Uint8ClampedArray;

		/**
		* Underlying data type.
		*/
		dtype: 'uint8c';

		/**
		* Sets an array element specified according to provided subscripts.
		*
		* ## Notes
		*
		* -   The number of provided subscripts should equal the number of dimensions.
		*
		* @param args - subscripts and value to set
		* @returns ndarray instance
		*/
		set( ...args: Array<number> ): uint8cndarray;
	}

	/**
	* Interface describing an ndarray having a real-valued data type.
	*
	* @example
	* const arr: realndarray = {
	*     'byteLength': 24,
	*     'BYTES_PER_ELEMENT': 8,
	*     'data': new Float64Array( [ 1, 2, 3 ] ),
	*     'dtype': 'float64',
	*     'flags': {
	*         'ROW_MAJOR_CONTIGUOUS': true,
	*         'COLUMN_MAJOR_CONTIGUOUS': false
	*     },
	*     'length': 3,
	*     'ndims': 1,
	*     'offset': 0,
	*     'order': 'row-major',
	*     'shape': [ 3 ],
	*     'strides': [ 1 ],
	*     'get': function get( i ) {
	*         return this.data[ i ];
	*     },
	*     'set': function set( i, v ) {
	*         this.data[ i ] = v;
	*         return this;
	*     }
	* };
	*/
	interface realndarray extends typedndarray<number> { // tslint:disable-line:class-name
		/**
		* Size (in bytes) of the array.
		*/
		byteLength: number;

		/**
		* Size (in bytes) of each array element.
		*/
		BYTES_PER_ELEMENT: number;

		/**
		* A reference to the underlying data buffer.
		*/
		data: RealTypedArray;

		/**
		* Underlying data type.
		*/
		dtype: RealDataType;

		/**
		* Sets an array element specified according to provided subscripts.
		*
		* ## Notes
		*
		* -   The number of provided subscripts should equal the number of dimensions.
		*
		* @param args - subscripts and value to set
		* @returns ndarray instance
		*/
		set( ...args: Array<number> ): realndarray;
	}

	/**
	* Interface describing an ndarray having a real or complex number data type.
	*
	* @example
	* const arr: realcomplexndarray = {
	*     'byteLength': 24,
	*     'BYTES_PER_ELEMENT': 8,
	*     'data': new Float64Array( [ 1, 2, 3 ] ),
	*     'dtype': 'float64',
	*     'flags': {
	*         'ROW_MAJOR_CONTIGUOUS': true,
	*         'COLUMN_MAJOR_CONTIGUOUS': false
	*     },
	*     'length': 3,
	*     'ndims': 1,
	*     'offset': 0,
	*     'order': 'row-major',
	*     'shape': [ 3 ],
	*     'strides': [ 1 ],
	*     'get': function get( i ) {
	*         return this.data[ i ];
	*     },
	*     'set': function set( i, v ) {
	*         this.data[ i ] = v;
	*         return this;
	*     }
	* };
	*/
	interface realcomplexndarray extends ndarray { // tslint:disable-line:class-name
		/**
		* Size (in bytes) of the array.
		*/
		byteLength: number;

		/**
		* Size (in bytes) of each array element.
		*/
		BYTES_PER_ELEMENT: number;

		/**
		* A reference to the underlying data buffer.
		*/
		data: RealOrComplexTypedArray;

		/**
		* Underlying data type.
		*/
		dtype: RealOrComplexDataType;

		/**
		* Returns an array element specified according to provided subscripts.
		*
		* ## Notes
		*
		* -   The number of provided subscripts should equal the number of dimensions.
		*
		* @param args - subscripts
		* @returns array element
		*/
		get( ...args: Array<number> ): number | ComplexLike | void;

		/**
		* Sets an array element specified according to provided subscripts.
		*
		* ## Notes
		*
		* -   The number of provided subscripts should equal the number of dimensions.
		*
		* @param args - subscripts and value to set
		* @returns ndarray instance
		*/
		set( ...args: Array<number | ComplexLike> ): realcomplexndarray;
	}

	/**
	* Interface describing an ndarray having a floating-point real or complex number data type.
	*
	* @example
	* const arr: floatcomplexndarray = {
	*     'byteLength': 24,
	*     'BYTES_PER_ELEMENT': 8,
	*     'data': new Float64Array( [ 1, 2, 3 ] ),
	*     'dtype': 'float64',
	*     'flags': {
	*         'ROW_MAJOR_CONTIGUOUS': true,
	*         'COLUMN_MAJOR_CONTIGUOUS': false
	*     },
	*     'length': 3,
	*     'ndims': 1,
	*     'offset': 0,
	*     'order': 'row-major',
	*     'shape': [ 3 ],
	*     'strides': [ 1 ],
	*     'get': function get( i ) {
	*         return this.data[ i ];
	*     },
	*     'set': function set( i, v ) {
	*         this.data[ i ] = v;
	*         return this;
	*     }
	* };
	*/
	interface floatcomplexndarray extends ndarray { // tslint:disable-line:class-name
		/**
		* Size (in bytes) of the array.
		*/
		byteLength: number;

		/**
		* Size (in bytes) of each array element.
		*/
		BYTES_PER_ELEMENT: number;

		/**
		* A reference to the underlying data buffer.
		*/
		data: FloatOrComplexTypedArray;

		/**
		* Underlying data type.
		*/
		dtype: FloatOrComplexDataType;

		/**
		* Returns an array element specified according to provided subscripts.
		*
		* ## Notes
		*
		* -   The number of provided subscripts should equal the number of dimensions.
		*
		* @param args - subscripts
		* @returns array element
		*/
		get( ...args: Array<number> ): number | ComplexLike | void;

		/**
		* Sets an array element specified according to provided subscripts.
		*
		* ## Notes
		*
		* -   The number of provided subscripts should equal the number of dimensions.
		*
		* @param args - subscripts and value to set
		* @returns ndarray instance
		*/
		set( ...args: Array<number | ComplexLike> ): floatcomplexndarray;
	}

	/**
	* Interface describing an ndarray having a complex number data type.
	*
	* @example
	* const arr: complexndarray = {
	*     'byteLength': 48,
	*     'BYTES_PER_ELEMENT': 16,
	*     'data': new Complex128Array( [ 1, 2, 3, 4, 5, 6 ] ),
	*     'dtype': 'complex128',
	*     'flags': {
	*         'ROW_MAJOR_CONTIGUOUS': true,
	*         'COLUMN_MAJOR_CONTIGUOUS': false
	*     },
	*     'length': 3,
	*     'ndims': 1,
	*     'offset': 0,
	*     'order': 'row-major',
	*     'shape': [ 3 ],
	*     'strides': [ 1 ],
	*     'get': function get( i ) {
	*         return new Complex128( this.data[ i*2 ], this.data[ (i*2)+1 ] );
	*     },
	*     'set': function set( i, v ) {
	*         this.data[ i ] = v;
	*         return this;
	*     }
	* };
	*/
	interface complexndarray extends ndarray { // tslint:disable-line:class-name
		/**
		* Size (in bytes) of the array.
		*/
		byteLength: number;

		/**
		* Size (in bytes) of each array element.
		*/
		BYTES_PER_ELEMENT: number;

		/**
		* A reference to the underlying data buffer.
		*/
		data: ComplexTypedArray;

		/**
		* Underlying data type.
		*/
		dtype: ComplexDataType;

		/**
		* Returns an array element specified according to provided subscripts.
		*
		* ## Notes
		*
		* -   The number of provided subscripts should equal the number of dimensions.
		*
		* @param args - subscripts
		* @returns array element
		*/
		get( ...args: Array<number> ): ComplexLike | void;

		/**
		* Sets an array element specified according to provided subscripts.
		*
		* ## Notes
		*
		* -   The number of provided subscripts should equal the number of dimensions.
		*
		* @param args - subscripts and value to set
		* @returns ndarray instance
		*/
		set( ...args: Array<number | ComplexLike> ): complexndarray;
	}

	/**
	* Interface describing an ndarray having a double-precision complex floating-point data type.
	*
	* @example
	* const arr: complex128ndarray = {
	*     'byteLength': 48,
	*     'BYTES_PER_ELEMENT': 16,
	*     'data': new Complex128Array( [ 1, 2, 3, 4, 5, 6 ] ),
	*     'dtype': 'complex128',
	*     'flags': {
	*         'ROW_MAJOR_CONTIGUOUS': true,
	*         'COLUMN_MAJOR_CONTIGUOUS': false
	*     },
	*     'length': 3,
	*     'ndims': 1,
	*     'offset': 0,
	*     'order': 'row-major',
	*     'shape': [ 3 ],
	*     'strides': [ 1 ],
	*     'get': function get( i ) {
	*         return new Complex128( this.data[ i*2 ], this.data[ (i*2)+1 ] );
	*     },
	*     'set': function set( i, v ) {
	*         this.data[ i ] = v;
	*         return this;
	*     }
	* };
	*/
	interface complex128ndarray extends complexndarray { // tslint:disable-line:class-name
		/**
		* Size (in bytes) of each array element.
		*/
		BYTES_PER_ELEMENT: 16;

		/**
		* A reference to the underlying data buffer.
		*/
		data: Complex128Array;

		/**
		* Underlying data type.
		*/
		dtype: 'complex128';

		/**
		* Returns an array element specified according to provided subscripts.
		*
		* ## Notes
		*
		* -   The number of provided subscripts should equal the number of dimensions.
		*
		* @param args - subscripts
		* @returns array element
		*/
		get( ...args: Array<number> ): Complex128 | void;

		/**
		* Sets an array element specified according to provided subscripts.
		*
		* ## Notes
		*
		* -   The number of provided subscripts should equal the number of dimensions.
		*
		* @param args - subscripts and value to set
		* @returns ndarray instance
		*/
		set( ...args: Array<number | ComplexLike> ): complex128ndarray;
	}

	/**
	* Interface describing an ndarray having a single-precision complex floating-point data type.
	*
	* @example
	* const arr: complex64ndarray = {
	*     'byteLength': 24,
	*     'BYTES_PER_ELEMENT': 8,
	*     'data': new Complex64Array( [ 1, 2, 3, 4, 5, 6 ] ),
	*     'dtype': 'complex64',
	*     'flags': {
	*         'ROW_MAJOR_CONTIGUOUS': true,
	*         'COLUMN_MAJOR_CONTIGUOUS': false
	*     },
	*     'length': 3,
	*     'ndims': 1,
	*     'offset': 0,
	*     'order': 'row-major',
	*     'shape': [ 3 ],
	*     'strides': [ 1 ],
	*     'get': function get( i ) {
	*         return new Complex64( this.data[ i*2 ], this.data[ (i*2)+1 ] );
	*     },
	*     'set': function set( i, v ) {
	*         this.data[ i ] = v;
	*         return this;
	*     }
	* };
	*/
	interface complex64ndarray extends complexndarray { // tslint:disable-line:class-name
		/**
		* Size (in bytes) of each array element.
		*/
		BYTES_PER_ELEMENT: 8;

		/**
		* A reference to the underlying data buffer.
		*/
		data: Complex64Array;

		/**
		* Underlying data type.
		*/
		dtype: 'complex64';

		/**
		* Returns an array element specified according to provided subscripts.
		*
		* ## Notes
		*
		* -   The number of provided subscripts should equal the number of dimensions.
		*
		* @param args - subscripts
		* @returns array element
		*/
		get( ...args: Array<number> ): Complex64 | void;

		/**
		* Sets an array element specified according to provided subscripts.
		*
		* ## Notes
		*
		* -   The number of provided subscripts should equal the number of dimensions.
		*
		* @param args - subscripts and value to set
		* @returns ndarray instance
		*/
		set( ...args: Array<number | ComplexLike> ): complex64ndarray;
	}

	/**
	* Interface describing a one-dimensional ndarray having a homogeneous data type.
	*
	* @example
	* const arr: Vector<number> = {
	*     'byteLength': 24,
	*     'BYTES_PER_ELEMENT': 8,
	*     'data': new Float64Array( [ 1, 2, 3 ] ),
	*     'dtype': 'float64',
	*     'flags': {
	*         'ROW_MAJOR_CONTIGUOUS': true,
	*         'COLUMN_MAJOR_CONTIGUOUS': false
	*     },
	*     'length': 3,
	*     'ndims': 1,
	*     'offset': 0,
	*     'order': 'row-major',
	*     'shape': [ 3 ],
	*     'strides': [ 1 ],
	*     'get': function get( i ) {
	*         return this.data[ i ];
	*     },
	*     'set': function set( i, v ) {
	*         this.data[ i ] = v;
	*         return this;
	*     }
	* };
	*/
	interface Vector<T> extends typedndarray<T> {
		/**
		* Number of dimensions.
		*/
		ndims: 1;

		/**
		* Array shape.
		*/
		shape: [ number ]; // tslint:disable-line:no-single-element-tuple-type

		/**
		* Array strides.
		*/
		strides: [ number ]; // tslint:disable-line:no-single-element-tuple-type

		/**
		* Sets an array element specified according to provided subscripts.
		*
		* ## Notes
		*
		* -   The number of provided subscripts should equal the number of dimensions.
		*
		* @param i - element index
		* @param value - value to set
		* @returns ndarray instance
		*/
		set( i: number, value: T ): Vector<T>;
	}

	/**
	* Interface describing a two-dimensional ndarray having a homogeneous data type.
	*
	* @example
	* const arr: Matrix<number> = {
	*     'byteLength': 24,
	*     'BYTES_PER_ELEMENT': 8,
	*     'data': new Float64Array( [ 1, 2, 3 ] ),
	*     'dtype': 'float64',
	*     'flags': {
	*         'ROW_MAJOR_CONTIGUOUS': true,
	*         'COLUMN_MAJOR_CONTIGUOUS': false
	*     },
	*     'length': 3,
	*     'ndims': 2,
	*     'offset': 0,
	*     'order': 'row-major',
	*     'shape': [ 1, 3 ],
	*     'strides': [ 3, 1 ],
	*     'get': function get( i ) {
	*         return this.data[ i ];
	*     },
	*     'set': function set( i, v ) {
	*         this.data[ i ] = v;
	*         return this;
	*     }
	* };
	*/
	interface Matrix<T> extends typedndarray<T> {
		/**
		* Number of dimensions.
		*/
		ndims: 2;

		/**
		* Array shape.
		*/
		shape: [ number, number ];

		/**
		* Array strides.
		*/
		strides: [ number, number ];

		/**
		* Sets an array element specified according to provided subscripts.
		*
		* ## Notes
		*
		* -   The number of provided subscripts should equal the number of dimensions.
		*
		* @param i - index along first dimension
		* @param j - index along second dimension
		* @param value - value to set
		* @returns ndarray instance
		*/
		set( i: number, j: number, value: T ): Matrix<T>;
	}
}

/**
* Module containing object definitions.
*
* @example
* import * as obj from `@stdlib/types/object`;
*
* const desc: obj.DataPropertyDescriptor = {
*     'configurable': false,
*     'enumerable': true,
*     'writable': false,
*     'value': 'beep'
* };
*
* @example
* import { DataPropertyDescriptor } from `@stdlib/types/object`;
*
* const desc: DataPropertyDescriptor = {
*     'configurable': false,
*     'enumerable': true,
*     'writable': false,
*     'value': 'beep'
* };
*/
declare module '@stdlib/types/object' {
	import { ArrayLike, TypedArray } from '@stdlib/types/array';

	/**
	* Interface describing a data property descriptor object.
	*
	* @example
	* const desc: DataPropertyDescriptor = {
	*     'configurable': false,
	*     'enumerable': true,
	*     'writable': false,
	*     'value': 'beep'
	* };
	*/
	interface DataPropertyDescriptor {
		/**
		* Specifies whether a property descriptor may be changed and whether a property may be deleted from a corresponding object (default: `false`).
		*/
		configurable?: boolean;

		/**
		* Specifies whether a property can be enumerated (default: `false`).
		*/
		enumerable?: boolean;

		/**
		* Specifies whether the value associated with a property can be changed via the assignment operator (default: `false`).
		*/
		writable?: boolean;

		/**
		* Value associated with a property (default: `undefined`).
		*/
		value?: any;
	}

	/**
	* Interface describing an accessor property descriptor object.
	*
	* @example
	* const desc: AccessorPropertyDescriptor = {
	*     'configurable': false,
	*     'enumerable': true,
	*     'get': (): string => 'foo',
	*     'set': () => { throw new Error( 'invalid operation.' ); }
	* };
	*/
	interface AccessorPropertyDescriptor {
		/**
		* Specifies whether a property descriptor may be changed and whether a property may be deleted from a corresponding object (default: `false`).
		*/
		configurable?: boolean;

		/**
		* Specifies whether a property can be enumerated (default: `false`).
		*/
		enumerable?: boolean;

		/**
		* A function which serves as a getter for the property.
		*
		* ## Notes
		*
		* -   If omitted from a descriptor, a property value cannot be accessed.
		* -   When the property is accessed, the function is called without arguments and with `this` set to the object through which the property is accessed (note: this may **not** be the object on which the property is defined due to inheritance).
		* -   The return value will be used as the value of the property.
		*/
		get?(): any;

		/**
		* A function which serves as a setter for the property.
		*
		* ## Notes
		*
		* -   If omitted from a descriptor, a property value cannot be assigned.
		* -   When the property is assigned to, the function is called with one argument (the value being assigned to the property) and with `this` set to the object through which the property is assigned.
		*/
		set?( x: any ): void;
	}

	/**
	* Property descriptor object.
	*
	* @example
	* const desc: PropertyDescriptor = {
	*     'configurable': false,
	*     'enumerable': true,
	*     'writable': false,
	*     'value': 'beep'
	* };
	*/
	type PropertyDescriptor = DataPropertyDescriptor | AccessorPropertyDescriptor; // tslint:disable-line:max-line-length

	/**
	* An object property name.
	*
	* @example
	* const prop: PropertyName = 'foo';
	*/
	type PropertyName = string | symbol;

	/**
	* A collection, which is defined as either an array, typed array, or an array-like object (excluding strings and functions).
	*
	* @example
	* const arr: Collection = [ 1, 2, 3 ];
	*/
	type Collection = Array<any> | TypedArray | ArrayLike<any>;

	/**
	* Complex number data type.
	*/
	type ComplexDataType = 'complex64' | 'complex128';

	/**
	* A complex number-like object.
	*
	* @example
	* const x: ComplexLike = { 're': 5.0, 'im': 3.0 };
	*/
	interface ComplexLike {
		/**
		* Real component.
		*/
		re: number;

		/**
		* Imaginary component.
		*/
		im: number;
	}

	/**
	* A 64-bit complex number.
	*
	* @example
	* const x: Complex64 = {
	*     're': 5.0,
	*     'im': 3.0,
	*     'byteLength': 8,
	*     'BYTES_PER_ELEMENT': 4
	* };
	*/
	interface Complex64 extends ComplexLike {
		/**
		* Size (in bytes) of the complex number.
		*/
		byteLength: 8;

		/**
		* Size (in bytes) of each component.
		*/
		BYTES_PER_ELEMENT: 4;
	}

	/**
	* A 128-bit complex number.
	*
	* @example
	* const x: Complex128 = {
	*     're': 5.0,
	*     'im': 3.0,
	*     'byteLength': 16,
	*     'BYTES_PER_ELEMENT': 8
	* };
	*/
	interface Complex128 extends ComplexLike {
		/**
		* Size (in bytes) of the complex number.
		*/
		byteLength: 16;

		/**
		* Size (in bytes) of each component.
		*/
		BYTES_PER_ELEMENT: 8;
	}
}

/**
* Module containing PRNG definitions.
*
* @example
* import * as random from `@stdlib/types/random`;
*
* const rand: random.PRNG = () => 3.14;
*
* @example
* import { PRNG } from `@stdlib/types/random`;
*
* const rand: PRNG = () => 3.14;
*/
declare module '@stdlib/types/random' {
	import { ArrayLike } from '@stdlib/types/array';

	/**
	* A pseudorandom number generator (PRNG).
	*
	* @param args - PRNG parameters
	* @returns pseudorandom number
	*
	* @example
	* const rand: PRNG = () => 3.14;
	*/
	type PRNG = ( ...args: Array<any> ) => number;

	/**
	* A pseudorandom number generator (PRNG) seed for the 32-bit Mersenne Twister (MT19937) PRNG.
	*
	* @example
	* const s: PRNGSeedMT19937 = 12345;
	*
	* @example
	* const s: PRNGSeedMT19937 = [ 12345, 67891 ];
	*/
	type PRNGSeedMT19937 = number | ArrayLike<number>;

	/**
	* A pseudorandom number generator (PRNG) state for the 32-bit Mersenne Twister (MT19937) PRNG.
	*
	* @example
	* const s: PRNGStateMT19937 = new Uint32Array( 627 );
	*/
	type PRNGStateMT19937 = Uint32Array;

	/**
	* A pseudorandom number generator (PRNG) seed for the MINSTD PRNG.
	*
	* @example
	* const s: PRNGSeedMINSTD = 12345;
	*
	* @example
	* const s: PRNGSeedMINSTD = [ 12345, 67891 ];
	*/
	type PRNGSeedMINSTD = number | ArrayLike<number>;

	/**
	* A pseudorandom number generator (PRNG) state for the MINSTD PRNG.
	*
	* @example
	* const s: PRNGStateMINSTD = new Int32Array( 6 );
	*/
	type PRNGStateMINSTD = Int32Array;
}
