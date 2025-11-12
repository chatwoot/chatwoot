/**
 * @file videojs-http-streaming.js
 *
 * The main file for the HLS project.
 * License: https://github.com/videojs/videojs-http-streaming/blob/master/LICENSE
 */
import document from 'global/document';
import window from 'global/window';
import PlaylistLoader from './playlist-loader';
import Playlist from './playlist';
import xhrFactory from './xhr';
import { simpleTypeFromSourceType } from '@videojs/vhs-utils/es/media-types.js';
import * as utils from './bin-utils';
import {
  getProgramTime,
  seekToProgramTime
} from './util/time';
import { timeRangesToArray } from './ranges';
import videojs from 'video.js';
import { MasterPlaylistController } from './master-playlist-controller';
import Config from './config';
import renditionSelectionMixin from './rendition-mixin';
import PlaybackWatcher from './playback-watcher';
import SourceUpdater from './source-updater';
import reloadSourceOnError from './reload-source-on-error';
import {
  lastBandwidthSelector,
  lowestBitrateCompatibleVariantSelector,
  movingAverageBandwidthSelector,
  comparePlaylistBandwidth,
  comparePlaylistResolution
} from './playlist-selectors.js';
import {
  browserSupportsCodec,
  getMimeForCodec,
  parseCodecs
} from '@videojs/vhs-utils/es/codecs.js';
import { unwrapCodecList } from './util/codecs.js';
import logger from './util/logger';
import {SAFE_TIME_DELTA} from './ranges';

// IMPORTANT:
// keep these at the bottom they are replaced at build time
// because webpack and rollup without plugins do not support json
// and we do not want to break our users
import {version as vhsVersion} from '../package.json';
import {version as muxVersion} from 'mux.js/package.json';
import {version as mpdVersion} from 'mpd-parser/package.json';
import {version as m3u8Version} from 'm3u8-parser/package.json';
import {version as aesVersion} from 'aes-decrypter/package.json';

const Vhs = {
  PlaylistLoader,
  Playlist,
  utils,

  STANDARD_PLAYLIST_SELECTOR: lastBandwidthSelector,
  INITIAL_PLAYLIST_SELECTOR: lowestBitrateCompatibleVariantSelector,
  lastBandwidthSelector,
  movingAverageBandwidthSelector,
  comparePlaylistBandwidth,
  comparePlaylistResolution,

  xhr: xhrFactory()
};

// Define getter/setters for config properties
Object.keys(Config).forEach((prop) => {
  Object.defineProperty(Vhs, prop, {
    get() {
      videojs.log.warn(`using Vhs.${prop} is UNSAFE be sure you know what you are doing`);
      return Config[prop];
    },
    set(value) {
      videojs.log.warn(`using Vhs.${prop} is UNSAFE be sure you know what you are doing`);

      if (typeof value !== 'number' || value < 0) {
        videojs.log.warn(`value of Vhs.${prop} must be greater than or equal to 0`);
        return;
      }

      Config[prop] = value;
    }
  });
});

export const LOCAL_STORAGE_KEY = 'videojs-vhs';

/**
 * Updates the selectedIndex of the QualityLevelList when a mediachange happens in vhs.
 *
 * @param {QualityLevelList} qualityLevels The QualityLevelList to update.
 * @param {PlaylistLoader} playlistLoader PlaylistLoader containing the new media info.
 * @function handleVhsMediaChange
 */
const handleVhsMediaChange = function(qualityLevels, playlistLoader) {
  const newPlaylist = playlistLoader.media();
  let selectedIndex = -1;

  for (let i = 0; i < qualityLevels.length; i++) {
    if (qualityLevels[i].id === newPlaylist.id) {
      selectedIndex = i;
      break;
    }
  }

  qualityLevels.selectedIndex_ = selectedIndex;
  qualityLevels.trigger({
    selectedIndex,
    type: 'change'
  });
};

/**
 * Adds quality levels to list once playlist metadata is available
 *
 * @param {QualityLevelList} qualityLevels The QualityLevelList to attach events to.
 * @param {Object} vhs Vhs object to listen to for media events.
 * @function handleVhsLoadedMetadata
 */
const handleVhsLoadedMetadata = function(qualityLevels, vhs) {
  vhs.representations().forEach((rep) => {
    qualityLevels.addQualityLevel(rep);
  });
  handleVhsMediaChange(qualityLevels, vhs.playlists);
};

// HLS is a source handler, not a tech. Make sure attempts to use it
// as one do not cause exceptions.
Vhs.canPlaySource = function() {
  return videojs.log.warn('HLS is no longer a tech. Please remove it from ' +
    'your player\'s techOrder.');
};

