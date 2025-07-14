/**
 * @file m3u8/parse-stream.js
 */
import Stream from '@videojs/vhs-utils/es/stream.js';

const TAB = String.fromCharCode(0x09);

const parseByterange = function(byterangeString) {
  // optionally match and capture 0+ digits before `@`
  // optionally match and capture 0+ digits after `@`
  const match = /([0-9.]*)?@?([0-9.]*)?/.exec(byterangeString || '');
  const result = {};

  if (match[1]) {
    result.length = parseInt(match[1], 10);
  }

  if (match[2]) {
    result.offset = parseInt(match[2], 10);
  }

  return result;
};

/**
 * "forgiving" attribute list psuedo-grammar:
 * attributes -> keyvalue (',' keyvalue)*
 * keyvalue   -> key '=' value
 * key        -> [^=]*
 * value      -> '"' [^"]* '"' | [^,]*
 */
const attributeSeparator = function() {
  const key = '[^=]*';
  const value = '"[^"]*"|[^,]*';
  const keyvalue = '(?:' + key + ')=(?:' + value + ')';

  return new RegExp('(?:^|,)(' + keyvalue + ')');
};

/**
 * Parse attributes from a line given the separator
 *
 * @param {string} attributes the attribute line to parse
 */
const parseAttributes = function(attributes) {
  // split the string using attributes as the separator
  const attrs = attributes.split(attributeSeparator());
  const result = {};
  let i = attrs.length;
  let attr;

  while (i--) {
    // filter out unmatched portions of the string
    if (attrs[i] === '') {
      continue;
    }

    // split the key and value
    attr = (/([^=]*)=(.*)/).exec(attrs[i]).slice(1);
    // trim whitespace and remove optional quotes around the value
    attr[0] = attr[0].replace(/^\s+|\s+$/g, '');
    attr[1] = attr[1].replace(/^\s+|\s+$/g, '');
    attr[1] = attr[1].replace(/^['"](.*)['"]$/g, '$1');
    result[attr[0]] = attr[1];
  }
  return result;
};

/**
 * A line-level M3U8 parser event stream. It expects to receive input one
 * line at a time and performs a context-free parse of its contents. A stream
 * interpretation of a manifest can be useful if the manifest is expected to
 * be too large to fit comfortably into memory or the entirety of the input
 * is not immediately available. Otherwise, it's probably much easier to work
 * with a regular `Parser` object.
 *
 * Produces `data` events with an object that captures the parser's
 * interpretation of the input. That object has a property `tag` that is one
 * of `uri`, `comment`, or `tag`. URIs only have a single additional
 * property, `line`, which captures the entirety of the input without
 * interpretation. Comments similarly have a single additional property
 * `text` which is the input without the leading `#`.
 *
 * Tags always have a property `tagType` which is the lower-cased version of
 * the M3U8 directive without the `#EXT` or `#EXT-X-` prefix. For instance,
 * `#EXT-X-MEDIA-SEQUENCE` becomes `media-sequence` when parsed. Unrecognized
 * tags are given the tag type `unknown` and a single additional property
 * `data` with the remainder of the input.
 *
 * @class ParseStream
 * @extends Stream
 */
export default class ParseStream extends Stream {
  constructor() {
    super();
    this.customParsers = [];
    this.tagMappers = [];
  }

  /**
   * Parses an additional line of input.
   *
   * @param {string} line a single line of an M3U8 file to parse
   */
  push(line) {
    let match;
    let event;

    // strip whitespace
    line = line.trim();

    if (line.length === 0) {
      // ignore empty lines
      return;
    }

    // URIs
    if (line[0] !== '#') {
      this.trigger('data', {
        type: 'uri',
        uri: line
      });
      return;
    }

    // map tags
    const newLines = this.tagMappers.reduce((acc, mapper) => {
      const mappedLine = mapper(line);

      // skip if unchanged
      if (mappedLine === line) {
        return acc;
      }

      return acc.concat([mappedLine]);
    }, [line]);

    newLines.forEach(newLine => {
      for (let i = 0; i < this.customParsers.length; i++) {
        if (this.customParsers[i].call(this, newLine)) {
          return;
        }
      }

      // Comments
      if (newLine.indexOf('#EXT') !== 0) {
        this.trigger('data', {
          type: 'comment',
          text: newLine.slice(1)
        });
        return;
      }

      // strip off any carriage returns here so the regex matching
      // doesn't have to account for them.
      newLine = newLine.replace('\r', '');

      // Tags
      match = (/^#EXTM3U/).exec(newLine);
      if (match) {
        this.trigger('data', {
          type: 'tag',
          tagType: 'm3u'
        });
        return;
      }
      match = (/^#EXTINF:?([0-9\.]*)?,?(.*)?$/).exec(newLine);
      if (match) {
        event = {
          type: 'tag',
          tagType: 'inf'
        };
        if (match[1]) {
          event.duration = parseFloat(match[1]);
        }
        if (match[2]) {
          event.title = match[2];
        }
        this.trigger('data', event);
        return;
      }
      match = (/^#EXT-X-TARGETDURATION:?([0-9.]*)?/).exec(newLine);
      if (match) {
        event = {
          type: 'tag',
          tagType: 'targetduration'
        };
        if (match[1]) {
          event.duration = parseInt(match[1], 10);
        }
        this.trigger('data', event);
        return;
      }
      match = (/^#EXT-X-VERSION:?([0-9.]*)?/).exec(newLine);
      if (match) {
        event = {
          type: 'tag',
          tagType: 'version'
        };
        if (match[1]) {
          event.version = parseInt(match[1], 10);
        }
        this.trigger('data', event);
        return;
      }
      match = (/^#EXT-X-MEDIA-SEQUENCE:?(\-?[0-9.]*)?/).exec(newLine);
      if (match) {
        event = {
          type: 'tag',
          tagType: 'media-sequence'
        };
        if (match[1]) {
          event.number = parseInt(match[1], 10);
        }
        this.trigger('data', event);
        return;
      }
      match = (/^#EXT-X-DISCONTINUITY-SEQUENCE:?(\-?[0-9.]*)?/).exec(newLine);
      if (match) {
        event = {
          type: 'tag',
          tagType: 'discontinuity-sequence'
        };
        if (match[1]) {
          event.number = parseInt(match[1], 10);
        }
        this.trigger('data', event);
        return;
      }
      match = (/^#EXT-X-PLAYLIST-TYPE:?(.*)?$/).exec(newLine);
      if (match) {
        event = {
          type: 'tag',
          tagType: 'playlist-type'
        };
        if (match[1]) {
          event.playlistType = match[1];
        }
        this.trigger('data', event);
        return;
      }
      match = (/^#EXT-X-BYTERANGE:?(.*)?$/).exec(newLine);
      if (match) {
        event = Object.assign(parseByterange(match[1]), {
          type: 'tag',
          tagType: 'byterange'
        });
        this.trigger('data', event);
        return;
      }
      match = (/^#EXT-X-ALLOW-CACHE:?(YES|NO)?/).exec(newLine);
      if (match) {
        event = {
          type: 'tag',
          tagType: 'allow-cache'
        };
        if (match[1]) {
          event.allowed = !(/NO/).test(match[1]);
        }
        this.trigger('data', event);
        return;
      }
      match = (/^#EXT-X-MAP:?(.*)$/).exec(newLine);
      if (match) {
        event = {
          type: 'tag',
          tagType: 'map'
        };

        if (match[1]) {
          const attributes = parseAttributes(match[1]);

          if (attributes.URI) {
            event.uri = attributes.URI;
          }
          if (attributes.BYTERANGE) {
            event.byterange = parseByterange(attributes.BYTERANGE);
          }
        }

        this.trigger('data', event);
        return;
      }
      match = (/^#EXT-X-STREAM-INF:?(.*)$/).exec(newLine);
      if (match) {
        event = {
          type: 'tag',
          tagType: 'stream-inf'
        };
        if (match[1]) {
          event.attributes = parseAttributes(match[1]);

          if (event.attributes.RESOLUTION) {
            const split = event.attributes.RESOLUTION.split('x');
            const resolution = {};

            if (split[0]) {
              resolution.width = parseInt(split[0], 10);
            }
            if (split[1]) {
              resolution.height = parseInt(split[1], 10);
            }
            event.attributes.RESOLUTION = resolution;
          }
          if (event.attributes.BANDWIDTH) {
            event.attributes.BANDWIDTH = parseInt(event.attributes.BANDWIDTH, 10);
          }
          if (event.attributes['PROGRAM-ID']) {
            event.attributes['PROGRAM-ID'] = parseInt(event.attributes['PROGRAM-ID'], 10);
          }
        }
        this.trigger('data', event);
        return;
      }
      match = (/^#EXT-X-MEDIA:?(.*)$/).exec(newLine);
      if (match) {
        event = {
          type: 'tag',
          tagType: 'media'
        };
        if (match[1]) {
          event.attributes = parseAttributes(match[1]);
        }
        this.trigger('data', event);
        return;
      }
      match = (/^#EXT-X-ENDLIST/).exec(newLine);
      if (match) {
        this.trigger('data', {
          type: 'tag',
          tagType: 'endlist'
        });
        return;
      }
      match = (/^#EXT-X-DISCONTINUITY/).exec(newLine);
      if (match) {
        this.trigger('data', {
          type: 'tag',
          tagType: 'discontinuity'
        });
        return;
      }
      match = (/^#EXT-X-PROGRAM-DATE-TIME:?(.*)$/).exec(newLine);
      if (match) {
        event = {
          type: 'tag',
          tagType: 'program-date-time'
        };
        if (match[1]) {
          event.dateTimeString = match[1];
          event.dateTimeObject = new Date(match[1]);
        }
        this.trigger('data', event);
        return;
      }
      match = (/^#EXT-X-KEY:?(.*)$/).exec(newLine);
      if (match) {
        event = {
          type: 'tag',
          tagType: 'key'
        };
        if (match[1]) {
          event.attributes = parseAttributes(match[1]);
          // parse the IV string into a Uint32Array
          if (event.attributes.IV) {
            if (event.attributes.IV.substring(0, 2).toLowerCase() === '0x') {
              event.attributes.IV = event.attributes.IV.substring(2);
            }

            event.attributes.IV = event.attributes.IV.match(/.{8}/g);
            event.attributes.IV[0] = parseInt(event.attributes.IV[0], 16);
            event.attributes.IV[1] = parseInt(event.attributes.IV[1], 16);
            event.attributes.IV[2] = parseInt(event.attributes.IV[2], 16);
            event.attributes.IV[3] = parseInt(event.attributes.IV[3], 16);
            event.attributes.IV = new Uint32Array(event.attributes.IV);
          }
        }
        this.trigger('data', event);
        return;
      }
      match = (/^#EXT-X-START:?(.*)$/).exec(newLine);
      if (match) {
        event = {
          type: 'tag',
          tagType: 'start'
        };
        if (match[1]) {
          event.attributes = parseAttributes(match[1]);

          event.attributes['TIME-OFFSET'] = parseFloat(event.attributes['TIME-OFFSET']);
          event.attributes.PRECISE = (/YES/).test(event.attributes.PRECISE);
        }
        this.trigger('data', event);
        return;
      }
      match = (/^#EXT-X-CUE-OUT-CONT:?(.*)?$/).exec(newLine);
      if (match) {
        event = {
          type: 'tag',
          tagType: 'cue-out-cont'
        };
        if (match[1]) {
          event.data = match[1];
        } else {
          event.data = '';
        }
        this.trigger('data', event);
        return;
      }
      match = (/^#EXT-X-CUE-OUT:?(.*)?$/).exec(newLine);
      if (match) {
        event = {
          type: 'tag',
          tagType: 'cue-out'
        };
        if (match[1]) {
          event.data = match[1];
        } else {
          event.data = '';
        }
        this.trigger('data', event);
        return;
      }
      match = (/^#EXT-X-CUE-IN:?(.*)?$/).exec(newLine);
      if (match) {
        event = {
          type: 'tag',
          tagType: 'cue-in'
        };
        if (match[1]) {
          event.data = match[1];
        } else {
          event.data = '';
        }
        this.trigger('data', event);
        return;
      }
      match = (/^#EXT-X-SKIP:(.*)$/).exec(newLine);
      if (match && match[1]) {
        event = {
          type: 'tag',
          tagType: 'skip'
        };
        event.attributes = parseAttributes(match[1]);

        if (event.attributes.hasOwnProperty('SKIPPED-SEGMENTS')) {
          event.attributes['SKIPPED-SEGMENTS'] = parseInt(event.attributes['SKIPPED-SEGMENTS'], 10);
        }

        if (event.attributes.hasOwnProperty('RECENTLY-REMOVED-DATERANGES')) {
          event.attributes['RECENTLY-REMOVED-DATERANGES'] =
            event.attributes['RECENTLY-REMOVED-DATERANGES'].split(TAB);
        }

        this.trigger('data', event);
        return;
      }
      match = (/^#EXT-X-PART:(.*)$/).exec(newLine);
      if (match && match[1]) {
        event = {
          type: 'tag',
          tagType: 'part'
        };
        event.attributes = parseAttributes(match[1]);
        ['DURATION'].forEach(function(key) {
          if (event.attributes.hasOwnProperty(key)) {
            event.attributes[key] = parseFloat(event.attributes[key]);
          }
        });

        ['INDEPENDENT', 'GAP'].forEach(function(key) {
          if (event.attributes.hasOwnProperty(key)) {
            event.attributes[key] = (/YES/).test(event.attributes[key]);
          }
        });

        if (event.attributes.hasOwnProperty('BYTERANGE')) {
          event.attributes.byterange = parseByterange(event.attributes.BYTERANGE);
        }

        this.trigger('data', event);
        return;
      }
      match = (/^#EXT-X-SERVER-CONTROL:(.*)$/).exec(newLine);
      if (match && match[1]) {
        event = {
          type: 'tag',
          tagType: 'server-control'
        };
        event.attributes = parseAttributes(match[1]);
        ['CAN-SKIP-UNTIL', 'PART-HOLD-BACK', 'HOLD-BACK'].forEach(function(key) {
          if (event.attributes.hasOwnProperty(key)) {
            event.attributes[key] = parseFloat(event.attributes[key]);
          }
        });

        ['CAN-SKIP-DATERANGES', 'CAN-BLOCK-RELOAD'].forEach(function(key) {
          if (event.attributes.hasOwnProperty(key)) {
            event.attributes[key] = (/YES/).test(event.attributes[key]);
          }
        });

        this.trigger('data', event);
        return;
      }
      match = (/^#EXT-X-PART-INF:(.*)$/).exec(newLine);
      if (match && match[1]) {
        event = {
          type: 'tag',
          tagType: 'part-inf'
        };
        event.attributes = parseAttributes(match[1]);
        ['PART-TARGET'].forEach(function(key) {
          if (event.attributes.hasOwnProperty(key)) {
            event.attributes[key] = parseFloat(event.attributes[key]);
          }
        });

        this.trigger('data', event);
        return;
      }

      match = (/^#EXT-X-PRELOAD-HINT:(.*)$/).exec(newLine);
      if (match && match[1]) {
        event = {
          type: 'tag',
          tagType: 'preload-hint'
        };
        event.attributes = parseAttributes(match[1]);
        ['BYTERANGE-START', 'BYTERANGE-LENGTH'].forEach(function(key) {
          if (event.attributes.hasOwnProperty(key)) {
            event.attributes[key] = parseInt(event.attributes[key], 10);

            const subkey = key === 'BYTERANGE-LENGTH' ? 'length' : 'offset';

            event.attributes.byterange = event.attributes.byterange || {};
            event.attributes.byterange[subkey] = event.attributes[key];
            // only keep the parsed byterange object.
            delete event.attributes[key];
          }
        });

        this.trigger('data', event);
        return;
      }
      match = (/^#EXT-X-RENDITION-REPORT:(.*)$/).exec(newLine);
      if (match && match[1]) {
        event = {
          type: 'tag',
          tagType: 'rendition-report'
        };
        event.attributes = parseAttributes(match[1]);
        ['LAST-MSN', 'LAST-PART'].forEach(function(key) {
          if (event.attributes.hasOwnProperty(key)) {
            event.attributes[key] = parseInt(event.attributes[key], 10);
          }
        });

        this.trigger('data', event);
        return;
      }

      // unknown tag type
      this.trigger('data', {
        type: 'tag',
        data: newLine.slice(4)
      });
    });
  }

  /**
   * Add a parser for custom headers
   *
   * @param {Object}   options              a map of options for the added parser
   * @param {RegExp}   options.expression   a regular expression to match the custom header
   * @param {string}   options.customType   the custom type to register to the output
   * @param {Function} [options.dataParser] function to parse the line into an object
   * @param {boolean}  [options.segment]    should tag data be attached to the segment object
   */
  addParser({expression, customType, dataParser, segment}) {
    if (typeof dataParser !== 'function') {
      dataParser = (line) => line;
    }
    this.customParsers.push(line => {
      const match = expression.exec(line);

      if (match) {
        this.trigger('data', {
          type: 'custom',
          data: dataParser(line),
          customType,
          segment
        });
        return true;
      }
    });
  }

  /**
   * Add a custom header mapper
   *
   * @param {Object}   options
   * @param {RegExp}   options.expression   a regular expression to match the custom header
   * @param {Function} options.map          function to translate tag into a different tag
   */
  addTagMapper({expression, map}) {
    const mapFn = line => {
      if (expression.test(line)) {
        return map(line);
      }

      return line;
    };

    this.tagMappers.push(mapFn);
  }
}
