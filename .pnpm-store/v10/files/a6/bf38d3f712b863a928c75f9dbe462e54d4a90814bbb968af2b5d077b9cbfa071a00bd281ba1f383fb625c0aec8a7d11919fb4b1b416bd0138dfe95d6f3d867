var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
/** Decode an array buffer into an audio buffer */
function decode(audioData, sampleRate) {
    return __awaiter(this, void 0, void 0, function* () {
        const audioCtx = new AudioContext({ sampleRate });
        const decode = audioCtx.decodeAudioData(audioData);
        return decode.finally(() => audioCtx.close());
    });
}
/** Normalize peaks to -1..1 */
function normalize(channelData) {
    const firstChannel = channelData[0];
    if (firstChannel.some((n) => n > 1 || n < -1)) {
        const length = firstChannel.length;
        let max = 0;
        for (let i = 0; i < length; i++) {
            const absN = Math.abs(firstChannel[i]);
            if (absN > max)
                max = absN;
        }
        for (const channel of channelData) {
            for (let i = 0; i < length; i++) {
                channel[i] /= max;
            }
        }
    }
    return channelData;
}
/** Create an audio buffer from pre-decoded audio data */
function createBuffer(channelData, duration) {
    // If a single array of numbers is passed, make it an array of arrays
    if (typeof channelData[0] === 'number')
        channelData = [channelData];
    // Normalize to -1..1
    normalize(channelData);
    return {
        duration,
        length: channelData[0].length,
        sampleRate: channelData[0].length / duration,
        numberOfChannels: channelData.length,
        getChannelData: (i) => channelData === null || channelData === void 0 ? void 0 : channelData[i],
        copyFromChannel: AudioBuffer.prototype.copyFromChannel,
        copyToChannel: AudioBuffer.prototype.copyToChannel,
    };
}
const Decoder = {
    decode,
    createBuffer,
};
export default Decoder;