const emeKeySystems = (keySystemOptions, mainPlaylist, audioPlaylist) => {
  if (!keySystemOptions) {
    return keySystemOptions;
  }

  let codecs = {};

  if (mainPlaylist && mainPlaylist.attributes && mainPlaylist.attributes.CODECS) {
    codecs = unwrapCodecList(parseCodecs(mainPlaylist.attributes.CODECS));
  }

  if (audioPlaylist && audioPlaylist.attributes && audioPlaylist.attributes.CODECS) {
    codecs.audio = audioPlaylist.attributes.CODECS;
  }

  const videoContentType = getMimeForCodec(codecs.video);
  const audioContentType = getMimeForCodec(codecs.audio);

  // upsert the content types based on the selected playlist
  const keySystemContentTypes = {};

  for (const keySystem in keySystemOptions) {
    keySystemContentTypes[keySystem] = {};

    if (audioContentType) {
      keySystemContentTypes[keySystem].audioContentType = audioContentType;
    }
    if (videoContentType) {
      keySystemContentTypes[keySystem].videoContentType = videoContentType;
    }

    // Default to using the video playlist's PSSH even though they may be different, as
    // videojs-contrib-eme will only accept one in the options.
    //
    // This shouldn't be an issue for most cases as early intialization will handle all
    // unique PSSH values, and if they aren't, then encrypted events should have the
    // specific information needed for the unique license.
    if (mainPlaylist.contentProtection &&
        mainPlaylist.contentProtection[keySystem] &&
        mainPlaylist.contentProtection[keySystem].pssh) {
      keySystemContentTypes[keySystem].pssh =
        mainPlaylist.contentProtection[keySystem].pssh;
    }

    // videojs-contrib-eme accepts the option of specifying: 'com.some.cdm': 'url'
    // so we need to prevent overwriting the URL entirely
    if (typeof keySystemOptions[keySystem] === 'string') {
      keySystemContentTypes[keySystem].url = keySystemOptions[keySystem];
    }
  }

  return videojs.mergeOptions(keySystemOptions, keySystemContentTypes);
};

/**
 * @typedef {Object} KeySystems
 *
 * keySystems configuration for https://github.com/videojs/videojs-contrib-eme
 * Note: not all options are listed here.
 *
 * @property {Uint8Array} [pssh]
 *           Protection System Specific Header
 */

/**
 * Goes through all the playlists and collects an array of KeySystems options objects
 * containing each playlist's keySystems and their pssh values, if available.
 *
 * @param {Object[]} playlists
 *        The playlists to look through
 * @param {string[]} keySystems
 *        The keySystems to collect pssh values for
 *
 * @return {KeySystems[]}
 *         An array of KeySystems objects containing available key systems and their
 *         pssh values
 */
const getAllPsshKeySystemsOptions = (playlists, keySystems) => {
  return playlists.reduce((keySystemsArr, playlist) => {
    if (!playlist.contentProtection) {
      return keySystemsArr;
    }

    const keySystemsOptions = keySystems.reduce((keySystemsObj, keySystem) => {
      const keySystemOptions = playlist.contentProtection[keySystem];

      if (keySystemOptions && keySystemOptions.pssh) {
        keySystemsObj[keySystem] = { pssh: keySystemOptions.pssh };
      }

      return keySystemsObj;
    }, {});

    if (Object.keys(keySystemsOptions).length) {
      keySystemsArr.push(keySystemsOptions);
    }

    return keySystemsArr;
  }, []);
};

/**
 * Returns a promise that waits for the
 * [eme plugin](https://github.com/videojs/videojs-contrib-eme) to create a key session.
 *
 * Works around https://bugs.chromium.org/p/chromium/issues/detail?id=895449 in non-IE11
 * browsers.
 *
 * As per the above ticket, this is particularly important for Chrome, where, if
 * unencrypted content is appended before encrypted content and the key session has not
 * been created, a MEDIA_ERR_DECODE will be thrown once the encrypted content is reached
 * during playback.
 *
 * @param {Object} player
 *        The player instance
 * @param {Object[]} sourceKeySystems
 *        The key systems options from the player source
 * @param {Object} [audioMedia]
 *        The active audio media playlist (optional)
 * @param {Object[]} mainPlaylists
 *        The playlists found on the master playlist object
 *
 * @return {Object}
 *         Promise that resolves when the key session has been created
 */
export const waitForKeySessionCreation = ({
  player,
  sourceKeySystems,
  audioMedia,
  mainPlaylists
}) => {
  if (!player.eme.initializeMediaKeys) {
    return Promise.resolve();
  }

  // TODO should all audio PSSH values be initialized for DRM?
  //
  // All unique video rendition pssh values are initialized for DRM, but here only
  // the initial audio playlist license is initialized. In theory, an encrypted
  // event should be fired if the user switches to an alternative audio playlist
  // where a license is required, but this case hasn't yet been tested. In addition, there
  // may be many alternate audio playlists unlikely to be used (e.g., multiple different
  // languages).
  const playlists = audioMedia ? mainPlaylists.concat([audioMedia]) : mainPlaylists;

  const keySystemsOptionsArr = getAllPsshKeySystemsOptions(
    playlists,
    Object.keys(sourceKeySystems)
  );

  const initializationFinishedPromises = [];
  const keySessionCreatedPromises = [];

  // Since PSSH values are interpreted as initData, EME will dedupe any duplicates. The
  // only place where it should not be deduped is for ms-prefixed APIs, but the early
  // return for IE11 above, and the existence of modern EME APIs in addition to
  // ms-prefixed APIs on Edge should prevent this from being a concern.
  // initializeMediaKeys also won't use the webkit-prefixed APIs.
  keySystemsOptionsArr.forEach((keySystemsOptions) => {
    keySessionCreatedPromises.push(new Promise((resolve, reject) => {
      player.tech_.one('keysessioncreated', resolve);
    }));

    initializationFinishedPromises.push(new Promise((resolve, reject) => {
      player.eme.initializeMediaKeys({
        keySystems: keySystemsOptions
      }, (err) => {
        if (err) {
          reject(err);
          return;
        }
        resolve();
      });
    }));
  });

  // The reasons Promise.race is chosen over Promise.any:
  //
  // * Promise.any is only available in Safari 14+.
  // * None of these promises are expected to reject. If they do reject, it might be
  //   better here for the race to surface the rejection, rather than mask it by using
  //   Promise.any.
  return Promise.race([
    // If a session was previously created, these will all finish resolving without
    // creating a new session, otherwise it will take until the end of all license
    // requests, which is why the key session check is used (to make setup much faster).
    Promise.all(initializationFinishedPromises),
    // Once a single session is created, the browser knows DRM will be used.
    Promise.race(keySessionCreatedPromises)
  ]);
};

