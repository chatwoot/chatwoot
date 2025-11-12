/**
 * Options for compressing data into a DEFLATE format
 */
export interface DeflateOptions {
    /**
     * The level of compression to use, ranging from 0-9.
     *
     * 0 will store the data without compression.
     * 1 is fastest but compresses the worst, 9 is slowest but compresses the best.
     * The default level is 6.
     *
     * Typically, binary data benefits much more from higher values than text data.
     * In both cases, higher values usually take disproportionately longer than the reduction in final size that results.
     *
     * For example, a 1 MB text file could:
     * - become 1.01 MB with level 0 in 1ms
     * - become 400 kB with level 1 in 10ms
     * - become 320 kB with level 9 in 100ms
     */
    level?: 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9;
    /**
     * The memory level to use, ranging from 0-12. Increasing this increases speed and compression ratio at the cost of memory.
     *
     * Note that this is exponential: while level 0 uses 4 kB, level 4 uses 64 kB, level 8 uses 1 MB, and level 12 uses 16 MB.
     * It is recommended not to lower the value below 4, since that tends to hurt performance.
     * In addition, values above 8 tend to help very little on most data and can even hurt performance.
     *
     * The default value is automatically determined based on the size of the input data.
     */
    mem?: 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12;
}
/**
 * Options for compressing data into a GZIP format
 */
export interface GzipOptions extends DeflateOptions {
    /**
     * When the file was last modified. Defaults to the current time.
     * If you're using GZIP, set this to 0 to avoid revealing a modification date entirely.
     */
    mtime?: Date | string | number;
    /**
     * The filename of the data. If the `gunzip` command is used to decompress the data, it will output a file
     * with this name instead of the name of the compressed file.
     */
    filename?: string;
}
/**
 * Options for compressing data into a Zlib format
 */
export interface ZlibOptions extends DeflateOptions {
}
/**
 * Handler for data (de)compression streams
 * @param data The data output from the stream processor
 * @param final Whether this is the final block
 */
export declare type FlateStreamHandler = (data: Uint8Array, final: boolean) => void;
/**
 * Handler for asynchronous data (de)compression streams
 * @param err Any error that occurred
 * @param data The data output from the stream processor
 * @param final Whether this is the final block
 */
export declare type AsyncFlateStreamHandler = (err: Error, data: Uint8Array, final: boolean) => void;
/**
 * Callback for asynchronous (de)compression methods
 * @param err Any error that occurred
 * @param data The resulting data. Only present if `err` is null
 */
export declare type FlateCallback = (err: Error | string, data: Uint8Array) => void;
interface AsyncOptions {
    /**
     * Whether or not to "consume" the source data. This will make the typed array/buffer you pass in
     * unusable but will increase performance and reduce memory usage.
     */
    consume?: boolean;
}
/**
 * Options for compressing data asynchronously into a DEFLATE format
 */
export interface AsyncDeflateOptions extends DeflateOptions, AsyncOptions {
}
/**
 * Options for decompressing DEFLATE data asynchronously
 */
export interface AsyncInflateOptions extends AsyncOptions {
    /**
     * The original size of the data. Currently, the asynchronous API disallows
     * writing into a buffer you provide; the best you can do is provide the
     * size in bytes and be given back a new typed array.
     */
    size?: number;
}
/**
 * Options for compressing data asynchronously into a GZIP format
 */
export interface AsyncGzipOptions extends GzipOptions, AsyncOptions {
}
/**
 * Options for decompressing GZIP data asynchronously
 */
export interface AsyncGunzipOptions extends AsyncOptions {
}
/**
 * Options for compressing data asynchronously into a Zlib format
 */
export interface AsyncZlibOptions extends ZlibOptions, AsyncOptions {
}
/**
 * Options for decompressing Zlib data asynchronously
 */
export interface AsyncUnzlibOptions extends AsyncInflateOptions {
}
/**
 * A terminable compression/decompression process
 */
export interface AsyncTerminable {
    /**
     * Terminates the worker thread immediately. The callback will not be called.
     */
    (): void;
}
/**
 * Streaming DEFLATE compression
 */
