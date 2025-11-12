import videojs from 'video.js';
import {
  parse as parseMpd,
  addSidxSegmentsToPlaylist,
  generateSidxKey,
  parseUTCTiming
} from 'mpd-parser';
import {
  refreshDelay,
  updateMaster as updatePlaylist,
  isPlaylistUnchanged
} from './playlist-loader';
import { resolveUrl, resolveManifestRedirect } from './resolve-url';
import parseSidx from 'mux.js/lib/tools/parse-sidx';
import { segmentXhrHeaders } from './xhr';
import window from 'global/window';
import {
  forEachMediaGroup,
  addPropertiesToMaster
} from './manifest';
import containerRequest from './util/container-request.js';
import {toUint8} from '@videojs/vhs-utils/es/byte-helpers';
import logger from './util/logger';

const { EventTarget, mergeOptions } = videojs;

const dashPlaylistUnchanged = function(a, b) {
  if (!isPlaylistUnchanged(a, b)) {
    return false;
  }

  // for dash the above check will often return true in scenarios where
  // the playlist actually has changed because mediaSequence isn't a
  // dash thing, and we often set it to 1. So if the playlists have the same amount
  // of segments we return true.
  // So for dash we need to make sure that the underlying segments are different.

  // if sidx changed then the playlists are different.
  if (a.sidx && b.sidx && (a.sidx.offset !== b.sidx.offset || a.sidx.length !== b.sidx.length)) {
    return false;
  } else if ((!a.sidx && b.sidx) || (a.sidx && !b.sidx)) {
    return false;
  }

  // one or the other does not have segments
  // there was a change.
  if (a.segments && !b.segments || !a.segments && b.segments) {
    return false;
  }

  // neither has segments nothing changed
  if (!a.segments && !b.segments) {
    return true;
  }

  // check segments themselves
  for (let i = 0; i < a.segments.length; i++) {
    const aSegment = a.segments[i];
    const bSegment = b.segments[i];

    // if uris are different between segments there was a change
    if (aSegment.uri !== bSegment.uri) {
      return false;
    }

    // neither segment has a byterange, there will be no byterange change.
    if (!aSegment.byterange && !bSegment.byterange) {
      continue;
    }
    const aByterange = aSegment.byterange;
    const bByterange = bSegment.byterange;

    // if byterange only exists on one of the segments, there was a change.
    if ((aByterange && !bByterange) || (!aByterange && bByterange)) {
      return false;
    }

    // if both segments have byterange with different offsets, there was a change.
    if (aByterange.offset !== bByterange.offset || aByterange.length !== bByterange.length) {
      return false;
    }
  }

  // if everything was the same with segments, this is the same playlist.
  return true;
};

/**
 * Parses the master XML string and updates playlist URI references.
 *
 * @param {Object} config
 *        Object of arguments
 * @param {string} config.masterXml
 *        The mpd XML
 * @param {string} config.srcUrl
 *        The mpd URL
 * @param {Date} config.clientOffset
 *         A time difference between server and client
 * @param {Object} config.sidxMapping
 *        SIDX mappings for moof/mdat URIs and byte ranges
 * @return {Object}
 *         The parsed mpd manifest object
 */
export const parseMasterXml = ({
  masterXml,
  srcUrl,
  clientOffset,
  sidxMapping,
  previousManifest
}) => {
  const manifest = parseMpd(masterXml, {
    manifestUri: srcUrl,
    clientOffset,
    sidxMapping,
    previousManifest
  });

  addPropertiesToMaster(manifest, srcUrl);

  return manifest;
};

/**
 * Returns a new master manifest that is the result of merging an updated master manifest
 * into the original version.
 *
 * @param {Object} oldMaster
 *        The old parsed mpd object
 * @param {Object} newMaster
 *        The updated parsed mpd object
 * @return {Object}
 *         A new object representing the original master manifest with the updated media
 *         playlists merged in
 */
