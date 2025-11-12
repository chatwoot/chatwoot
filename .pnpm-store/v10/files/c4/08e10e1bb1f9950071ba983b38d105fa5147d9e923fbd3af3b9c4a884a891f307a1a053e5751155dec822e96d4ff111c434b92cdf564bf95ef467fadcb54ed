function isGzipSupported() {
    return 'CompressionStream' in globalThis;
}
async function gzipCompress(input) {
    let isDebug = arguments.length > 1 && void 0 !== arguments[1] ? arguments[1] : true;
    try {
        const dataStream = new Blob([
            input
        ], {
            type: 'text/plain'
        }).stream();
        const compressedStream = dataStream.pipeThrough(new CompressionStream('gzip'));
        return await new Response(compressedStream).blob();
    } catch (error) {
        if (isDebug) console.error('Failed to gzip compress data', error);
        return null;
    }
}
export { gzipCompress, isGzipSupported };
