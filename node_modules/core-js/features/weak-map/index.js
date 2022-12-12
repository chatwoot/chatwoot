var parent = require('../../es/weak-map');
require('../../modules/esnext.weak-map.emplace');
require('../../modules/esnext.weak-map.from');
require('../../modules/esnext.weak-map.of');
require('../../modules/esnext.weak-map.delete-all');
// TODO: remove from `core-js@4`
require('../../modules/esnext.weak-map.upsert');

module.exports = parent;
