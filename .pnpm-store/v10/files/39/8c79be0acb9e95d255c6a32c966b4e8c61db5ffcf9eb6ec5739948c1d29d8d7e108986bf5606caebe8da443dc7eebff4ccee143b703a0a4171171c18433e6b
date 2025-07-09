/*!
 * bytes
 * Copyright(c) 2012-2014 TJ Holowaychuk
 * Copyright(c) 2015 Jed Watson
 * MIT Licensed
 */

'use strict';

/**
 * Module exports.
 * @public
 */
module.exports = withDefaultMode('metric');

/**
 * Module variables.
 * @private
 */

var formatThousandsRegExp = /\B(?=(\d{3})+(?!\d))/g;

var formatDecimalsRegExp = /(?:\.0*|(\.[^0]+)0+)$/;

var allUnits = {
  // Metric units
  b: {val: 1, longName: 'byte', name: 'B'},
  kb: {val: Math.pow(1000, 1), longName: 'kilobyte', name: "kB"},
  mb: {val: Math.pow(1000, 2), longName: 'megabyte', name: "MB"},
  gb: {val: Math.pow(1000, 3), longName: 'gigabyte', name: "GB"},
  tb: {val: Math.pow(1000, 4), longName: 'terabyte', name: "TB"},
  pb: {val: Math.pow(1000, 5), longName: 'petabyte', name: "PB"},
  eb: {val: Math.pow(1000, 6), longName: 'exabyte', name: "EB"},
  zb: {val: Math.pow(1000, 7), longName: 'zettabyte', name: "ZB"},
  yb: {val: Math.pow(1000, 8), longName: 'yottabyte', name: "YB"},

  // Binary units
  kib: {val: Math.pow(1024, 1), longName: 'kibibyte', name: "KiB"},
  mib: {val: Math.pow(1024, 2), longName: 'mebibyte', name: "MiB"},
  gib: {val: Math.pow(1024, 3), longName: 'gibibyte', name: "GiB"},
  tib: {val: Math.pow(1024, 4), longName: 'tebibyte', name: "TiB"},
  pib: {val: Math.pow(1024, 5), longName: 'pebibyte', name: "PiB"},
  eib: {val: Math.pow(1024, 6), longName: 'exbibyte', name: "EiB"},
  zib: {val: Math.pow(1024, 7), longName: 'zebibyte', name: "ZiB"},
  yib: {val: Math.pow(1024, 8), longName: 'yobibyte', name: "YiB"},

  // Compatibility units
  _kb: {val: Math.pow(1024, 1), longName: 'kilobyte', name: "kB"},
  _mb: {val: Math.pow(1024, 2), longName: 'megabyte', name: "MB"},
  _gb: {val: Math.pow(1024, 3), longName: 'gigabyte', name: "GB"},
  _tb: {val: Math.pow(1024, 4), longName: 'terabyte', name: "TB"},
};


function _invertUnitMap(expectedUnits) {
  var orderedUnits = [];

  for (var i=0; i < expectedUnits.length; i++) {
    var unitData = expectedUnits[i];

    orderedUnits.push(allUnits[unitData]);
  }

  orderedUnits.sort(function sortLargest(a, b) {
    return (b.val - a.val);
  });
  return orderedUnits;
}

var metricMap = _invertUnitMap([
  'b',
  'kb',
  'mb',
  'gb',
  'tb',
  'pb',
  'eb',
  'zb',
  'yb',
]);
var binaryMap = _invertUnitMap([
  'b',
  'kib',
  'mib',
  'gib',
  'tib',
  'pib',
  'eib',
  'zib',
  'yib',
]);
var compatibilityMap = _invertUnitMap([
  'b',
  '_kb',
  '_mb',
  '_gb',
  '_tb',
]);


var parseRegExp = /^((-|\+)?(\d+(?:\.\d+)?)) *((k|m|g|t|p|e|z|y)?i?(b))?$/i;


function _checkMode(mode) {
  if (mode == 'compatibility') {
    mode = 'jedec';
  }
  if (mode == 'decimal') {
    mode = 'metric';
  }

  if (!/^(binary|metric|jedec)/.test(mode)) {
    throw Error("bytes.js: invalid mode passed in: " + mode);
  }

  return mode;
}


/**
 * Convert the given value in bytes into a string or parse to string to an integer in bytes.
 *
 * @param {string|number} value
 * @param {{
 *  case: [string],
 *  decimalPlaces: [number]
 *  fixedDecimals: [boolean]
 *  thousandsSeparator: [string]
 *  unitSeparator: [string]
 *  mode: [string]
 *  unit: [string]
 *  }} [options] bytes options.
 *
 * @returns {string|number|null}
 */

function bytes(value, options) {
  if (typeof value === 'string') {
    return parse(value, options);
  }

  if (typeof value === 'number') {
    return format(value, options);
  }

  return null;
}

/**
 * Creates a library wrapper that forces a certain mode to be default
 *
 * @param {string} mode
 */
