import { encodePcmToMp3 } from './mp3Encoder';

globalThis.onmessage = ({ data }) => {
  const { channelData, sampleRate, bitrate } = data;
  try {
    const chunks = encodePcmToMp3(channelData, sampleRate, bitrate);
    globalThis.postMessage(
      { chunks },
      chunks.map(chunk => chunk.buffer)
    );
  } catch (error) {
    globalThis.postMessage({ error: error.message });
  }
};