export const updateMaster = (oldMaster, newMaster, sidxMapping) => {
  let noChanges = true;
  let update = mergeOptions(oldMaster, {
    // These are top level properties that can be updated
    duration: newMaster.duration,
    minimumUpdatePeriod: newMaster.minimumUpdatePeriod,
    timelineStarts: newMaster.timelineStarts
  });

  // First update the playlists in playlist list
  for (let i = 0; i < newMaster.playlists.length; i++) {
    const playlist = newMaster.playlists[i];

    if (playlist.sidx) {
      const sidxKey = generateSidxKey(playlist.sidx);

      // add sidx segments to the playlist if we have all the sidx info already
      if (sidxMapping && sidxMapping[sidxKey] && sidxMapping[sidxKey].sidx) {
        addSidxSegmentsToPlaylist(playlist, sidxMapping[sidxKey].sidx, playlist.sidx.resolvedUri);
      }
    }
    const playlistUpdate = updatePlaylist(update, playlist, dashPlaylistUnchanged);

    if (playlistUpdate) {
      update = playlistUpdate;
      noChanges = false;
    }
  }

  // Then update media group playlists
  forEachMediaGroup(newMaster, (properties, type, group, label) => {
    if (properties.playlists && properties.playlists.length) {
      const id = properties.playlists[0].id;
      const playlistUpdate = updatePlaylist(update, properties.playlists[0], dashPlaylistUnchanged);

      if (playlistUpdate) {
        update = playlistUpdate;
        // update the playlist reference within media groups
        update.mediaGroups[type][group][label].playlists[0] = update.playlists[id];
        noChanges = false;
      }
    }
  });

  if (newMaster.minimumUpdatePeriod !== oldMaster.minimumUpdatePeriod) {
    noChanges = false;
  }

  if (noChanges) {
    return null;
  }

  return update;
};

// SIDX should be equivalent if the URI and byteranges of the SIDX match.
// If the SIDXs have maps, the two maps should match,
// both `a` and `b` missing SIDXs is considered matching.
// If `a` or `b` but not both have a map, they aren't matching.
const equivalentSidx = (a, b) => {
  const neitherMap = Boolean(!a.map && !b.map);

  const equivalentMap = neitherMap || Boolean(a.map && b.map &&
    a.map.byterange.offset === b.map.byterange.offset &&
    a.map.byterange.length === b.map.byterange.length);

  return equivalentMap &&
    a.uri === b.uri &&
    a.byterange.offset === b.byterange.offset &&
    a.byterange.length === b.byterange.length;
};

// exported for testing
export const compareSidxEntry = (playlists, oldSidxMapping) => {
  const newSidxMapping = {};

  for (const id in playlists) {
    const playlist = playlists[id];
    const currentSidxInfo = playlist.sidx;

    if (currentSidxInfo) {
      const key = generateSidxKey(currentSidxInfo);

      if (!oldSidxMapping[key]) {
        break;
      }

      const savedSidxInfo = oldSidxMapping[key].sidxInfo;

      if (equivalentSidx(savedSidxInfo, currentSidxInfo)) {
        newSidxMapping[key] = oldSidxMapping[key];
      }
    }
  }

  return newSidxMapping;
};

/**
 *  A function that filters out changed items as they need to be requested separately.
 *
 *  The method is exported for testing
 *
 *  @param {Object} master the parsed mpd XML returned via mpd-parser
 *  @param {Object} oldSidxMapping the SIDX to compare against
 */
export const filterChangedSidxMappings = (master, oldSidxMapping) => {
  const videoSidx = compareSidxEntry(master.playlists, oldSidxMapping);
  let mediaGroupSidx = videoSidx;

  forEachMediaGroup(master, (properties, mediaType, groupKey, labelKey) => {
    if (properties.playlists && properties.playlists.length) {
      const playlists = properties.playlists;

      mediaGroupSidx = mergeOptions(
        mediaGroupSidx,
        compareSidxEntry(playlists, oldSidxMapping)
      );
    }
  });

  return mediaGroupSidx;
};

export default class DashPlaylistLoader extends EventTarget {
  // DashPlaylistLoader must accept either a src url or a playlist because subsequent
  // playlist loader setups from media groups will expect to be able to pass a playlist
  // (since there aren't external URLs to media playlists with DASH)
  constructor(srcUrlOrPlaylist, vhs, options = { }, masterPlaylistLoader) {
    super();

    this.masterPlaylistLoader_ = masterPlaylistLoader || this;
    if (!masterPlaylistLoader) {
      this.isMaster_ = true;
    }

    const { withCredentials = false, handleManifestRedirects = false } = options;

    this.vhs_ = vhs;
    this.withCredentials = withCredentials;
    this.handleManifestRedirects = handleManifestRedirects;

    if (!srcUrlOrPlaylist) {
      throw new Error('A non-empty playlist URL or object is required');
    }

    // event naming?
    this.on('minimumUpdatePeriod', () => {
      this.refreshXml_();
    });

    // live playlist staleness timeout
    this.on('mediaupdatetimeout', () => {
      this.refreshMedia_(this.media().id);
    });

    this.state = 'HAVE_NOTHING';
    this.loadedPlaylists_ = {};
    this.logger_ = logger('DashPlaylistLoader');

    // initialize the loader state
    // The masterPlaylistLoader will be created with a string
    if (this.isMaster_) {
      this.masterPlaylistLoader_.srcUrl = srcUrlOrPlaylist;
      // TODO: reset sidxMapping between period changes
      // once multi-period is refactored
      this.masterPlaylistLoader_.sidxMapping_ = {};
    } else {
      this.childPlaylist_ = srcUrlOrPlaylist;
    }
  }

