import emojione from 'emojione';
/* eslint-disable */
export default function (value, method = 'shortnameToImage') {
  return emojione[method](value);
}

export function getEmojiUnicode(value) {
  return emojione.shortnameToUnicode(value);
}
