# @license Apache-2.0
#
# Copyright (c) 2018 The Stdlib Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# A GYP include file for building a Node.js native add-on.
#
# Main documentation:
#
# [1]: https://gyp.gsrc.io/docs/InputFormatReference.md
# [2]: https://gyp.gsrc.io/docs/UserDocumentation.md
{
  # Define variables to be used throughout the configuration for all targets:
  'variables': {
    # Source directory:
    'src_dir': './src',

    # Include directories:
    'include_dirs': [
      '<!@(node -e "var arr = require(\'@stdlib/utils-library-manifest\')(\'./manifest.json\',{},{\'basedir\':process.cwd(),\'paths\':\'posix\'}).include; for ( var i = 0; i < arr.length; i++ ) { console.log( arr[ i ] ); }")',
    ],

    # Add-on destination directory:
    'addon_output_dir': './src',

    # Source files:
    'src_files': [
      '<(src_dir)/addon.cpp',
      '<!@(node -e "var arr = require(\'@stdlib/utils-library-manifest\')(\'./manifest.json\',{},{\'basedir\':process.cwd(),\'paths\':\'posix\'}).src; for ( var i = 0; i < arr.length; i++ ) { console.log( arr[ i ] ); }")',
    ],

    # Library dependencies:
    'libraries': [
      '<!@(node -e "var arr = require(\'@stdlib/utils-library-manifest\')(\'./manifest.json\',{},{\'basedir\':process.cwd(),\'paths\':\'posix\'}).libraries; for ( var i = 0; i < arr.length; i++ ) { console.log( arr[ i ] ); }")',
    ],

    # Library directories:
    'library_dirs': [
      '<!@(node -e "var arr = require(\'@stdlib/utils-library-manifest\')(\'./manifest.json\',{},{\'basedir\':process.cwd(),\'paths\':\'posix\'}).libpath; for ( var i = 0; i < arr.length; i++ ) { console.log( arr[ i ] ); }")',
    ],
  }, # end variables
}
