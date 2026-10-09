import { encodePcmToMp3 } from './mp3Encoder';
import { remuxWebmToOgg } from './webmOpusToOgg';

const writeString = (view, offset, string) => {
  // eslint-disable-next-line no-plusplus
  for (let i = 0; i < string.length; i++) {
    view.setUint8(offset + i, string.charCodeAt(i));
  }
};

const bufferToWav = async (buffer, numChannels, sampleRate) => {
  const length = buffer.length * numChannels * 2;
  const wav = new ArrayBuffer(44 + length);
  const view = new DataView(wav);

  // WAV Header
  writeString(view, 0, 'RIFF');
  view.setUint32(4, 36 + length, true);
  writeString(view, 8, 'WAVE');
  writeString(view, 12, 'fmt ');
  view.setUint32(16, 16, true);
  view.setUint16(20, 1, true);
  view.setUint16(22, numChannels, true);
  view.setUint32(24, sampleRate, true);
  view.setUint32(28, sampleRate * numChannels * 2, true);
  view.setUint16(32, numChannels * 2, true);
  view.setUint16(34, 16, true);
  writeString(view, 36, 'data');
  view.setUint32(40, length, true);

  // WAV Data
  const offset = 44;
  // eslint-disable-next-line no-plusplus
  for (let i = 0; i < buffer.length; i++) {
    // eslint-disable-next-line no-plusplus
    for (let channel = 0; channel < numChannels; channel++) {
      const sample = Math.max(
        -1,
        Math.min(1, buffer.getChannelData(channel)[i])
      );
      view.setInt16(
        offset + (i * numChannels + channel) * 2,
        sample * 0x7fff,
        true
      );
    }
  }

  return new Blob([wav], { type: 'audio/wav' });
};

const decodeAudioData = async audioBlob => {
  const audioContext = new (window.AudioContext || window.webkitAudioContext)();
  const arrayBuffer = await audioBlob.arrayBuffer();
  const audioData = await audioContext.decodeAudioData(arrayBuffer);
  return audioData;
};

export const convertToWav = async audioBlob => {
  const audioBuffer = await decodeAudioData(audioBlob);
  return bufferToWav(
    audioBuffer,
    audioBuffer.numberOfChannels,
    audioBuffer.sampleRate
  );
};

const encodeInWorker = (channelData, sampleRate, bitrate) =>
  new Promise((resolve, reject) => {
    const worker = new Worker(
      new URL('./mp3Encoder.worker.js', import.meta.url),
      { type: 'module' }
    );
    worker.onmessage = ({ data }) => {
      worker.terminate();
      resolve(data);
    };
    worker.onerror = event => {
      worker.terminate();
      reject(event);
    };
    worker.postMessage({ channelData, sampleRate, bitrate });
  });

// lamejs is synchronous: encoding a long recording on the main thread freezes
// the UI for seconds, so the work runs in a Web Worker whenever possible.
const encodeMp3 = async (channelData, sampleRate, bitrate) => {
  if (typeof Worker === 'undefined') {
    return encodePcmToMp3(channelData, sampleRate, bitrate);
  }

  let result;
  try {
    result = await encodeInWorker(channelData, sampleRate, bitrate);
  } catch (error) {
    // The worker script could not be loaded, encode on the main thread.
    return encodePcmToMp3(channelData, sampleRate, bitrate);
  }

  if (result.error) throw new Error(result.error);
  return result.chunks;
};

/**
 * Converts an audio Blob to an MP3 format Blob.
 * @param {Blob} audioBlob - The audio data as a Blob.
 * @param {number} bitrate - MP3 bitrate (default: 128)
 * @returns {Promise<Blob>} - A Blob containing the MP3 encoded audio.
 */
export const convertToMp3 = async (audioBlob, bitrate = 128) => {
  try {
    const audioBuffer = await decodeAudioData(audioBlob);
    const channelData = Array.from(
      { length: audioBuffer.numberOfChannels },
      (_, channel) => audioBuffer.getChannelData(channel)
    );
    const chunks = await encodeMp3(
      channelData,
      audioBuffer.sampleRate,
      bitrate
    );
    return new Blob(chunks, { type: 'audio/mp3' });
  } catch (error) {
    throw new Error('Conversion to MP3 failed.');
  }
};

export const convertAudio = async (inputBlob, outputFormat, bitrate = 128) => {
  let audio;
  if (outputFormat === 'audio/wav') {
    audio = await convertToWav(inputBlob);
  } else if (outputFormat === 'audio/mp3') {
    audio = await convertToMp3(inputBlob, bitrate);
  } else if (outputFormat === 'audio/ogg') {
    const inputType = inputBlob.type.split(';')[0].trim();
    if (inputType === 'audio/webm' || inputType === 'video/webm') {
      audio = await remuxWebmToOgg(inputBlob);
    } else if (inputType === 'audio/ogg') {
      audio = inputBlob;
    } else {
      // Browsers that record neither WebM nor OGG (e.g. Safari records
      // audio/mp4) cannot produce OGG/Opus. Fall back to MP3 so the recording
      // still sends as a regular audio message instead of failing. The caller
      // keys the voice-note flag off the returned blob type, so an MP3 result
      // is never mislabeled as an OGG/Opus voice note.
      audio = await convertToMp3(inputBlob, bitrate);
    }
  } else {
    throw new Error('Unsupported output format');
  }
  return audio;
};
