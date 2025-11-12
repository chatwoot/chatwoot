/**
 * @file m3u8/parser.js
 */
import Stream from '@videojs/vhs-utils/es/stream.js';
import decodeB64ToUint8Array from '@videojs/vhs-utils/es/decode-b64-to-uint8-array.js';
import LineStream from './line-stream';
import ParseStream from './parse-stream';

const camelCase = (str) => str
  .toLowerCase()
  .replace(/-(\w)/g, (a) => a[1].toUpperCase());

const camelCaseKeys = function(attributes) {
  const result = {};

  Object.keys(attributes).forEach(function(key) {
    result[camelCase(key)] = attributes[key];
  });

  return result;
};

// set SERVER-CONTROL hold back based upon targetDuration and partTargetDuration
// we need this helper because defaults are based upon targetDuration and
// partTargetDuration being set, but they may not be if SERVER-CONTROL appears before
// target durations are set.
const setHoldBack = function(manifest) {
  const {serverControl, targetDuration, partTargetDuration} = manifest;

  if (!serverControl) {
    return;
  }

  const tag = '#EXT-X-SERVER-CONTROL';
  const hb = 'holdBack';
  const phb = 'partHoldBack';
  const minTargetDuration = targetDuration && targetDuration * 3;
  const minPartDuration = partTargetDuration && partTargetDuration * 2;

  if (targetDuration && !serverControl.hasOwnProperty(hb)) {
    serverControl[hb] = minTargetDuration;
    this.trigger('info', {
      message: `${tag} defaulting HOLD-BACK to targetDuration * 3 (${minTargetDuration}).`
    });
  }

  if (minTargetDuration && serverControl[hb] < minTargetDuration) {
    this.trigger('warn', {
      message: `${tag} clamping HOLD-BACK (${serverControl[hb]}) to targetDuration * 3 (${minTargetDuration})`
    });
    serverControl[hb] = minTargetDuration;
  }

  // default no part hold back to part target duration * 3
  if (partTargetDuration && !serverControl.hasOwnProperty(phb)) {
    serverControl[phb] = partTargetDuration * 3;
    this.trigger('info', {
      message: `${tag} defaulting PART-HOLD-BACK to partTargetDuration * 3 (${serverControl[phb]}).`
    });
  }

  // if part hold back is too small default it to part target duration * 2
  if (partTargetDuration && serverControl[phb] < (minPartDuration)) {
    this.trigger('warn', {
      message: `${tag} clamping PART-HOLD-BACK (${serverControl[phb]}) to partTargetDuration * 2 (${minPartDuration}).`
    });

    serverControl[phb] = minPartDuration;
  }
};

/**
 * A parser for M3U8 files. The current interpretation of the input is
 * exposed as a property `manifest` on parser objects. It's just two lines to
 * create and parse a manifest once you have the contents available as a string:
 *
 * ```js
 * var parser = new m3u8.Parser();
 * parser.push(xhr.responseText);
 * ```
 *
 * New input can later be applied to update the manifest object by calling
 * `push` again.
 *
 * The parser attempts to create a usable manifest object even if the
 * underlying input is somewhat nonsensical. It emits `info` and `warning`
 * events during the parse if it encounters input that seems invalid or
 * requires some property of the manifest object to be defaulted.
 *
 * @class Parser
 * @extends Stream
 */
