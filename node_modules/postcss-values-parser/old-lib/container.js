const Node = require('./node');

class Container extends Node {
  walk(callback) {
    return this.each((child, i) => {
      let result = callback(child, i);
      if (result !== false && child.walk) {
        result = child.walk(callback);
      }
      return result;
    });
  }

  walkType(type, callback) {
    if (!type || !callback) {
      throw new Error('Parameters {type} and {callback} are required.');
    }

    // allow users to pass a constructor, or node type string; eg. Word.
    const isTypeCallable = typeof type === 'function';

    return this.walk((node, index) => {
      if ((isTypeCallable && node instanceof type) || (!isTypeCallable && node.type === type)) {
        return callback.call(this, node, index);
      }
    });
  }
}

Container.registerWalker = (constructor) => {
  let walkerName = `walk${constructor.name}`;

  // plural sugar
  if (walkerName.lastIndexOf('s') !== walkerName.length - 1) {
    walkerName += 's';
  }

  if (Container.prototype[walkerName]) {
    return;
  }

  // we need access to `this` so we can't use an arrow function
  Container.prototype[walkerName] = function(callback) {
    return this.walkType(constructor, callback);
  };
};

module.exports = Container;