export declare class Deflate {
    /**
     * Creates a DEFLATE stream
     * @param opts The compression options
     * @param cb The callback to call whenever data is deflated
     */
    constructor(opts: DeflateOptions, cb?: FlateStreamHandler);
    constructor(cb?: FlateStreamHandler);
    private o;
    private d;
    /**
     * The handler to call whenever data is available
     */
    ondata: FlateStreamHandler;
    private p;
    /**
     * Pushes a chunk to be deflated
     * @param chunk The chunk to push
     * @param final Whether this is the last chunk
     */
    push(chunk: Uint8Array, final?: boolean): void;
}
/**
 * Asynchronous streaming DEFLATE compression
 */
export declare class AsyncDeflate {
    /**
     * The handler to call whenever data is available
     */
    ondata: AsyncFlateStreamHandler;
    /**
     * Creates an asynchronous DEFLATE stream
     * @param opts The compression options
     * @param cb The callback to call whenever data is deflated
     */
    constructor(opts: DeflateOptions, cb?: AsyncFlateStreamHandler);
    /**
     * Creates an asynchronous DEFLATE stream
     * @param cb The callback to call whenever data is deflated
     */
    constructor(cb?: AsyncFlateStreamHandler);
    /**
     * Pushes a chunk to be deflated
     * @param chunk The chunk to push
     * @param final Whether this is the last chunk
     */
    push(chunk: Uint8Array, final?: boolean): void;
    /**
     * A method to terminate the stream's internal worker. Subsequent calls to
     * push() will silently fail.
     */
    terminate: AsyncTerminable;
}
/**
 * Asynchronously compresses data with DEFLATE without any wrapper
 * @param data The data to compress
 * @param opts The compression options
 * @param cb The function to be called upon compression completion
 * @returns A function that can be used to immediately terminate the compression
 */
export declare function deflate(data: Uint8Array, opts: AsyncDeflateOptions, cb: FlateCallback): AsyncTerminable;
/**
 * Asynchronously compresses data with DEFLATE without any wrapper
 * @param data The data to compress
 * @param cb The function to be called upon compression completion
 */
export declare function deflate(data: Uint8Array, cb: FlateCallback): AsyncTerminable;
/**
 * Compresses data with DEFLATE without any wrapper
 * @param data The data to compress
 * @param opts The compression options
 * @returns The deflated version of the data
 */
export declare function deflateSync(data: Uint8Array, opts?: DeflateOptions): Uint8Array;
/**
 * Streaming DEFLATE decompression
 */
export declare class Inflate {
    /**
     * Creates an inflation stream
     * @param cb The callback to call whenever data is inflated
     */
    constructor(cb?: FlateStreamHandler);
    private s;
    private o;
    private p;
    private d;
    /**
     * The handler to call whenever data is available
     */
    ondata: FlateStreamHandler;
    private e;
    private c;
    /**
     * Pushes a chunk to be inflated
     * @param chunk The chunk to push
     * @param final Whether this is the final chunk
     */
    push(chunk: Uint8Array, final?: boolean): void;
}
/**
 * Asynchronous streaming DEFLATE decompression
 */
export declare class AsyncInflate {
    /**
     * The handler to call whenever data is available
     */
    ondata: AsyncFlateStreamHandler;
    /**
     * Creates an asynchronous inflation stream
     * @param cb The callback to call whenever data is deflated
     */
    constructor(cb?: AsyncFlateStreamHandler);
    /**
     * Pushes a chunk to be inflated
     * @param chunk The chunk to push
     * @param final Whether this is the last chunk
     */
    push(chunk: Uint8Array, final?: boolean): void;
    /**
     * A method to terminate the stream's internal worker. Subsequent calls to
     * push() will silently fail.
     */
    terminate: AsyncTerminable;
}
/**
 * Asynchronously expands DEFLATE data with no wrapper
 * @param data The data to decompress
 * @param opts The decompression options
 * @param cb The function to be called upon decompression completion
 * @returns A function that can be used to immediately terminate the decompression
 */
export declare function inflate(data: Uint8Array, opts: AsyncInflateOptions, cb: FlateCallback): AsyncTerminable;
/**
 * Asynchronously expands DEFLATE data with no wrapper
 * @param data The data to decompress
 * @param cb The function to be called upon decompression completion
 * @returns A function that can be used to immediately terminate the decompression
 */