export default class Parser extends Stream {
  constructor() {
    super();
    this.lineStream = new LineStream();
    this.parseStream = new ParseStream();
    this.lineStream.pipe(this.parseStream);

    /* eslint-disable consistent-this */
    const self = this;
    /* eslint-enable consistent-this */
    const uris = [];
    let currentUri = {};
    // if specified, the active EXT-X-MAP definition
    let currentMap;
    // if specified, the active decryption key
    let key;
    let hasParts = false;
    const noop = function() {};
    const defaultMediaGroups = {
      'AUDIO': {},
      'VIDEO': {},
      'CLOSED-CAPTIONS': {},
      'SUBTITLES': {}
    };
    // This is the Widevine UUID from DASH IF IOP. The same exact string is
    // used in MPDs with Widevine encrypted streams.
    const widevineUuid = 'urn:uuid:edef8ba9-79d6-4ace-a3c8-27dcd51d21ed';
    // group segments into numbered timelines delineated by discontinuities
    let currentTimeline = 0;

    // the manifest is empty until the parse stream begins delivering data
    this.manifest = {
      allowCache: true,
      discontinuityStarts: [],
      segments: []
    };
    // keep track of the last seen segment's byte range end, as segments are not required
    // to provide the offset, in which case it defaults to the next byte after the
    // previous segment
    let lastByterangeEnd = 0;
    // keep track of the last seen part's byte range end.
    let lastPartByterangeEnd = 0;

    this.on('end', () => {
      // only add preloadSegment if we don't yet have a uri for it.
      // and we actually have parts/preloadHints
      if (currentUri.uri || (!currentUri.parts && !currentUri.preloadHints)) {
        return;
      }
      if (!currentUri.map && currentMap) {
        currentUri.map = currentMap;
      }

      if (!currentUri.key && key) {
        currentUri.key = key;
      }

      if (!currentUri.timeline && typeof currentTimeline === 'number') {
        currentUri.timeline = currentTimeline;
      }

      this.manifest.preloadSegment = currentUri;
    });

    // update the manifest with the m3u8 entry from the parse stream
    this.parseStream.on('data', function(entry) {
      let mediaGroup;
      let rendition;

      ({
        tag() {
          // switch based on the tag type
          (({
            version() {
              if (entry.version) {
                this.manifest.version = entry.version;
              }
            },
            'allow-cache'() {
              this.manifest.allowCache = entry.allowed;
              if (!('allowed' in entry)) {
                this.trigger('info', {
                  message: 'defaulting allowCache to YES'
                });
                this.manifest.allowCache = true;
              }
            },
            byterange() {
              const byterange = {};

              if ('length' in entry) {
                currentUri.byterange = byterange;
                byterange.length = entry.length;

                if (!('offset' in entry)) {
                  /*
                   * From the latest spec (as of this writing):
                   * https://tools.ietf.org/html/draft-pantos-http-live-streaming-23#section-4.3.2.2
                   *
                   * Same text since EXT-X-BYTERANGE's introduction in draft 7:
                   * https://tools.ietf.org/html/draft-pantos-http-live-streaming-07#section-3.3.1)
                   *
                   * "If o [offset] is not present, the sub-range begins at the next byte
                   * following the sub-range of the previous media segment."
                   */
                  entry.offset = lastByterangeEnd;
                }
              }
              if ('offset' in entry) {
                currentUri.byterange = byterange;
                byterange.offset = entry.offset;
              }
              lastByterangeEnd = byterange.offset + byterange.length;
            },
            endlist() {
              this.manifest.endList = true;
            },
            inf() {
              if (!('mediaSequence' in this.manifest)) {
                this.manifest.mediaSequence = 0;
                this.trigger('info', {
                  message: 'defaulting media sequence to zero'
                });
              }
              if (!('discontinuitySequence' in this.manifest)) {
                this.manifest.discontinuitySequence = 0;
                this.trigger('info', {
                  message: 'defaulting discontinuity sequence to zero'
                });
              }
              if (entry.duration > 0) {
                currentUri.duration = entry.duration;
              }

              if (entry.duration === 0) {
                currentUri.duration = 0.01;
                this.trigger('info', {
                  message: 'updating zero segment duration to a small value'
                });
              }

              this.manifest.segments = uris;
            },
            key() {
              if (!entry.attributes) {
                this.trigger('warn', {
                  message: 'ignoring key declaration without attribute list'
                });
                return;
              }
              // clear the active encryption key
              if (entry.attributes.METHOD === 'NONE') {
                key = null;
                return;
              }
              if (!entry.attributes.URI) {
                this.trigger('warn', {
                  message: 'ignoring key declaration without URI'
                });
                return;
              }

              if (entry.attributes.KEYFORMAT === 'com.apple.streamingkeydelivery') {
                this.manifest.contentProtection = this.manifest.contentProtection || {};

                // TODO: add full support for this.
                this.manifest.contentProtection['com.apple.fps.1_0'] = {
                  attributes: entry.attributes
                };

                return;
              }

              // check if the content is encrypted for Widevine
              // Widevine/HLS spec: https://storage.googleapis.com/wvdocs/Widevine_DRM_HLS.pdf
              if (entry.attributes.KEYFORMAT === widevineUuid) {
                const VALID_METHODS = ['SAMPLE-AES', 'SAMPLE-AES-CTR', 'SAMPLE-AES-CENC'];

                if (VALID_METHODS.indexOf(entry.attributes.METHOD) === -1) {
                  this.trigger('warn', {
                    message: 'invalid key method provided for Widevine'
                  });
                  return;
                }

                if (entry.attributes.METHOD === 'SAMPLE-AES-CENC') {
                  this.trigger('warn', {
                    message: 'SAMPLE-AES-CENC is deprecated, please use SAMPLE-AES-CTR instead'
                  });
                }

                if (entry.attributes.URI.substring(0, 23) !== 'data:text/plain;base64,') {
                  this.trigger('warn', {
                    message: 'invalid key URI provided for Widevine'
                  });
                  return;
                }

                if (!(entry.attributes.KEYID && entry.attributes.KEYID.substring(0, 2) === '0x')) {
                  this.trigger('warn', {
                    message: 'invalid key ID provided for Widevine'
                  });
                  return;
                }

                // if Widevine key attributes are valid, store them as `contentProtection`
                // on the manifest to emulate Widevine tag structure in a DASH mpd
                this.manifest.contentProtection = this.manifest.contentProtection || {};
                this.manifest.contentProtection['com.widevine.alpha'] = {
                  attributes: {
                    schemeIdUri: entry.attributes.KEYFORMAT,
                    // remove '0x' from the key id string
                    keyId: entry.attributes.KEYID.substring(2)
                  },
                  // decode the base64-encoded PSSH box
                  pssh: decodeB64ToUint8Array(entry.attributes.URI.split(',')[1])
                };
                return;
              }

              if (!entry.attributes.METHOD) {
                this.trigger('warn', {
                  message: 'defaulting key method to AES-128'
                });
              }

              // setup an encryption key for upcoming segments
              key = {
                method: entry.attributes.METHOD || 'AES-128',
                uri: entry.attributes.URI
              };

              if (typeof entry.attributes.IV !== 'undefined') {
                key.iv = entry.attributes.IV;
              }
            },
            'media-sequence'() {
              if (!isFinite(entry.number)) {
                this.trigger('warn', {
                  message: 'ignoring invalid media sequence: ' + entry.number
                });
                return;
              }
              this.manifest.mediaSequence = entry.number;
            },
            'discontinuity-sequence'() {
              if (!isFinite(entry.number)) {
                this.trigger('warn', {
                  message: 'ignoring invalid discontinuity sequence: ' + entry.number
                });
                return;
              }
              this.manifest.discontinuitySequence = entry.number;
              currentTimeline = entry.number;
            },
            'playlist-type'() {
              if (!(/VOD|EVENT/).test(entry.playlistType)) {
                this.trigger('warn', {
                  message: 'ignoring unknown playlist type: ' + entry.playlist
                });
                return;
              }
              this.manifest.playlistType = entry.playlistType;
            },
            map() {
              currentMap = {};
              if (entry.uri) {
                currentMap.uri = entry.uri;
              }
              if (entry.byterange) {
                currentMap.byterange = entry.byterange;
              }

              if (key) {
                currentMap.key = key;
              }
            },
            'stream-inf'() {
              this.manifest.playlists = uris;
              this.manifest.mediaGroups =
                this.manifest.mediaGroups || defaultMediaGroups;

              if (!entry.attributes) {
                this.trigger('warn', {
                  message: 'ignoring empty stream-inf attributes'
                });
                return;
              }

              if (!currentUri.attributes) {
                currentUri.attributes = {};
              }
              Object.assign(currentUri.attributes, entry.attributes);
            },
            media() {
              this.manifest.mediaGroups =
                this.manifest.mediaGroups || defaultMediaGroups;

              if (!(entry.attributes &&
                    entry.attributes.TYPE &&
                    entry.attributes['GROUP-ID'] &&
                    entry.attributes.NAME)) {
                this.trigger('warn', {
                  message: 'ignoring incomplete or missing media group'
                });
                return;
              }

              // find the media group, creating defaults as necessary
              const mediaGroupType = this.manifest.mediaGroups[entry.attributes.TYPE];

              mediaGroupType[entry.attributes['GROUP-ID']] =
                mediaGroupType[entry.attributes['GROUP-ID']] || {};
              mediaGroup = mediaGroupType[entry.attributes['GROUP-ID']];

              // collect the rendition metadata
              rendition = {
                default: (/yes/i).test(entry.attributes.DEFAULT)
              };
              if (rendition.default) {
                rendition.autoselect = true;
              } else {
                rendition.autoselect = (/yes/i).test(entry.attributes.AUTOSELECT);
              }
              if (entry.attributes.LANGUAGE) {
                rendition.language = entry.attributes.LANGUAGE;
              }
              if (entry.attributes.URI) {
                rendition.uri = entry.attributes.URI;
              }
              if (entry.attributes['INSTREAM-ID']) {
                rendition.instreamId = entry.attributes['INSTREAM-ID'];
              }
              if (entry.attributes.CHARACTERISTICS) {
                rendition.characteristics = entry.attributes.CHARACTERISTICS;
              }
              if (entry.attributes.FORCED) {
                rendition.forced = (/yes/i).test(entry.attributes.FORCED);
              }

              // insert the new rendition
              mediaGroup[entry.attributes.NAME] = rendition;
            },
            discontinuity() {
              currentTimeline += 1;
              currentUri.discontinuity = true;
              this.manifest.discontinuityStarts.push(uris.length);
            },
            'program-date-time'() {
              if (typeof this.manifest.dateTimeString === 'undefined') {
                // PROGRAM-DATE-TIME is a media-segment tag, but for backwards
                // compatibility, we add the first occurence of the PROGRAM-DATE-TIME tag
                // to the manifest object
                // TODO: Consider removing this in future major version
                this.manifest.dateTimeString = entry.dateTimeString;
                this.manifest.dateTimeObject = entry.dateTimeObject;
              }

              currentUri.dateTimeString = entry.dateTimeString;
              currentUri.dateTimeObject = entry.dateTimeObject;
            },
            targetduration() {
              if (!isFinite(entry.duration) || entry.duration < 0) {
                this.trigger('warn', {
                  message: 'ignoring invalid target duration: ' + entry.duration
                });
                return;
              }
              this.manifest.targetDuration = entry.duration;

              setHoldBack.call(this, this.manifest);
            },
            start() {
              if (!entry.attributes || isNaN(entry.attributes['TIME-OFFSET'])) {
                this.trigger('warn', {
                  message: 'ignoring start declaration without appropriate attribute list'
                });
                return;
              }
              this.manifest.start = {
                timeOffset: entry.attributes['TIME-OFFSET'],
                precise: entry.attributes.PRECISE
              };
            },
            'cue-out'() {
              currentUri.cueOut = entry.data;
            },
            'cue-out-cont'() {
              currentUri.cueOutCont = entry.data;
            },
            'cue-in'() {
              currentUri.cueIn = entry.data;
            },
            'skip'() {
              this.manifest.skip = camelCaseKeys(entry.attributes);

              this.warnOnMissingAttributes_(
                '#EXT-X-SKIP',
                entry.attributes,
                ['SKIPPED-SEGMENTS']
              );
            },
            'part'() {
              hasParts = true;
              // parts are always specifed before a segment
              const segmentIndex = this.manifest.segments.length;
              const part = camelCaseKeys(entry.attributes);

              currentUri.parts = currentUri.parts || [];
              currentUri.parts.push(part);

              if (part.byterange) {
                if (!part.byterange.hasOwnProperty('offset')) {
                  part.byterange.offset = lastPartByterangeEnd;
                }
                lastPartByterangeEnd = part.byterange.offset + part.byterange.length;
              }

              const partIndex = currentUri.parts.length - 1;

              this.warnOnMissingAttributes_(
                `#EXT-X-PART #${partIndex} for segment #${segmentIndex}`,
                entry.attributes,
                ['URI', 'DURATION']
              );

              if (this.manifest.renditionReports) {
                this.manifest.renditionReports.forEach((r, i) => {
                  if (!r.hasOwnProperty('lastPart')) {
                    this.trigger('warn', {
                      message: `#EXT-X-RENDITION-REPORT #${i} lacks required attribute(s): LAST-PART`
                    });
                  }
                });
              }
            },
            'server-control'() {
              const attrs = this.manifest.serverControl = camelCaseKeys(entry.attributes);

              if (!attrs.hasOwnProperty('canBlockReload')) {
                attrs.canBlockReload = false;
                this.trigger('info', {
                  message: '#EXT-X-SERVER-CONTROL defaulting CAN-BLOCK-RELOAD to false'
                });
              }
              setHoldBack.call(this, this.manifest);

              if (attrs.canSkipDateranges && !attrs.hasOwnProperty('canSkipUntil')) {
                this.trigger('warn', {
                  message: '#EXT-X-SERVER-CONTROL lacks required attribute CAN-SKIP-UNTIL which is required when CAN-SKIP-DATERANGES is set'
                });
              }
            },
            'preload-hint'() {
              // parts are always specifed before a segment
              const segmentIndex = this.manifest.segments.length;
              const hint = camelCaseKeys(entry.attributes);
              const isPart = hint.type && hint.type === 'PART';

              currentUri.preloadHints = currentUri.preloadHints || [];
              currentUri.preloadHints.push(hint);

              if (hint.byterange) {

                if (!hint.byterange.hasOwnProperty('offset')) {
                  // use last part byterange end or zero if not a part.
                  hint.byterange.offset = isPart ? lastPartByterangeEnd : 0;
                  if (isPart) {
                    lastPartByterangeEnd = hint.byterange.offset + hint.byterange.length;
                  }
                }
              }
              const index = currentUri.preloadHints.length - 1;

              this.warnOnMissingAttributes_(
                `#EXT-X-PRELOAD-HINT #${index} for segment #${segmentIndex}`,
                entry.attributes,
                ['TYPE', 'URI']
              );

              if (!hint.type) {
                return;
              }
              // search through all preload hints except for the current one for
              // a duplicate type.
              for (let i = 0; i < currentUri.preloadHints.length - 1; i++) {
                const otherHint = currentUri.preloadHints[i];

                if (!otherHint.type) {
                  continue;
                }

                if (otherHint.type === hint.type) {
                  this.trigger('warn', {
                    message: `#EXT-X-PRELOAD-HINT #${index} for segment #${segmentIndex} has the same TYPE ${hint.type} as preload hint #${i}`
                  });
                }
              }
            },
            'rendition-report'() {
              const report = camelCaseKeys(entry.attributes);

              this.manifest.renditionReports = this.manifest.renditionReports || [];
              this.manifest.renditionReports.push(report);
              const index = this.manifest.renditionReports.length - 1;
              const required = ['LAST-MSN', 'URI'];

              if (hasParts) {
                required.push('LAST-PART');
              }

              this.warnOnMissingAttributes_(
                `#EXT-X-RENDITION-REPORT #${index}`,
                entry.attributes,
                required
              );
            },
            'part-inf'() {
              this.manifest.partInf = camelCaseKeys(entry.attributes);

              this.warnOnMissingAttributes_(
                '#EXT-X-PART-INF',
                entry.attributes,
                ['PART-TARGET']
              );
              if (this.manifest.partInf.partTarget) {
                this.manifest.partTargetDuration = this.manifest.partInf.partTarget;
              }

              setHoldBack.call(this, this.manifest);
            }
          })[entry.tagType] || noop).call(self);
        },
        uri() {
          currentUri.uri = entry.uri;
          uris.push(currentUri);

          // if no explicit duration was declared, use the target duration
          if (this.manifest.targetDuration && !('duration' in currentUri)) {
            this.trigger('warn', {
              message: 'defaulting segment duration to the target duration'
            });
            currentUri.duration = this.manifest.targetDuration;
          }
          // annotate with encryption information, if necessary
          if (key) {
            currentUri.key = key;
          }
          currentUri.timeline = currentTimeline;
          // annotate with initialization segment information, if necessary
          if (currentMap) {
            currentUri.map = currentMap;
          }

          // reset the last byterange end as it needs to be 0 between parts
          lastPartByterangeEnd = 0;

          // prepare for the next URI
          currentUri = {};
        },
        comment() {
          // comments are not important for playback
        },
        custom() {
          // if this is segment-level data attach the output to the segment
          if (entry.segment) {
            currentUri.custom = currentUri.custom || {};
            currentUri.custom[entry.customType] = entry.data;
          // if this is manifest-level data attach to the top level manifest object
          } else {
            this.manifest.custom = this.manifest.custom || {};
            this.manifest.custom[entry.customType] = entry.data;
          }
        }
      })[entry.type].call(self);
    });
  }

