'use strict';

const Container = require('./container');
const Node = require('./node');

class Word extends Node {
  constructor (opts) {
    super(opts);
    this.type = 'word';
  }
}

Container.registerWalker(Word);

module.exports = Word;
