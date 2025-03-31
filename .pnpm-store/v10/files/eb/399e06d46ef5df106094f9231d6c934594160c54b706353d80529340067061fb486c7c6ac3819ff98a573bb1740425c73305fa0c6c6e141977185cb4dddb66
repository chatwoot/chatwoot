# SparkMD5

SparkMD5 is a fast md5 implementation of the MD5 algorithm.
This script is based in the JKM md5 library which is the [fastest](http://jsperf.com/md5-shootout/7) algorithm around. This is most suitable for browser usage, because `nodejs` version might be faster.

NOTE: Please disable Firebug while performing the test!
      Firebug consumes a lot of memory and CPU and slows the test by a great margin.


**[Demo](http://9px.ir/demo/incremental-md5.html)**

## Install

```sh
npm install --save spark-md5
```

## Improvements over the JKM md5 library

 * Strings are converted to utf8, like most server side algorithms
 * Fix computation for large amounts of data (overflow)
 * Incremental md5 (see below)
 * Support for array buffers (typed arrays)
 * Functionality wrapped in a closure, to avoid global assignments
 * Object oriented library
 * CommonJS (it can be used in node) and AMD integration
 * Code passed through JSHint and JSCS


Incremental md5 performs a lot better for hashing large amounts of data, such as
files. One could read files in chunks, using the FileReader & Blob's, and append
each chunk for md5 hashing while keeping memory usage low. See example below.


## Usage

### Normal usage

```js
var hexHash = SparkMD5.hash('Hi there');        // hex hash
var rawHash = SparkMD5.hash('Hi there', true);  // OR raw hash (binary string)
```

### Incremental usage

```js
var spark = new SparkMD5();
spark.append('Hi');
spark.append(' there');
var hexHash = spark.end();                      // hex hash
var rawHash = spark.end(true);                  // OR raw hash (binary string)
```

### Hash a file incrementally

NOTE: If you test the code bellow using the file:// protocol in chrome you must start the browser with -allow-file-access-from-files argument.
      Please see: http://code.google.com/p/chromium/issues/detail?id=60889

```js
document.getElementById('file').addEventListener('change', function () {
    var blobSlice = File.prototype.slice || File.prototype.mozSlice || File.prototype.webkitSlice,
        file = this.files[0],
        chunkSize = 2097152,                             // Read in chunks of 2MB
        chunks = Math.ceil(file.size / chunkSize),
        currentChunk = 0,
        spark = new SparkMD5.ArrayBuffer(),
        fileReader = new FileReader();

    fileReader.onload = function (e) {
        console.log('read chunk nr', currentChunk + 1, 'of', chunks);
        spark.append(e.target.result);                   // Append array buffer
        currentChunk++;

        if (currentChunk < chunks) {
            loadNext();
        } else {
            console.log('finished loading');
            console.info('computed hash', spark.end());  // Compute hash
        }
    };

    fileReader.onerror = function () {
        console.warn('oops, something went wrong.');
    };

    function loadNext() {
        var start = currentChunk * chunkSize,
            end = ((start + chunkSize) >= file.size) ? file.size : start + chunkSize;

        fileReader.readAsArrayBuffer(blobSlice.call(file, start, end));
    }

    loadNext();
});
```

You can see some more examples in the test folder.

## Documentation


### SparkMD5 class

#### SparkMD5#append(str)

Appends a string, encoding it to UTF8 if necessary.

#### SparkMD5#appendBinary(str)

Appends a binary string (e.g.: string returned from the deprecated [readAsBinaryString](https://developer.mozilla.org/en-US/docs/Web/API/FileReader/readAsBinaryString)).

#### SparkMD5#end(raw)

Finishes the computation of the md5, returning the hex result.
If `raw` is true, the result as a binary string will be returned instead.

#### SparkMD5#reset()

Resets the internal state of the computation.

#### SparkMD5#getState()

Returns an object representing the internal computation state.
You can pass this state to setState(). This feature is useful to resume an incremental md5.

#### SparkMD5#setState(state)

Sets the internal computation state. See: getState().

#### SparkMD5#destroy()

Releases memory used by the incremental buffer and other additional resources.

#### SparkMD5.hash(str, raw)

Hashes a string directly, returning the hex result.
If `raw` is true, the result as a binary string will be returned instead.
Note that this function is `static`.

#### SparkMD5.hashBinary(str, raw)

Hashes a binary string directly (e.g.: string returned from the deprecated [readAsBinaryString](https://developer.mozilla.org/en-US/docs/Web/API/FileReader/readAsBinaryString)), returning the hex result.
If `raw` is true, the result as a binary string will be returned instead.
Note that this function is `static`.


### SparkMD5.ArrayBuffer class

#### SparkMD5.ArrayBuffer#append(arr)

Appends an array buffer.

#### SparkMD5.ArrayBuffer#end(raw)

Finishes the computation of the md5, returning the hex result.
If `raw` is true, the result as a binary string will be returned instead.

#### SparkMD5.ArrayBuffer#reset()

Resets the internal state of the computation.

#### SparkMD5.ArrayBuffer#destroy()

Releases memory used by the incremental buffer and other additional resources.

#### SparkMD5.ArrayBuffer#getState()

Returns an object representing the internal computation state.
You can pass this state to setState(). This feature is useful to resume an incremental md5.

#### SparkMD5.ArrayBuffer#setState(state)

Sets the internal computation state. See: getState().

#### SparkMD5.ArrayBuffer.hash(arr, raw)

Hashes an array buffer directly, returning the hex result.
If `raw` is true, the result as a binary string will be returned instead.
Note that this function is `static`.


## License

The project is double licensed, being [WTF2](./LICENSE) the master license and [MIT](./LICENSE2) the alternative license.
The reason to have two licenses is that some entities refuse to use the master license (WTF2) due to
bad language. If that's also your case, you can choose the alternative license.


## Credits

[Joseph Myers](http://www.myersdaily.org/joseph/javascript/md5-text.html)