export declare function inflate(data: Uint8Array, cb: FlateCallback): AsyncTerminable;
/**
 * Expands DEFLATE data with no wrapper
 * @param data The data to decompress
 * @param out Where to write the data. Saves memory if you know the decompressed size and provide an output buffer of that length.
 * @returns The decompressed version of the data
 */
export declare function inflateSync(data: Uint8Array, out?: Uint8Array): Uint8Array;
/**
 * Streaming GZIP compression
 */
export declare class Gzip {
    private c;
    private l;
    private v;
    private o;
    /**
     * The handler to call whenever data is available
     */
    ondata: FlateStreamHandler;
    /**
     * Creates a GZIP stream
     * @param opts The compression options
     * @param cb The callback to call whenever data is deflated
     */
    constructor(opts: GzipOptions, cb?: FlateStreamHandler);
    /**
     * Creates a GZIP stream
     * @param cb The callback to call whenever data is deflated
     */
    constructor(cb?: FlateStreamHandler);
    /**
     * Pushes a chunk to be GZIPped
     * @param chunk The chunk to push
     * @param final Whether this is the last chunk
     */
    push(chunk: Uint8Array, final?: boolean): void;
    private p;
}
/**
 * Asynchronous streaming GZIP compression
 */
export declare class AsyncGzip {
    /**
     * The handler to call whenever data is available
     */
    ondata: AsyncFlateStreamHandler;
    /**
     * Creates an asynchronous GZIP stream
     * @param opts The compression options
     * @param cb The callback to call whenever data is deflated
     */
    constructor(opts: GzipOptions, cb?: AsyncFlateStreamHandler);
    /**
     * Creates an asynchronous GZIP stream
     * @param cb The callback to call whenever data is deflated
     */
    constructor(cb?: AsyncFlateStreamHandler);
    /**
     * Pushes a chunk to be GZIPped
     * @param chunk The chunk to push
     * @param final Whether this is the last chunk
     */
    push(chunk: Uint8Array, final?: boolean): void;
    /**
     * A method to terminate the stream's internal worker. Subsequent calls to
     * push() will silently fail.
     */
    terminate: AsyncTerminable;
}
/**
 * Asynchronously compresses data with GZIP
 * @param data The data to compress
 * @param opts The compression options
 * @param cb The function to be called upon compression completion
 * @returns A function that can be used to immediately terminate the compression
 */
export declare function gzip(data: Uint8Array, opts: AsyncGzipOptions, cb: FlateCallback): AsyncTerminable;
/**
 * Asynchronously compresses data with GZIP
 * @param data The data to compress
 * @param cb The function to be called upon compression completion
 * @returns A function that can be used to immediately terminate the decompression
 */
export declare function gzip(data: Uint8Array, cb: FlateCallback): AsyncTerminable;
/**
 * Compresses data with GZIP
 * @param data The data to compress
 * @param opts The compression options
 * @returns The gzipped version of the data
 */
export declare function gzipSync(data: Uint8Array, opts?: GzipOptions): Uint8Array;
/**
 * Streaming GZIP decompression
 */
export declare class Gunzip {
    private v;
    private p;
    /**
     * The handler to call whenever data is available
     */
    ondata: FlateStreamHandler;
    /**
     * Creates a GUNZIP stream
     * @param cb The callback to call whenever data is inflated
     */
    constructor(cb?: FlateStreamHandler);
    /**
     * Pushes a chunk to be GUNZIPped
     * @param chunk The chunk to push
     * @param final Whether this is the last chunk
     */
    push(chunk: Uint8Array, final?: boolean): void;
}
/**
 * Asynchronous streaming GZIP decompression
 */
