'use strict';

const Container = require('./container');

class AtWord extends Container {
  constructor (opts) {
    super(opts);
    this.type = 'atword';
  }

  toString () {
    let quote = this.quoted ? this.raws.quote : '';
    return [
      this.raws.before,
      '@',
      // we can't use String() here because it'll try using itself
      // as the constructor
      String.prototype.toString.call(this.value),
      this.raws.after
    ].join('');
  }
}

Container.registerWalker(AtWord);

module.exports = AtWord;
