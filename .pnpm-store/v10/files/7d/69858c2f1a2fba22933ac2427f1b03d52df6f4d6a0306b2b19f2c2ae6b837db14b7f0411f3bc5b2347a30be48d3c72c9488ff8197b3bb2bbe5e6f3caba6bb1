import { values } from './utils/object';
import { findIndex, findIndexes } from './utils/list';
import { addSidxSegmentsToPlaylist as addSidxSegmentsToPlaylist_ } from './segment/segmentBase';
import { byteRangeToString } from './segment/urlType';
import {
  getUniqueTimelineStarts,
  positionManifestOnTimeline
} from './playlist-merge';

export const generateSidxKey = (sidx) => sidx &&
  sidx.uri + '-' + byteRangeToString(sidx.byterange);

const mergeDiscontiguousPlaylists = playlists => {
  const mergedPlaylists = values(playlists.reduce((acc, playlist) => {
    // assuming playlist IDs are the same across periods
    // TODO: handle multiperiod where representation sets are not the same
    // across periods
    const name = playlist.attributes.id + (playlist.attributes.lang || '');

    if (!acc[name]) {
      // First Period
      acc[name] = playlist;
      acc[name].attributes.timelineStarts = [];
    } else {
      // Subsequent Periods
      if (playlist.segments) {
        // first segment of subsequent periods signal a discontinuity
        if (playlist.segments[0]) {
          playlist.segments[0].discontinuity = true;
        }
        acc[name].segments.push(...playlist.segments);
      }

      // bubble up contentProtection, this assumes all DRM content
      // has the same contentProtection
      if (playlist.attributes.contentProtection) {
        acc[name].attributes.contentProtection =
          playlist.attributes.contentProtection;
      }
    }

    acc[name].attributes.timelineStarts.push({
      // Although they represent the same number, it's important to have both to make it
      // compatible with HLS potentially having a similar attribute.
      start: playlist.attributes.periodStart,
      timeline: playlist.attributes.periodStart
    });

    return acc;
  }, {}));

  return mergedPlaylists.map(playlist => {
    playlist.discontinuityStarts =
        findIndexes(playlist.segments || [], 'discontinuity');

    return playlist;
  });
};

export const addSidxSegmentsToPlaylist = (playlist, sidxMapping) => {
  const sidxKey = generateSidxKey(playlist.sidx);
  const sidxMatch = sidxKey && sidxMapping[sidxKey] && sidxMapping[sidxKey].sidx;

  if (sidxMatch) {
    addSidxSegmentsToPlaylist_(playlist, sidxMatch, playlist.sidx.resolvedUri);
  }

  return playlist;
};

export const addSidxSegmentsToPlaylists = (playlists, sidxMapping = {}) => {
  if (!Object.keys(sidxMapping).length) {
    return playlists;
  }

  for (const i in playlists) {
    playlists[i] = addSidxSegmentsToPlaylist(playlists[i], sidxMapping);
  }

  return playlists;
};

export const formatAudioPlaylist = ({
  attributes,
  segments,
  sidx,
  mediaSequence,
  discontinuitySequence,
  discontinuityStarts
}, isAudioOnly) => {
  const playlist = {
    attributes: {
      NAME: attributes.id,
      BANDWIDTH: attributes.bandwidth,
      CODECS: attributes.codecs,
      ['PROGRAM-ID']: 1
    },
    uri: '',
    endList: attributes.type === 'static',
    timeline: attributes.periodStart,
    resolvedUri: '',
    targetDuration: attributes.duration,
    discontinuitySequence,
    discontinuityStarts,
    timelineStarts: attributes.timelineStarts,
    mediaSequence,
    segments
  };

  if (attributes.contentProtection) {
    playlist.contentProtection = attributes.contentProtection;
  }

  if (sidx) {
    playlist.sidx = sidx;
  }

  if (isAudioOnly) {
    playlist.attributes.AUDIO = 'audio';
    playlist.attributes.SUBTITLES = 'subs';
  }

  return playlist;
};

export const formatVttPlaylist = ({
  attributes,
  segments,
  mediaSequence,
  discontinuityStarts,
  discontinuitySequence
}) => {
  if (typeof segments === 'undefined') {
    // vtt tracks may use single file in BaseURL
    segments = [{
      uri: attributes.baseUrl,
      timeline: attributes.periodStart,
      resolvedUri: attributes.baseUrl || '',
      duration: attributes.sourceDuration,
      number: 0
    }];
    // targetDuration should be the same duration as the only segment
    attributes.duration = attributes.sourceDuration;
  }

  const m3u8Attributes = {
    NAME: attributes.id,
    BANDWIDTH: attributes.bandwidth,
    ['PROGRAM-ID']: 1
  };

  if (attributes.codecs) {
    m3u8Attributes.CODECS = attributes.codecs;
  }
  return {
    attributes: m3u8Attributes,
    uri: '',
    endList: attributes.type === 'static',
    timeline: attributes.periodStart,
    resolvedUri: attributes.baseUrl || '',
    targetDuration: attributes.duration,
    timelineStarts: attributes.timelineStarts,
    discontinuityStarts,
    discontinuitySequence,
    mediaSequence,
    segments
  };
};

