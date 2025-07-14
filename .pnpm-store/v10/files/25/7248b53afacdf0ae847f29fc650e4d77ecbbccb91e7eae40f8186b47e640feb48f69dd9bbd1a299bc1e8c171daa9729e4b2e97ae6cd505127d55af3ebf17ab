/**
 * @file playlist-loader.js
 *
 * A state machine that manages the loading, caching, and updating of
 * M3U8 playlists.
 *
 */
import { resolveUrl, resolveManifestRedirect } from './resolve-url';
import videojs from 'video.js';
import window from 'global/window';
import logger from './util/logger';
import {
  parseManifest,
  addPropertiesToMaster,
  masterForMedia,
  setupMediaPlaylist,
  forEachMediaGroup
} from './manifest';
import {getKnownPartCount} from './playlist.js';

const { mergeOptions, EventTarget } = videojs;

const addLLHLSQueryDirectives = (uri, media) => {
  if (media.endList || !media.serverControl) {
    return uri;
  }

  const parameters = {};

  if (media.serverControl.canBlockReload) {
    const {preloadSegment} = media;
    // next msn is a zero based value, length is not.
    let nextMSN = media.mediaSequence + media.segments.length;

    // If preload segment has parts then it is likely
    // that we are going to request a part of that preload segment.
    // the logic below is used to determine that.
    if (preloadSegment) {
      const parts = preloadSegment.parts || [];
      // _HLS_part is a zero based index
      const nextPart = getKnownPartCount(media) - 1;

      // if nextPart is > -1 and not equal to just the
      // length of parts, then we know we had part preload hints
      // and we need to add the _HLS_part= query
      if (nextPart > -1 && nextPart !== (parts.length - 1)) {
        // add existing parts to our preload hints
        // eslint-disable-next-line
        parameters._HLS_part = nextPart;
      }

      // this if statement makes sure that we request the msn
      // of the preload segment if:
      // 1. the preload segment had parts (and was not yet a full segment)
      //    but was added to our segments array
      // 2. the preload segment had preload hints for parts that are not in
      //    the manifest yet.
      // in all other cases we want the segment after the preload segment
      // which will be given by using media.segments.length because it is 1 based
      // rather than 0 based.
      if (nextPart > -1 || parts.length) {
        nextMSN--;
      }
    }

    // add _HLS_msn= in front of any _HLS_part query
    // eslint-disable-next-line
    parameters._HLS_msn = nextMSN;
  }

  if (media.serverControl && media.serverControl.canSkipUntil) {
    // add _HLS_skip= infront of all other queries.
    // eslint-disable-next-line
    parameters._HLS_skip = (media.serverControl.canSkipDateranges ? 'v2' : 'YES');
  }

  if (Object.keys(parameters).length) {
    const parsedUri = new window.URL(uri);

    ['_HLS_skip', '_HLS_msn', '_HLS_part'].forEach(function(name) {
      if (!parameters.hasOwnProperty(name)) {
        return;
      }

      parsedUri.searchParams.set(name, parameters[name]);
    });

    uri = parsedUri.toString();
  }

  return uri;
};

/**
 * Returns a new segment object with properties and
 * the parts array merged.
 *
 * @param {Object} a the old segment
 * @param {Object} b the new segment
 *
 * @return {Object} the merged segment
 */
export const updateSegment = (a, b) => {
  if (!a) {
    return b;
  }

  const result = mergeOptions(a, b);

  // if only the old segment has preload hints
  // and the new one does not, remove preload hints.
  if (a.preloadHints && !b.preloadHints) {
    delete result.preloadHints;
  }

  // if only the old segment has parts
  // then the parts are no longer valid
  if (a.parts && !b.parts) {
    delete result.parts;
  // if both segments have parts
  // copy part propeties from the old segment
  // to the new one.
  } else if (a.parts && b.parts) {
    for (let i = 0; i < b.parts.length; i++) {
      if (a.parts && a.parts[i]) {
        result.parts[i] = mergeOptions(a.parts[i], b.parts[i]);
      }
    }
  }

  // set skipped to false for segments that have
  // have had information merged from the old segment.
  if (!a.skipped && b.skipped) {
    result.skipped = false;
  }

  // set preload to false for segments that have
  // had information added in the new segment.
  if (a.preload && !b.preload) {
    result.preload = false;
  }

  return result;
};