  warnOnMissingAttributes_(identifier, attributes, required) {
    const missing = [];

    required.forEach(function(key) {
      if (!attributes.hasOwnProperty(key)) {
        missing.push(key);
      }
    });

    if (missing.length) {
      this.trigger('warn', {message: `${identifier} lacks required attribute(s): ${missing.join(', ')}`});
    }
  }

  /**
   * Parse the input string and update the manifest object.
   *
   * @param {string} chunk a potentially incomplete portion of the manifest
   */
  push(chunk) {
    this.lineStream.push(chunk);
  }

  /**
   * Flush any remaining input. This can be handy if the last line of an M3U8
   * manifest did not contain a trailing newline but the file has been
   * completely received.
   */
  end() {
    // flush any buffered input
    this.lineStream.push('\n');

    this.trigger('end');
  }
  /**
   * Add an additional parser for non-standard tags
   *
   * @param {Object}   options              a map of options for the added parser
   * @param {RegExp}   options.expression   a regular expression to match the custom header
   * @param {string}   options.type         the type to register to the output
   * @param {Function} [options.dataParser] function to parse the line into an object
   * @param {boolean}  [options.segment]    should tag data be attached to the segment object
   */
  addParser(options) {
    this.parseStream.addParser(options);
  }
  /**
   * Add a custom header mapper
   *
   * @param {Object}   options
   * @param {RegExp}   options.expression   a regular expression to match the custom header
   * @param {Function} options.map          function to translate tag into a different tag
   */
  addTagMapper(options) {
    this.parseStream.addTagMapper(options);
  }
}