  requestErrored_(err, request, startingState) {
    // disposed
    if (!this.request) {
      return true;
    }

    // pending request is cleared
    this.request = null;

    if (err) {
      // use the provided error object or create one
      // based on the request/response
      this.error = typeof err === 'object' && !(err instanceof Error) ? err : {
        status: request.status,
        message: 'DASH request error at URL: ' + request.uri,
        response: request.response,
        // MEDIA_ERR_NETWORK
        code: 2
      };
      if (startingState) {
        this.state = startingState;
      }

      this.trigger('error');
      return true;
    }
  }

  /**
   * Verify that the container of the sidx segment can be parsed
   * and if it can, get and parse that segment.
   */
  addSidxSegments_(playlist, startingState, cb) {
    const sidxKey = playlist.sidx && generateSidxKey(playlist.sidx);

    // playlist lacks sidx or sidx segments were added to this playlist already.
    if (!playlist.sidx || !sidxKey || this.masterPlaylistLoader_.sidxMapping_[sidxKey]) {
      // keep this function async
      this.mediaRequest_ = window.setTimeout(() => cb(false), 0);
      return;
    }

    // resolve the segment URL relative to the playlist
    const uri = resolveManifestRedirect(this.handleManifestRedirects, playlist.sidx.resolvedUri);

    const fin = (err, request) => {
      if (this.requestErrored_(err, request, startingState)) {
        return;
      }

      const sidxMapping = this.masterPlaylistLoader_.sidxMapping_;
      let sidx;

      try {
        sidx = parseSidx(toUint8(request.response).subarray(8));
      } catch (e) {
        // sidx parsing failed.
        this.requestErrored_(e, request, startingState);
        return;
      }

      sidxMapping[sidxKey] = {
        sidxInfo: playlist.sidx,
        sidx
      };

      addSidxSegmentsToPlaylist(playlist, sidx, playlist.sidx.resolvedUri);

      return cb(true);
    };

    this.request = containerRequest(uri, this.vhs_.xhr, (err, request, container, bytes) => {
      if (err) {
        return fin(err, request);
      }

      if (!container || container !== 'mp4') {
        return fin({
          status: request.status,
          message: `Unsupported ${container || 'unknown'} container type for sidx segment at URL: ${uri}`,
          // response is just bytes in this case
          // but we really don't want to return that.
          response: '',
          playlist,
          internal: true,
          blacklistDuration: Infinity,
          // MEDIA_ERR_NETWORK
          code: 2
        }, request);
      }

      // if we already downloaded the sidx bytes in the container request, use them
      const {offset, length} = playlist.sidx.byterange;

      if (bytes.length >= (length + offset)) {
        return fin(err, {
          response: bytes.subarray(offset, offset + length),
          status: request.status,
          uri: request.uri
        });
      }

      // otherwise request sidx bytes
      this.request = this.vhs_.xhr({
        uri,
        responseType: 'arraybuffer',
        headers: segmentXhrHeaders({byterange: playlist.sidx.byterange})
      }, fin);
    });
  }

  dispose() {
    this.trigger('dispose');
    this.stopRequest();
    this.loadedPlaylists_ = {};
    window.clearTimeout(this.minimumUpdatePeriodTimeout_);
    window.clearTimeout(this.mediaRequest_);
    window.clearTimeout(this.mediaUpdateTimeout);
    this.mediaUpdateTimeout = null;
    this.mediaRequest_ = null;
    this.minimumUpdatePeriodTimeout_ = null;

    if (this.masterPlaylistLoader_.createMupOnMedia_) {
      this.off('loadedmetadata', this.masterPlaylistLoader_.createMupOnMedia_);
      this.masterPlaylistLoader_.createMupOnMedia_ = null;
    }

    this.off();
  }

  hasPendingRequest() {
    return this.request || this.mediaRequest_;
  }