export const organizeAudioPlaylists = (playlists, sidxMapping = {}, isAudioOnly = false) => {
  let mainPlaylist;

  const formattedPlaylists = playlists.reduce((a, playlist) => {
    const role = playlist.attributes.role &&
      playlist.attributes.role.value || '';
    const language = playlist.attributes.lang || '';

    let label = playlist.attributes.label || 'main';

    if (language && !playlist.attributes.label) {
      const roleLabel = role ? ` (${role})` : '';

      label = `${playlist.attributes.lang}${roleLabel}`;
    }

    if (!a[label]) {
      a[label] = {
        language,
        autoselect: true,
        default: role === 'main',
        playlists: [],
        uri: ''
      };
    }

    const formatted = addSidxSegmentsToPlaylist(formatAudioPlaylist(playlist, isAudioOnly), sidxMapping);

    a[label].playlists.push(formatted);

    if (typeof mainPlaylist === 'undefined' && role === 'main') {
      mainPlaylist = playlist;
      mainPlaylist.default = true;
    }

    return a;
  }, {});

  // if no playlists have role "main", mark the first as main
  if (!mainPlaylist) {
    const firstLabel = Object.keys(formattedPlaylists)[0];

    formattedPlaylists[firstLabel].default = true;
  }

  return formattedPlaylists;
};

export const organizeVttPlaylists = (playlists, sidxMapping = {}) => {
  return playlists.reduce((a, playlist) => {
    const label = playlist.attributes.lang || 'text';

    if (!a[label]) {
      a[label] = {
        language: label,
        default: false,
        autoselect: false,
        playlists: [],
        uri: ''
      };
    }
    a[label].playlists.push(addSidxSegmentsToPlaylist(formatVttPlaylist(playlist), sidxMapping));

    return a;
  }, {});
};

const organizeCaptionServices = (captionServices) => captionServices.reduce((svcObj, svc) => {
  if (!svc) {
    return svcObj;
  }

  svc.forEach((service) => {
    const {
      channel,
      language
    } = service;

    svcObj[language] = {
      autoselect: false,
      default: false,
      instreamId: channel,
      language
    };

    if (service.hasOwnProperty('aspectRatio')) {
      svcObj[language].aspectRatio = service.aspectRatio;
    }
    if (service.hasOwnProperty('easyReader')) {
      svcObj[language].easyReader = service.easyReader;
    }
    if (service.hasOwnProperty('3D')) {
      svcObj[language]['3D'] = service['3D'];
    }

  });

  return svcObj;
}, {});

export const formatVideoPlaylist = ({
  attributes,
  segments,
  sidx,
  discontinuityStarts
}) => {
  const playlist = {
    attributes: {
      NAME: attributes.id,
      AUDIO: 'audio',
      SUBTITLES: 'subs',
      RESOLUTION: {
        width: attributes.width,
        height: attributes.height
      },
      CODECS: attributes.codecs,
      BANDWIDTH: attributes.bandwidth,
      ['PROGRAM-ID']: 1
    },
    uri: '',
    endList: attributes.type === 'static',
    timeline: attributes.periodStart,
    resolvedUri: '',
    targetDuration: attributes.duration,
    discontinuityStarts,
    timelineStarts: attributes.timelineStarts,
    segments
  };

  if (attributes.contentProtection) {
    playlist.contentProtection = attributes.contentProtection;
  }

  if (sidx) {
    playlist.sidx = sidx;
  }

  return playlist;
};

const videoOnly = ({ attributes }) =>
  attributes.mimeType === 'video/mp4' || attributes.mimeType === 'video/webm' || attributes.contentType === 'video';
const audioOnly = ({ attributes }) =>
  attributes.mimeType === 'audio/mp4' || attributes.mimeType === 'audio/webm' || attributes.contentType === 'audio';
const vttOnly = ({ attributes }) =>
  attributes.mimeType === 'text/vtt' || attributes.contentType === 'text';

/**
 * Contains start and timeline properties denoting a timeline start. For DASH, these will
 * be the same number.
 *
 * @typedef {Object} TimelineStart
 * @property {number} start - the start time of the timeline
 * @property {number} timeline - the timeline number
 */