/**
 * Returns a new array of segments that is the result of merging
 * properties from an older list of segments onto an updated
 * list. No properties on the updated playlist will be ovewritten.
 *
 * @param {Array} original the outdated list of segments
 * @param {Array} update the updated list of segments
 * @param {number=} offset the index of the first update
 * segment in the original segment list. For non-live playlists,
 * this should always be zero and does not need to be
 * specified. For live playlists, it should be the difference
 * between the media sequence numbers in the original and updated
 * playlists.
 * @return {Array} a list of merged segment objects
 */
export const updateSegments = (original, update, offset) => {
  const oldSegments = original.slice();
  const newSegments = update.slice();

  offset = offset || 0;
  const result = [];

  let currentMap;

  for (let newIndex = 0; newIndex < newSegments.length; newIndex++) {
    const oldSegment = oldSegments[newIndex + offset];
    const newSegment = newSegments[newIndex];

    if (oldSegment) {
      currentMap = oldSegment.map || currentMap;

      result.push(updateSegment(oldSegment, newSegment));
    } else {
      // carry over map to new segment if it is missing
      if (currentMap && !newSegment.map) {
        newSegment.map = currentMap;
      }

      result.push(newSegment);

    }
  }
  return result;
};

export const resolveSegmentUris = (segment, baseUri) => {
  // preloadSegment will not have a uri at all
  // as the segment isn't actually in the manifest yet, only parts
  if (!segment.resolvedUri && segment.uri) {
    segment.resolvedUri = resolveUrl(baseUri, segment.uri);
  }
  if (segment.key && !segment.key.resolvedUri) {
    segment.key.resolvedUri = resolveUrl(baseUri, segment.key.uri);
  }
  if (segment.map && !segment.map.resolvedUri) {
    segment.map.resolvedUri = resolveUrl(baseUri, segment.map.uri);
  }

  if (segment.map && segment.map.key && !segment.map.key.resolvedUri) {
    segment.map.key.resolvedUri = resolveUrl(baseUri, segment.map.key.uri);
  }
  if (segment.parts && segment.parts.length) {
    segment.parts.forEach((p) => {
      if (p.resolvedUri) {
        return;
      }
      p.resolvedUri = resolveUrl(baseUri, p.uri);
    });
  }

  if (segment.preloadHints && segment.preloadHints.length) {
    segment.preloadHints.forEach((p) => {
      if (p.resolvedUri) {
        return;
      }
      p.resolvedUri = resolveUrl(baseUri, p.uri);
    });
  }
};

const getAllSegments = function(media) {
  const segments = media.segments || [];
  const preloadSegment = media.preloadSegment;

  // a preloadSegment with only preloadHints is not currently
  // a usable segment, only include a preloadSegment that has
  // parts.
  if (preloadSegment && preloadSegment.parts && preloadSegment.parts.length) {
    // if preloadHints has a MAP that means that the
    // init segment is going to change. We cannot use any of the parts
    // from this preload segment.
    if (preloadSegment.preloadHints) {
      for (let i = 0; i < preloadSegment.preloadHints.length; i++) {
        if (preloadSegment.preloadHints[i].type === 'MAP') {
          return segments;
        }
      }
    }
    // set the duration for our preload segment to target duration.
    preloadSegment.duration = media.targetDuration;
    preloadSegment.preload = true;

    segments.push(preloadSegment);
  }

  return segments;
};