  stopRequest() {
    if (this.request) {
      const oldRequest = this.request;

      this.request = null;
      oldRequest.onreadystatechange = null;
      oldRequest.abort();
    }
  }

  media(playlist) {
    // getter
    if (!playlist) {
      return this.media_;
    }

    // setter
    if (this.state === 'HAVE_NOTHING') {
      throw new Error('Cannot switch media playlist from ' + this.state);
    }

    const startingState = this.state;

    // find the playlist object if the target playlist has been specified by URI
    if (typeof playlist === 'string') {
      if (!this.masterPlaylistLoader_.master.playlists[playlist]) {
        throw new Error('Unknown playlist URI: ' + playlist);
      }
      playlist = this.masterPlaylistLoader_.master.playlists[playlist];
    }

    const mediaChange = !this.media_ || playlist.id !== this.media_.id;

    // switch to previously loaded playlists immediately
    if (mediaChange &&
      this.loadedPlaylists_[playlist.id] &&
      this.loadedPlaylists_[playlist.id].endList) {
      this.state = 'HAVE_METADATA';
      this.media_ = playlist;

      // trigger media change if the active media has been updated
      if (mediaChange) {
        this.trigger('mediachanging');
        this.trigger('mediachange');
      }
      return;
    }

    // switching to the active playlist is a no-op
    if (!mediaChange) {
      return;
    }

    // switching from an already loaded playlist
    if (this.media_) {
      this.trigger('mediachanging');
    }
    this.addSidxSegments_(playlist, startingState, (sidxChanged) => {
      // everything is ready just continue to haveMetadata
      this.haveMetadata({startingState, playlist});
    });
  }

  haveMetadata({startingState, playlist}) {
    this.state = 'HAVE_METADATA';
    this.loadedPlaylists_[playlist.id] = playlist;
    this.mediaRequest_ = null;

    // This will trigger loadedplaylist
    this.refreshMedia_(playlist.id);

    // fire loadedmetadata the first time a media playlist is loaded
    // to resolve setup of media groups
    if (startingState === 'HAVE_MASTER') {
      this.trigger('loadedmetadata');
    } else {
      // trigger media change if the active media has been updated
      this.trigger('mediachange');
    }
  }

  pause() {
    if (this.masterPlaylistLoader_.createMupOnMedia_) {
      this.off('loadedmetadata', this.masterPlaylistLoader_.createMupOnMedia_);
      this.masterPlaylistLoader_.createMupOnMedia_ = null;
    }
    this.stopRequest();
    window.clearTimeout(this.mediaUpdateTimeout);
    this.mediaUpdateTimeout = null;
    if (this.isMaster_) {
      window.clearTimeout(this.masterPlaylistLoader_.minimumUpdatePeriodTimeout_);
      this.masterPlaylistLoader_.minimumUpdatePeriodTimeout_ = null;
    }
    if (this.state === 'HAVE_NOTHING') {
      // If we pause the loader before any data has been retrieved, its as if we never
      // started, so reset to an unstarted state.
      this.started = false;
    }
  }

  load(isFinalRendition) {
    window.clearTimeout(this.mediaUpdateTimeout);
    this.mediaUpdateTimeout = null;

    const media = this.media();

    if (isFinalRendition) {
      const delay = media ? (media.targetDuration / 2) * 1000 : 5 * 1000;

      this.mediaUpdateTimeout = window.setTimeout(() => this.load(), delay);
      return;
    }

    // because the playlists are internal to the manifest, load should either load the
    // main manifest, or do nothing but trigger an event
    if (!this.started) {
      this.start();
      return;
    }

    if (media && !media.endList) {
      // Check to see if this is the master loader and the MUP was cleared (this happens
      // when the loader was paused). `media` should be set at this point since one is always
      // set during `start()`.
      if (this.isMaster_ && !this.minimumUpdatePeriodTimeout_) {
        // Trigger minimumUpdatePeriod to refresh the master manifest
        this.trigger('minimumUpdatePeriod');
        // Since there was no prior minimumUpdatePeriodTimeout it should be recreated
        this.updateMinimumUpdatePeriodTimeout_();
      }
      this.trigger('mediaupdatetimeout');
    } else {
      this.trigger('loadedplaylist');
    }
  }

  start() {
    this.started = true;

    // We don't need to request the master manifest again
    // Call this asynchronously to match the xhr request behavior below
    if (!this.isMaster_) {
      this.mediaRequest_ = window.setTimeout(() => this.haveMaster_(), 0);
      return;
    }

    this.requestMaster_((req, masterChanged) => {
      this.haveMaster_();

      if (!this.hasPendingRequest() && !this.media_) {
        this.media(this.masterPlaylistLoader_.master.playlists[0]);
      }
    });
  }

