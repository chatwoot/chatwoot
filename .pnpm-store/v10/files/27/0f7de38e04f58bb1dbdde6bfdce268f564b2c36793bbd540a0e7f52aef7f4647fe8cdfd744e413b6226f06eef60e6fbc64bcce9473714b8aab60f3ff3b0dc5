import { dropUndefinedKeys } from '@sentry/utils';

/**
 * Generate bucket key from metric properties.
 */
function getBucketKey(
  metricType,
  name,
  unit,
  tags,
) {
  const stringifiedTags = Object.entries(dropUndefinedKeys(tags)).sort((a, b) => a[0].localeCompare(b[0]));
  return `${metricType}${name}${unit}${stringifiedTags}`;
}

/* eslint-disable no-bitwise */
/**
 * Simple hash function for strings.
 */
function simpleHash(s) {
  let rv = 0;
  for (let i = 0; i < s.length; i++) {
    const c = s.charCodeAt(i);
    rv = (rv << 5) - rv + c;
    rv &= rv;
  }
  return rv >>> 0;
}
/* eslint-enable no-bitwise */

/**
 * Serialize metrics buckets into a string based on statsd format.
 *
 * Example of format:
 * metric.name@second:1:1.2|d|#a:value,b:anothervalue|T12345677
 * Segments:
 * name: metric.name
 * unit: second
 * value: [1, 1.2]
 * type of metric: d (distribution)
 * tags: { a: value, b: anothervalue }
 * timestamp: 12345677
 */
function serializeMetricBuckets(metricBucketItems) {
  let out = '';
  for (const item of metricBucketItems) {
    const tagEntries = Object.entries(item.tags);
    const maybeTags = tagEntries.length > 0 ? `|#${tagEntries.map(([key, value]) => `${key}:${value}`).join(',')}` : '';
    out += `${item.name}@${item.unit}:${item.metric}|${item.metricType}${maybeTags}|T${item.timestamp}\n`;
  }
  return out;
}

/**
 * Sanitizes units
 *
 * These Regex's are straight from the normalisation docs:
 * https://develop.sentry.dev/sdk/metrics/#normalization
 */
function sanitizeUnit(unit) {
  return unit.replace(/[^\w]+/gi, '_');
}

/**
 * Sanitizes metric keys
 *
 * These Regex's are straight from the normalisation docs:
 * https://develop.sentry.dev/sdk/metrics/#normalization
 */
function sanitizeMetricKey(key) {
  return key.replace(/[^\w\-.]+/gi, '_');
}

/**
 * Sanitizes metric keys
 *
 * These Regex's are straight from the normalisation docs:
 * https://develop.sentry.dev/sdk/metrics/#normalization
 */
function sanitizeTagKey(key) {
  return key.replace(/[^\w\-./]+/gi, '');
}

/**
 * These Regex's are straight from the normalisation docs:
 * https://develop.sentry.dev/sdk/metrics/#normalization
 */
const tagValueReplacements = [
  ['\n', '\\n'],
  ['\r', '\\r'],
  ['\t', '\\t'],
  ['\\', '\\\\'],
  ['|', '\\u{7c}'],
  [',', '\\u{2c}'],
];

function getCharOrReplacement(input) {
  for (const [search, replacement] of tagValueReplacements) {
    if (input === search) {
      return replacement;
    }
  }

  return input;
}

function sanitizeTagValue(value) {
  return [...value].reduce((acc, char) => acc + getCharOrReplacement(char), '');
}

/**
 * Sanitizes tags.
 */
function sanitizeTags(unsanitizedTags) {
  const tags = {};
  for (const key in unsanitizedTags) {
    if (Object.prototype.hasOwnProperty.call(unsanitizedTags, key)) {
      const sanitizedKey = sanitizeTagKey(key);
      tags[sanitizedKey] = sanitizeTagValue(String(unsanitizedTags[key]));
    }
  }
  return tags;
}

export { getBucketKey, sanitizeMetricKey, sanitizeTags, sanitizeUnit, serializeMetricBuckets, simpleHash };
//# sourceMappingURL=utils.js.map