/**
 * If the [eme](https://github.com/videojs/videojs-contrib-eme) plugin is available, and
 * there are keySystems on the source, sets up source options to prepare the source for
 * eme.
 *
 * @param {Object} player
 *        The player instance
 * @param {Object[]} sourceKeySystems
 *        The key systems options from the player source
 * @param {Object} media
 *        The active media playlist
 * @param {Object} [audioMedia]
 *        The active audio media playlist (optional)
 *
 * @return {boolean}
 *         Whether or not options were configured and EME is available
 */
const setupEmeOptions = ({
  player,
  sourceKeySystems,
  media,
  audioMedia
}) => {
  const sourceOptions = emeKeySystems(sourceKeySystems, media, audioMedia);

  if (!sourceOptions) {
    return false;
  }

  player.currentSource().keySystems = sourceOptions;

  // eme handles the rest of the setup, so if it is missing
  // do nothing.
  if (sourceOptions && !player.eme) {
    videojs.log.warn('DRM encrypted source cannot be decrypted without a DRM plugin');
    return false;
  }

  return true;
};

const getVhsLocalStorage = () => {
  if (!window.localStorage) {
    return null;
  }

  const storedObject = window.localStorage.getItem(LOCAL_STORAGE_KEY);

  if (!storedObject) {
    return null;
  }

  try {
    return JSON.parse(storedObject);
  } catch (e) {
    // someone may have tampered with the value
    return null;
  }
};

const updateVhsLocalStorage = (options) => {
  if (!window.localStorage) {
    return false;
  }

  let objectToStore = getVhsLocalStorage();

  objectToStore = objectToStore ? videojs.mergeOptions(objectToStore, options) : options;

  try {
    window.localStorage.setItem(LOCAL_STORAGE_KEY, JSON.stringify(objectToStore));
  } catch (e) {
    // Throws if storage is full (e.g., always on iOS 5+ Safari private mode, where
    // storage is set to 0).
    // https://developer.mozilla.org/en-US/docs/Web/API/Storage/setItem#Exceptions
    // No need to perform any operation.
    return false;
  }

  return objectToStore;
};

/**
 * Parses VHS-supported media types from data URIs. See
 * https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/Data_URIs
 * for information on data URIs.
 *
 * @param {string} dataUri
 *        The data URI
 *
 * @return {string|Object}
 *         The parsed object/string, or the original string if no supported media type
 *         was found
 */
const expandDataUri = (dataUri) => {
  if (dataUri.toLowerCase().indexOf('data:application/vnd.videojs.vhs+json,') === 0) {
    return JSON.parse(dataUri.substring(dataUri.indexOf(',') + 1));
  }
  // no known case for this data URI, return the string as-is
  return dataUri;
};

/**
 * Whether the browser has built-in HLS support.
 */
Vhs.supportsNativeHls = (function() {
  if (!document || !document.createElement) {
    return false;
  }

  const video = document.createElement('video');

  // native HLS is definitely not supported if HTML5 video isn't
  if (!videojs.getTech('Html5').isSupported()) {
    return false;
  }

  // HLS manifests can go by many mime-types
  const canPlay = [
    // Apple santioned
    'application/vnd.apple.mpegurl',
    // Apple sanctioned for backwards compatibility
    'audio/mpegurl',
    // Very common
    'audio/x-mpegurl',
    // Very common
    'application/x-mpegurl',
    // Included for completeness
    'video/x-mpegurl',
    'video/mpegurl',
    'application/mpegurl'
  ];

  return canPlay.some(function(canItPlay) {
    return (/maybe|probably/i).test(video.canPlayType(canItPlay));
  });
}());

Vhs.supportsNativeDash = (function() {
  if (!document || !document.createElement || !videojs.getTech('Html5').isSupported()) {
    return false;
  }

  return (/maybe|probably/i).test(document.createElement('video').canPlayType('application/dash+xml'));
}());

Vhs.supportsTypeNatively = (type) => {
  if (type === 'hls') {
    return Vhs.supportsNativeHls;
  }

  if (type === 'dash') {
    return Vhs.supportsNativeDash;
  }

  return false;
};

/**
 * HLS is a source handler, not a tech. Make sure attempts to use it
 * as one do not cause exceptions.
 */
Vhs.isSupported = function() {
  return videojs.log.warn('HLS is no longer a tech. Please remove it from ' +
    'your player\'s techOrder.');
};

const Component = videojs.getComponent('Component');

/**
 * The Vhs Handler object, where we orchestrate all of the parts
 * of HLS to interact with video.js
 *
 * @class VhsHandler
 * @extends videojs.Component
 * @param {Object} source the soruce object
 * @param {Tech} tech the parent tech object
 * @param {Object} options optional and required options
 */
