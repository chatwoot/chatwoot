var
  QUnit = require('qunit'),
  toUnsigned = require('../lib/utils/bin').toUnsigned;

QUnit.module('Binary Utils');

QUnit.test('converts values to unsigned integers after bitwise operations', function(assert) {
  var bytes;

  bytes = [0, 0, 124, 129];

  assert.equal(toUnsigned(bytes[0] << 24 |
                         bytes[1] << 16 |
                         bytes[2] <<  8 |
                         bytes[3]),
              31873, 'positive signed result stays positive');

  bytes = [150, 234, 221, 192];

  // sanity check
  assert.equal(bytes[0] << 24 |
              bytes[1] << 16 |
              bytes[2] <<  8 |
              bytes[3],
              -1762992704, 'bitwise operation produces negative signed result');

  assert.equal(toUnsigned(bytes[0] << 24 |
                         bytes[1] << 16 |
                         bytes[2] <<  8 |
                         bytes[3]),
              2531974592, 'negative signed result becomes unsigned positive');
});
