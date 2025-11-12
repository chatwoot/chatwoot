import {DOMParser} from '@xmldom/xmldom';
import errors from './errors';

export const stringToMpdXml = (manifestString) => {
  if (manifestString === '') {
    throw new Error(errors.DASH_EMPTY_MANIFEST);
  }

  const parser = new DOMParser();
  let xml;
  let mpd;

  try {
    xml = parser.parseFromString(manifestString, 'application/xml');
    mpd = xml && xml.documentElement.tagName === 'MPD' ?
      xml.documentElement : null;
  } catch (e) {
    // ie 11 throwsw on invalid xml
  }

  if (!mpd || mpd &&
      mpd.getElementsByTagName('parsererror').length > 0) {
    throw new Error(errors.DASH_INVALID_XML);
  }

  return mpd;
};
