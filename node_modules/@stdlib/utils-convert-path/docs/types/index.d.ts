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
* Converts between POSIX and Windows paths.
*
* @param from - path to convert
* @param to - output path convention
* @throws second argument must be a recognized output path convention
* @throws cannot convert a Windows extended-length path to a non-Windows path convention
* @returns converted path
*
* @example
* var p = convertPath( '/c/foo/bar/beep.c', 'win32' );
* // returns 'c:\\foo\\bar\\beep.c'
*
* @example
* var p = convertPath( '/c/foo/bar/beep.c', 'mixed' );
* // returns 'c:/foo/bar/beep.c'
*
* @example
* var p = convertPath( 'C:\\foo\\bar\\beep.c', 'posix' );
* // returns '/c/foo/bar/beep.c'
*
* @example
* var p = convertPath( 'C:\\foo\\bar\\beep.c', 'mixed' );
* // returns 'C:/foo/bar/beep.c'
*/
declare function convertPath( from: string, to: string ): string;


// EXPORTS //

export = convertPath;