// consider the playlist unchanged if the playlist object is the same or
// the number of segments is equal, the media sequence number is unchanged,
// and this playlist hasn't become the end of the playlist
export const isPlaylistUnchanged = (a, b) => a === b ||
  (a.segments && b.segments && a.segments.length === b.segments.length &&
   a.endList === b.endList &&
   a.mediaSequence === b.mediaSequence &&
   a.preloadSegment === b.preloadSegment);

/**
  * Returns a new master playlist that is the result of merging an
  * updated media playlist into the original version. If the
  * updated media playlist does not match any of the playlist
  * entries in the original master playlist, null is returned.
  *
  * @param {Object} master a parsed master M3U8 object
  * @param {Object} media a parsed media M3U8 object
  * @return {Object} a new object that represents the original
  * master playlist with the updated media playlist merged in, or
  * null if the merge produced no change.
  */
export const updateMaster = (master, newMedia, unchangedCheck = isPlaylistUnchanged) => {
  const result = mergeOptions(master, {});
  const oldMedia = result.playlists[newMedia.id];

  if (!oldMedia) {
    return null;
  }

  if (unchangedCheck(oldMedia, newMedia)) {
    return null;
  }

  newMedia.segments = getAllSegments(newMedia);

  const mergedPlaylist = mergeOptions(oldMedia, newMedia);

  // always use the new media's preload segment
  if (mergedPlaylist.preloadSegment && !newMedia.preloadSegment) {
    delete mergedPlaylist.preloadSegment;
  }

  // if the update could overlap existing segment information, merge the two segment lists
  if (oldMedia.segments) {
    if (newMedia.skip) {
      newMedia.segments = newMedia.segments || [];
      // add back in objects for skipped segments, so that we merge
      // old properties into the new segments
      for (let i = 0; i < newMedia.skip.skippedSegments; i++) {
        newMedia.segments.unshift({skipped: true});
      }
    }
    mergedPlaylist.segments = updateSegments(
      oldMedia.segments,
      newMedia.segments,
      newMedia.mediaSequence - oldMedia.mediaSequence
    );
  }

  // resolve any segment URIs to prevent us from having to do it later
  mergedPlaylist.segments.forEach((segment) => {
    resolveSegmentUris(segment, mergedPlaylist.resolvedUri);
  });

  // TODO Right now in the playlists array there are two references to each playlist, one
  // that is referenced by index, and one by URI. The index reference may no longer be
  // necessary.
  for (let i = 0; i < result.playlists.length; i++) {
    if (result.playlists[i].id === newMedia.id) {
      result.playlists[i] = mergedPlaylist;
    }
  }
  result.playlists[newMedia.id] = mergedPlaylist;
  // URI reference added for backwards compatibility
  result.playlists[newMedia.uri] = mergedPlaylist;

  // update media group playlist references.
  forEachMediaGroup(master, (properties, mediaType, groupKey, labelKey) => {
    if (!properties.playlists) {
      return;
    }
    for (let i = 0; i < properties.playlists.length; i++) {
      if (newMedia.id === properties.playlists[i].id) {
        properties.playlists[i] = newMedia;
      }
    }
  });

  return result;
};

/**
 * Calculates the time to wait before refreshing a live playlist
 *
 * @param {Object} media
 *        The current media
 * @param {boolean} update
 *        True if there were any updates from the last refresh, false otherwise
 * @return {number}
 *         The time in ms to wait before refreshing the live playlist
 */
export const refreshDelay = (media, update) => {
  const segments = media.segments || [];
  const lastSegment = segments[segments.length - 1];
  const lastPart = lastSegment && lastSegment.parts && lastSegment.parts[lastSegment.parts.length - 1];
  const lastDuration = lastPart && lastPart.duration || lastSegment && lastSegment.duration;

  if (update && lastDuration) {
    return lastDuration * 1000;
  }

  // if the playlist is unchanged since the last reload or last segment duration
  // cannot be determined, try again after half the target duration
  return (media.partTargetDuration || media.targetDuration || 10) * 500;
};