class VhsHandler extends Component {
  constructor(source, tech, options) {
    super(tech, videojs.mergeOptions(options.hls, options.vhs));

    if (options.hls && Object.keys(options.hls).length) {
      videojs.log.warn('Using hls options is deprecated. Use vhs instead.');
    }

    // if a tech level `initialBandwidth` option was passed
    // use that over the VHS level `bandwidth` option
    if (typeof options.initialBandwidth === 'number') {
      this.options_.bandwidth = options.initialBandwidth;
    }

    this.logger_ = logger('VhsHandler');

    // tech.player() is deprecated but setup a reference to HLS for
    // backwards-compatibility
    if (tech.options_ && tech.options_.playerId) {
      const _player = videojs(tech.options_.playerId);

      if (!_player.hasOwnProperty('hls')) {
        Object.defineProperty(_player, 'hls', {
          get: () => {
            videojs.log.warn('player.hls is deprecated. Use player.tech().vhs instead.');
            tech.trigger({ type: 'usage', name: 'hls-player-access' });
            return this;
          },
          configurable: true
        });
      }

      if (!_player.hasOwnProperty('vhs')) {
        Object.defineProperty(_player, 'vhs', {
          get: () => {
            videojs.log.warn('player.vhs is deprecated. Use player.tech().vhs instead.');
            tech.trigger({ type: 'usage', name: 'vhs-player-access' });
            return this;
          },
          configurable: true
        });
      }

      if (!_player.hasOwnProperty('dash')) {
        Object.defineProperty(_player, 'dash', {
          get: () => {
            videojs.log.warn('player.dash is deprecated. Use player.tech().vhs instead.');
            return this;
          },
          configurable: true
        });
      }

      this.player_ = _player;
    }

    this.tech_ = tech;
    this.source_ = source;
    this.stats = {};
    this.ignoreNextSeekingEvent_ = false;
    this.setOptions_();

    if (this.options_.overrideNative &&
      tech.overrideNativeAudioTracks &&
      tech.overrideNativeVideoTracks) {
      tech.overrideNativeAudioTracks(true);
      tech.overrideNativeVideoTracks(true);
    } else if (this.options_.overrideNative &&
      (tech.featuresNativeVideoTracks || tech.featuresNativeAudioTracks)) {
      // overriding native HLS only works if audio tracks have been emulated
      // error early if we're misconfigured
      throw new Error('Overriding native HLS requires emulated tracks. ' +
        'See https://git.io/vMpjB');
    }

    // listen for fullscreenchange events for this player so that we
    // can adjust our quality selection quickly
    this.on(document, [
      'fullscreenchange', 'webkitfullscreenchange',
      'mozfullscreenchange', 'MSFullscreenChange'
    ], (event) => {
      const fullscreenElement = document.fullscreenElement ||
        document.webkitFullscreenElement ||
        document.mozFullScreenElement ||
        document.msFullscreenElement;

      if (fullscreenElement && fullscreenElement.contains(this.tech_.el())) {
        this.masterPlaylistController_.fastQualityChange_();
      } else {
        // When leaving fullscreen, since the in page pixel dimensions should be smaller
        // than full screen, see if there should be a rendition switch down to preserve
        // bandwidth.
        this.masterPlaylistController_.checkABR_();
      }
    });

    this.on(this.tech_, 'seeking', function() {
      if (this.ignoreNextSeekingEvent_) {
        this.ignoreNextSeekingEvent_ = false;
        return;
      }

      this.setCurrentTime(this.tech_.currentTime());
    });

    this.on(this.tech_, 'error', function() {
      // verify that the error was real and we are loaded
      // enough to have mpc loaded.
      if (this.tech_.error() && this.masterPlaylistController_) {
        this.masterPlaylistController_.pauseLoading();
      }
    });

    this.on(this.tech_, 'play', this.play);
  }

