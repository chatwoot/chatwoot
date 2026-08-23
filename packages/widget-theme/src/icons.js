// [chatpaw] Default launcher glyph registry.
// Each entry is inline SVG markup (white glyphs designed to sit on a colored bubble).
// Custom themes may pass any SVG URL / data-URI via `icon` instead.

import pawBlob from '../icons/paw-blob.svg';
import cat from '../icons/cat.svg';
import owl from '../icons/owl.svg';
import fox from '../icons/fox.svg';
import ghost from '../icons/ghost.svg';
import robotBox from '../icons/robot-box.svg';
import heart from '../icons/heart.svg';
import star from '../icons/star.svg';

export const DEFAULT_ICONS = {
  'paw-blob': pawBlob,
  cat,
  owl,
  fox,
  ghost,
  'robot-box': robotBox,
  heart,
  star,
};

export const isDefaultIcon = id => Object.prototype.hasOwnProperty.call(DEFAULT_ICONS, id);

export const resolveIconMarkup = icon => {
  if (isDefaultIcon(icon)) return DEFAULT_ICONS[icon];
  return null;
};