export declare class AsyncGunzip {
    /**
     * The handler to call whenever data is available
     */
    ondata: AsyncFlateStreamHandler;
    /**
     * Creates an asynchronous GUNZIP stream
     * @param cb The callback to call whenever data is deflated
     */
    constructor(cb: AsyncFlateStreamHandler);
    /**
     * Pushes a chunk to be GUNZIPped
     * @param chunk The chunk to push
     * @param final Whether this is the last chunk
     */
    push(chunk: Uint8Array, final?: boolean): void;
    /**
     * A method to terminate the stream's internal worker. Subsequent calls to
     * push() will silently fail.
     */
    terminate: AsyncTerminable;
}
/**
 * Asynchronously expands GZIP data
 * @param data The data to decompress
 * @param opts The decompression options
 * @param cb The function to be called upon decompression completion
 * @returns A function that can be used to immediately terminate the decompression
 */
export declare function gunzip(data: Uint8Array, opts: AsyncGunzipOptions, cb: FlateCallback): AsyncTerminable;
/**
 * Asynchronously expands GZIP data
 * @param data The data to decompress
 * @param cb The function to be called upon decompression completion
 * @returns A function that can be used to immediately terminate the decompression
 */
export declare function gunzip(data: Uint8Array, cb: FlateCallback): AsyncTerminable;
/**
 * Expands GZIP data
 * @param data The data to decompress
 * @param out Where to write the data. GZIP already encodes the output size, so providing this doesn't save memory.
 * @returns The decompressed version of the data
 */
export declare function gunzipSync(data: Uint8Array, out?: Uint8Array): Uint8Array;
/**
 * Streaming Zlib compression
 */
export declare class Zlib {
    private c;
    private v;
    private o;
    /**
     * The handler to call whenever data is available
     */
    ondata: FlateStreamHandler;
    /**
     * Creates a Zlib stream
     * @param opts The compression options
     * @param cb The callback to call whenever data is deflated
     */
    constructor(opts: ZlibOptions, cb?: FlateStreamHandler);
    /**
     * Creates a Zlib stream
     * @param cb The callback to call whenever data is deflated
     */
    constructor(cb?: FlateStreamHandler);
    /**
     * Pushes a chunk to be zlibbed
     * @param chunk The chunk to push
     * @param final Whether this is the last chunk
     */
    push(chunk: Uint8Array, final?: boolean): void;
    private p;
}
/**
 * Asynchronous streaming Zlib compression
 */
export declare class AsyncZlib {
    /**
     * The handler to call whenever data is available
     */
    ondata: AsyncFlateStreamHandler;
    /**
     * Creates an asynchronous DEFLATE stream
     * @param opts The compression options
     * @param cb The callback to call whenever data is deflated
     */
    constructor(opts: ZlibOptions, cb?: AsyncFlateStreamHandler);
    /**
     * Creates an asynchronous DEFLATE stream
     * @param cb The callback to call whenever data is deflated
     */
    constructor(cb?: AsyncFlateStreamHandler);
    /**
     * Pushes a chunk to be deflated
     * @param chunk The chunk to push
     * @param final Whether this is the last chunk
     */
    push(chunk: Uint8Array, final?: boolean): void;
    /**
     * A method to terminate the stream's internal worker. Subsequent calls to
     * push() will silently fail.
     */
    terminate: AsyncTerminable;
}
/**
 * Asynchronously compresses data with Zlib
 * @param data The data to compress
 * @param opts The compression options
 * @param cb The function to be called upon compression completion
 */
export declare function zlib(data: Uint8Array, opts: AsyncZlibOptions, cb: FlateCallback): AsyncTerminable;
/**
 * Asynchronously compresses data with Zlib
 * @param data The data to compress
 * @param cb The function to be called upon compression completion
 * @returns A function that can be used to immediately terminate the compression
 */
export declare function zlib(data: Uint8Array, cb: FlateCallback): AsyncTerminable;
/**
 * Compress data with Zlib
 * @param data The data to compress
 * @param opts The compression options
 * @returns The zlib-compressed version of the data
 */
export declare function zlibSync(data: Uint8Array, opts?: ZlibOptions): Uint8Array;
/**
 * Streaming Zlib decompression
 */