/**
 * Load a playlist from a remote location
 *
 * @class PlaylistLoader
 * @extends Stream
 * @param {string|Object} src url or object of manifest
 * @param {boolean} withCredentials the withCredentials xhr option
 * @class
 */
export default class PlaylistLoader extends EventTarget {
  constructor(src, vhs, options = { }) {
    super();

    if (!src) {
      throw new Error('A non-empty playlist URL or object is required');
    }
    this.logger_ = logger('PlaylistLoader');

    const { withCredentials = false, handleManifestRedirects = false } = options;

    this.src = src;
    this.vhs_ = vhs;
    this.withCredentials = withCredentials;
    this.handleManifestRedirects = handleManifestRedirects;

    const vhsOptions = vhs.options_;

    this.customTagParsers = (vhsOptions && vhsOptions.customTagParsers) || [];
    this.customTagMappers = (vhsOptions && vhsOptions.customTagMappers) || [];
    this.experimentalLLHLS = (vhsOptions && vhsOptions.experimentalLLHLS) || false;

    // force experimentalLLHLS for IE 11
    if (videojs.browser.IE_VERSION) {
      this.experimentalLLHLS = false;
    }

    // initialize the loader state
    this.state = 'HAVE_NOTHING';

    // live playlist staleness timeout
    this.handleMediaupdatetimeout_ = this.handleMediaupdatetimeout_.bind(this);
    this.on('mediaupdatetimeout', this.handleMediaupdatetimeout_);
  }

  handleMediaupdatetimeout_() {
    if (this.state !== 'HAVE_METADATA') {
      // only refresh the media playlist if no other activity is going on
      return;
    }
    const media = this.media();

    let uri = resolveUrl(this.master.uri, media.uri);

    if (this.experimentalLLHLS) {
      uri = addLLHLSQueryDirectives(uri, media);
    }
    this.state = 'HAVE_CURRENT_METADATA';

    this.request = this.vhs_.xhr({
      uri,
      withCredentials: this.withCredentials
    }, (error, req) => {
      // disposed
      if (!this.request) {
        return;
      }

      if (error) {
        return this.playlistRequestError(this.request, this.media(), 'HAVE_METADATA');
      }

      this.haveMetadata({
        playlistString: this.request.responseText,
        url: this.media().uri,
        id: this.media().id
      });
    });

  }

  playlistRequestError(xhr, playlist, startingState) {
    const {
      uri,
      id
    } = playlist;

    // any in-flight request is now finished
    this.request = null;

    if (startingState) {
      this.state = startingState;
    }

    this.error = {
      playlist: this.master.playlists[id],
      status: xhr.status,
      message: `HLS playlist request error at URL: ${uri}.`,
      responseText: xhr.responseText,
      code: (xhr.status >= 500) ? 4 : 2
    };

    this.trigger('error');
  }

  parseManifest_({url, manifestString}) {
    return parseManifest({
      onwarn: ({message}) => this.logger_(`m3u8-parser warn for ${url}: ${message}`),
      oninfo: ({message}) => this.logger_(`m3u8-parser info for ${url}: ${message}`),
      manifestString,
      customTagParsers: this.customTagParsers,
      customTagMappers: this.customTagMappers,
      experimentalLLHLS: this.experimentalLLHLS
    });
  }

  /**
   * Update the playlist loader's state in response to a new or updated playlist.
   *
   * @param {string} [playlistString]
   *        Playlist string (if playlistObject is not provided)
   * @param {Object} [playlistObject]
   *        Playlist object (if playlistString is not provided)
   * @param {string} url
   *        URL of playlist
   * @param {string} id
   *        ID to use for playlist
   */
  haveMetadata({ playlistString, playlistObject, url, id }) {
    // any in-flight request is now finished
    this.request = null;
    this.state = 'HAVE_METADATA';

    const playlist = playlistObject || this.parseManifest_({
      url,
      manifestString: playlistString
    });

    playlist.lastRequest = Date.now();

    setupMediaPlaylist({
      playlist,
      uri: url,
      id
    });

    // merge this playlist into the master
    const update = updateMaster(this.master, playlist);

    this.targetDuration = playlist.partTargetDuration || playlist.targetDuration;

    this.pendingMedia_ = null;

    if (update) {
      this.master = update;
      this.media_ = this.master.playlists[id];
    } else {
      this.trigger('playlistunchanged');
    }

    this.updateMediaUpdateTimeout_(refreshDelay(this.media(), !!update));

    this.trigger('loadedplaylist');
  }

