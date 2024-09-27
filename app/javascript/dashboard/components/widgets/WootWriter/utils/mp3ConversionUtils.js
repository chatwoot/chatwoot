import lamejs from '@breezystack/lamejs';
export const convertWebMToWav = async webmBlob => {
  // Create an AudioContext
  const audioContext = new (window.AudioContext || window.webkitAudioContext)();

  // Read the WebM file
  const arrayBuffer = await webmBlob.arrayBuffer();

  // Decode the audio data
  const audioBuffer = await audioContext.decodeAudioData(arrayBuffer);

  // Create a new AudioBuffer for the WAV format
  const wavBuffer = audioContext.createBuffer(
    audioBuffer.numberOfChannels,
    audioBuffer.length,
    audioBuffer.sampleRate
  );

  // Copy the decoded audio data to the new buffer
  for (let channel = 0; channel < audioBuffer.numberOfChannels; channel += 1) {
    wavBuffer.copyToChannel(audioBuffer.getChannelData(channel), channel);
  }

  // Create a new AudioBufferSourceNode and set its buffer
  const source = audioContext.createBufferSource();
  source.buffer = wavBuffer;

  // Connect the source to a MediaStreamDestination
  const dest = audioContext.createMediaStreamDestination();
  source.connect(dest);

  // Start playing (this is necessary to generate the stream)
  source.start(0);

  // Use MediaRecorder to save the stream as a WAV file
  const mediaRecorder = new MediaRecorder(dest.stream);
  const chunks = [];

  return new Promise(resolve => {
    mediaRecorder.ondataavailable = e => chunks.push(e.data);
    mediaRecorder.onstop = () =>
      resolve(new Blob(chunks, { type: 'audio/wav' }));

    mediaRecorder.start();
    setTimeout(() => mediaRecorder.stop(), wavBuffer.duration * 1000 + 100);
  });
};

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