function withDefaultMode(mode) {
  // Check that the mode is valid
  mode = _checkMode(mode);

  // Adds the default mode to the method
  function setDefault(options) {
    options = (options !== undefined ? options : {});

    if (options.mode === undefined) {
      options.mode = mode;
    }

    return options;
  }

  function bytesWithDefault(value, options) {
    return bytes(value, setDefault(options));
  }

  bytesWithDefault.format = function formatWithDefault(value, options) {
    return format(value, setDefault(options));
  };

  bytesWithDefault.parse = function formatWithDefault(value, options) {
    return parse(value, setDefault(options));
  };

  // Also allow it to act completely like the original module
  // So we can still change the default mode (but only by makind a new module)
  bytesWithDefault.withDefaultMode = withDefaultMode;

  return bytesWithDefault;
}

/**
 * Format the given value in bytes into a string.
 *
 * If the value is negative, it is kept as such. If it is a float,
 * it is rounded.
 *
 * @param {number} value
 * @param {object} [options]
 * @param {number} [options.decimalPlaces=2]
 * @param {number} [options.fixedDecimals=false]
 * @param {string} [options.thousandsSeparator=]
 * @param {string} [options.unit=]
 * @param {string} [options.unitSeparator=]
 * @param {string} [options.mode='metric']
 * @param {string} [options.unit=]
 *
 * @returns {string|null}
 * @public
 */

function format(value, options) {
  if (!Number.isFinite(value)) {
    return null;
  }

  var mag = Math.abs(value);
  var thousandsSeparator = (options && options.thousandsSeparator) || '';
  var unitSeparator = (options && options.unitSeparator) || '';
  var decimalPlaces = (options && options.decimalPlaces !== undefined) ? options.decimalPlaces : 2;
  var fixedDecimals = Boolean(options && options.fixedDecimals);
  var expectedUnit = (options && options.unit);

  var mode = (options && options.mode) || 'metric';
  mode = _checkMode(options.mode);

  // Find which set of units we're converting to
  var unitMap = _getUnitMap(mode);

  // Find what to convert to
  var conversionUnit;
  if (expectedUnit !== undefined) {
    // The user specified an expected unit
    conversionUnit = _findUnit(allUnits, expectedUnit, mode);
  } else {
    // The user wants the most appropriate unit
    conversionUnit = _findLargestUnit(unitMap, mag);
  }

  // Convert the unit
  var val = value / conversionUnit.val;
  var str = val.toFixed(decimalPlaces);
  var unit = conversionUnit.name;

  if (!fixedDecimals) {
    str = str.replace(formatDecimalsRegExp, '$1');
  }

  if (thousandsSeparator) {
    str = str.replace(formatThousandsRegExp, thousandsSeparator);
  }

  return str + unitSeparator + unit;
}

/**
 * Returns an array that tells you what units to convert to and in what order.
 */
function _getUnitMap(mode) {
  // Allow the mode synonym
  if (mode == 'metric') {
    return metricMap;
  } else if (mode == 'jedec') {
    return compatibilityMap;
  } else if (mode == 'binary') {
    return binaryMap;
  }
}

/**
 * Finds the given unit in the unit map
 */
function _findUnit(unitMap, unit, mode) {
  var conversionUnit;

  unit = unit.toLowerCase();

  // Check the compatibility units first
  if (mode == 'compatibility' || mode == 'jedec') {
    conversionUnit = allUnits['_' + unit];
  }

  // Otherwise check the rest of the units
  if (conversionUnit === undefined) {
    conversionUnit = allUnits[unit];
  }

  // Finally if we still didn't find the unit, its an error
  if (conversionUnit === undefined) {
    throw Error("byte.js: unit not found: " + unit);
  }

  return conversionUnit;
}

/**
 * Finds the largest unit that the value can be converted to
 *
 * @param {Array} unitMap Array of units sorted with the largest units first
 * @param {int}   value
 *
 * @returns {}
 * @private
 */
function _findLargestUnit(unitMap, value) {
  for (var i=0; i < unitMap.length; i++) {
    var unitData = unitMap[i];

    // Find the largest unit to convert to, otherwise use the last one
    if (value >= unitData.val || i >= unitMap.length - 1) {
      return unitData;
    }
  }

}

/**
 * Parse the string value into an integer in bytes.
 *
 * If no unit is given, it is assumed the value is in bytes.
 *
 * @param {number|string} val
 * @param {object} [options]
 * @param {string} [options.mode='metric']
 *
 * @returns {number|null}
 * @public
 */
function parse(val, options) {
  if (typeof val === 'number' && !isNaN(val)) {
    return val;
  }

  if (typeof val !== 'string') {
    return null;
  }

  // Mode info is only used to check for compatibility mode
  // Since the mode is already in the units used
  var mode = (options && options.mode) || 'metric';
  mode = _checkMode(mode);

  // Test if the string passed is valid
  var results = parseRegExp.exec(val);
  var floatValue;
  var unit;

  // No number was extracted from the input string
  if (!results) {
    return null;
  }

  // Retrieve the value and the unit
  floatValue = parseFloat(results[1]);
  unit = results[4];

  // Default unit if none are specified
  if (unit === undefined) {
    unit = 'b';
  }

  // Make sure we're case-insensitive
  unit = unit.toLowerCase();

  var unitData;
  // If we're using compatibility units, try those first
  if (mode == 'jedec') {
    unitData = allUnits['_' + unit];
  }

  // Try to get the unit from the normal units
  if (unitData === undefined) {
    unitData = allUnits[unit];
  }

  return Math.floor(unitData.val * floatValue);
}