  /**
    * Abort any outstanding work and clean up.
    */
  dispose() {
    this.trigger('dispose');
    this.stopRequest();
    window.clearTimeout(this.mediaUpdateTimeout);
    window.clearTimeout(this.finalRenditionTimeout);

    this.off();
  }

  stopRequest() {
    if (this.request) {
      const oldRequest = this.request;

      this.request = null;
      oldRequest.onreadystatechange = null;
      oldRequest.abort();
    }
  }

  /**
    * When called without any arguments, returns the currently
    * active media playlist. When called with a single argument,
    * triggers the playlist loader to asynchronously switch to the
    * specified media playlist. Calling this method while the
    * loader is in the HAVE_NOTHING causes an error to be emitted
    * but otherwise has no effect.
    *
    * @param {Object=} playlist the parsed media playlist
    * object to switch to
    * @param {boolean=} shouldDelay whether we should delay the request by half target duration
    *
    * @return {Playlist} the current loaded media
    */
  media(playlist, shouldDelay) {
    // getter
    if (!playlist) {
      return this.media_;
    }

    // setter
    if (this.state === 'HAVE_NOTHING') {
      throw new Error('Cannot switch media playlist from ' + this.state);
    }

    // find the playlist object if the target playlist has been
    // specified by URI
    if (typeof playlist === 'string') {
      if (!this.master.playlists[playlist]) {
        throw new Error('Unknown playlist URI: ' + playlist);
      }
      playlist = this.master.playlists[playlist];
    }

    window.clearTimeout(this.finalRenditionTimeout);

    if (shouldDelay) {
      const delay = ((playlist.partTargetDuration || playlist.targetDuration) / 2) * 1000 || 5 * 1000;

      this.finalRenditionTimeout =
        window.setTimeout(this.media.bind(this, playlist, false), delay);
      return;
    }

    const startingState = this.state;
    const mediaChange = !this.media_ || playlist.id !== this.media_.id;
    const masterPlaylistRef = this.master.playlists[playlist.id];

    // switch to fully loaded playlists immediately
    if (masterPlaylistRef && masterPlaylistRef.endList ||
        // handle the case of a playlist object (e.g., if using vhs-json with a resolved
        // media playlist or, for the case of demuxed audio, a resolved audio media group)
        (playlist.endList && playlist.segments.length)) {

      // abort outstanding playlist requests
      if (this.request) {
        this.request.onreadystatechange = null;
        this.request.abort();
        this.request = null;
      }
      this.state = 'HAVE_METADATA';
      this.media_ = playlist;

      // trigger media change if the active media has been updated
      if (mediaChange) {
        this.trigger('mediachanging');

        if (startingState === 'HAVE_MASTER') {
          // The initial playlist was a master manifest, and the first media selected was
          // also provided (in the form of a resolved playlist object) as part of the
          // source object (rather than just a URL). Therefore, since the media playlist
          // doesn't need to be requested, loadedmetadata won't trigger as part of the
          // normal flow, and needs an explicit trigger here.
          this.trigger('loadedmetadata');
        } else {
          this.trigger('mediachange');
        }
      }
      return;
    }

    // We update/set the timeout here so that live playlists
    // that are not a media change will "start" the loader as expected.
    // We expect that this function will start the media update timeout
    // cycle again. This also prevents a playlist switch failure from
    // causing us to stall during live.
    this.updateMediaUpdateTimeout_(refreshDelay(playlist, true));

    // switching to the active playlist is a no-op
    if (!mediaChange) {
      return;
    }

    this.state = 'SWITCHING_MEDIA';

    // there is already an outstanding playlist request
    if (this.request) {
      if (playlist.resolvedUri === this.request.url) {
        // requesting to switch to the same playlist multiple times
        // has no effect after the first
        return;
      }
      this.request.onreadystatechange = null;
      this.request.abort();
      this.request = null;
    }

    // request the new playlist
    if (this.media_) {
      this.trigger('mediachanging');
    }

    this.pendingMedia_ = playlist;

    this.request = this.vhs_.xhr({
      uri: playlist.resolvedUri,
      withCredentials: this.withCredentials
    }, (error, req) => {
      // disposed
      if (!this.request) {
        return;
      }

      playlist.lastRequest = Date.now();

      playlist.resolvedUri = resolveManifestRedirect(this.handleManifestRedirects, playlist.resolvedUri, req);

      if (error) {
        return this.playlistRequestError(this.request, playlist, startingState);
      }

      this.haveMetadata({
        playlistString: req.responseText,
        url: playlist.uri,
        id: playlist.id
      });

      // fire loadedmetadata the first time a media playlist is loaded
      if (startingState === 'HAVE_MASTER') {
        this.trigger('loadedmetadata');
      } else {
        this.trigger('mediachange');
      }
    });
  }

