import lamejs from 'lamejs';
/**
 * Encodes a mono channel audio stream to MP3 format.
 * @param {number} channels - Number of audio channels.
 * @param {number} sampleRate - Sample rate in Hz.
 * @param {Int16Array} samples - Audio samples to be encoded.
 * @returns {Blob} - The MP3 encoded audio as a Blob.
 */
export const encodeToMP3 = (channels, sampleRate, samples) => {
  const outputBuffer = [];
  const encoder = new lamejs.Mp3Encoder(channels, sampleRate, 128);
  const maxSamplesPerFrame = 1152;

  for (let offset = 0; offset < samples.length; offset += maxSamplesPerFrame) {
    const sliceEnd = Math.min(offset + maxSamplesPerFrame, samples.length);
    const sampleSlice = samples.subarray(offset, sliceEnd);
    const mp3Buffer = encoder.encodeBuffer(sampleSlice);

    if (mp3Buffer.length > 0) {
      outputBuffer.push(new Int8Array(mp3Buffer));
    }
  }

  const remainingData = encoder.flush();
  if (remainingData.length > 0) {
    outputBuffer.push(new Int8Array(remainingData));
  }

  return new Blob(outputBuffer, { type: 'audio/mp3' });
};

/**
 * Converts a WAV audio Blob to an MP3 format Blob.
 * @param {Blob} blob - The audio data in WAV format as a Blob.
 * @returns {Promise<Blob>} - A Blob containing the MP3 encoded audio.
 */
export const convertWavToMp3 = async blob => {
  try {
    const audioBuffer = await blob.arrayBuffer();
    const wavHeader = lamejs.WavHeader.readHeader(new DataView(audioBuffer));
    const samples = new Int16Array(
      audioBuffer,
      wavHeader.dataOffset,
      wavHeader.dataLen / 2
    );

    return encodeToMP3(wavHeader.channels, wavHeader.sampleRate, samples);
  } catch (error) {
    // eslint-disable-next-line
    console.log('Failed to convert WAV to MP3:', error);
    throw new Error('Conversion from WAV to MP3 failed.');
  }
};
