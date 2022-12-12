
/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

'use strict';

const Collection = require('../Collection');

const matchNode = require('../matchNode');
const once = require('../utils/once');
const recast = require('recast');

const Node = recast.types.namedTypes.Node;
var types = recast.types.namedTypes;

/**
* @mixin
*/
const traversalMethods = {

  /**
   * Find nodes of a specific type within the nodes of this collection.
   *
   * @param {type}
   * @param {filter}
   * @return {Collection}
   */
  find: function(type, filter) {
    const paths = [];
    const visitorMethodName = 'visit' + type;

    const visitor = {};
    function visit(path) {
      /*jshint validthis:true */
      if (!filter || matchNode(path.value, filter)) {
        paths.push(path);
      }
      this.traverse(path);
    }
    this.__paths.forEach(function(p, i) {
      const self = this;
      visitor[visitorMethodName] = function(path) {
        if (self.__paths[i] === path) {
          this.traverse(path);
        } else {
          return visit.call(this, path);
        }
      };
      recast.visit(p, visitor);
    }, this);

    return Collection.fromPaths(paths, this, type);
  },

  /**
   * Returns a collection containing the paths that create the scope of the
   * currently selected paths. Dedupes the paths.
   *
   * @return {Collection}
   */
  closestScope: function() {
    return this.map(path => path.scope && path.scope.path);
  },

  /**
   * Traverse the AST up and finds the closest node of the provided type.
   *
   * @param {Collection}
   * @param {filter}
   * @return {Collection}
   */
  closest: function(type, filter) {
    return this.map(function(path) {
      let parent = path.parent;
      while (
        parent &&
        !(
          type.check(parent.value) &&
          (!filter || matchNode(parent.value, filter))
        )
      ) {
        parent = parent.parent;
      }
      return parent || null;
    });
  },

  /**
   * Finds the declaration for each selected path. Useful for member expressions
   * or JSXElements. Expects a callback function that maps each path to the name
   * to look for.
   *
   * If the callback returns a falsey value, the element is skipped.
   *
   * @param {function} nameGetter
   *
   * @return {Collection}
   */
  getVariableDeclarators: function(nameGetter) {
    return this.map(function(path) {
      /*jshint curly:false*/
      let scope = path.scope;
      if (!scope) return;
      const name = nameGetter.apply(path, arguments);
      if (!name) return;
      scope = scope.lookup(name);
      if (!scope) return;
      const bindings = scope.getBindings()[name];
      if (!bindings) return;
      const decl = Collection.fromPaths(bindings)
        .closest(types.VariableDeclarator);
      if (decl.length === 1) {
        return decl.paths()[0];
      }
    }, types.VariableDeclarator);
  },
};

function toArray(value) {
  return Array.isArray(value) ? value : [value];
}

/**
* @mixin
*/
const mutationMethods = {
  /**
   * Simply replaces the selected nodes with the provided node. If a function
   * is provided it is executed for every node and the node is replaced with the
   * functions return value.
   *
   * @param {Node|Array<Node>|function} nodes
   * @return {Collection}
   */
  replaceWith: function(nodes) {
    return this.forEach(function(path, i) {
      const newNodes =
        (typeof nodes === 'function') ? nodes.call(path, path, i) : nodes;
      path.replace.apply(path, toArray(newNodes));
    });
  },

  /**
   * Inserts a new node before the current one.
   *
   * @param {Node|Array<Node>|function} insert
   * @return {Collection}
   */
  insertBefore: function(insert) {
    return this.forEach(function(path, i) {
      const newNodes =
        (typeof insert === 'function') ? insert.call(path, path, i) : insert;
      path.insertBefore.apply(path, toArray(newNodes));
    });
  },

  /**
   * Inserts a new node after the current one.
   *
   * @param {Node|Array<Node>|function} insert
   * @return {Collection}
   */
  insertAfter: function(insert) {
    return this.forEach(function(path, i) {
      const newNodes =
        (typeof insert === 'function') ? insert.call(path, path, i) : insert;
      path.insertAfter.apply(path, toArray(newNodes));
    });
  },

  remove: function() {
    return this.forEach(path => path.prune());
  }

};

function register() {
  Collection.registerMethods(traversalMethods, Node);
  Collection.registerMethods(mutationMethods, Node);
  Collection.setDefaultCollectionType(Node);
}

exports.register = once(register);