  /**
   * pause loading of the playlist
   */
  pause() {
    if (this.mediaUpdateTimeout) {
      window.clearTimeout(this.mediaUpdateTimeout);
      this.mediaUpdateTimeout = null;
    }

    this.stopRequest();
    if (this.state === 'HAVE_NOTHING') {
      // If we pause the loader before any data has been retrieved, its as if we never
      // started, so reset to an unstarted state.
      this.started = false;
    }
    // Need to restore state now that no activity is happening
    if (this.state === 'SWITCHING_MEDIA') {
      // if the loader was in the process of switching media, it should either return to
      // HAVE_MASTER or HAVE_METADATA depending on if the loader has loaded a media
      // playlist yet. This is determined by the existence of loader.media_
      if (this.media_) {
        this.state = 'HAVE_METADATA';
      } else {
        this.state = 'HAVE_MASTER';
      }
    } else if (this.state === 'HAVE_CURRENT_METADATA') {
      this.state = 'HAVE_METADATA';
    }
  }

  /**
   * start loading of the playlist
   */
  load(shouldDelay) {
    if (this.mediaUpdateTimeout) {
      window.clearTimeout(this.mediaUpdateTimeout);
      this.mediaUpdateTimeout = null;
    }
    const media = this.media();

    if (shouldDelay) {
      const delay = media ? ((media.partTargetDuration || media.targetDuration) / 2) * 1000 : 5 * 1000;

      this.mediaUpdateTimeout = window.setTimeout(() => {
        this.mediaUpdateTimeout = null;
        this.load();
      }, delay);

      return;
    }

    if (!this.started) {
      this.start();
      return;
    }

    if (media && !media.endList) {
      this.trigger('mediaupdatetimeout');
    } else {
      this.trigger('loadedplaylist');
    }
  }

  updateMediaUpdateTimeout_(delay) {
    if (this.mediaUpdateTimeout) {
      window.clearTimeout(this.mediaUpdateTimeout);
      this.mediaUpdateTimeout = null;
    }

    // we only have use mediaupdatetimeout for live playlists.
    if (!this.media() || this.media().endList) {
      return;
    }

    this.mediaUpdateTimeout = window.setTimeout(() => {
      this.mediaUpdateTimeout = null;
      this.trigger('mediaupdatetimeout');
      this.updateMediaUpdateTimeout_(delay);
    }, delay);
  }

