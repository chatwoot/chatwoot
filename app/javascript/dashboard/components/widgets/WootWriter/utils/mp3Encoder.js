import lamejs from '@breezystack/lamejs';

const MAX_SAMPLES_PER_FRAME = 1152;

const floatTo16BitPCM = input => {
  const output = new Int16Array(input.length);
  for (let i = 0; i < input.length; i += 1) {
    const sample = Math.max(-1, Math.min(1, input[i]));
    output[i] = sample < 0 ? sample * 0x8000 : sample * 0x7fff;
  }
  return output;
};

/**
 * Encodes PCM channel data to MP3. lamejs only supports mono and stereo, so
 * channels beyond the first two are ignored.
 * @param {Float32Array[]} channelData - One Float32Array per channel.
 * @param {number} sampleRate - Sample rate in Hz.
 * @param {number} bitrate - MP3 bitrate (default: 128)
 * @returns {Int8Array[]} - The MP3 encoded chunks.
 */
export const encodePcmToMp3 = (channelData, sampleRate, bitrate = 128) => {
  const channels = channelData.slice(0, 2).map(floatTo16BitPCM);
  const [left, right] = channels;
  const encoder = new lamejs.Mp3Encoder(channels.length, sampleRate, bitrate);
  const chunks = [];

  for (let offset = 0; offset < left.length; offset += MAX_SAMPLES_PER_FRAME) {
    const end = offset + MAX_SAMPLES_PER_FRAME;
    const mp3Buffer = encoder.encodeBuffer(
      left.subarray(offset, end),
      right?.subarray(offset, end)
    );
    if (mp3Buffer.length > 0) chunks.push(mp3Buffer);
  }

  const remainingData = encoder.flush();
  if (remainingData.length > 0) chunks.push(remainingData);

  return chunks;
};