  setOptions_() {
    // defaults
    this.options_.withCredentials = this.options_.withCredentials || false;
    this.options_.handleManifestRedirects = this.options_.handleManifestRedirects === false ? false : true;
    this.options_.limitRenditionByPlayerDimensions = this.options_.limitRenditionByPlayerDimensions === false ? false : true;
    this.options_.useDevicePixelRatio = this.options_.useDevicePixelRatio || false;
    this.options_.smoothQualityChange = this.options_.smoothQualityChange || false;
    this.options_.useBandwidthFromLocalStorage =
      typeof this.source_.useBandwidthFromLocalStorage !== 'undefined' ?
        this.source_.useBandwidthFromLocalStorage :
        this.options_.useBandwidthFromLocalStorage || false;
    this.options_.useNetworkInformationApi = this.options_.useNetworkInformationApi || false;
    this.options_.customTagParsers = this.options_.customTagParsers || [];
    this.options_.customTagMappers = this.options_.customTagMappers || [];
    this.options_.cacheEncryptionKeys = this.options_.cacheEncryptionKeys || false;

    if (typeof this.options_.blacklistDuration !== 'number') {
      this.options_.blacklistDuration = 5 * 60;
    }

    if (typeof this.options_.bandwidth !== 'number') {
      if (this.options_.useBandwidthFromLocalStorage) {
        const storedObject = getVhsLocalStorage();

        if (storedObject && storedObject.bandwidth) {
          this.options_.bandwidth = storedObject.bandwidth;
          this.tech_.trigger({type: 'usage', name: 'vhs-bandwidth-from-local-storage'});
          this.tech_.trigger({type: 'usage', name: 'hls-bandwidth-from-local-storage'});
        }
        if (storedObject && storedObject.throughput) {
          this.options_.throughput = storedObject.throughput;
          this.tech_.trigger({type: 'usage', name: 'vhs-throughput-from-local-storage'});
          this.tech_.trigger({type: 'usage', name: 'hls-throughput-from-local-storage'});
        }
      }
    }
    // if bandwidth was not set by options or pulled from local storage, start playlist
    // selection at a reasonable bandwidth
    if (typeof this.options_.bandwidth !== 'number') {
      this.options_.bandwidth = Config.INITIAL_BANDWIDTH;
    }

    // If the bandwidth number is unchanged from the initial setting
    // then this takes precedence over the enableLowInitialPlaylist option
    this.options_.enableLowInitialPlaylist =
      this.options_.enableLowInitialPlaylist &&
      this.options_.bandwidth === Config.INITIAL_BANDWIDTH;

    // grab options passed to player.src
    [
      'withCredentials',
      'useDevicePixelRatio',
      'limitRenditionByPlayerDimensions',
      'bandwidth',
      'smoothQualityChange',
      'customTagParsers',
      'customTagMappers',
      'handleManifestRedirects',
      'cacheEncryptionKeys',
      'playlistSelector',
      'initialPlaylistSelector',
      'experimentalBufferBasedABR',
      'liveRangeSafeTimeDelta',
      'experimentalLLHLS',
      'useNetworkInformationApi',
      'experimentalExactManifestTimings',
      'experimentalLeastPixelDiffSelector'
    ].forEach((option) => {
      if (typeof this.source_[option] !== 'undefined') {
        this.options_[option] = this.source_[option];
      }
    });

    this.limitRenditionByPlayerDimensions = this.options_.limitRenditionByPlayerDimensions;
    this.useDevicePixelRatio = this.options_.useDevicePixelRatio;
  }
  /**
   * called when player.src gets called, handle a new source
   *
   * @param {Object} src the source object to handle
   */
  src(src, type) {
    // do nothing if the src is falsey
    if (!src) {
      return;
    }
    this.setOptions_();
    // add master playlist controller options
    this.options_.src = expandDataUri(this.source_.src);
    this.options_.tech = this.tech_;
    this.options_.externVhs = Vhs;
    this.options_.sourceType = simpleTypeFromSourceType(type);

    // Whenever we seek internally, we should update the tech
    this.options_.seekTo = (time) => {
      this.tech_.setCurrentTime(time);
    };

    if (this.options_.smoothQualityChange) {
      videojs.log.warn('smoothQualityChange is deprecated and will be removed in the next major version');
    }

    this.masterPlaylistController_ = new MasterPlaylistController(this.options_);

    const playbackWatcherOptions = videojs.mergeOptions(
      {
        liveRangeSafeTimeDelta: SAFE_TIME_DELTA
      },
      this.options_,
      {
        seekable: () => this.seekable(),
        media: () => this.masterPlaylistController_.media(),
        masterPlaylistController: this.masterPlaylistController_
      }
    );

    this.playbackWatcher_ = new PlaybackWatcher(playbackWatcherOptions);

    this.masterPlaylistController_.on('error', () => {
      const player = videojs.players[this.tech_.options_.playerId];
      let error = this.masterPlaylistController_.error;

      if (typeof error === 'object' && !error.code) {
        error.code = 3;
      } else if (typeof error === 'string') {
        error = {message: error, code: 3};
      }

      player.error(error);
    });

    const defaultSelector = this.options_.experimentalBufferBasedABR ?
      Vhs.movingAverageBandwidthSelector(0.55) : Vhs.STANDARD_PLAYLIST_SELECTOR;

    // `this` in selectPlaylist should be the VhsHandler for backwards
    // compatibility with < v2
    this.masterPlaylistController_.selectPlaylist = this.selectPlaylist ?
      this.selectPlaylist.bind(this) :
      defaultSelector.bind(this);

    this.masterPlaylistController_.selectInitialPlaylist =
      Vhs.INITIAL_PLAYLIST_SELECTOR.bind(this);

    // re-expose some internal objects for backwards compatibility with < v2
    this.playlists = this.masterPlaylistController_.masterPlaylistLoader_;
    this.mediaSource = this.masterPlaylistController_.mediaSource;

    // Proxy assignment of some properties to the master playlist
    // controller. Using a custom property for backwards compatibility
    // with < v2
    Object.defineProperties(this, {
      selectPlaylist: {
        get() {
          return this.masterPlaylistController_.selectPlaylist;
        },
        set(selectPlaylist) {
          this.masterPlaylistController_.selectPlaylist = selectPlaylist.bind(this);
        }
      },
      throughput: {
        get() {
          return this.masterPlaylistController_.mainSegmentLoader_.throughput.rate;
        },
        set(throughput) {
          this.masterPlaylistController_.mainSegmentLoader_.throughput.rate = throughput;
          // By setting `count` to 1 the throughput value becomes the starting value
          // for the cumulative average
          this.masterPlaylistController_.mainSegmentLoader_.throughput.count = 1;
        }
      },
      bandwidth: {
        get() {
          let playerBandwidthEst = this.masterPlaylistController_.mainSegmentLoader_.bandwidth;

          const networkInformation = window.navigator.connection || window.navigator.mozConnection || window.navigator.webkitConnection;
          const tenMbpsAsBitsPerSecond = 10e6;

          if (this.options_.useNetworkInformationApi && networkInformation) {
            // downlink returns Mbps
            // https://developer.mozilla.org/en-US/docs/Web/API/NetworkInformation/downlink
            const networkInfoBandwidthEstBitsPerSec = networkInformation.downlink * 1000 * 1000;

            // downlink maxes out at 10 Mbps. In the event that both networkInformationApi and the player
            // estimate a bandwidth greater than 10 Mbps, use the larger of the two estimates to ensure that
            // high quality streams are not filtered out.
            if (networkInfoBandwidthEstBitsPerSec >= tenMbpsAsBitsPerSecond && playerBandwidthEst >= tenMbpsAsBitsPerSecond) {
              playerBandwidthEst = Math.max(playerBandwidthEst, networkInfoBandwidthEstBitsPerSec);
            } else {
              playerBandwidthEst = networkInfoBandwidthEstBitsPerSec;
            }
          }

          return playerBandwidthEst;
        },
        set(bandwidth) {
          this.masterPlaylistController_.mainSegmentLoader_.bandwidth = bandwidth;
          // setting the bandwidth manually resets the throughput counter
          // `count` is set to zero that current value of `rate` isn't included
          // in the cumulative average
          this.masterPlaylistController_.mainSegmentLoader_.throughput = {
            rate: 0,
            count: 0
          };
        }
      },
      /**
       * `systemBandwidth` is a combination of two serial processes bit-rates. The first
       * is the network bitrate provided by `bandwidth` and the second is the bitrate of
       * the entire process after that - decryption, transmuxing, and appending - provided
       * by `throughput`.
       *
       * Since the two process are serial, the overall system bandwidth is given by:
       *   sysBandwidth = 1 / (1 / bandwidth + 1 / throughput)
       */
      systemBandwidth: {
        get() {
          const invBandwidth = 1 / (this.bandwidth || 1);
          let invThroughput;

          if (this.throughput > 0) {
            invThroughput = 1 / this.throughput;
          } else {
            invThroughput = 0;
          }

          const systemBitrate = Math.floor(1 / (invBandwidth + invThroughput));

          return systemBitrate;
        },
        set() {
          videojs.log.error('The "systemBandwidth" property is read-only');
        }
      }
    });

    if (this.options_.bandwidth) {
      this.bandwidth = this.options_.bandwidth;
    }
    if (this.options_.throughput) {
      this.throughput = this.options_.throughput;
    }

    Object.defineProperties(this.stats, {
      bandwidth: {
        get: () => this.bandwidth || 0,
        enumerable: true
      },
      mediaRequests: {
        get: () => this.masterPlaylistController_.mediaRequests_() || 0,
        enumerable: true
      },
      mediaRequestsAborted: {
        get: () => this.masterPlaylistController_.mediaRequestsAborted_() || 0,
        enumerable: true
      },
      mediaRequestsTimedout: {
        get: () => this.masterPlaylistController_.mediaRequestsTimedout_() || 0,
        enumerable: true
      },
      mediaRequestsErrored: {
        get: () => this.masterPlaylistController_.mediaRequestsErrored_() || 0,
        enumerable: true
      },
      mediaTransferDuration: {
        get: () => this.masterPlaylistController_.mediaTransferDuration_() || 0,
        enumerable: true
      },
      mediaBytesTransferred: {
        get: () => this.masterPlaylistController_.mediaBytesTransferred_() || 0,
        enumerable: true
      },
      mediaSecondsLoaded: {
        get: () => this.masterPlaylistController_.mediaSecondsLoaded_() || 0,
        enumerable: true
      },
      mediaAppends: {
        get: () => this.masterPlaylistController_.mediaAppends_() || 0,
        enumerable: true
      },
      mainAppendsToLoadedData: {
        get: () => this.masterPlaylistController_.mainAppendsToLoadedData_() || 0,
        enumerable: true
      },
      audioAppendsToLoadedData: {
        get: () => this.masterPlaylistController_.audioAppendsToLoadedData_() || 0,
        enumerable: true
      },
      appendsToLoadedData: {
        get: () => this.masterPlaylistController_.appendsToLoadedData_() || 0,
        enumerable: true
      },
      timeToLoadedData: {
        get: () => this.masterPlaylistController_.timeToLoadedData_() || 0,
        enumerable: true
      },
      buffered: {
        get: () => timeRangesToArray(this.tech_.buffered()),
        enumerable: true
      },
      currentTime: {
        get: () => this.tech_.currentTime(),
        enumerable: true
      },
      currentSource: {
        get: () => this.tech_.currentSource_,
        enumerable: true
      },
      currentTech: {
        get: () => this.tech_.name_,
        enumerable: true
      },
      duration: {
        get: () => this.tech_.duration(),
        enumerable: true
      },
      master: {
        get: () => this.playlists.master,
        enumerable: true
      },
      playerDimensions: {
        get: () => this.tech_.currentDimensions(),
        enumerable: true
      },
      seekable: {
        get: () => timeRangesToArray(this.tech_.seekable()),
        enumerable: true
      },
      timestamp: {
        get: () => Date.now(),
        enumerable: true
      },
      videoPlaybackQuality: {
        get: () => this.tech_.getVideoPlaybackQuality(),
        enumerable: true
      }
    });

    this.tech_.one(
      'canplay',
      this.masterPlaylistController_.setupFirstPlay.bind(this.masterPlaylistController_)
    );

    this.tech_.on('bandwidthupdate', () => {
      if (this.options_.useBandwidthFromLocalStorage) {
        updateVhsLocalStorage({
          bandwidth: this.bandwidth,
          throughput: Math.round(this.throughput)
        });
      }
    });

    this.masterPlaylistController_.on('selectedinitialmedia', () => {
      // Add the manual rendition mix-in to VhsHandler
      renditionSelectionMixin(this);
    });

    this.masterPlaylistController_.sourceUpdater_.on('createdsourcebuffers', () => {
      this.setupEme_();
    });

    // the bandwidth of the primary segment loader is our best
    // estimate of overall bandwidth
    this.on(this.masterPlaylistController_, 'progress', function() {
      this.tech_.trigger('progress');
    });

    // In the live case, we need to ignore the very first `seeking` event since
    // that will be the result of the seek-to-live behavior
    this.on(this.masterPlaylistController_, 'firstplay', function() {
      this.ignoreNextSeekingEvent_ = true;
    });

    this.setupQualityLevels_();

    // do nothing if the tech has been disposed already
    // this can occur if someone sets the src in player.ready(), for instance
    if (!this.tech_.el()) {
      return;
    }

    this.mediaSourceUrl_ = window.URL.createObjectURL(this.masterPlaylistController_.mediaSource);

    this.tech_.src(this.mediaSourceUrl_);
  }