  /**
   * start loading of the playlist
   */
  start() {
    this.started = true;

    if (typeof this.src === 'object') {
      // in the case of an entirely constructed manifest object (meaning there's no actual
      // manifest on a server), default the uri to the page's href
      if (!this.src.uri) {
        this.src.uri = window.location.href;
      }

      // resolvedUri is added on internally after the initial request. Since there's no
      // request for pre-resolved manifests, add on resolvedUri here.
      this.src.resolvedUri = this.src.uri;

      // Since a manifest object was passed in as the source (instead of a URL), the first
      // request can be skipped (since the top level of the manifest, at a minimum, is
      // already available as a parsed manifest object). However, if the manifest object
      // represents a master playlist, some media playlists may need to be resolved before
      // the starting segment list is available. Therefore, go directly to setup of the
      // initial playlist, and let the normal flow continue from there.
      //
      // Note that the call to setup is asynchronous, as other sections of VHS may assume
      // that the first request is asynchronous.
      setTimeout(() => {
        this.setupInitialPlaylist(this.src);
      }, 0);
      return;
    }

    // request the specified URL
    this.request = this.vhs_.xhr({
      uri: this.src,
      withCredentials: this.withCredentials
    }, (error, req) => {
      // disposed
      if (!this.request) {
        return;
      }

      // clear the loader's request reference
      this.request = null;

      if (error) {
        this.error = {
          status: req.status,
          message: `HLS playlist request error at URL: ${this.src}.`,
          responseText: req.responseText,
          // MEDIA_ERR_NETWORK
          code: 2
        };
        if (this.state === 'HAVE_NOTHING') {
          this.started = false;
        }
        return this.trigger('error');
      }

      this.src = resolveManifestRedirect(this.handleManifestRedirects, this.src, req);

      const manifest = this.parseManifest_({
        manifestString: req.responseText,
        url: this.src
      });

      this.setupInitialPlaylist(manifest);
    });
  }

  srcUri() {
    return typeof this.src === 'string' ? this.src : this.src.uri;
  }

  /**
   * Given a manifest object that's either a master or media playlist, trigger the proper
   * events and set the state of the playlist loader.
   *
   * If the manifest object represents a master playlist, `loadedplaylist` will be
   * triggered to allow listeners to select a playlist. If none is selected, the loader
   * will default to the first one in the playlists array.
   *
   * If the manifest object represents a media playlist, `loadedplaylist` will be
   * triggered followed by `loadedmetadata`, as the only available playlist is loaded.
   *
   * In the case of a media playlist, a master playlist object wrapper with one playlist
   * will be created so that all logic can handle playlists in the same fashion (as an
   * assumed manifest object schema).
   *
   * @param {Object} manifest
   *        The parsed manifest object
   */
  setupInitialPlaylist(manifest) {
    this.state = 'HAVE_MASTER';

    if (manifest.playlists) {
      this.master = manifest;
      addPropertiesToMaster(this.master, this.srcUri());
      // If the initial master playlist has playlists wtih segments already resolved,
      // then resolve URIs in advance, as they are usually done after a playlist request,
      // which may not happen if the playlist is resolved.
      manifest.playlists.forEach((playlist) => {
        playlist.segments = getAllSegments(playlist);

        playlist.segments.forEach((segment) => {
          resolveSegmentUris(segment, playlist.resolvedUri);
        });
      });
      this.trigger('loadedplaylist');
      if (!this.request) {
        // no media playlist was specifically selected so start
        // from the first listed one
        this.media(this.master.playlists[0]);
      }
      return;
    }

    // In order to support media playlists passed in as vhs-json, the case where the uri
    // is not provided as part of the manifest should be considered, and an appropriate
    // default used.
    const uri = this.srcUri() || window.location.href;

    this.master = masterForMedia(manifest, uri);
    this.haveMetadata({
      playlistObject: manifest,
      url: uri,
      id: this.master.playlists[0].id
    });
    this.trigger('loadedmetadata');
  }

}
