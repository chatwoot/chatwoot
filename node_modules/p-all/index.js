'use strict';
const pMap = require('p-map');

module.exports = (iterable, options) => pMap(iterable, element => element(), options);
// TODO: Remove this for the next major release
module.exports.default = module.exports;