  createKeySessions_() {
    const audioPlaylistLoader =
      this.masterPlaylistController_.mediaTypes_.AUDIO.activePlaylistLoader;

    this.logger_('waiting for EME key session creation');
    waitForKeySessionCreation({
      player: this.player_,
      sourceKeySystems: this.source_.keySystems,
      audioMedia: audioPlaylistLoader && audioPlaylistLoader.media(),
      mainPlaylists: this.playlists.master.playlists
    }).then(() => {
      this.logger_('created EME key session');
      this.masterPlaylistController_.sourceUpdater_.initializedEme();
    }).catch((err) => {
      this.logger_('error while creating EME key session', err);
      this.player_.error({
        message: 'Failed to initialize media keys for EME',
        code: 3
      });
    });
  }

  handleWaitingForKey_() {
    // If waitingforkey is fired, it's possible that the data that's necessary to retrieve
    // the key is in the manifest. While this should've happened on initial source load, it
    // may happen again in live streams where the keys change, and the manifest info
    // reflects the update.
    //
    // Because videojs-contrib-eme compares the PSSH data we send to that of PSSH data it's
    // already requested keys for, we don't have to worry about this generating extraneous
    // requests.
    this.logger_('waitingforkey fired, attempting to create any new key sessions');
    this.createKeySessions_();
  }

