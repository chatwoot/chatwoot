'use strict';

const Container = require('./container');

module.exports = class Root extends Container {
  constructor (opts) {
    super(opts);
    this.type = 'root';
  }
};
