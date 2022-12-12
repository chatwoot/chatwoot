
/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

'use strict';

const Collection = require('../Collection');
const NodeCollection = require('./Node');
const once = require('../utils/once');
const recast = require('recast');

const astNodesAreEquivalent = recast.types.astNodesAreEquivalent;
const b = recast.types.builders;
var types = recast.types.namedTypes;

const VariableDeclarator = recast.types.namedTypes.VariableDeclarator;

/**
* @mixin
*/
const globalMethods = {
  /**
   * Finds all variable declarators, optionally filtered by name.
   *
   * @param {string} name
   * @return {Collection}
   */
  findVariableDeclarators: function(name) {
    const filter = name ? {id: {name: name}} : null;
    return this.find(VariableDeclarator, filter);
  }
};

const filterMethods = {
  /**
   * Returns a function that returns true if the provided path is a variable
   * declarator and requires one of the specified module names.
   *
   * @param {string|Array} names A module name or an array of module names
   * @return {Function}
   */
  requiresModule: function(names) {
    if (names && !Array.isArray(names)) {
      names = [names];
    }
    const requireIdentifier = b.identifier('require');
    return function(path) {
      const node = path.value;
      if (!VariableDeclarator.check(node) ||
          !types.CallExpression.check(node.init) ||
          !astNodesAreEquivalent(node.init.callee, requireIdentifier)) {
        return false;
      }
      return !names ||
        names.some(
          n => astNodesAreEquivalent(node.init.arguments[0], b.literal(n))
        );
    };
  }
};

/**
* @mixin
*/
const transformMethods = {
  /**
   * Renames a variable and all its occurrences.
   *
   * @param {string} newName
   * @return {Collection}
   */
  renameTo: function(newName) {
    // TODO: Include JSXElements
    return this.forEach(function(path) {
      const node = path.value;
      const oldName = node.id.name;
      const rootScope = path.scope;
      const rootPath = rootScope.path;
      Collection.fromPaths([rootPath])
        .find(types.Identifier, {name: oldName})
        .filter(function(path) { // ignore non-variables
          const parent = path.parent.node;

          if (
            types.MemberExpression.check(parent) &&
            parent.property === path.node &&
            !parent.computed
          ) {
            // obj.oldName
            return false;
          }

          if (
            types.Property.check(parent) &&
            parent.key === path.node &&
            !parent.computed
          ) {
            // { oldName: 3 }
            return false;
          }

          if (
            types.MethodDefinition.check(parent) &&
            parent.key === path.node &&
            !parent.computed
          ) {
            // class A { oldName() {} }
            return false;
          }

          if (
            types.ClassProperty.check(parent) &&
            parent.key === path.node &&
            !parent.computed
          ) {
            // class A { oldName = 3 }
            return false;
          }

          if (
            types.JSXAttribute.check(parent) &&
            parent.name === path.node &&
            !parent.computed
          ) {
            // <Foo oldName={oldName} />
            return false;
          }

          return true;
        })
        .forEach(function(path) {
          let scope = path.scope;
          while (scope && scope !== rootScope) {
            if (scope.declares(oldName)) {
              return;
            }
            scope = scope.parent;
          }
          if (scope) { // identifier must refer to declared variable

            // It may look like we filtered out properties,
            // but the filter only ignored property "keys", not "value"s
            // In shorthand properties, "key" and "value" both have an
            // Identifier with the same structure.
            const parent = path.parent.node;
            if (
              types.Property.check(parent) &&
              parent.shorthand &&
              !parent.method
            )  {

              path.parent.get('shorthand').replace(false);
            }

            path.get('name').replace(newName);
          }
        });
    });
  }
};


function register() {
  NodeCollection.register();
  Collection.registerMethods(globalMethods);
  Collection.registerMethods(transformMethods, VariableDeclarator);
}

exports.register = once(register);
exports.filters = filterMethods;