  /**
   * If necessary and EME is available, sets up EME options and waits for key session
   * creation.
   *
   * This function also updates the source updater so taht it can be used, as for some
   * browsers, EME must be configured before content is appended (if appending unencrypted
   * content before encrypted content).
   */
  setupEme_() {
    const audioPlaylistLoader =
      this.masterPlaylistController_.mediaTypes_.AUDIO.activePlaylistLoader;

    const didSetupEmeOptions = setupEmeOptions({
      player: this.player_,
      sourceKeySystems: this.source_.keySystems,
      media: this.playlists.media(),
      audioMedia: audioPlaylistLoader && audioPlaylistLoader.media()
    });

    this.player_.tech_.on('keystatuschange', (e) => {
      if (e.status === 'output-restricted') {
        this.masterPlaylistController_.blacklistCurrentPlaylist({
          playlist: this.masterPlaylistController_.media(),
          message: `DRM keystatus changed to ${e.status}. Playlist will fail to play. Check for HDCP content.`,
          blacklistDuration: Infinity
        });
      }
    });

    this.handleWaitingForKey_ = this.handleWaitingForKey_.bind(this);
    this.player_.tech_.on('waitingforkey', this.handleWaitingForKey_);

    // In IE11 this is too early to initialize media keys, and IE11 does not support
    // promises.
    if (videojs.browser.IE_VERSION === 11 || !didSetupEmeOptions) {
      // If EME options were not set up, we've done all we could to initialize EME.
      this.masterPlaylistController_.sourceUpdater_.initializedEme();
      return;
    }

    this.createKeySessions_();
  }

  /**
   * Initializes the quality levels and sets listeners to update them.
   *
   * @method setupQualityLevels_
   * @private
   */
  setupQualityLevels_() {
    const player = videojs.players[this.tech_.options_.playerId];

    // if there isn't a player or there isn't a qualityLevels plugin
    // or qualityLevels_ listeners have already been setup, do nothing.
    if (!player || !player.qualityLevels || this.qualityLevels_) {
      return;
    }

    this.qualityLevels_ = player.qualityLevels();

    this.masterPlaylistController_.on('selectedinitialmedia', () => {
      handleVhsLoadedMetadata(this.qualityLevels_, this);
    });

    this.playlists.on('mediachange', () => {
      handleVhsMediaChange(this.qualityLevels_, this.playlists);
    });
  }

  /**
   * return the version
   */
  static version() {
    return {
      '@videojs/http-streaming': vhsVersion,
      'mux.js': muxVersion,
      'mpd-parser': mpdVersion,
      'm3u8-parser': m3u8Version,
      'aes-decrypter': aesVersion
    };
  }

  /**
   * return the version
   */
  version() {
    return this.constructor.version();
  }

  canChangeType() {
    return SourceUpdater.canChangeType();
  }

  /**
   * Begin playing the video.
   */
  play() {
    this.masterPlaylistController_.play();
  }

  /**
   * a wrapper around the function in MasterPlaylistController
   */
  setCurrentTime(currentTime) {
    this.masterPlaylistController_.setCurrentTime(currentTime);
  }

  /**
   * a wrapper around the function in MasterPlaylistController
   */
  duration() {
    return this.masterPlaylistController_.duration();
  }