export declare class Unzlib {
    private v;
    private p;
    /**
     * The handler to call whenever data is available
     */
    ondata: FlateStreamHandler;
    /**
     * Creates a Zlib decompression stream
     * @param cb The callback to call whenever data is inflated
     */
    constructor(cb?: FlateStreamHandler);
    /**
     * Pushes a chunk to be unzlibbed
     * @param chunk The chunk to push
     * @param final Whether this is the last chunk
     */
    push(chunk: Uint8Array, final?: boolean): void;
}
/**
 * Asynchronous streaming Zlib decompression
 */
export declare class AsyncUnzlib {
    /**
     * The handler to call whenever data is available
     */
    ondata: AsyncFlateStreamHandler;
    /**
     * Creates an asynchronous Zlib decompression stream
     * @param cb The callback to call whenever data is deflated
     */
    constructor(cb?: AsyncFlateStreamHandler);
    /**
     * Pushes a chunk to be decompressed from Zlib
     * @param chunk The chunk to push
     * @param final Whether this is the last chunk
     */
    push(chunk: Uint8Array, final?: boolean): void;
    /**
     * A method to terminate the stream's internal worker. Subsequent calls to
     * push() will silently fail.
     */
    terminate: AsyncTerminable;
}
/**
 * Asynchronously expands Zlib data
 * @param data The data to decompress
 * @param opts The decompression options
 * @param cb The function to be called upon decompression completion
 * @returns A function that can be used to immediately terminate the decompression
 */
export declare function unzlib(data: Uint8Array, opts: AsyncGunzipOptions, cb: FlateCallback): AsyncTerminable;
/**
 * Asynchronously expands Zlib data
 * @param data The data to decompress
 * @param cb The function to be called upon decompression completion
 * @returns A function that can be used to immediately terminate the decompression
 */
export declare function unzlib(data: Uint8Array, cb: FlateCallback): AsyncTerminable;
/**
 * Expands Zlib data
 * @param data The data to decompress
 * @param out Where to write the data. Saves memory if you know the decompressed size and provide an output buffer of that length.
 * @returns The decompressed version of the data
 */
export declare function unzlibSync(data: Uint8Array, out?: Uint8Array): Uint8Array;
export { gzip as compress, AsyncGzip as AsyncCompress };
export { gzipSync as compressSync, Gzip as Compress };
/**
 * Streaming GZIP, Zlib, or raw DEFLATE decompression
 */
export declare class Decompress {
    private G;
    private I;
    private Z;
    /**
     * Creates a decompression stream
     * @param cb The callback to call whenever data is decompressed
     */
    constructor(cb?: FlateStreamHandler);
    private s;
    /**
     * The handler to call whenever data is available
     */
    ondata: FlateStreamHandler;
    private p;
    /**
     * Pushes a chunk to be decompressed
     * @param chunk The chunk to push
     * @param final Whether this is the last chunk
     */
    push(chunk: Uint8Array, final?: boolean): void;
}
/**
 * Asynchronous streaming GZIP, Zlib, or raw DEFLATE decompression
 */
export declare class AsyncDecompress {
    private G;
    private I;
    private Z;
    /**
   * Creates an asynchronous decompression stream
   * @param cb The callback to call whenever data is decompressed
   */
    constructor(cb?: AsyncFlateStreamHandler);
    /**
     * The handler to call whenever data is available
     */
    ondata: AsyncFlateStreamHandler;
    /**
     * Pushes a chunk to be decompressed
     * @param chunk The chunk to push
     * @param final Whether this is the last chunk
     */
    push(chunk: Uint8Array, final?: boolean): void;
}
/**
 * Asynchrononously expands compressed GZIP, Zlib, or raw DEFLATE data, automatically detecting the format
 * @param data The data to decompress
 * @param opts The decompression options
 * @param cb The function to be called upon decompression completion
 * @returns A function that can be used to immediately terminate the decompression
 */
export declare function decompress(data: Uint8Array, opts: AsyncInflateOptions, cb: FlateCallback): AsyncTerminable;
/**
 * Asynchrononously expands compressed GZIP, Zlib, or raw DEFLATE data, automatically detecting the format
 * @param data The data to decompress
 * @param cb The function to be called upon decompression completion
 * @returns A function that can be used to immediately terminate the decompression
 */
