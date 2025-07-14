import {isVideoCodec, isAudioCodec} from '../src/codecs.js';

const codecAliasMap = {
  mp3: ['mp3', 'mp4a.40.34', 'mp4a.6b'],
  aac: ['aac', 'mp4a.40.2', 'mp4a.40.5', 'mp4a.40.29']
};

Object.keys(codecAliasMap).forEach((alias) => {
  // map aliases as keys so that everything is linked to each other
  codecAliasMap[alias].forEach((subalias) => {
    codecAliasMap[subalias] = codecAliasMap[alias];
  });
});

export const doesCodecMatch = function(a, b) {
  if (!a) {
    return false;
  }
  if (codecAliasMap[b]) {
    return codecAliasMap[a].indexOf(b) !== -1;
  }

  return a === b;
};

export const codecsFromFile = function(file) {
  const codecs = {};
  const extension = file.split('.').pop();
  const codecStr = file.replace(`.${extension}`, '');

  codecStr.split(',').forEach((codec) => {
    if (isVideoCodec(codec)) {
      codecs.video = codec;
    } else if (isAudioCodec(codec)) {
      codecs.audio = codec;
    } else {
      throw new Error(`${codec} is not detected as audio or video`);
    }
  });

  return codecs;
};
