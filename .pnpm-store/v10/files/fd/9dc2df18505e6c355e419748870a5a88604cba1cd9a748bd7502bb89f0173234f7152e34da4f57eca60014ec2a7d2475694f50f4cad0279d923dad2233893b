/** Decode an array buffer into an audio buffer */
declare function decode(audioData: ArrayBuffer, sampleRate: number): Promise<AudioBuffer>;
/** Create an audio buffer from pre-decoded audio data */
declare function createBuffer(channelData: Array<Float32Array | number[]>, duration: number): AudioBuffer;
declare const Decoder: {
    decode: typeof decode;
    createBuffer: typeof createBuffer;
};
export default Decoder;