  /**
   * a wrapper around the function in MasterPlaylistController
   */
  seekable() {
    return this.masterPlaylistController_.seekable();
  }

  /**
   * Abort all outstanding work and cleanup.
   */
  dispose() {
    if (this.playbackWatcher_) {
      this.playbackWatcher_.dispose();
    }
    if (this.masterPlaylistController_) {
      this.masterPlaylistController_.dispose();
    }
    if (this.qualityLevels_) {
      this.qualityLevels_.dispose();
    }

    if (this.player_) {
      delete this.player_.vhs;
      delete this.player_.dash;
      delete this.player_.hls;
    }

    if (this.tech_ && this.tech_.vhs) {
      delete this.tech_.vhs;
    }

    // don't check this.tech_.hls as it will log a deprecated warning
    if (this.tech_) {
      delete this.tech_.hls;
    }

    if (this.mediaSourceUrl_ && window.URL.revokeObjectURL) {
      window.URL.revokeObjectURL(this.mediaSourceUrl_);
      this.mediaSourceUrl_ = null;
    }

    if (this.tech_) {
      this.tech_.off('waitingforkey', this.handleWaitingForKey_);
    }

    super.dispose();
  }

  convertToProgramTime(time, callback) {
    return getProgramTime({
      playlist: this.masterPlaylistController_.media(),
      time,
      callback
    });
  }

  // the player must be playing before calling this
  seekToProgramTime(programTime, callback, pauseAfterSeek = true, retryCount = 2) {
    return seekToProgramTime({
      programTime,
      playlist: this.masterPlaylistController_.media(),
      retryCount,
      pauseAfterSeek,
      seekTo: this.options_.seekTo,
      tech: this.options_.tech,
      callback
    });
  }
}

/**
 * The Source Handler object, which informs video.js what additional
 * MIME types are supported and sets up playback. It is registered
 * automatically to the appropriate tech based on the capabilities of
 * the browser it is running in. It is not necessary to use or modify
 * this object in normal usage.
 */
const VhsSourceHandler = {
  name: 'videojs-http-streaming',
  VERSION: vhsVersion,
  canHandleSource(srcObj, options = {}) {
    const localOptions = videojs.mergeOptions(videojs.options, options);

    return VhsSourceHandler.canPlayType(srcObj.type, localOptions);
  },
  handleSource(source, tech, options = {}) {
    const localOptions = videojs.mergeOptions(videojs.options, options);

    tech.vhs = new VhsHandler(source, tech, localOptions);
    if (!videojs.hasOwnProperty('hls')) {
      Object.defineProperty(tech, 'hls', {
        get: () => {
          videojs.log.warn('player.tech().hls is deprecated. Use player.tech().vhs instead.');
          return tech.vhs;
        },
        configurable: true
      });
    }
    tech.vhs.xhr = xhrFactory();

    tech.vhs.src(source.src, source.type);
    return tech.vhs;
  },
  canPlayType(type, options = {}) {
    const {
      vhs: { overrideNative = !videojs.browser.IS_ANY_SAFARI } = {},
      hls: { overrideNative: legacyOverrideNative = false } = {}
    } = videojs.mergeOptions(videojs.options, options);

    const supportedType = simpleTypeFromSourceType(type);
    const canUseMsePlayback = supportedType &&
      (!Vhs.supportsTypeNatively(supportedType) || legacyOverrideNative || overrideNative);

    return canUseMsePlayback ? 'maybe' : '';
  }
};

/**
 * Check to see if the native MediaSource object exists and supports
 * an MP4 container with both H.264 video and AAC-LC audio.
 *
 * @return {boolean} if  native media sources are supported
 */
const supportsNativeMediaSources = () => {
  return browserSupportsCodec('avc1.4d400d,mp4a.40.2');
};

// register source handlers with the appropriate techs
if (supportsNativeMediaSources()) {
  videojs.getTech('Html5').registerSourceHandler(VhsSourceHandler, 0);
}

videojs.VhsHandler = VhsHandler;
Object.defineProperty(videojs, 'HlsHandler', {
  get: () => {
    videojs.log.warn('videojs.HlsHandler is deprecated. Use videojs.VhsHandler instead.');
    return VhsHandler;
  },
  configurable: true
});
videojs.VhsSourceHandler = VhsSourceHandler;
Object.defineProperty(videojs, 'HlsSourceHandler', {
  get: () => {
    videojs.log.warn('videojs.HlsSourceHandler is deprecated. ' +
      'Use videojs.VhsSourceHandler instead.');
    return VhsSourceHandler;
  },
  configurable: true
});
videojs.Vhs = Vhs;
Object.defineProperty(videojs, 'Hls', {
  get: () => {
    videojs.log.warn('videojs.Hls is deprecated. Use videojs.Vhs instead.');
    return Vhs;
  },
  configurable: true
});
if (!videojs.use) {
  videojs.registerComponent('Hls', Vhs);
  videojs.registerComponent('Vhs', Vhs);
}
videojs.options.vhs = videojs.options.vhs || {};
videojs.options.hls = videojs.options.hls || {};

if (!videojs.getPlugin || !videojs.getPlugin('reloadSourceOnError')) {
  const registerPlugin = videojs.registerPlugin || videojs.plugin;

  registerPlugin('reloadSourceOnError', reloadSourceOnError);
}

export {
  Vhs,
  VhsHandler,
  VhsSourceHandler,
  emeKeySystems,
  simpleTypeFromSourceType,
  expandDataUri,
  setupEmeOptions,
  getAllPsshKeySystemsOptions
};
