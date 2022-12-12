'use strict';

const Container = require('./container');
const Node = require('./node');

class Colon extends Node {
  constructor (opts) {
    super(opts);
    this.type = 'colon';
  }
}

Container.registerWalker(Colon);

module.exports = Colon;
