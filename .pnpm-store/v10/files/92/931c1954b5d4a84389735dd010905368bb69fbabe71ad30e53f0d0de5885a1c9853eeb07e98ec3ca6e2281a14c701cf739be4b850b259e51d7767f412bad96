/*! @name mpd-parser @version 0.21.0 @license Apache-2.0 */
(function (global, factory) {
  typeof exports === 'object' && typeof module !== 'undefined' ? factory(exports, require('@xmldom/xmldom')) :
  typeof define === 'function' && define.amd ? define(['exports', '@xmldom/xmldom'], factory) :
  (global = typeof globalThis !== 'undefined' ? globalThis : global || self, factory(global.mpdParser = {}, global.window));
}(this, (function (exports, xmldom) { 'use strict';

  var version = "0.21.0";

  var isObject = function isObject(obj) {
    return !!obj && typeof obj === 'object';
  };

  var merge = function merge() {
    for (var _len = arguments.length, objects = new Array(_len), _key = 0; _key < _len; _key++) {
      objects[_key] = arguments[_key];
    }

    return objects.reduce(function (result, source) {
      if (typeof source !== 'object') {
        return result;
      }

      Object.keys(source).forEach(function (key) {
        if (Array.isArray(result[key]) && Array.isArray(source[key])) {
          result[key] = result[key].concat(source[key]);
        } else if (isObject(result[key]) && isObject(source[key])) {
          result[key] = merge(result[key], source[key]);
        } else {
          result[key] = source[key];
        }
      });
      return result;
    }, {});
  };
  var values = function values(o) {
    return Object.keys(o).map(function (k) {
      return o[k];
    });
  };

  var range = function range(start, end) {
    var result = [];

    for (var i = start; i < end; i++) {
      result.push(i);
    }

    return result;
  };
  var flatten = function flatten(lists) {
    return lists.reduce(function (x, y) {
      return x.concat(y);
    }, []);
  };
  var from = function from(list) {
    if (!list.length) {
      return [];
    }

    var result = [];

    for (var i = 0; i < list.length; i++) {
      result.push(list[i]);
    }

    return result;
  };
  var findIndexes = function findIndexes(l, key) {
    return l.reduce(function (a, e, i) {
      if (e[key]) {
        a.push(i);
      }

      return a;
    }, []);
  };
  /**
   * Returns the first index that satisfies the matching function, or -1 if not found.
   *
   * Only necessary because of IE11 support.
   *
   * @param {Array} list - the list to search through
   * @param {Function} matchingFunction - the matching function
   *
   * @return {number} the matching index or -1 if not found
   */

  var findIndex = function findIndex(list, matchingFunction) {
    for (var i = 0; i < list.length; i++) {
      if (matchingFunction(list[i])) {
        return i;
      }
    }

    return -1;
  };
  /**
   * Returns a union of the included lists provided each element can be identified by a key.
   *
   * @param {Array} list - list of lists to get the union of
   * @param {Function} keyFunction - the function to use as a key for each element
   *
   * @return {Array} the union of the arrays
   */

  var union = function union(lists, keyFunction) {
    return values(lists.reduce(function (acc, list) {
      list.forEach(function (el) {
        acc[keyFunction(el)] = el;
      });
      return acc;
    }, {}));
  };

  var errors = {
    INVALID_NUMBER_OF_PERIOD: 'INVALID_NUMBER_OF_PERIOD',
    DASH_EMPTY_MANIFEST: 'DASH_EMPTY_MANIFEST',
    DASH_INVALID_XML: 'DASH_INVALID_XML',
    NO_BASE_URL: 'NO_BASE_URL',
    MISSING_SEGMENT_INFORMATION: 'MISSING_SEGMENT_INFORMATION',
    SEGMENT_TIME_UNSPECIFIED: 'SEGMENT_TIME_UNSPECIFIED',
    UNSUPPORTED_UTC_TIMING_SCHEME: 'UNSUPPORTED_UTC_TIMING_SCHEME'
  };

  function createCommonjsModule(fn, basedir, module) {
  	return module = {
  	  path: basedir,
  	  exports: {},
  	  require: function (path, base) {
        return commonjsRequire(path, (base === undefined || base === null) ? module.path : base);
      }
  	}, fn(module, module.exports), module.exports;
  }

  function commonjsRequire () {
  	throw new Error('Dynamic requires are not currently supported by @rollup/plugin-commonjs');
  }

  var urlToolkit = createCommonjsModule(function (module, exports) {
    // see https://tools.ietf.org/html/rfc1808
    (function (root) {
      var URL_REGEX = /^((?:[a-zA-Z0-9+\-.]+:)?)(\/\/[^\/?#]*)?((?:[^\/?#]*\/)*[^;?#]*)?(;[^?#]*)?(\?[^#]*)?(#[^]*)?$/;
      var FIRST_SEGMENT_REGEX = /^([^\/?#]*)([^]*)$/;
      var SLASH_DOT_REGEX = /(?:\/|^)\.(?=\/)/g;
      var SLASH_DOT_DOT_REGEX = /(?:\/|^)\.\.\/(?!\.\.\/)[^\/]*(?=\/)/g;
      var URLToolkit = {
        // If opts.alwaysNormalize is true then the path will always be normalized even when it starts with / or //
        // E.g
        // With opts.alwaysNormalize = false (default, spec compliant)
        // http://a.com/b/cd + /e/f/../g => http://a.com/e/f/../g
        // With opts.alwaysNormalize = true (not spec compliant)
        // http://a.com/b/cd + /e/f/../g => http://a.com/e/g
        buildAbsoluteURL: function buildAbsoluteURL(baseURL, relativeURL, opts) {
          opts = opts || {}; // remove any remaining space and CRLF

          baseURL = baseURL.trim();
          relativeURL = relativeURL.trim();

          if (!relativeURL) {
            // 2a) If the embedded URL is entirely empty, it inherits the
            // entire base URL (i.e., is set equal to the base URL)
            // and we are done.
            if (!opts.alwaysNormalize) {
              return baseURL;
            }

            var basePartsForNormalise = URLToolkit.parseURL(baseURL);

            if (!basePartsForNormalise) {
              throw new Error('Error trying to parse base URL.');
            }

            basePartsForNormalise.path = URLToolkit.normalizePath(basePartsForNormalise.path);
            return URLToolkit.buildURLFromParts(basePartsForNormalise);
          }

          var relativeParts = URLToolkit.parseURL(relativeURL);

          if (!relativeParts) {
            throw new Error('Error trying to parse relative URL.');
          }

          if (relativeParts.scheme) {
            // 2b) If the embedded URL starts with a scheme name, it is
            // interpreted as an absolute URL and we are done.
            if (!opts.alwaysNormalize) {
              return relativeURL;
            }

            relativeParts.path = URLToolkit.normalizePath(relativeParts.path);
            return URLToolkit.buildURLFromParts(relativeParts);
          }

          var baseParts = URLToolkit.parseURL(baseURL);

          if (!baseParts) {
            throw new Error('Error trying to parse base URL.');
          }

          if (!baseParts.netLoc && baseParts.path && baseParts.path[0] !== '/') {
            // If netLoc missing and path doesn't start with '/', assume everthing before the first '/' is the netLoc
            // This causes 'example.com/a' to be handled as '//example.com/a' instead of '/example.com/a'
            var pathParts = FIRST_SEGMENT_REGEX.exec(baseParts.path);
            baseParts.netLoc = pathParts[1];
            baseParts.path = pathParts[2];
          }

          if (baseParts.netLoc && !baseParts.path) {
            baseParts.path = '/';
          }

          var builtParts = {
            // 2c) Otherwise, the embedded URL inherits the scheme of
            // the base URL.
            scheme: baseParts.scheme,
            netLoc: relativeParts.netLoc,
            path: null,
            params: relativeParts.params,
            query: relativeParts.query,
            fragment: relativeParts.fragment
          };

          if (!relativeParts.netLoc) {
            // 3) If the embedded URL's <net_loc> is non-empty, we skip to
            // Step 7.  Otherwise, the embedded URL inherits the <net_loc>
            // (if any) of the base URL.
            builtParts.netLoc = baseParts.netLoc; // 4) If the embedded URL path is preceded by a slash "/", the
            // path is not relative and we skip to Step 7.

            if (relativeParts.path[0] !== '/') {
              if (!relativeParts.path) {
                // 5) If the embedded URL path is empty (and not preceded by a
                // slash), then the embedded URL inherits the base URL path
                builtParts.path = baseParts.path; // 5a) if the embedded URL's <params> is non-empty, we skip to
                // step 7; otherwise, it inherits the <params> of the base
                // URL (if any) and

                if (!relativeParts.params) {
                  builtParts.params = baseParts.params; // 5b) if the embedded URL's <query> is non-empty, we skip to
                  // step 7; otherwise, it inherits the <query> of the base
                  // URL (if any) and we skip to step 7.

                  if (!relativeParts.query) {
                    builtParts.query = baseParts.query;
                  }
                }
              } else {
                // 6) The last segment of the base URL's path (anything
                // following the rightmost slash "/", or the entire path if no
                // slash is present) is removed and the embedded URL's path is
                // appended in its place.
                var baseURLPath = baseParts.path;
                var newPath = baseURLPath.substring(0, baseURLPath.lastIndexOf('/') + 1) + relativeParts.path;
                builtParts.path = URLToolkit.normalizePath(newPath);
              }
            }
          }

          if (builtParts.path === null) {
            builtParts.path = opts.alwaysNormalize ? URLToolkit.normalizePath(relativeParts.path) : relativeParts.path;
          }

          return URLToolkit.buildURLFromParts(builtParts);
        },
        parseURL: function parseURL(url) {
          var parts = URL_REGEX.exec(url);

          if (!parts) {
            return null;
          }

          return {
            scheme: parts[1] || '',
            netLoc: parts[2] || '',
            path: parts[3] || '',
            params: parts[4] || '',
            query: parts[5] || '',
            fragment: parts[6] || ''
          };
        },
        normalizePath: function normalizePath(path) {
          // The following operations are
          // then applied, in order, to the new path:
          // 6a) All occurrences of "./", where "." is a complete path
          // segment, are removed.
          // 6b) If the path ends with "." as a complete path segment,
          // that "." is removed.
          path = path.split('').reverse().join('').replace(SLASH_DOT_REGEX, ''); // 6c) All occurrences of "<segment>/../", where <segment> is a
          // complete path segment not equal to "..", are removed.
          // Removal of these path segments is performed iteratively,
          // removing the leftmost matching pattern on each iteration,
          // until no matching pattern remains.
          // 6d) If the path ends with "<segment>/..", where <segment> is a
          // complete path segment not equal to "..", that
          // "<segment>/.." is removed.

          while (path.length !== (path = path.replace(SLASH_DOT_DOT_REGEX, '')).length) {}

          return path.split('').reverse().join('');
        },
        buildURLFromParts: function buildURLFromParts(parts) {
          return parts.scheme + parts.netLoc + parts.path + parts.params + parts.query + parts.fragment;
        }
      };
      module.exports = URLToolkit;
    })();
  });

  var DEFAULT_LOCATION = 'http://example.com';

  var resolveUrl = function resolveUrl(baseUrl, relativeUrl) {
    // return early if we don't need to resolve
    if (/^[a-z]+:/i.test(relativeUrl)) {
      return relativeUrl;
    } // if baseUrl is a data URI, ignore it and resolve everything relative to window.location


    if (/^data:/.test(baseUrl)) {
      baseUrl = window.location && window.location.href || '';
    } // IE11 supports URL but not the URL constructor
    // feature detect the behavior we want


    var nativeURL = typeof window.URL === 'function';
    var protocolLess = /^\/\//.test(baseUrl); // remove location if window.location isn't available (i.e. we're in node)
    // and if baseUrl isn't an absolute url

    var removeLocation = !window.location && !/\/\//i.test(baseUrl); // if the base URL is relative then combine with the current location

    if (nativeURL) {
      baseUrl = new window.URL(baseUrl, window.location || DEFAULT_LOCATION);
    } else if (!/\/\//i.test(baseUrl)) {
      baseUrl = urlToolkit.buildAbsoluteURL(window.location && window.location.href || '', baseUrl);
    }

    if (nativeURL) {
      var newUrl = new URL(relativeUrl, baseUrl); // if we're a protocol-less url, remove the protocol
      // and if we're location-less, remove the location
      // otherwise, return the url unmodified

      if (removeLocation) {
        return newUrl.href.slice(DEFAULT_LOCATION.length);
      } else if (protocolLess) {
        return newUrl.href.slice(newUrl.protocol.length);
      }

      return newUrl.href;
    }

    return urlToolkit.buildAbsoluteURL(baseUrl, relativeUrl);
  };

  /**
   * @typedef {Object} SingleUri
   * @property {string} uri - relative location of segment
   * @property {string} resolvedUri - resolved location of segment
   * @property {Object} byterange - Object containing information on how to make byte range
   *   requests following byte-range-spec per RFC2616.
   * @property {String} byterange.length - length of range request
   * @property {String} byterange.offset - byte offset of range request
   *
   * @see https://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.35.1
   */

  /**
   * Converts a URLType node (5.3.9.2.3 Table 13) to a segment object
   * that conforms to how m3u8-parser is structured
   *
   * @see https://github.com/videojs/m3u8-parser
   *
   * @param {string} baseUrl - baseUrl provided by <BaseUrl> nodes
   * @param {string} source - source url for segment
   * @param {string} range - optional range used for range calls,
   *   follows  RFC 2616, Clause 14.35.1
   * @return {SingleUri} full segment information transformed into a format similar
   *   to m3u8-parser
   */

  var urlTypeToSegment = function urlTypeToSegment(_ref) {
    var _ref$baseUrl = _ref.baseUrl,
        baseUrl = _ref$baseUrl === void 0 ? '' : _ref$baseUrl,
        _ref$source = _ref.source,
        source = _ref$source === void 0 ? '' : _ref$source,
        _ref$range = _ref.range,
        range = _ref$range === void 0 ? '' : _ref$range,
        _ref$indexRange = _ref.indexRange,
        indexRange = _ref$indexRange === void 0 ? '' : _ref$indexRange;
    var segment = {
      uri: source,
      resolvedUri: resolveUrl(baseUrl || '', source)
    };

    if (range || indexRange) {
      var rangeStr = range ? range : indexRange;
      var ranges = rangeStr.split('-'); // default to parsing this as a BigInt if possible

      var startRange = window.BigInt ? window.BigInt(ranges[0]) : parseInt(ranges[0], 10);
      var endRange = window.BigInt ? window.BigInt(ranges[1]) : parseInt(ranges[1], 10); // convert back to a number if less than MAX_SAFE_INTEGER

      if (startRange < Number.MAX_SAFE_INTEGER && typeof startRange === 'bigint') {
        startRange = Number(startRange);
      }

      if (endRange < Number.MAX_SAFE_INTEGER && typeof endRange === 'bigint') {
        endRange = Number(endRange);
      }

      var length;

      if (typeof endRange === 'bigint' || typeof startRange === 'bigint') {
        length = window.BigInt(endRange) - window.BigInt(startRange) + window.BigInt(1);
      } else {
        length = endRange - startRange + 1;
      }

      if (typeof length === 'bigint' && length < Number.MAX_SAFE_INTEGER) {
        length = Number(length);
      } // byterange should be inclusive according to
      // RFC 2616, Clause 14.35.1


      segment.byterange = {
        length: length,
        offset: startRange
      };
    }

    return segment;
  };
  var byteRangeToString = function byteRangeToString(byterange) {
    // `endRange` is one less than `offset + length` because the HTTP range
    // header uses inclusive ranges
    var endRange;

    if (typeof byterange.offset === 'bigint' || typeof byterange.length === 'bigint') {
      endRange = window.BigInt(byterange.offset) + window.BigInt(byterange.length) - window.BigInt(1);
    } else {
      endRange = byterange.offset + byterange.length - 1;
    }

    return byterange.offset + "-" + endRange;
  };

  /**
   * parse the end number attribue that can be a string
   * number, or undefined.
   *
   * @param {string|number|undefined} endNumber
   *        The end number attribute.
   *
   * @return {number|null}
   *          The result of parsing the end number.
   */

  var parseEndNumber = function parseEndNumber(endNumber) {
    if (endNumber && typeof endNumber !== 'number') {
      endNumber = parseInt(endNumber, 10);
    }

    if (isNaN(endNumber)) {
      return null;
    }

    return endNumber;
  };
  /**
   * Functions for calculating the range of available segments in static and dynamic
   * manifests.
   */


  var segmentRange = {
    /**
     * Returns the entire range of available segments for a static MPD
     *
     * @param {Object} attributes
     *        Inheritied MPD attributes
     * @return {{ start: number, end: number }}
     *         The start and end numbers for available segments
     */
    static: function _static(attributes) {
      var duration = attributes.duration,
          _attributes$timescale = attributes.timescale,
          timescale = _attributes$timescale === void 0 ? 1 : _attributes$timescale,
          sourceDuration = attributes.sourceDuration,
          periodDuration = attributes.periodDuration;
      var endNumber = parseEndNumber(attributes.endNumber);
      var segmentDuration = duration / timescale;

      if (typeof endNumber === 'number') {
        return {
          start: 0,
          end: endNumber
        };
      }

      if (typeof periodDuration === 'number') {
        return {
          start: 0,
          end: periodDuration / segmentDuration
        };
      }

      return {
        start: 0,
        end: sourceDuration / segmentDuration
      };
    },

    /**
     * Returns the current live window range of available segments for a dynamic MPD
     *
     * @param {Object} attributes
     *        Inheritied MPD attributes
     * @return {{ start: number, end: number }}
     *         The start and end numbers for available segments
     */
    dynamic: function dynamic(attributes) {
      var NOW = attributes.NOW,
          clientOffset = attributes.clientOffset,
          availabilityStartTime = attributes.availabilityStartTime,
          _attributes$timescale2 = attributes.timescale,
          timescale = _attributes$timescale2 === void 0 ? 1 : _attributes$timescale2,
          duration = attributes.duration,
          _attributes$periodSta = attributes.periodStart,
          periodStart = _attributes$periodSta === void 0 ? 0 : _attributes$periodSta,
          _attributes$minimumUp = attributes.minimumUpdatePeriod,
          minimumUpdatePeriod = _attributes$minimumUp === void 0 ? 0 : _attributes$minimumUp,
          _attributes$timeShift = attributes.timeShiftBufferDepth,
          timeShiftBufferDepth = _attributes$timeShift === void 0 ? Infinity : _attributes$timeShift;
      var endNumber = parseEndNumber(attributes.endNumber); // clientOffset is passed in at the top level of mpd-parser and is an offset calculated
      // after retrieving UTC server time.

      var now = (NOW + clientOffset) / 1000; // WC stands for Wall Clock.
      // Convert the period start time to EPOCH.

      var periodStartWC = availabilityStartTime + periodStart; // Period end in EPOCH is manifest's retrieval time + time until next update.

      var periodEndWC = now + minimumUpdatePeriod;
      var periodDuration = periodEndWC - periodStartWC;
      var segmentCount = Math.ceil(periodDuration * timescale / duration);
      var availableStart = Math.floor((now - periodStartWC - timeShiftBufferDepth) * timescale / duration);
      var availableEnd = Math.floor((now - periodStartWC) * timescale / duration);
      return {
        start: Math.max(0, availableStart),
        end: typeof endNumber === 'number' ? endNumber : Math.min(segmentCount, availableEnd)
      };
    }
  };
  /**
   * Maps a range of numbers to objects with information needed to build the corresponding
   * segment list
   *
   * @name toSegmentsCallback
   * @function
   * @param {number} number
   *        Number of the segment
   * @param {number} index
   *        Index of the number in the range list
   * @return {{ number: Number, duration: Number, timeline: Number, time: Number }}
   *         Object with segment timing and duration info
   */

  /**
   * Returns a callback for Array.prototype.map for mapping a range of numbers to
   * information needed to build the segment list.
   *
   * @param {Object} attributes
   *        Inherited MPD attributes
   * @return {toSegmentsCallback}
   *         Callback map function
   */

  var toSegments = function toSegments(attributes) {
    return function (number) {
      var duration = attributes.duration,
          _attributes$timescale3 = attributes.timescale,
          timescale = _attributes$timescale3 === void 0 ? 1 : _attributes$timescale3,
          periodStart = attributes.periodStart,
          _attributes$startNumb = attributes.startNumber,
          startNumber = _attributes$startNumb === void 0 ? 1 : _attributes$startNumb;
      return {
        number: startNumber + number,
        duration: duration / timescale,
        timeline: periodStart,
        time: number * duration
      };
    };
  };
  /**
   * Returns a list of objects containing segment timing and duration info used for
   * building the list of segments. This uses the @duration attribute specified
   * in the MPD manifest to derive the range of segments.
   *
   * @param {Object} attributes
   *        Inherited MPD attributes
   * @return {{number: number, duration: number, time: number, timeline: number}[]}
   *         List of Objects with segment timing and duration info
   */

  var parseByDuration = function parseByDuration(attributes) {
    var type = attributes.type,
        duration = attributes.duration,
        _attributes$timescale4 = attributes.timescale,
        timescale = _attributes$timescale4 === void 0 ? 1 : _attributes$timescale4,
        periodDuration = attributes.periodDuration,
        sourceDuration = attributes.sourceDuration;

    var _segmentRange$type = segmentRange[type](attributes),
        start = _segmentRange$type.start,
        end = _segmentRange$type.end;

    var segments = range(start, end).map(toSegments(attributes));

    if (type === 'static') {
      var index = segments.length - 1; // section is either a period or the full source

      var sectionDuration = typeof periodDuration === 'number' ? periodDuration : sourceDuration; // final segment may be less than full segment duration

      segments[index].duration = sectionDuration - duration / timescale * index;
    }

    return segments;
  };

  /**
   * Translates SegmentBase into a set of segments.
   * (DASH SPEC Section 5.3.9.3.2) contains a set of <SegmentURL> nodes.  Each
   * node should be translated into segment.
   *
   * @param {Object} attributes
   *   Object containing all inherited attributes from parent elements with attribute
   *   names as keys
   * @return {Object.<Array>} list of segments
   */

  var segmentsFromBase = function segmentsFromBase(attributes) {
    var baseUrl = attributes.baseUrl,
        _attributes$initializ = attributes.initialization,
        initialization = _attributes$initializ === void 0 ? {} : _attributes$initializ,
        sourceDuration = attributes.sourceDuration,
        _attributes$indexRang = attributes.indexRange,
        indexRange = _attributes$indexRang === void 0 ? '' : _attributes$indexRang,
        periodStart = attributes.periodStart,
        presentationTime = attributes.presentationTime,
        _attributes$number = attributes.number,
        number = _attributes$number === void 0 ? 0 : _attributes$number,
        duration = attributes.duration; // base url is required for SegmentBase to work, per spec (Section 5.3.9.2.1)

    if (!baseUrl) {
      throw new Error(errors.NO_BASE_URL);
    }

    var initSegment = urlTypeToSegment({
      baseUrl: baseUrl,
      source: initialization.sourceURL,
      range: initialization.range
    });
    var segment = urlTypeToSegment({
      baseUrl: baseUrl,
      source: baseUrl,
      indexRange: indexRange
    });
    segment.map = initSegment; // If there is a duration, use it, otherwise use the given duration of the source
    // (since SegmentBase is only for one total segment)

    if (duration) {
      var segmentTimeInfo = parseByDuration(attributes);

      if (segmentTimeInfo.length) {
        segment.duration = segmentTimeInfo[0].duration;
        segment.timeline = segmentTimeInfo[0].timeline;
      }
    } else if (sourceDuration) {
      segment.duration = sourceDuration;
      segment.timeline = periodStart;
    } // If presentation time is provided, these segments are being generated by SIDX
    // references, and should use the time provided. For the general case of SegmentBase,
    // there should only be one segment in the period, so its presentation time is the same
    // as its period start.


    segment.presentationTime = presentationTime || periodStart;
    segment.number = number;
    return [segment];
  };
  /**
   * Given a playlist, a sidx box, and a baseUrl, update the segment list of the playlist
   * according to the sidx information given.
   *
   * playlist.sidx has metadadata about the sidx where-as the sidx param
   * is the parsed sidx box itself.
   *
   * @param {Object} playlist the playlist to update the sidx information for
   * @param {Object} sidx the parsed sidx box
   * @return {Object} the playlist object with the updated sidx information
   */

  var addSidxSegmentsToPlaylist$1 = function addSidxSegmentsToPlaylist(playlist, sidx, baseUrl) {
    // Retain init segment information
    var initSegment = playlist.sidx.map ? playlist.sidx.map : null; // Retain source duration from initial main manifest parsing

    var sourceDuration = playlist.sidx.duration; // Retain source timeline

    var timeline = playlist.timeline || 0;
    var sidxByteRange = playlist.sidx.byterange;
    var sidxEnd = sidxByteRange.offset + sidxByteRange.length; // Retain timescale of the parsed sidx

    var timescale = sidx.timescale; // referenceType 1 refers to other sidx boxes

    var mediaReferences = sidx.references.filter(function (r) {
      return r.referenceType !== 1;
    });
    var segments = [];
    var type = playlist.endList ? 'static' : 'dynamic';
    var periodStart = playlist.sidx.timeline;
    var presentationTime = periodStart;
    var number = playlist.mediaSequence || 0; // firstOffset is the offset from the end of the sidx box

    var startIndex; // eslint-disable-next-line

    if (typeof sidx.firstOffset === 'bigint') {
      startIndex = window.BigInt(sidxEnd) + sidx.firstOffset;
    } else {
      startIndex = sidxEnd + sidx.firstOffset;
    }

    for (var i = 0; i < mediaReferences.length; i++) {
      var reference = sidx.references[i]; // size of the referenced (sub)segment

      var size = reference.referencedSize; // duration of the referenced (sub)segment, in  the  timescale
      // this will be converted to seconds when generating segments

      var duration = reference.subsegmentDuration; // should be an inclusive range

      var endIndex = void 0; // eslint-disable-next-line

      if (typeof startIndex === 'bigint') {
        endIndex = startIndex + window.BigInt(size) - window.BigInt(1);
      } else {
        endIndex = startIndex + size - 1;
      }

      var indexRange = startIndex + "-" + endIndex;
      var attributes = {
        baseUrl: baseUrl,
        timescale: timescale,
        timeline: timeline,
        periodStart: periodStart,
        presentationTime: presentationTime,
        number: number,
        duration: duration,
        sourceDuration: sourceDuration,
        indexRange: indexRange,
        type: type
      };
      var segment = segmentsFromBase(attributes)[0];

      if (initSegment) {
        segment.map = initSegment;
      }

      segments.push(segment);

      if (typeof startIndex === 'bigint') {
        startIndex += window.BigInt(size);
      } else {
        startIndex += size;
      }

      presentationTime += duration / timescale;
      number++;
    }

    playlist.segments = segments;
    return playlist;
  };

  /**
   * Loops through all supported media groups in master and calls the provided
   * callback for each group
   *
   * @param {Object} master
   *        The parsed master manifest object
   * @param {string[]} groups
   *        The media groups to call the callback for
   * @param {Function} callback
   *        Callback to call for each media group
   */
  var forEachMediaGroup = function forEachMediaGroup(master, groups, callback) {
    groups.forEach(function (mediaType) {
      for (var groupKey in master.mediaGroups[mediaType]) {
        for (var labelKey in master.mediaGroups[mediaType][groupKey]) {
          var mediaProperties = master.mediaGroups[mediaType][groupKey][labelKey];
          callback(mediaProperties, mediaType, groupKey, labelKey);
        }
      }
    });
  };

  var SUPPORTED_MEDIA_TYPES = ['AUDIO', 'SUBTITLES']; // allow one 60fps frame as leniency (arbitrarily chosen)

  var TIME_FUDGE = 1 / 60;
  /**
   * Given a list of timelineStarts, combines, dedupes, and sorts them.
   *
   * @param {TimelineStart[]} timelineStarts - list of timeline starts
   *
   * @return {TimelineStart[]} the combined and deduped timeline starts
   */

  var getUniqueTimelineStarts = function getUniqueTimelineStarts(timelineStarts) {
    return union(timelineStarts, function (_ref) {
      var timeline = _ref.timeline;
      return timeline;
    }).sort(function (a, b) {
      return a.timeline > b.timeline ? 1 : -1;
    });
  };
  /**
   * Finds the playlist with the matching NAME attribute.
   *
   * @param {Array} playlists - playlists to search through
   * @param {string} name - the NAME attribute to search for
   *
   * @return {Object|null} the matching playlist object, or null
   */

  var findPlaylistWithName = function findPlaylistWithName(playlists, name) {
    for (var i = 0; i < playlists.length; i++) {
      if (playlists[i].attributes.NAME === name) {
        return playlists[i];
      }
    }

    return null;
  };
  /**
   * Gets a flattened array of media group playlists.
   *
   * @param {Object} manifest - the main manifest object
   *
   * @return {Array} the media group playlists
   */

  var getMediaGroupPlaylists = function getMediaGroupPlaylists(manifest) {
    var mediaGroupPlaylists = [];
    forEachMediaGroup(manifest, SUPPORTED_MEDIA_TYPES, function (properties, type, group, label) {
      mediaGroupPlaylists = mediaGroupPlaylists.concat(properties.playlists || []);
    });
    return mediaGroupPlaylists;
  };
  /**
   * Updates the playlist's media sequence numbers.
   *
   * @param {Object} config - options object
   * @param {Object} config.playlist - the playlist to update
   * @param {number} config.mediaSequence - the mediaSequence number to start with
   */

  var updateMediaSequenceForPlaylist = function updateMediaSequenceForPlaylist(_ref2) {
    var playlist = _ref2.playlist,
        mediaSequence = _ref2.mediaSequence;
    playlist.mediaSequence = mediaSequence;
    playlist.segments.forEach(function (segment, index) {
      segment.number = playlist.mediaSequence + index;
    });
  };
  /**
   * Updates the media and discontinuity sequence numbers of newPlaylists given oldPlaylists
   * and a complete list of timeline starts.
   *
   * If no matching playlist is found, only the discontinuity sequence number of the playlist
   * will be updated.
   *
   * Since early available timelines are not supported, at least one segment must be present.
   *
   * @param {Object} config - options object
   * @param {Object[]} oldPlaylists - the old playlists to use as a reference
   * @param {Object[]} newPlaylists - the new playlists to update
   * @param {Object} timelineStarts - all timelineStarts seen in the stream to this point
   */

  var updateSequenceNumbers = function updateSequenceNumbers(_ref3) {
    var oldPlaylists = _ref3.oldPlaylists,
        newPlaylists = _ref3.newPlaylists,
        timelineStarts = _ref3.timelineStarts;
    newPlaylists.forEach(function (playlist) {
      playlist.discontinuitySequence = findIndex(timelineStarts, function (_ref4) {
        var timeline = _ref4.timeline;
        return timeline === playlist.timeline;
      }); // Playlists NAMEs come from DASH Representation IDs, which are mandatory
      // (see ISO_23009-1-2012 5.3.5.2).
      //
      // If the same Representation existed in a prior Period, it will retain the same NAME.

      var oldPlaylist = findPlaylistWithName(oldPlaylists, playlist.attributes.NAME);

      if (!oldPlaylist) {
        // Since this is a new playlist, the media sequence values can start from 0 without
        // consequence.
        return;
      } // TODO better support for live SIDX
      //
      // As of this writing, mpd-parser does not support multiperiod SIDX (in live or VOD).
      // This is evident by a playlist only having a single SIDX reference. In a multiperiod
      // playlist there would need to be multiple SIDX references. In addition, live SIDX is
      // not supported when the SIDX properties change on refreshes.
      //
      // In the future, if support needs to be added, the merging logic here can be called
      // after SIDX references are resolved. For now, exit early to prevent exceptions being
      // thrown due to undefined references.


      if (playlist.sidx) {
        return;
      } // Since we don't yet support early available timelines, we don't need to support
      // playlists with no segments.


      var firstNewSegment = playlist.segments[0];
      var oldMatchingSegmentIndex = findIndex(oldPlaylist.segments, function (oldSegment) {
        return Math.abs(oldSegment.presentationTime - firstNewSegment.presentationTime) < TIME_FUDGE;
      }); // No matching segment from the old playlist means the entire playlist was refreshed.
      // In this case the media sequence should account for this update, and the new segments
      // should be marked as discontinuous from the prior content, since the last prior
      // timeline was removed.

      if (oldMatchingSegmentIndex === -1) {
        updateMediaSequenceForPlaylist({
          playlist: playlist,
          mediaSequence: oldPlaylist.mediaSequence + oldPlaylist.segments.length
        });
        playlist.segments[0].discontinuity = true;
        playlist.discontinuityStarts.unshift(0); // No matching segment does not necessarily mean there's missing content.
        //
        // If the new playlist's timeline is the same as the last seen segment's timeline,
        // then a discontinuity can be added to identify that there's potentially missing
        // content. If there's no missing content, the discontinuity should still be rather
        // harmless. It's possible that if segment durations are accurate enough, that the
        // existence of a gap can be determined using the presentation times and durations,
        // but if the segment timing info is off, it may introduce more problems than simply
        // adding the discontinuity.
        //
        // If the new playlist's timeline is different from the last seen segment's timeline,
        // then a discontinuity can be added to identify that this is the first seen segment
        // of a new timeline. However, the logic at the start of this function that
        // determined the disconinuity sequence by timeline index is now off by one (the
        // discontinuity of the newest timeline hasn't yet fallen off the manifest...since
        // we added it), so the disconinuity sequence must be decremented.
        //
        // A period may also have a duration of zero, so the case of no segments is handled
        // here even though we don't yet support early available periods.

        if (!oldPlaylist.segments.length && playlist.timeline > oldPlaylist.timeline || oldPlaylist.segments.length && playlist.timeline > oldPlaylist.segments[oldPlaylist.segments.length - 1].timeline) {
          playlist.discontinuitySequence--;
        }

        return;
      } // If the first segment matched with a prior segment on a discontinuity (it's matching
      // on the first segment of a period), then the discontinuitySequence shouldn't be the
      // timeline's matching one, but instead should be the one prior, and the first segment
      // of the new manifest should be marked with a discontinuity.
      //
      // The reason for this special case is that discontinuity sequence shows how many
      // discontinuities have fallen off of the playlist, and discontinuities are marked on
      // the first segment of a new "timeline." Because of this, while DASH will retain that
      // Period while the "timeline" exists, HLS keeps track of it via the discontinuity
      // sequence, and that first segment is an indicator, but can be removed before that
      // timeline is gone.


      var oldMatchingSegment = oldPlaylist.segments[oldMatchingSegmentIndex];

      if (oldMatchingSegment.discontinuity && !firstNewSegment.discontinuity) {
        firstNewSegment.discontinuity = true;
        playlist.discontinuityStarts.unshift(0);
        playlist.discontinuitySequence--;
      }

      updateMediaSequenceForPlaylist({
        playlist: playlist,
        mediaSequence: oldPlaylist.segments[oldMatchingSegmentIndex].number
      });
    });
  };
  /**
   * Given an old parsed manifest object and a new parsed manifest object, updates the
   * sequence and timing values within the new manifest to ensure that it lines up with the
   * old.
   *
   * @param {Array} oldManifest - the old main manifest object
   * @param {Array} newManifest - the new main manifest object
   *
   * @return {Object} the updated new manifest object
   */

  var positionManifestOnTimeline = function positionManifestOnTimeline(_ref5) {
    var oldManifest = _ref5.oldManifest,
        newManifest = _ref5.newManifest;
    // Starting from v4.1.2 of the IOP, section 4.4.3.3 states:
    //
    // "MPD@availabilityStartTime and Period@start shall not be changed over MPD updates."
    //
    // This was added from https://github.com/Dash-Industry-Forum/DASH-IF-IOP/issues/160
    //
    // Because of this change, and the difficulty of supporting periods with changing start
    // times, periods with changing start times are not supported. This makes the logic much
    // simpler, since periods with the same start time can be considerred the same period
    // across refreshes.
    //
    // To give an example as to the difficulty of handling periods where the start time may
    // change, if a single period manifest is refreshed with another manifest with a single
    // period, and both the start and end times are increased, then the only way to determine
    // if it's a new period or an old one that has changed is to look through the segments of
    // each playlist and determine the presentation time bounds to find a match. In addition,
    // if the period start changed to exceed the old period end, then there would be no
    // match, and it would not be possible to determine whether the refreshed period is a new
    // one or the old one.
    var oldPlaylists = oldManifest.playlists.concat(getMediaGroupPlaylists(oldManifest));
    var newPlaylists = newManifest.playlists.concat(getMediaGroupPlaylists(newManifest)); // Save all seen timelineStarts to the new manifest. Although this potentially means that
    // there's a "memory leak" in that it will never stop growing, in reality, only a couple
    // of properties are saved for each seen Period. Even long running live streams won't
    // generate too many Periods, unless the stream is watched for decades. In the future,
    // this can be optimized by mapping to discontinuity sequence numbers for each timeline,
    // but it may not become an issue, and the additional info can be useful for debugging.

    newManifest.timelineStarts = getUniqueTimelineStarts([oldManifest.timelineStarts, newManifest.timelineStarts]);
    updateSequenceNumbers({
      oldPlaylists: oldPlaylists,
      newPlaylists: newPlaylists,
      timelineStarts: newManifest.timelineStarts
    });
    return newManifest;
  };

  var generateSidxKey = function generateSidxKey(sidx) {
    return sidx && sidx.uri + '-' + byteRangeToString(sidx.byterange);
  };

  var mergeDiscontiguousPlaylists = function mergeDiscontiguousPlaylists(playlists) {
    var mergedPlaylists = values(playlists.reduce(function (acc, playlist) {
      // assuming playlist IDs are the same across periods
      // TODO: handle multiperiod where representation sets are not the same
      // across periods
      var name = playlist.attributes.id + (playlist.attributes.lang || '');

      if (!acc[name]) {
        // First Period
        acc[name] = playlist;
        acc[name].attributes.timelineStarts = [];
      } else {
        // Subsequent Periods
        if (playlist.segments) {
          var _acc$name$segments;

          // first segment of subsequent periods signal a discontinuity
          if (playlist.segments[0]) {
            playlist.segments[0].discontinuity = true;
          }

          (_acc$name$segments = acc[name].segments).push.apply(_acc$name$segments, playlist.segments);
        } // bubble up contentProtection, this assumes all DRM content
        // has the same contentProtection


        if (playlist.attributes.contentProtection) {
          acc[name].attributes.contentProtection = playlist.attributes.contentProtection;
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
    return mergedPlaylists.map(function (playlist) {
      playlist.discontinuityStarts = findIndexes(playlist.segments || [], 'discontinuity');
      return playlist;
    });
  };

  var addSidxSegmentsToPlaylist = function addSidxSegmentsToPlaylist(playlist, sidxMapping) {
    var sidxKey = generateSidxKey(playlist.sidx);
    var sidxMatch = sidxKey && sidxMapping[sidxKey] && sidxMapping[sidxKey].sidx;

    if (sidxMatch) {
      addSidxSegmentsToPlaylist$1(playlist, sidxMatch, playlist.sidx.resolvedUri);
    }

    return playlist;
  };
  var addSidxSegmentsToPlaylists = function addSidxSegmentsToPlaylists(playlists, sidxMapping) {
    if (sidxMapping === void 0) {
      sidxMapping = {};
    }

    if (!Object.keys(sidxMapping).length) {
      return playlists;
    }

    for (var i in playlists) {
      playlists[i] = addSidxSegmentsToPlaylist(playlists[i], sidxMapping);
    }

    return playlists;
  };
  var formatAudioPlaylist = function formatAudioPlaylist(_ref, isAudioOnly) {
    var _attributes;

    var attributes = _ref.attributes,
        segments = _ref.segments,
        sidx = _ref.sidx,
        mediaSequence = _ref.mediaSequence,
        discontinuitySequence = _ref.discontinuitySequence,
        discontinuityStarts = _ref.discontinuityStarts;
    var playlist = {
      attributes: (_attributes = {
        NAME: attributes.id,
        BANDWIDTH: attributes.bandwidth,
        CODECS: attributes.codecs
      }, _attributes['PROGRAM-ID'] = 1, _attributes),
      uri: '',
      endList: attributes.type === 'static',
      timeline: attributes.periodStart,
      resolvedUri: '',
      targetDuration: attributes.duration,
      discontinuitySequence: discontinuitySequence,
      discontinuityStarts: discontinuityStarts,
      timelineStarts: attributes.timelineStarts,
      mediaSequence: mediaSequence,
      segments: segments
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
  var formatVttPlaylist = function formatVttPlaylist(_ref2) {
    var _m3u8Attributes;

    var attributes = _ref2.attributes,
        segments = _ref2.segments,
        mediaSequence = _ref2.mediaSequence,
        discontinuityStarts = _ref2.discontinuityStarts,
        discontinuitySequence = _ref2.discontinuitySequence;

    if (typeof segments === 'undefined') {
      // vtt tracks may use single file in BaseURL
      segments = [{
        uri: attributes.baseUrl,
        timeline: attributes.periodStart,
        resolvedUri: attributes.baseUrl || '',
        duration: attributes.sourceDuration,
        number: 0
      }]; // targetDuration should be the same duration as the only segment

      attributes.duration = attributes.sourceDuration;
    }

    var m3u8Attributes = (_m3u8Attributes = {
      NAME: attributes.id,
      BANDWIDTH: attributes.bandwidth
    }, _m3u8Attributes['PROGRAM-ID'] = 1, _m3u8Attributes);

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
      discontinuityStarts: discontinuityStarts,
      discontinuitySequence: discontinuitySequence,
      mediaSequence: mediaSequence,
      segments: segments
    };
  };
  var organizeAudioPlaylists = function organizeAudioPlaylists(playlists, sidxMapping, isAudioOnly) {
    if (sidxMapping === void 0) {
      sidxMapping = {};
    }

    if (isAudioOnly === void 0) {
      isAudioOnly = false;
    }

    var mainPlaylist;
    var formattedPlaylists = playlists.reduce(function (a, playlist) {
      var role = playlist.attributes.role && playlist.attributes.role.value || '';
      var language = playlist.attributes.lang || '';
      var label = playlist.attributes.label || 'main';

      if (language && !playlist.attributes.label) {
        var roleLabel = role ? " (" + role + ")" : '';
        label = "" + playlist.attributes.lang + roleLabel;
      }

      if (!a[label]) {
        a[label] = {
          language: language,
          autoselect: true,
          default: role === 'main',
          playlists: [],
          uri: ''
        };
      }

      var formatted = addSidxSegmentsToPlaylist(formatAudioPlaylist(playlist, isAudioOnly), sidxMapping);
      a[label].playlists.push(formatted);

      if (typeof mainPlaylist === 'undefined' && role === 'main') {
        mainPlaylist = playlist;
        mainPlaylist.default = true;
      }

      return a;
    }, {}); // if no playlists have role "main", mark the first as main

    if (!mainPlaylist) {
      var firstLabel = Object.keys(formattedPlaylists)[0];
      formattedPlaylists[firstLabel].default = true;
    }

    return formattedPlaylists;
  };
  var organizeVttPlaylists = function organizeVttPlaylists(playlists, sidxMapping) {
    if (sidxMapping === void 0) {
      sidxMapping = {};
    }

    return playlists.reduce(function (a, playlist) {
      var label = playlist.attributes.lang || 'text';

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

  var organizeCaptionServices = function organizeCaptionServices(captionServices) {
    return captionServices.reduce(function (svcObj, svc) {
      if (!svc) {
        return svcObj;
      }

      svc.forEach(function (service) {
        var channel = service.channel,
            language = service.language;
        svcObj[language] = {
          autoselect: false,
          default: false,
          instreamId: channel,
          language: language
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
  };

  var formatVideoPlaylist = function formatVideoPlaylist(_ref3) {
    var _attributes2;

    var attributes = _ref3.attributes,
        segments = _ref3.segments,
        sidx = _ref3.sidx,
        discontinuityStarts = _ref3.discontinuityStarts;
    var playlist = {
      attributes: (_attributes2 = {
        NAME: attributes.id,
        AUDIO: 'audio',
        SUBTITLES: 'subs',
        RESOLUTION: {
          width: attributes.width,
          height: attributes.height
        },
        CODECS: attributes.codecs,
        BANDWIDTH: attributes.bandwidth
      }, _attributes2['PROGRAM-ID'] = 1, _attributes2),
      uri: '',
      endList: attributes.type === 'static',
      timeline: attributes.periodStart,
      resolvedUri: '',
      targetDuration: attributes.duration,
      discontinuityStarts: discontinuityStarts,
      timelineStarts: attributes.timelineStarts,
      segments: segments
    };

    if (attributes.contentProtection) {
      playlist.contentProtection = attributes.contentProtection;
    }

    if (sidx) {
      playlist.sidx = sidx;
    }

    return playlist;
  };

  var videoOnly = function videoOnly(_ref4) {
    var attributes = _ref4.attributes;
    return attributes.mimeType === 'video/mp4' || attributes.mimeType === 'video/webm' || attributes.contentType === 'video';
  };

  var audioOnly = function audioOnly(_ref5) {
    var attributes = _ref5.attributes;
    return attributes.mimeType === 'audio/mp4' || attributes.mimeType === 'audio/webm' || attributes.contentType === 'audio';
  };

  var vttOnly = function vttOnly(_ref6) {
    var attributes = _ref6.attributes;
    return attributes.mimeType === 'text/vtt' || attributes.contentType === 'text';
  };
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


  var addMediaSequenceValues = function addMediaSequenceValues(playlists, timelineStarts) {
    // increment all segments sequentially
    playlists.forEach(function (playlist) {
      playlist.mediaSequence = 0;
      playlist.discontinuitySequence = findIndex(timelineStarts, function (_ref7) {
        var timeline = _ref7.timeline;
        return timeline === playlist.timeline;
      });

      if (!playlist.segments) {
        return;
      }

      playlist.segments.forEach(function (segment, index) {
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

  var flattenMediaGroupPlaylists = function flattenMediaGroupPlaylists(mediaGroupObject) {
    if (!mediaGroupObject) {
      return [];
    }

    return Object.keys(mediaGroupObject).reduce(function (acc, label) {
      var labelContents = mediaGroupObject[label];
      return acc.concat(labelContents.playlists);
    }, []);
  };
  var toM3u8 = function toM3u8(_ref8) {
    var _mediaGroups;

    var dashPlaylists = _ref8.dashPlaylists,
        locations = _ref8.locations,
        _ref8$sidxMapping = _ref8.sidxMapping,
        sidxMapping = _ref8$sidxMapping === void 0 ? {} : _ref8$sidxMapping,
        previousManifest = _ref8.previousManifest;

    if (!dashPlaylists.length) {
      return {};
    } // grab all main manifest attributes


    var _dashPlaylists$0$attr = dashPlaylists[0].attributes,
        duration = _dashPlaylists$0$attr.sourceDuration,
        type = _dashPlaylists$0$attr.type,
        suggestedPresentationDelay = _dashPlaylists$0$attr.suggestedPresentationDelay,
        minimumUpdatePeriod = _dashPlaylists$0$attr.minimumUpdatePeriod;
    var videoPlaylists = mergeDiscontiguousPlaylists(dashPlaylists.filter(videoOnly)).map(formatVideoPlaylist);
    var audioPlaylists = mergeDiscontiguousPlaylists(dashPlaylists.filter(audioOnly));
    var vttPlaylists = mergeDiscontiguousPlaylists(dashPlaylists.filter(vttOnly));
    var captions = dashPlaylists.map(function (playlist) {
      return playlist.attributes.captionServices;
    }).filter(Boolean);
    var manifest = {
      allowCache: true,
      discontinuityStarts: [],
      segments: [],
      endList: true,
      mediaGroups: (_mediaGroups = {
        AUDIO: {},
        VIDEO: {}
      }, _mediaGroups['CLOSED-CAPTIONS'] = {}, _mediaGroups.SUBTITLES = {}, _mediaGroups),
      uri: '',
      duration: duration,
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

    var isAudioOnly = manifest.playlists.length === 0;
    var organizedAudioGroup = audioPlaylists.length ? organizeAudioPlaylists(audioPlaylists, sidxMapping, isAudioOnly) : null;
    var organizedVttGroup = vttPlaylists.length ? organizeVttPlaylists(vttPlaylists, sidxMapping) : null;
    var formattedPlaylists = videoPlaylists.concat(flattenMediaGroupPlaylists(organizedAudioGroup), flattenMediaGroupPlaylists(organizedVttGroup));
    var playlistTimelineStarts = formattedPlaylists.map(function (_ref9) {
      var timelineStarts = _ref9.timelineStarts;
      return timelineStarts;
    });
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

  /**
   * Calculates the R (repetition) value for a live stream (for the final segment
   * in a manifest where the r value is negative 1)
   *
   * @param {Object} attributes
   *        Object containing all inherited attributes from parent elements with attribute
   *        names as keys
   * @param {number} time
   *        current time (typically the total time up until the final segment)
   * @param {number} duration
   *        duration property for the given <S />
   *
   * @return {number}
   *        R value to reach the end of the given period
   */
  var getLiveRValue = function getLiveRValue(attributes, time, duration) {
    var NOW = attributes.NOW,
        clientOffset = attributes.clientOffset,
        availabilityStartTime = attributes.availabilityStartTime,
        _attributes$timescale = attributes.timescale,
        timescale = _attributes$timescale === void 0 ? 1 : _attributes$timescale,
        _attributes$periodSta = attributes.periodStart,
        periodStart = _attributes$periodSta === void 0 ? 0 : _attributes$periodSta,
        _attributes$minimumUp = attributes.minimumUpdatePeriod,
        minimumUpdatePeriod = _attributes$minimumUp === void 0 ? 0 : _attributes$minimumUp;
    var now = (NOW + clientOffset) / 1000;
    var periodStartWC = availabilityStartTime + periodStart;
    var periodEndWC = now + minimumUpdatePeriod;
    var periodDuration = periodEndWC - periodStartWC;
    return Math.ceil((periodDuration * timescale - time) / duration);
  };
  /**
   * Uses information provided by SegmentTemplate.SegmentTimeline to determine segment
   * timing and duration
   *
   * @param {Object} attributes
   *        Object containing all inherited attributes from parent elements with attribute
   *        names as keys
   * @param {Object[]} segmentTimeline
   *        List of objects representing the attributes of each S element contained within
   *
   * @return {{number: number, duration: number, time: number, timeline: number}[]}
   *         List of Objects with segment timing and duration info
   */


  var parseByTimeline = function parseByTimeline(attributes, segmentTimeline) {
    var type = attributes.type,
        _attributes$minimumUp2 = attributes.minimumUpdatePeriod,
        minimumUpdatePeriod = _attributes$minimumUp2 === void 0 ? 0 : _attributes$minimumUp2,
        _attributes$media = attributes.media,
        media = _attributes$media === void 0 ? '' : _attributes$media,
        sourceDuration = attributes.sourceDuration,
        _attributes$timescale2 = attributes.timescale,
        timescale = _attributes$timescale2 === void 0 ? 1 : _attributes$timescale2,
        _attributes$startNumb = attributes.startNumber,
        startNumber = _attributes$startNumb === void 0 ? 1 : _attributes$startNumb,
        timeline = attributes.periodStart;
    var segments = [];
    var time = -1;

    for (var sIndex = 0; sIndex < segmentTimeline.length; sIndex++) {
      var S = segmentTimeline[sIndex];
      var duration = S.d;
      var repeat = S.r || 0;
      var segmentTime = S.t || 0;

      if (time < 0) {
        // first segment
        time = segmentTime;
      }

      if (segmentTime && segmentTime > time) {
        // discontinuity
        // TODO: How to handle this type of discontinuity
        // timeline++ here would treat it like HLS discontuity and content would
        // get appended without gap
        // E.G.
        //  <S t="0" d="1" />
        //  <S d="1" />
        //  <S d="1" />
        //  <S t="5" d="1" />
        // would have $Time$ values of [0, 1, 2, 5]
        // should this be appened at time positions [0, 1, 2, 3],(#EXT-X-DISCONTINUITY)
        // or [0, 1, 2, gap, gap, 5]? (#EXT-X-GAP)
        // does the value of sourceDuration consider this when calculating arbitrary
        // negative @r repeat value?
        // E.G. Same elements as above with this added at the end
        //  <S d="1" r="-1" />
        //  with a sourceDuration of 10
        // Would the 2 gaps be included in the time duration calculations resulting in
        // 8 segments with $Time$ values of [0, 1, 2, 5, 6, 7, 8, 9] or 10 segments
        // with $Time$ values of [0, 1, 2, 5, 6, 7, 8, 9, 10, 11] ?
        time = segmentTime;
      }

      var count = void 0;

      if (repeat < 0) {
        var nextS = sIndex + 1;

        if (nextS === segmentTimeline.length) {
          // last segment
          if (type === 'dynamic' && minimumUpdatePeriod > 0 && media.indexOf('$Number$') > 0) {
            count = getLiveRValue(attributes, time, duration);
          } else {
            // TODO: This may be incorrect depending on conclusion of TODO above
            count = (sourceDuration * timescale - time) / duration;
          }
        } else {
          count = (segmentTimeline[nextS].t - time) / duration;
        }
      } else {
        count = repeat + 1;
      }

      var end = startNumber + segments.length + count;
      var number = startNumber + segments.length;

      while (number < end) {
        segments.push({
          number: number,
          duration: duration / timescale,
          time: time,
          timeline: timeline
        });
        time += duration;
        number++;
      }
    }

    return segments;
  };

  var identifierPattern = /\$([A-z]*)(?:(%0)([0-9]+)d)?\$/g;
  /**
   * Replaces template identifiers with corresponding values. To be used as the callback
   * for String.prototype.replace
   *
   * @name replaceCallback
   * @function
   * @param {string} match
   *        Entire match of identifier
   * @param {string} identifier
   *        Name of matched identifier
   * @param {string} format
   *        Format tag string. Its presence indicates that padding is expected
   * @param {string} width
   *        Desired length of the replaced value. Values less than this width shall be left
   *        zero padded
   * @return {string}
   *         Replacement for the matched identifier
   */

  /**
   * Returns a function to be used as a callback for String.prototype.replace to replace
   * template identifiers
   *
   * @param {Obect} values
   *        Object containing values that shall be used to replace known identifiers
   * @param {number} values.RepresentationID
   *        Value of the Representation@id attribute
   * @param {number} values.Number
   *        Number of the corresponding segment
   * @param {number} values.Bandwidth
   *        Value of the Representation@bandwidth attribute.
   * @param {number} values.Time
   *        Timestamp value of the corresponding segment
   * @return {replaceCallback}
   *         Callback to be used with String.prototype.replace to replace identifiers
   */

  var identifierReplacement = function identifierReplacement(values) {
    return function (match, identifier, format, width) {
      if (match === '$$') {
        // escape sequence
        return '$';
      }

      if (typeof values[identifier] === 'undefined') {
        return match;
      }

      var value = '' + values[identifier];

      if (identifier === 'RepresentationID') {
        // Format tag shall not be present with RepresentationID
        return value;
      }

      if (!format) {
        width = 1;
      } else {
        width = parseInt(width, 10);
      }

      if (value.length >= width) {
        return value;
      }

      return "" + new Array(width - value.length + 1).join('0') + value;
    };
  };
  /**
   * Constructs a segment url from a template string
   *
   * @param {string} url
   *        Template string to construct url from
   * @param {Obect} values
   *        Object containing values that shall be used to replace known identifiers
   * @param {number} values.RepresentationID
   *        Value of the Representation@id attribute
   * @param {number} values.Number
   *        Number of the corresponding segment
   * @param {number} values.Bandwidth
   *        Value of the Representation@bandwidth attribute.
   * @param {number} values.Time
   *        Timestamp value of the corresponding segment
   * @return {string}
   *         Segment url with identifiers replaced
   */

  var constructTemplateUrl = function constructTemplateUrl(url, values) {
    return url.replace(identifierPattern, identifierReplacement(values));
  };
  /**
   * Generates a list of objects containing timing and duration information about each
   * segment needed to generate segment uris and the complete segment object
   *
   * @param {Object} attributes
   *        Object containing all inherited attributes from parent elements with attribute
   *        names as keys
   * @param {Object[]|undefined} segmentTimeline
   *        List of objects representing the attributes of each S element contained within
   *        the SegmentTimeline element
   * @return {{number: number, duration: number, time: number, timeline: number}[]}
   *         List of Objects with segment timing and duration info
   */

  var parseTemplateInfo = function parseTemplateInfo(attributes, segmentTimeline) {
    if (!attributes.duration && !segmentTimeline) {
      // if neither @duration or SegmentTimeline are present, then there shall be exactly
      // one media segment
      return [{
        number: attributes.startNumber || 1,
        duration: attributes.sourceDuration,
        time: 0,
        timeline: attributes.periodStart
      }];
    }

    if (attributes.duration) {
      return parseByDuration(attributes);
    }

    return parseByTimeline(attributes, segmentTimeline);
  };
  /**
   * Generates a list of segments using information provided by the SegmentTemplate element
   *
   * @param {Object} attributes
   *        Object containing all inherited attributes from parent elements with attribute
   *        names as keys
   * @param {Object[]|undefined} segmentTimeline
   *        List of objects representing the attributes of each S element contained within
   *        the SegmentTimeline element
   * @return {Object[]}
   *         List of segment objects
   */

  var segmentsFromTemplate = function segmentsFromTemplate(attributes, segmentTimeline) {
    var templateValues = {
      RepresentationID: attributes.id,
      Bandwidth: attributes.bandwidth || 0
    };
    var _attributes$initializ = attributes.initialization,
        initialization = _attributes$initializ === void 0 ? {
      sourceURL: '',
      range: ''
    } : _attributes$initializ;
    var mapSegment = urlTypeToSegment({
      baseUrl: attributes.baseUrl,
      source: constructTemplateUrl(initialization.sourceURL, templateValues),
      range: initialization.range
    });
    var segments = parseTemplateInfo(attributes, segmentTimeline);
    return segments.map(function (segment) {
      templateValues.Number = segment.number;
      templateValues.Time = segment.time;
      var uri = constructTemplateUrl(attributes.media || '', templateValues); // See DASH spec section 5.3.9.2.2
      // - if timescale isn't present on any level, default to 1.

      var timescale = attributes.timescale || 1; // - if presentationTimeOffset isn't present on any level, default to 0

      var presentationTimeOffset = attributes.presentationTimeOffset || 0;
      var presentationTime = // Even if the @t attribute is not specified for the segment, segment.time is
      // calculated in mpd-parser prior to this, so it's assumed to be available.
      attributes.periodStart + (segment.time - presentationTimeOffset) / timescale;
      var map = {
        uri: uri,
        timeline: segment.timeline,
        duration: segment.duration,
        resolvedUri: resolveUrl(attributes.baseUrl || '', uri),
        map: mapSegment,
        number: segment.number,
        presentationTime: presentationTime
      };
      return map;
    });
  };

  /**
   * Converts a <SegmentUrl> (of type URLType from the DASH spec 5.3.9.2 Table 14)
   * to an object that matches the output of a segment in videojs/mpd-parser
   *
   * @param {Object} attributes
   *   Object containing all inherited attributes from parent elements with attribute
   *   names as keys
   * @param {Object} segmentUrl
   *   <SegmentURL> node to translate into a segment object
   * @return {Object} translated segment object
   */

  var SegmentURLToSegmentObject = function SegmentURLToSegmentObject(attributes, segmentUrl) {
    var baseUrl = attributes.baseUrl,
        _attributes$initializ = attributes.initialization,
        initialization = _attributes$initializ === void 0 ? {} : _attributes$initializ;
    var initSegment = urlTypeToSegment({
      baseUrl: baseUrl,
      source: initialization.sourceURL,
      range: initialization.range
    });
    var segment = urlTypeToSegment({
      baseUrl: baseUrl,
      source: segmentUrl.media,
      range: segmentUrl.mediaRange
    });
    segment.map = initSegment;
    return segment;
  };
  /**
   * Generates a list of segments using information provided by the SegmentList element
   * SegmentList (DASH SPEC Section 5.3.9.3.2) contains a set of <SegmentURL> nodes.  Each
   * node should be translated into segment.
   *
   * @param {Object} attributes
   *   Object containing all inherited attributes from parent elements with attribute
   *   names as keys
   * @param {Object[]|undefined} segmentTimeline
   *        List of objects representing the attributes of each S element contained within
   *        the SegmentTimeline element
   * @return {Object.<Array>} list of segments
   */


  var segmentsFromList = function segmentsFromList(attributes, segmentTimeline) {
    var duration = attributes.duration,
        _attributes$segmentUr = attributes.segmentUrls,
        segmentUrls = _attributes$segmentUr === void 0 ? [] : _attributes$segmentUr,
        periodStart = attributes.periodStart; // Per spec (5.3.9.2.1) no way to determine segment duration OR
    // if both SegmentTimeline and @duration are defined, it is outside of spec.

    if (!duration && !segmentTimeline || duration && segmentTimeline) {
      throw new Error(errors.SEGMENT_TIME_UNSPECIFIED);
    }

    var segmentUrlMap = segmentUrls.map(function (segmentUrlObject) {
      return SegmentURLToSegmentObject(attributes, segmentUrlObject);
    });
    var segmentTimeInfo;

    if (duration) {
      segmentTimeInfo = parseByDuration(attributes);
    }

    if (segmentTimeline) {
      segmentTimeInfo = parseByTimeline(attributes, segmentTimeline);
    }

    var segments = segmentTimeInfo.map(function (segmentTime, index) {
      if (segmentUrlMap[index]) {
        var segment = segmentUrlMap[index]; // See DASH spec section 5.3.9.2.2
        // - if timescale isn't present on any level, default to 1.

        var timescale = attributes.timescale || 1; // - if presentationTimeOffset isn't present on any level, default to 0

        var presentationTimeOffset = attributes.presentationTimeOffset || 0;
        segment.timeline = segmentTime.timeline;
        segment.duration = segmentTime.duration;
        segment.number = segmentTime.number;
        segment.presentationTime = periodStart + (segmentTime.time - presentationTimeOffset) / timescale;
        return segment;
      } // Since we're mapping we should get rid of any blank segments (in case
      // the given SegmentTimeline is handling for more elements than we have
      // SegmentURLs for).

    }).filter(function (segment) {
      return segment;
    });
    return segments;
  };

  var generateSegments = function generateSegments(_ref) {
    var attributes = _ref.attributes,
        segmentInfo = _ref.segmentInfo;
    var segmentAttributes;
    var segmentsFn;

    if (segmentInfo.template) {
      segmentsFn = segmentsFromTemplate;
      segmentAttributes = merge(attributes, segmentInfo.template);
    } else if (segmentInfo.base) {
      segmentsFn = segmentsFromBase;
      segmentAttributes = merge(attributes, segmentInfo.base);
    } else if (segmentInfo.list) {
      segmentsFn = segmentsFromList;
      segmentAttributes = merge(attributes, segmentInfo.list);
    }

    var segmentsInfo = {
      attributes: attributes
    };

    if (!segmentsFn) {
      return segmentsInfo;
    }

    var segments = segmentsFn(segmentAttributes, segmentInfo.segmentTimeline); // The @duration attribute will be used to determin the playlist's targetDuration which
    // must be in seconds. Since we've generated the segment list, we no longer need
    // @duration to be in @timescale units, so we can convert it here.

    if (segmentAttributes.duration) {
      var _segmentAttributes = segmentAttributes,
          duration = _segmentAttributes.duration,
          _segmentAttributes$ti = _segmentAttributes.timescale,
          timescale = _segmentAttributes$ti === void 0 ? 1 : _segmentAttributes$ti;
      segmentAttributes.duration = duration / timescale;
    } else if (segments.length) {
      // if there is no @duration attribute, use the largest segment duration as
      // as target duration
      segmentAttributes.duration = segments.reduce(function (max, segment) {
        return Math.max(max, Math.ceil(segment.duration));
      }, 0);
    } else {
      segmentAttributes.duration = 0;
    }

    segmentsInfo.attributes = segmentAttributes;
    segmentsInfo.segments = segments; // This is a sidx box without actual segment information

    if (segmentInfo.base && segmentAttributes.indexRange) {
      segmentsInfo.sidx = segments[0];
      segmentsInfo.segments = [];
    }

    return segmentsInfo;
  };
  var toPlaylists = function toPlaylists(representations) {
    return representations.map(generateSegments);
  };

  var findChildren = function findChildren(element, name) {
    return from(element.childNodes).filter(function (_ref) {
      var tagName = _ref.tagName;
      return tagName === name;
    });
  };
  var getContent = function getContent(element) {
    return element.textContent.trim();
  };

  var parseDuration = function parseDuration(str) {
    var SECONDS_IN_YEAR = 365 * 24 * 60 * 60;
    var SECONDS_IN_MONTH = 30 * 24 * 60 * 60;
    var SECONDS_IN_DAY = 24 * 60 * 60;
    var SECONDS_IN_HOUR = 60 * 60;
    var SECONDS_IN_MIN = 60; // P10Y10M10DT10H10M10.1S

    var durationRegex = /P(?:(\d*)Y)?(?:(\d*)M)?(?:(\d*)D)?(?:T(?:(\d*)H)?(?:(\d*)M)?(?:([\d.]*)S)?)?/;
    var match = durationRegex.exec(str);

    if (!match) {
      return 0;
    }

    var _match$slice = match.slice(1),
        year = _match$slice[0],
        month = _match$slice[1],
        day = _match$slice[2],
        hour = _match$slice[3],
        minute = _match$slice[4],
        second = _match$slice[5];

    return parseFloat(year || 0) * SECONDS_IN_YEAR + parseFloat(month || 0) * SECONDS_IN_MONTH + parseFloat(day || 0) * SECONDS_IN_DAY + parseFloat(hour || 0) * SECONDS_IN_HOUR + parseFloat(minute || 0) * SECONDS_IN_MIN + parseFloat(second || 0);
  };
  var parseDate = function parseDate(str) {
    // Date format without timezone according to ISO 8601
    // YYY-MM-DDThh:mm:ss.ssssss
    var dateRegex = /^\d+-\d+-\d+T\d+:\d+:\d+(\.\d+)?$/; // If the date string does not specifiy a timezone, we must specifiy UTC. This is
    // expressed by ending with 'Z'

    if (dateRegex.test(str)) {
      str += 'Z';
    }

    return Date.parse(str);
  };

  var parsers = {
    /**
     * Specifies the duration of the entire Media Presentation. Format is a duration string
     * as specified in ISO 8601
     *
     * @param {string} value
     *        value of attribute as a string
     * @return {number}
     *         The duration in seconds
     */
    mediaPresentationDuration: function mediaPresentationDuration(value) {
      return parseDuration(value);
    },

    /**
     * Specifies the Segment availability start time for all Segments referred to in this
     * MPD. For a dynamic manifest, it specifies the anchor for the earliest availability
     * time. Format is a date string as specified in ISO 8601
     *
     * @param {string} value
     *        value of attribute as a string
     * @return {number}
     *         The date as seconds from unix epoch
     */
    availabilityStartTime: function availabilityStartTime(value) {
      return parseDate(value) / 1000;
    },

    /**
     * Specifies the smallest period between potential changes to the MPD. Format is a
     * duration string as specified in ISO 8601
     *
     * @param {string} value
     *        value of attribute as a string
     * @return {number}
     *         The duration in seconds
     */
    minimumUpdatePeriod: function minimumUpdatePeriod(value) {
      return parseDuration(value);
    },

    /**
     * Specifies the suggested presentation delay. Format is a
     * duration string as specified in ISO 8601
     *
     * @param {string} value
     *        value of attribute as a string
     * @return {number}
     *         The duration in seconds
     */
    suggestedPresentationDelay: function suggestedPresentationDelay(value) {
      return parseDuration(value);
    },

    /**
     * specifices the type of mpd. Can be either "static" or "dynamic"
     *
     * @param {string} value
     *        value of attribute as a string
     *
     * @return {string}
     *         The type as a string
     */
    type: function type(value) {
      return value;
    },

    /**
     * Specifies the duration of the smallest time shifting buffer for any Representation
     * in the MPD. Format is a duration string as specified in ISO 8601
     *
     * @param {string} value
     *        value of attribute as a string
     * @return {number}
     *         The duration in seconds
     */
    timeShiftBufferDepth: function timeShiftBufferDepth(value) {
      return parseDuration(value);
    },

    /**
     * Specifies the PeriodStart time of the Period relative to the availabilityStarttime.
     * Format is a duration string as specified in ISO 8601
     *
     * @param {string} value
     *        value of attribute as a string
     * @return {number}
     *         The duration in seconds
     */
    start: function start(value) {
      return parseDuration(value);
    },

    /**
     * Specifies the width of the visual presentation
     *
     * @param {string} value
     *        value of attribute as a string
     * @return {number}
     *         The parsed width
     */
    width: function width(value) {
      return parseInt(value, 10);
    },

    /**
     * Specifies the height of the visual presentation
     *
     * @param {string} value
     *        value of attribute as a string
     * @return {number}
     *         The parsed height
     */
    height: function height(value) {
      return parseInt(value, 10);
    },

    /**
     * Specifies the bitrate of the representation
     *
     * @param {string} value
     *        value of attribute as a string
     * @return {number}
     *         The parsed bandwidth
     */
    bandwidth: function bandwidth(value) {
      return parseInt(value, 10);
    },

    /**
     * Specifies the number of the first Media Segment in this Representation in the Period
     *
     * @param {string} value
     *        value of attribute as a string
     * @return {number}
     *         The parsed number
     */
    startNumber: function startNumber(value) {
      return parseInt(value, 10);
    },

    /**
     * Specifies the timescale in units per seconds
     *
     * @param {string} value
     *        value of attribute as a string
     * @return {number}
     *         The parsed timescale
     */
    timescale: function timescale(value) {
      return parseInt(value, 10);
    },

    /**
     * Specifies the presentationTimeOffset.
     *
     * @param {string} value
     *        value of the attribute as a string
     *
     * @return {number}
     *         The parsed presentationTimeOffset
     */
    presentationTimeOffset: function presentationTimeOffset(value) {
      return parseInt(value, 10);
    },

    /**
     * Specifies the constant approximate Segment duration
     * NOTE: The <Period> element also contains an @duration attribute. This duration
     *       specifies the duration of the Period. This attribute is currently not
     *       supported by the rest of the parser, however we still check for it to prevent
     *       errors.
     *
     * @param {string} value
     *        value of attribute as a string
     * @return {number}
     *         The parsed duration
     */
    duration: function duration(value) {
      var parsedValue = parseInt(value, 10);

      if (isNaN(parsedValue)) {
        return parseDuration(value);
      }

      return parsedValue;
    },

    /**
     * Specifies the Segment duration, in units of the value of the @timescale.
     *
     * @param {string} value
     *        value of attribute as a string
     * @return {number}
     *         The parsed duration
     */
    d: function d(value) {
      return parseInt(value, 10);
    },

    /**
     * Specifies the MPD start time, in @timescale units, the first Segment in the series
     * starts relative to the beginning of the Period
     *
     * @param {string} value
     *        value of attribute as a string
     * @return {number}
     *         The parsed time
     */
    t: function t(value) {
      return parseInt(value, 10);
    },

    /**
     * Specifies the repeat count of the number of following contiguous Segments with the
     * same duration expressed by the value of @d
     *
     * @param {string} value
     *        value of attribute as a string
     * @return {number}
     *         The parsed number
     */
    r: function r(value) {
      return parseInt(value, 10);
    },

    /**
     * Default parser for all other attributes. Acts as a no-op and just returns the value
     * as a string
     *
     * @param {string} value
     *        value of attribute as a string
     * @return {string}
     *         Unparsed value
     */
    DEFAULT: function DEFAULT(value) {
      return value;
    }
  };
  /**
   * Gets all the attributes and values of the provided node, parses attributes with known
   * types, and returns an object with attribute names mapped to values.
   *
   * @param {Node} el
   *        The node to parse attributes from
   * @return {Object}
   *         Object with all attributes of el parsed
   */

  var parseAttributes = function parseAttributes(el) {
    if (!(el && el.attributes)) {
      return {};
    }

    return from(el.attributes).reduce(function (a, e) {
      var parseFn = parsers[e.name] || parsers.DEFAULT;
      a[e.name] = parseFn(e.value);
      return a;
    }, {});
  };

  var atob = function atob(s) {
    return window.atob ? window.atob(s) : Buffer.from(s, 'base64').toString('binary');
  };

  function decodeB64ToUint8Array(b64Text) {
    var decodedString = atob(b64Text);
    var array = new Uint8Array(decodedString.length);

    for (var i = 0; i < decodedString.length; i++) {
      array[i] = decodedString.charCodeAt(i);
    }

    return array;
  }

  var keySystemsMap = {
    'urn:uuid:1077efec-c0b2-4d02-ace3-3c1e52e2fb4b': 'org.w3.clearkey',
    'urn:uuid:edef8ba9-79d6-4ace-a3c8-27dcd51d21ed': 'com.widevine.alpha',
    'urn:uuid:9a04f079-9840-4286-ab92-e65be0885f95': 'com.microsoft.playready',
    'urn:uuid:f239e769-efa3-4850-9c16-a903c6932efb': 'com.adobe.primetime'
  };
  /**
   * Builds a list of urls that is the product of the reference urls and BaseURL values
   *
   * @param {string[]} referenceUrls
   *        List of reference urls to resolve to
   * @param {Node[]} baseUrlElements
   *        List of BaseURL nodes from the mpd
   * @return {string[]}
   *         List of resolved urls
   */

  var buildBaseUrls = function buildBaseUrls(referenceUrls, baseUrlElements) {
    if (!baseUrlElements.length) {
      return referenceUrls;
    }

    return flatten(referenceUrls.map(function (reference) {
      return baseUrlElements.map(function (baseUrlElement) {
        return resolveUrl(reference, getContent(baseUrlElement));
      });
    }));
  };
  /**
   * Contains all Segment information for its containing AdaptationSet
   *
   * @typedef {Object} SegmentInformation
   * @property {Object|undefined} template
   *           Contains the attributes for the SegmentTemplate node
   * @property {Object[]|undefined} segmentTimeline
   *           Contains a list of atrributes for each S node within the SegmentTimeline node
   * @property {Object|undefined} list
   *           Contains the attributes for the SegmentList node
   * @property {Object|undefined} base
   *           Contains the attributes for the SegmentBase node
   */

  /**
   * Returns all available Segment information contained within the AdaptationSet node
   *
   * @param {Node} adaptationSet
   *        The AdaptationSet node to get Segment information from
   * @return {SegmentInformation}
   *         The Segment information contained within the provided AdaptationSet
   */

  var getSegmentInformation = function getSegmentInformation(adaptationSet) {
    var segmentTemplate = findChildren(adaptationSet, 'SegmentTemplate')[0];
    var segmentList = findChildren(adaptationSet, 'SegmentList')[0];
    var segmentUrls = segmentList && findChildren(segmentList, 'SegmentURL').map(function (s) {
      return merge({
        tag: 'SegmentURL'
      }, parseAttributes(s));
    });
    var segmentBase = findChildren(adaptationSet, 'SegmentBase')[0];
    var segmentTimelineParentNode = segmentList || segmentTemplate;
    var segmentTimeline = segmentTimelineParentNode && findChildren(segmentTimelineParentNode, 'SegmentTimeline')[0];
    var segmentInitializationParentNode = segmentList || segmentBase || segmentTemplate;
    var segmentInitialization = segmentInitializationParentNode && findChildren(segmentInitializationParentNode, 'Initialization')[0]; // SegmentTemplate is handled slightly differently, since it can have both
    // @initialization and an <Initialization> node.  @initialization can be templated,
    // while the node can have a url and range specified.  If the <SegmentTemplate> has
    // both @initialization and an <Initialization> subelement we opt to override with
    // the node, as this interaction is not defined in the spec.

    var template = segmentTemplate && parseAttributes(segmentTemplate);

    if (template && segmentInitialization) {
      template.initialization = segmentInitialization && parseAttributes(segmentInitialization);
    } else if (template && template.initialization) {
      // If it is @initialization we convert it to an object since this is the format that
      // later functions will rely on for the initialization segment.  This is only valid
      // for <SegmentTemplate>
      template.initialization = {
        sourceURL: template.initialization
      };
    }

    var segmentInfo = {
      template: template,
      segmentTimeline: segmentTimeline && findChildren(segmentTimeline, 'S').map(function (s) {
        return parseAttributes(s);
      }),
      list: segmentList && merge(parseAttributes(segmentList), {
        segmentUrls: segmentUrls,
        initialization: parseAttributes(segmentInitialization)
      }),
      base: segmentBase && merge(parseAttributes(segmentBase), {
        initialization: parseAttributes(segmentInitialization)
      })
    };
    Object.keys(segmentInfo).forEach(function (key) {
      if (!segmentInfo[key]) {
        delete segmentInfo[key];
      }
    });
    return segmentInfo;
  };
  /**
   * Contains Segment information and attributes needed to construct a Playlist object
   * from a Representation
   *
   * @typedef {Object} RepresentationInformation
   * @property {SegmentInformation} segmentInfo
   *           Segment information for this Representation
   * @property {Object} attributes
   *           Inherited attributes for this Representation
   */

  /**
   * Maps a Representation node to an object containing Segment information and attributes
   *
   * @name inheritBaseUrlsCallback
   * @function
   * @param {Node} representation
   *        Representation node from the mpd
   * @return {RepresentationInformation}
   *         Representation information needed to construct a Playlist object
   */

  /**
   * Returns a callback for Array.prototype.map for mapping Representation nodes to
   * Segment information and attributes using inherited BaseURL nodes.
   *
   * @param {Object} adaptationSetAttributes
   *        Contains attributes inherited by the AdaptationSet
   * @param {string[]} adaptationSetBaseUrls
   *        Contains list of resolved base urls inherited by the AdaptationSet
   * @param {SegmentInformation} adaptationSetSegmentInfo
   *        Contains Segment information for the AdaptationSet
   * @return {inheritBaseUrlsCallback}
   *         Callback map function
   */

  var inheritBaseUrls = function inheritBaseUrls(adaptationSetAttributes, adaptationSetBaseUrls, adaptationSetSegmentInfo) {
    return function (representation) {
      var repBaseUrlElements = findChildren(representation, 'BaseURL');
      var repBaseUrls = buildBaseUrls(adaptationSetBaseUrls, repBaseUrlElements);
      var attributes = merge(adaptationSetAttributes, parseAttributes(representation));
      var representationSegmentInfo = getSegmentInformation(representation);
      return repBaseUrls.map(function (baseUrl) {
        return {
          segmentInfo: merge(adaptationSetSegmentInfo, representationSegmentInfo),
          attributes: merge(attributes, {
            baseUrl: baseUrl
          })
        };
      });
    };
  };
  /**
   * Tranforms a series of content protection nodes to
   * an object containing pssh data by key system
   *
   * @param {Node[]} contentProtectionNodes
   *        Content protection nodes
   * @return {Object}
   *        Object containing pssh data by key system
   */

  var generateKeySystemInformation = function generateKeySystemInformation(contentProtectionNodes) {
    return contentProtectionNodes.reduce(function (acc, node) {
      var attributes = parseAttributes(node);
      var keySystem = keySystemsMap[attributes.schemeIdUri];

      if (keySystem) {
        acc[keySystem] = {
          attributes: attributes
        };
        var psshNode = findChildren(node, 'cenc:pssh')[0];

        if (psshNode) {
          var pssh = getContent(psshNode);
          var psshBuffer = pssh && decodeB64ToUint8Array(pssh);
          acc[keySystem].pssh = psshBuffer;
        }
      }

      return acc;
    }, {});
  }; // defined in ANSI_SCTE 214-1 2016


  var parseCaptionServiceMetadata = function parseCaptionServiceMetadata(service) {
    // 608 captions
    if (service.schemeIdUri === 'urn:scte:dash:cc:cea-608:2015') {
      var values = typeof service.value !== 'string' ? [] : service.value.split(';');
      return values.map(function (value) {
        var channel;
        var language; // default language to value

        language = value;

        if (/^CC\d=/.test(value)) {
          var _value$split = value.split('=');

          channel = _value$split[0];
          language = _value$split[1];
        } else if (/^CC\d$/.test(value)) {
          channel = value;
        }

        return {
          channel: channel,
          language: language
        };
      });
    } else if (service.schemeIdUri === 'urn:scte:dash:cc:cea-708:2015') {
      var _values = typeof service.value !== 'string' ? [] : service.value.split(';');

      return _values.map(function (value) {
        var flags = {
          // service or channel number 1-63
          'channel': undefined,
          // language is a 3ALPHA per ISO 639.2/B
          // field is required
          'language': undefined,
          // BIT 1/0 or ?
          // default value is 1, meaning 16:9 aspect ratio, 0 is 4:3, ? is unknown
          'aspectRatio': 1,
          // BIT 1/0
          // easy reader flag indicated the text is tailed to the needs of beginning readers
          // default 0, or off
          'easyReader': 0,
          // BIT 1/0
          // If 3d metadata is present (CEA-708.1) then 1
          // default 0
          '3D': 0
        };

        if (/=/.test(value)) {
          var _value$split2 = value.split('='),
              channel = _value$split2[0],
              _value$split2$ = _value$split2[1],
              opts = _value$split2$ === void 0 ? '' : _value$split2$;

          flags.channel = channel;
          flags.language = value;
          opts.split(',').forEach(function (opt) {
            var _opt$split = opt.split(':'),
                name = _opt$split[0],
                val = _opt$split[1];

            if (name === 'lang') {
              flags.language = val; // er for easyReadery
            } else if (name === 'er') {
              flags.easyReader = Number(val); // war for wide aspect ratio
            } else if (name === 'war') {
              flags.aspectRatio = Number(val);
            } else if (name === '3D') {
              flags['3D'] = Number(val);
            }
          });
        } else {
          flags.language = value;
        }

        if (flags.channel) {
          flags.channel = 'SERVICE' + flags.channel;
        }

        return flags;
      });
    }
  };
  /**
   * Maps an AdaptationSet node to a list of Representation information objects
   *
   * @name toRepresentationsCallback
   * @function
   * @param {Node} adaptationSet
   *        AdaptationSet node from the mpd
   * @return {RepresentationInformation[]}
   *         List of objects containing Representaion information
   */

  /**
   * Returns a callback for Array.prototype.map for mapping AdaptationSet nodes to a list of
   * Representation information objects
   *
   * @param {Object} periodAttributes
   *        Contains attributes inherited by the Period
   * @param {string[]} periodBaseUrls
   *        Contains list of resolved base urls inherited by the Period
   * @param {string[]} periodSegmentInfo
   *        Contains Segment Information at the period level
   * @return {toRepresentationsCallback}
   *         Callback map function
   */

  var toRepresentations = function toRepresentations(periodAttributes, periodBaseUrls, periodSegmentInfo) {
    return function (adaptationSet) {
      var adaptationSetAttributes = parseAttributes(adaptationSet);
      var adaptationSetBaseUrls = buildBaseUrls(periodBaseUrls, findChildren(adaptationSet, 'BaseURL'));
      var role = findChildren(adaptationSet, 'Role')[0];
      var roleAttributes = {
        role: parseAttributes(role)
      };
      var attrs = merge(periodAttributes, adaptationSetAttributes, roleAttributes);
      var accessibility = findChildren(adaptationSet, 'Accessibility')[0];
      var captionServices = parseCaptionServiceMetadata(parseAttributes(accessibility));

      if (captionServices) {
        attrs = merge(attrs, {
          captionServices: captionServices
        });
      }

      var label = findChildren(adaptationSet, 'Label')[0];

      if (label && label.childNodes.length) {
        var labelVal = label.childNodes[0].nodeValue.trim();
        attrs = merge(attrs, {
          label: labelVal
        });
      }

      var contentProtection = generateKeySystemInformation(findChildren(adaptationSet, 'ContentProtection'));

      if (Object.keys(contentProtection).length) {
        attrs = merge(attrs, {
          contentProtection: contentProtection
        });
      }

      var segmentInfo = getSegmentInformation(adaptationSet);
      var representations = findChildren(adaptationSet, 'Representation');
      var adaptationSetSegmentInfo = merge(periodSegmentInfo, segmentInfo);
      return flatten(representations.map(inheritBaseUrls(attrs, adaptationSetBaseUrls, adaptationSetSegmentInfo)));
    };
  };
  /**
   * Contains all period information for mapping nodes onto adaptation sets.
   *
   * @typedef {Object} PeriodInformation
   * @property {Node} period.node
   *           Period node from the mpd
   * @property {Object} period.attributes
   *           Parsed period attributes from node plus any added
   */

  /**
   * Maps a PeriodInformation object to a list of Representation information objects for all
   * AdaptationSet nodes contained within the Period.
   *
   * @name toAdaptationSetsCallback
   * @function
   * @param {PeriodInformation} period
   *        Period object containing necessary period information
   * @param {number} periodStart
   *        Start time of the Period within the mpd
   * @return {RepresentationInformation[]}
   *         List of objects containing Representaion information
   */

  /**
   * Returns a callback for Array.prototype.map for mapping Period nodes to a list of
   * Representation information objects
   *
   * @param {Object} mpdAttributes
   *        Contains attributes inherited by the mpd
   * @param {string[]} mpdBaseUrls
   *        Contains list of resolved base urls inherited by the mpd
   * @return {toAdaptationSetsCallback}
   *         Callback map function
   */

  var toAdaptationSets = function toAdaptationSets(mpdAttributes, mpdBaseUrls) {
    return function (period, index) {
      var periodBaseUrls = buildBaseUrls(mpdBaseUrls, findChildren(period.node, 'BaseURL'));
      var periodAttributes = merge(mpdAttributes, {
        periodStart: period.attributes.start
      });

      if (typeof period.attributes.duration === 'number') {
        periodAttributes.periodDuration = period.attributes.duration;
      }

      var adaptationSets = findChildren(period.node, 'AdaptationSet');
      var periodSegmentInfo = getSegmentInformation(period.node);
      return flatten(adaptationSets.map(toRepresentations(periodAttributes, periodBaseUrls, periodSegmentInfo)));
    };
  };
  /**
   * Gets Period@start property for a given period.
   *
   * @param {Object} options
   *        Options object
   * @param {Object} options.attributes
   *        Period attributes
   * @param {Object} [options.priorPeriodAttributes]
   *        Prior period attributes (if prior period is available)
   * @param {string} options.mpdType
   *        The MPD@type these periods came from
   * @return {number|null}
   *         The period start, or null if it's an early available period or error
   */

  var getPeriodStart = function getPeriodStart(_ref) {
    var attributes = _ref.attributes,
        priorPeriodAttributes = _ref.priorPeriodAttributes,
        mpdType = _ref.mpdType;

    // Summary of period start time calculation from DASH spec section 5.3.2.1
    //
    // A period's start is the first period's start + time elapsed after playing all
    // prior periods to this one. Periods continue one after the other in time (without
    // gaps) until the end of the presentation.
    //
    // The value of Period@start should be:
    // 1. if Period@start is present: value of Period@start
    // 2. if previous period exists and it has @duration: previous Period@start +
    //    previous Period@duration
    // 3. if this is first period and MPD@type is 'static': 0
    // 4. in all other cases, consider the period an "early available period" (note: not
    //    currently supported)
    // (1)
    if (typeof attributes.start === 'number') {
      return attributes.start;
    } // (2)


    if (priorPeriodAttributes && typeof priorPeriodAttributes.start === 'number' && typeof priorPeriodAttributes.duration === 'number') {
      return priorPeriodAttributes.start + priorPeriodAttributes.duration;
    } // (3)


    if (!priorPeriodAttributes && mpdType === 'static') {
      return 0;
    } // (4)
    // There is currently no logic for calculating the Period@start value if there is
    // no Period@start or prior Period@start and Period@duration available. This is not made
    // explicit by the DASH interop guidelines or the DASH spec, however, since there's
    // nothing about any other resolution strategies, it's implied. Thus, this case should
    // be considered an early available period, or error, and null should suffice for both
    // of those cases.


    return null;
  };
  /**
   * Traverses the mpd xml tree to generate a list of Representation information objects
   * that have inherited attributes from parent nodes
   *
   * @param {Node} mpd
   *        The root node of the mpd
   * @param {Object} options
   *        Available options for inheritAttributes
   * @param {string} options.manifestUri
   *        The uri source of the mpd
   * @param {number} options.NOW
   *        Current time per DASH IOP.  Default is current time in ms since epoch
   * @param {number} options.clientOffset
   *        Client time difference from NOW (in milliseconds)
   * @return {RepresentationInformation[]}
   *         List of objects containing Representation information
   */

  var inheritAttributes = function inheritAttributes(mpd, options) {
    if (options === void 0) {
      options = {};
    }

    var _options = options,
        _options$manifestUri = _options.manifestUri,
        manifestUri = _options$manifestUri === void 0 ? '' : _options$manifestUri,
        _options$NOW = _options.NOW,
        NOW = _options$NOW === void 0 ? Date.now() : _options$NOW,
        _options$clientOffset = _options.clientOffset,
        clientOffset = _options$clientOffset === void 0 ? 0 : _options$clientOffset;
    var periodNodes = findChildren(mpd, 'Period');

    if (!periodNodes.length) {
      throw new Error(errors.INVALID_NUMBER_OF_PERIOD);
    }

    var locations = findChildren(mpd, 'Location');
    var mpdAttributes = parseAttributes(mpd);
    var mpdBaseUrls = buildBaseUrls([manifestUri], findChildren(mpd, 'BaseURL')); // See DASH spec section 5.3.1.2, Semantics of MPD element. Default type to 'static'.

    mpdAttributes.type = mpdAttributes.type || 'static';
    mpdAttributes.sourceDuration = mpdAttributes.mediaPresentationDuration || 0;
    mpdAttributes.NOW = NOW;
    mpdAttributes.clientOffset = clientOffset;

    if (locations.length) {
      mpdAttributes.locations = locations.map(getContent);
    }

    var periods = []; // Since toAdaptationSets acts on individual periods right now, the simplest approach to
    // adding properties that require looking at prior periods is to parse attributes and add
    // missing ones before toAdaptationSets is called. If more such properties are added, it
    // may be better to refactor toAdaptationSets.

    periodNodes.forEach(function (node, index) {
      var attributes = parseAttributes(node); // Use the last modified prior period, as it may contain added information necessary
      // for this period.

      var priorPeriod = periods[index - 1];
      attributes.start = getPeriodStart({
        attributes: attributes,
        priorPeriodAttributes: priorPeriod ? priorPeriod.attributes : null,
        mpdType: mpdAttributes.type
      });
      periods.push({
        node: node,
        attributes: attributes
      });
    });
    return {
      locations: mpdAttributes.locations,
      representationInfo: flatten(periods.map(toAdaptationSets(mpdAttributes, mpdBaseUrls)))
    };
  };

  var stringToMpdXml = function stringToMpdXml(manifestString) {
    if (manifestString === '') {
      throw new Error(errors.DASH_EMPTY_MANIFEST);
    }

    var parser = new xmldom.DOMParser();
    var xml;
    var mpd;

    try {
      xml = parser.parseFromString(manifestString, 'application/xml');
      mpd = xml && xml.documentElement.tagName === 'MPD' ? xml.documentElement : null;
    } catch (e) {// ie 11 throwsw on invalid xml
    }

    if (!mpd || mpd && mpd.getElementsByTagName('parsererror').length > 0) {
      throw new Error(errors.DASH_INVALID_XML);
    }

    return mpd;
  };

  /**
   * Parses the manifest for a UTCTiming node, returning the nodes attributes if found
   *
   * @param {string} mpd
   *        XML string of the MPD manifest
   * @return {Object|null}
   *         Attributes of UTCTiming node specified in the manifest. Null if none found
   */

  var parseUTCTimingScheme = function parseUTCTimingScheme(mpd) {
    var UTCTimingNode = findChildren(mpd, 'UTCTiming')[0];

    if (!UTCTimingNode) {
      return null;
    }

    var attributes = parseAttributes(UTCTimingNode);

    switch (attributes.schemeIdUri) {
      case 'urn:mpeg:dash:utc:http-head:2014':
      case 'urn:mpeg:dash:utc:http-head:2012':
        attributes.method = 'HEAD';
        break;

      case 'urn:mpeg:dash:utc:http-xsdate:2014':
      case 'urn:mpeg:dash:utc:http-iso:2014':
      case 'urn:mpeg:dash:utc:http-xsdate:2012':
      case 'urn:mpeg:dash:utc:http-iso:2012':
        attributes.method = 'GET';
        break;

      case 'urn:mpeg:dash:utc:direct:2014':
      case 'urn:mpeg:dash:utc:direct:2012':
        attributes.method = 'DIRECT';
        attributes.value = Date.parse(attributes.value);
        break;

      case 'urn:mpeg:dash:utc:http-ntp:2014':
      case 'urn:mpeg:dash:utc:ntp:2014':
      case 'urn:mpeg:dash:utc:sntp:2014':
      default:
        throw new Error(errors.UNSUPPORTED_UTC_TIMING_SCHEME);
    }

    return attributes;
  };

  var VERSION = version;
  /*
   * Given a DASH manifest string and options, parses the DASH manifest into an object in the
   * form outputed by m3u8-parser and accepted by videojs/http-streaming.
   *
   * For live DASH manifests, if `previousManifest` is provided in options, then the newly
   * parsed DASH manifest will have its media sequence and discontinuity sequence values
   * updated to reflect its position relative to the prior manifest.
   *
   * @param {string} manifestString - the DASH manifest as a string
   * @param {options} [options] - any options
   *
   * @return {Object} the manifest object
   */

  var parse = function parse(manifestString, options) {
    if (options === void 0) {
      options = {};
    }

    var parsedManifestInfo = inheritAttributes(stringToMpdXml(manifestString), options);
    var playlists = toPlaylists(parsedManifestInfo.representationInfo);
    return toM3u8({
      dashPlaylists: playlists,
      locations: parsedManifestInfo.locations,
      sidxMapping: options.sidxMapping,
      previousManifest: options.previousManifest
    });
  };
  /**
   * Parses the manifest for a UTCTiming node, returning the nodes attributes if found
   *
   * @param {string} manifestString
   *        XML string of the MPD manifest
   * @return {Object|null}
   *         Attributes of UTCTiming node specified in the manifest. Null if none found
   */


  var parseUTCTiming = function parseUTCTiming(manifestString) {
    return parseUTCTimingScheme(stringToMpdXml(manifestString));
  };

  exports.VERSION = VERSION;
  exports.addSidxSegmentsToPlaylist = addSidxSegmentsToPlaylist$1;
  exports.generateSidxKey = generateSidxKey;
  exports.inheritAttributes = inheritAttributes;
  exports.parse = parse;
  exports.parseUTCTiming = parseUTCTiming;
  exports.stringToMpdXml = stringToMpdXml;
  exports.toM3u8 = toM3u8;
  exports.toPlaylists = toPlaylists;

  Object.defineProperty(exports, '__esModule', { value: true });

})));
