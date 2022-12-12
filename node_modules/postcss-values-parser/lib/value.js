'use strict';

const Container = require('./container');

module.exports = class Value extends Container {
  constructor (opts) {
    super(opts);
    this.type = 'value';
    this.unbalanced = 0;
  }
};