/**
 * Adds appropriate media and discontinuity sequence values to the segments and playlists.
 *
 * Throughout mpd-parser, the `number` attribute is used in relation to `startNumber`, a
 * DASH specific attribute used in constructing segment URI's from templates. However, from
 * an HLS perspective, the `number` attribute on a segment would be its `mediaSequence`
 * value, which should start at the original media sequence value (or 0) and increment by 1
 * for each segment thereafter. Since DASH's `startNumber` values are independent per
 * period, it doesn't make sense to use it for `number`. Instead, assume everything starts
 * from a 0 mediaSequence value and increment from there.
 *
 * Note that VHS currently doesn't use the `number` property, but it can be helpful for
 * debugging and making sense of the manifest.
 *
 * For live playlists, to account for values increasing in manifests when periods are
 * removed on refreshes, merging logic should be used to update the numbers to their
 * appropriate values (to ensure they're sequential and increasing).
 *
 * @param {Object[]} playlists - the playlists to update
 * @param {TimelineStart[]} timelineStarts - the timeline starts for the manifest
 */
export const addMediaSequenceValues = (playlists, timelineStarts) => {
  // increment all segments sequentially
  playlists.forEach((playlist) => {
    playlist.mediaSequence = 0;
    playlist.discontinuitySequence = findIndex(timelineStarts, ({ timeline }) => timeline === playlist.timeline);

    if (!playlist.segments) {
      return;
    }

    playlist.segments.forEach((segment, index) => {
      segment.number = index;
    });
  });
};

/**
 * Given a media group object, flattens all playlists within the media group into a single
 * array.
 *
 * @param {Object} mediaGroupObject - the media group object
 *
 * @return {Object[]}
 *         The media group playlists
 */
export const flattenMediaGroupPlaylists = (mediaGroupObject) => {
  if (!mediaGroupObject) {
    return [];
  }

  return Object.keys(mediaGroupObject).reduce((acc, label) => {
    const labelContents = mediaGroupObject[label];

    return acc.concat(labelContents.playlists);
  }, []);
};

export const toM3u8 = ({
  dashPlaylists,
  locations,
  sidxMapping = {},
  previousManifest
}) => {
  if (!dashPlaylists.length) {
    return {};
  }

  // grab all main manifest attributes
  const {
    sourceDuration: duration,
    type,
    suggestedPresentationDelay,
    minimumUpdatePeriod
  } = dashPlaylists[0].attributes;

  const videoPlaylists = mergeDiscontiguousPlaylists(dashPlaylists.filter(videoOnly)).map(formatVideoPlaylist);
  const audioPlaylists = mergeDiscontiguousPlaylists(dashPlaylists.filter(audioOnly));
  const vttPlaylists = mergeDiscontiguousPlaylists(dashPlaylists.filter(vttOnly));
  const captions = dashPlaylists.map((playlist) => playlist.attributes.captionServices).filter(Boolean);

  const manifest = {
    allowCache: true,
    discontinuityStarts: [],
    segments: [],
    endList: true,
    mediaGroups: {
      AUDIO: {},
      VIDEO: {},
      ['CLOSED-CAPTIONS']: {},
      SUBTITLES: {}
    },
    uri: '',
    duration,
    playlists: addSidxSegmentsToPlaylists(videoPlaylists, sidxMapping)
  };

  if (minimumUpdatePeriod >= 0) {
    manifest.minimumUpdatePeriod = minimumUpdatePeriod * 1000;
  }

  if (locations) {
    manifest.locations = locations;
  }

  if (type === 'dynamic') {
    manifest.suggestedPresentationDelay = suggestedPresentationDelay;
  }

  const isAudioOnly = manifest.playlists.length === 0;
  const organizedAudioGroup = audioPlaylists.length ?
    organizeAudioPlaylists(audioPlaylists, sidxMapping, isAudioOnly) : null;
  const organizedVttGroup = vttPlaylists.length ?
    organizeVttPlaylists(vttPlaylists, sidxMapping) : null;
  const formattedPlaylists = videoPlaylists.concat(
    flattenMediaGroupPlaylists(organizedAudioGroup),
    flattenMediaGroupPlaylists(organizedVttGroup)
  );
  const playlistTimelineStarts =
    formattedPlaylists.map(({ timelineStarts }) => timelineStarts);

  manifest.timelineStarts = getUniqueTimelineStarts(playlistTimelineStarts);

  addMediaSequenceValues(formattedPlaylists, manifest.timelineStarts);

  if (organizedAudioGroup) {
    manifest.mediaGroups.AUDIO.audio = organizedAudioGroup;
  }

  if (organizedVttGroup) {
    manifest.mediaGroups.SUBTITLES.subs = organizedVttGroup;
  }

  if (captions.length) {
    manifest.mediaGroups['CLOSED-CAPTIONS'].cc = organizeCaptionServices(captions);
  }

  if (previousManifest) {
    return positionManifestOnTimeline({
      oldManifest: previousManifest,
      newManifest: manifest
    });
  }

  return manifest;
};