  requestMaster_(cb) {
    this.request = this.vhs_.xhr({
      uri: this.masterPlaylistLoader_.srcUrl,
      withCredentials: this.withCredentials
    }, (error, req) => {
      if (this.requestErrored_(error, req)) {
        if (this.state === 'HAVE_NOTHING') {
          this.started = false;
        }
        return;
      }

      const masterChanged = req.responseText !== this.masterPlaylistLoader_.masterXml_;

      this.masterPlaylistLoader_.masterXml_ = req.responseText;

      if (req.responseHeaders && req.responseHeaders.date) {
        this.masterLoaded_ = Date.parse(req.responseHeaders.date);
      } else {
        this.masterLoaded_ = Date.now();
      }

      this.masterPlaylistLoader_.srcUrl = resolveManifestRedirect(this.handleManifestRedirects, this.masterPlaylistLoader_.srcUrl, req);

      if (masterChanged) {
        this.handleMaster_();
        this.syncClientServerClock_(() => {
          return cb(req, masterChanged);
        });
        return;
      }

      return cb(req, masterChanged);
    });

  }

  /**
   * Parses the master xml for UTCTiming node to sync the client clock to the server
   * clock. If the UTCTiming node requires a HEAD or GET request, that request is made.
   *
   * @param {Function} done
   *        Function to call when clock sync has completed
   */
  syncClientServerClock_(done) {
    const utcTiming = parseUTCTiming(this.masterPlaylistLoader_.masterXml_);

    // No UTCTiming element found in the mpd. Use Date header from mpd request as the
    // server clock
    if (utcTiming === null) {
      this.masterPlaylistLoader_.clientOffset_ = this.masterLoaded_ - Date.now();
      return done();
    }

    if (utcTiming.method === 'DIRECT') {
      this.masterPlaylistLoader_.clientOffset_ = utcTiming.value - Date.now();
      return done();
    }

    this.request = this.vhs_.xhr({
      uri: resolveUrl(this.masterPlaylistLoader_.srcUrl, utcTiming.value),
      method: utcTiming.method,
      withCredentials: this.withCredentials
    }, (error, req) => {
      // disposed
      if (!this.request) {
        return;
      }

      if (error) {
        // sync request failed, fall back to using date header from mpd
        // TODO: log warning
        this.masterPlaylistLoader_.clientOffset_ = this.masterLoaded_ - Date.now();
        return done();
      }

      let serverTime;

      if (utcTiming.method === 'HEAD') {
        if (!req.responseHeaders || !req.responseHeaders.date) {
          // expected date header not preset, fall back to using date header from mpd
          // TODO: log warning
          serverTime = this.masterLoaded_;
        } else {
          serverTime = Date.parse(req.responseHeaders.date);
        }
      } else {
        serverTime = Date.parse(req.responseText);
      }

      this.masterPlaylistLoader_.clientOffset_ = serverTime - Date.now();

      done();
    });
  }

  haveMaster_() {
    this.state = 'HAVE_MASTER';
    if (this.isMaster_) {
      // We have the master playlist at this point, so
      // trigger this to allow MasterPlaylistController
      // to make an initial playlist selection
      this.trigger('loadedplaylist');
    } else if (!this.media_) {
      // no media playlist was specifically selected so select
      // the one the child playlist loader was created with
      this.media(this.childPlaylist_);
    }
  }

  handleMaster_() {
    // clear media request
    this.mediaRequest_ = null;

    const oldMaster = this.masterPlaylistLoader_.master;

    let newMaster = parseMasterXml({
      masterXml: this.masterPlaylistLoader_.masterXml_,
      srcUrl: this.masterPlaylistLoader_.srcUrl,
      clientOffset: this.masterPlaylistLoader_.clientOffset_,
      sidxMapping: this.masterPlaylistLoader_.sidxMapping_,
      previousManifest: oldMaster
    });

    // if we have an old master to compare the new master against
    if (oldMaster) {
      newMaster = updateMaster(oldMaster, newMaster, this.masterPlaylistLoader_.sidxMapping_);
    }

    // only update master if we have a new master
    this.masterPlaylistLoader_.master = newMaster ? newMaster : oldMaster;
    const location = this.masterPlaylistLoader_.master.locations && this.masterPlaylistLoader_.master.locations[0];

    if (location && location !== this.masterPlaylistLoader_.srcUrl) {
      this.masterPlaylistLoader_.srcUrl = location;
    }

    if (!oldMaster || (newMaster && newMaster.minimumUpdatePeriod !== oldMaster.minimumUpdatePeriod)) {
      this.updateMinimumUpdatePeriodTimeout_();
    }

    return Boolean(newMaster);
  }

