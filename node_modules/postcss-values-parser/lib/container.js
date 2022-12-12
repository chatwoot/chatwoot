'use strict';

const Node = require('./node');

class Container extends Node {

  constructor (opts) {
    super(opts);

    if (!this.nodes) {
      this.nodes = [];
    }
  }

  push (child) {
    child.parent = this;
    this.nodes.push(child);
    return this;
  }

  each (callback) {
    if (!this.lastEach) this.lastEach = 0;
    if (!this.indexes) this.indexes = { };

    this.lastEach += 1;

    let id = this.lastEach,
      index,
      result;

    this.indexes[id] = 0;

    if (!this.nodes) return undefined;

    while (this.indexes[id] < this.nodes.length) {
      index  = this.indexes[id];
      result = callback(this.nodes[index], index);
      if (result === false) break;

      this.indexes[id] += 1;
    }

    delete this.indexes[id];

    return result;
  }

  walk (callback) {
    return this.each((child, i) => {
      let result = callback(child, i);
      if (result !== false && child.walk) {
        result = child.walk(callback);
      }
      return result;
    });
  }

  walkType (type, callback) {
    if (!type || !callback) {
      throw new Error('Parameters {type} and {callback} are required.');
    }

    // allow users to pass a constructor, or node type string; eg. Word.
    const isTypeCallable = typeof type === 'function';

    return this.walk((node, index) => {
      if (isTypeCallable && node instanceof type || !isTypeCallable && node.type === type) {
        return callback.call(this, node, index);
      }
    });
  }

  append (node) {
    node.parent = this;
    this.nodes.push(node);
    return this;
  }

  prepend (node) {
    node.parent = this;
    this.nodes.unshift(node);
    return this;
  }

  cleanRaws (keepBetween) {
    super.cleanRaws(keepBetween);
    if (this.nodes) {
      for (let node of this.nodes) node.cleanRaws(keepBetween);
    }
  }

  insertAfter (oldNode, newNode) {
    let oldIndex = this.index(oldNode),
      index;

    this.nodes.splice(oldIndex + 1, 0, newNode);

    for (let id in this.indexes) {
      index = this.indexes[id];
      if (oldIndex <= index) {
        this.indexes[id] = index + this.nodes.length;
      }
    }

    return this;
  }

  insertBefore (oldNode, newNode) {
    let oldIndex = this.index(oldNode),
      index;

    this.nodes.splice(oldIndex, 0, newNode);

    for (let id in this.indexes) {
      index = this.indexes[id];
      if (oldIndex <= index) {
        this.indexes[id] = index + this.nodes.length;
      }
    }

    return this;
  }

  removeChild (child) {
    child = this.index(child);
    this.nodes[child].parent = undefined;
    this.nodes.splice(child, 1);

    let index;
    for (let id in this.indexes) {
      index = this.indexes[id];
      if (index >= child) {
        this.indexes[id] = index - 1;
      }
    }

    return this;
  }

  removeAll () {
    for (let node of this.nodes) node.parent = undefined;
    this.nodes = [];
    return this;
  }

  every (condition) {
    return this.nodes.every(condition);
  }

  some (condition) {
    return this.nodes.some(condition);
  }

  index (child) {
    if (typeof child === 'number') {
      return child;
    }
    else {
      return this.nodes.indexOf(child);
    }
  }

  get first () {
    if (!this.nodes) return undefined;
    return this.nodes[0];
  }

  get last () {
    if (!this.nodes) return undefined;
    return this.nodes[this.nodes.length - 1];
  }

  toString () {
    let result = this.nodes.map(String).join('');

    if (this.value) {
      result = this.value + result;
    }

    if (this.raws.before) {
      result = this.raws.before + result;
    }

    if (this.raws.after) {
      result += this.raws.after;
    }

    return result;
  }
}

Container.registerWalker = (constructor) => {
  let walkerName = 'walk' + constructor.name;

  // plural sugar
  if (walkerName.lastIndexOf('s') !== walkerName.length - 1) {
    walkerName += 's';
  }

  if (Container.prototype[walkerName]) {
    return;
  }

  // we need access to `this` so we can't use an arrow function
  Container.prototype[walkerName] = function (callback) {
    return this.walkType(constructor, callback);
  };
};

module.exports = Container;
