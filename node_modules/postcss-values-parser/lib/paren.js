'use strict';

const Container = require('./container');
const Node = require('./node');

class Parenthesis extends Node {
  constructor (opts) {
    super(opts);
    this.type = 'paren';
    this.parenType = '';
  }
}

Container.registerWalker(Parenthesis);

module.exports = Parenthesis;