  updateMinimumUpdatePeriodTimeout_() {
    const mpl = this.masterPlaylistLoader_;

    // cancel any pending creation of mup on media
    // a new one will be added if needed.
    if (mpl.createMupOnMedia_) {
      mpl.off('loadedmetadata', mpl.createMupOnMedia_);
      mpl.createMupOnMedia_ = null;
    }

    // clear any pending timeouts
    if (mpl.minimumUpdatePeriodTimeout_) {
      window.clearTimeout(mpl.minimumUpdatePeriodTimeout_);
      mpl.minimumUpdatePeriodTimeout_ = null;
    }

    let mup = mpl.master && mpl.master.minimumUpdatePeriod;

    // If the minimumUpdatePeriod has a value of 0, that indicates that the current
    // MPD has no future validity, so a new one will need to be acquired when new
    // media segments are to be made available. Thus, we use the target duration
    // in this case
    if (mup === 0) {
      if (mpl.media()) {
        mup = mpl.media().targetDuration * 1000;
      } else {
        mpl.createMupOnMedia_ = mpl.updateMinimumUpdatePeriodTimeout_;
        mpl.one('loadedmetadata', mpl.createMupOnMedia_);
      }
    }

    // if minimumUpdatePeriod is invalid or <= zero, which
    // can happen when a live video becomes VOD. skip timeout
    // creation.
    if (typeof mup !== 'number' || mup <= 0) {
      if (mup < 0) {
        this.logger_(`found invalid minimumUpdatePeriod of ${mup}, not setting a timeout`);
      }
      return;
    }

    this.createMUPTimeout_(mup);
  }

  createMUPTimeout_(mup) {
    const mpl = this.masterPlaylistLoader_;

    mpl.minimumUpdatePeriodTimeout_ = window.setTimeout(() => {
      mpl.minimumUpdatePeriodTimeout_ = null;
      mpl.trigger('minimumUpdatePeriod');
      mpl.createMUPTimeout_(mup);
    }, mup);
  }

  /**
   * Sends request to refresh the master xml and updates the parsed master manifest
   */
  refreshXml_() {
    this.requestMaster_((req, masterChanged) => {
      if (!masterChanged) {
        return;
      }

      if (this.media_) {
        this.media_ = this.masterPlaylistLoader_.master.playlists[this.media_.id];
      }

      // This will filter out updated sidx info from the mapping
      this.masterPlaylistLoader_.sidxMapping_ = filterChangedSidxMappings(
        this.masterPlaylistLoader_.master,
        this.masterPlaylistLoader_.sidxMapping_
      );

      this.addSidxSegments_(this.media(), this.state, (sidxChanged) => {
        // TODO: do we need to reload the current playlist?
        this.refreshMedia_(this.media().id);
      });
    });
  }

  /**
   * Refreshes the media playlist by re-parsing the master xml and updating playlist
   * references. If this is an alternate loader, the updated parsed manifest is retrieved
   * from the master loader.
   */
  refreshMedia_(mediaID) {
    if (!mediaID) {
      throw new Error('refreshMedia_ must take a media id');
    }

    // for master we have to reparse the master xml
    // to re-create segments based on current timing values
    // which may change media. We only skip updating master
    // if this is the first time this.media_ is being set.
    // as master was just parsed in that case.
    if (this.media_ && this.isMaster_) {
      this.handleMaster_();
    }

    const playlists = this.masterPlaylistLoader_.master.playlists;
    const mediaChanged = !this.media_ || this.media_ !== playlists[mediaID];

    if (mediaChanged) {
      this.media_ = playlists[mediaID];
    } else {
      this.trigger('playlistunchanged');
    }

    if (!this.mediaUpdateTimeout) {
      const createMediaUpdateTimeout = () => {
        if (this.media().endList) {
          return;
        }

        this.mediaUpdateTimeout = window.setTimeout(() => {
          this.trigger('mediaupdatetimeout');
          createMediaUpdateTimeout();
        }, refreshDelay(this.media(), Boolean(mediaChanged)));
      };

      createMediaUpdateTimeout();
    }

    this.trigger('loadedplaylist');
  }
}