export declare function decompress(data: Uint8Array, cb: FlateCallback): AsyncTerminable;
/**
 * Expands compressed GZIP, Zlib, or raw DEFLATE data, automatically detecting the format
 * @param data The data to decompress
 * @param out Where to write the data. Saves memory if you know the decompressed size and provide an output buffer of that length.
 * @returns The decompressed version of the data
 */
export declare function decompressSync(data: Uint8Array, out?: Uint8Array): Uint8Array;
/**
 * Options for creating a ZIP archive
 */
export interface ZipOptions extends DeflateOptions, Pick<GzipOptions, 'mtime'> {
}
/**
 * Options for asynchronously creating a ZIP archive
 */
export interface AsyncZipOptions extends AsyncDeflateOptions, Pick<AsyncGzipOptions, 'mtime'> {
}
/**
 * Options for asynchronously expanding a ZIP archive
 */
export interface AsyncUnzipOptions extends AsyncOptions {
}
/**
 * A file that can be used to create a ZIP archive
 */
export declare type ZippableFile = Uint8Array | [Uint8Array, ZipOptions];
/**
 * A file that can be used to asynchronously create a ZIP archive
 */
export declare type AsyncZippableFile = Uint8Array | [Uint8Array, AsyncZipOptions];
/**
 * The complete directory structure of a ZIPpable archive
 */
export interface Zippable extends Record<string, Zippable | ZippableFile> {
}
/**
 * The complete directory structure of an asynchronously ZIPpable archive
 */
export interface AsyncZippable extends Record<string, AsyncZippable | AsyncZippableFile> {
}
/**
 * An unzipped archive. The full path of each file is used as the key,
 * and the file is the value
 */
export interface Unzipped extends Record<string, Uint8Array> {
}
/**
 * Callback for asynchronous ZIP decompression
 * @param err Any error that occurred
 * @param data The decompressed ZIP archive
 */
export declare type UnzipCallback = (err: Error | string, data: Unzipped) => void;
/**
 * Converts a string into a Uint8Array for use with compression/decompression methods
 * @param str The string to encode
 * @param latin1 Whether or not to interpret the data as Latin-1. This should
 *               not need to be true unless decoding a binary string.
 * @returns The string encoded in UTF-8/Latin-1 binary
 */
export declare function strToU8(str: string, latin1?: boolean): Uint8Array;
/**
 * Converts a Uint8Array to a string
 * @param dat The data to decode to string
 * @param latin1 Whether or not to interpret the data as Latin-1. This should
 *               not need to be true unless encoding to binary string.
 * @returns The original UTF-8/Latin-1 string
 */
export declare function strFromU8(dat: Uint8Array, latin1?: boolean): string;
/**
 * Asynchronously creates a ZIP file
 * @param data The directory structure for the ZIP archive
 * @param opts The main options, merged with per-file options
 * @param cb The callback to call with the generated ZIP archive
 * @returns A function that can be used to immediately terminate the compression
 */
export declare function zip(data: AsyncZippable, opts: AsyncZipOptions, cb: FlateCallback): AsyncTerminable;
/**
 * Asynchronously creates a ZIP file
 * @param data The directory structure for the ZIP archive
 * @param cb The callback to call with the generated ZIP archive
 * @returns A function that can be used to immediately terminate the compression
 */
export declare function zip(data: AsyncZippable, cb: FlateCallback): AsyncTerminable;
/**
 * Synchronously creates a ZIP file. Prefer using `zip` for better performance
 * with more than one file.
 * @param data The directory structure for the ZIP archive
 * @param opts The main options, merged with per-file options
 * @returns The generated ZIP archive
 */
export declare function zipSync(data: Zippable, opts?: ZipOptions): Uint8Array;
/**
 * Asynchronously decompresses a ZIP archive
 * @param data The raw compressed ZIP file
 * @param cb The callback to call with the decompressed files
 * @returns A function that can be used to immediately terminate the unzipping
 */
export declare function unzip(data: Uint8Array, cb: UnzipCallback): AsyncTerminable;
/**
 * Synchronously decompresses a ZIP archive. Prefer using `unzip` for better
 * performance with more than one file.
 * @param data The raw compressed ZIP file
 * @returns The decompressed files
 */
export declare function unzipSync(data: Uint8Array): Unzipped;
