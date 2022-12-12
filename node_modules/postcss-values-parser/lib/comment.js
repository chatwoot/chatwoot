'use strict';

const Container = require('./container');
const Node = require('./node');

class Comment extends Node {
  constructor (opts) {
    super(opts);
    this.type = 'comment';
    this.inline = Object(opts).inline || false;
  }

  toString () {
    return [
      this.raws.before,
      this.inline ? '//' : '/*',
      String(this.value),
      this.inline ? '' : '*/',
      this.raws.after
    ].join('');
  }
};

Container.registerWalker(Comment);

module.exports = Comment;
