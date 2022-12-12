"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.buildFieldsInitNodes = buildFieldsInitNodes;
exports.buildPrivateNamesMap = buildPrivateNamesMap;
exports.buildPrivateNamesNodes = buildPrivateNamesNodes;
exports.transformPrivateNamesUsage = transformPrivateNamesUsage;

var _core = require("@babel/core");

var _helperReplaceSupers = require("@babel/helper-replace-supers");

var _helperEnvironmentVisitor = require("@babel/helper-environment-visitor");

var _helperMemberExpressionToFunctions = require("@babel/helper-member-expression-to-functions");

var _helperOptimiseCallExpression = require("@babel/helper-optimise-call-expression");

var _helperAnnotateAsPure = require("@babel/helper-annotate-as-pure");

var ts = require("./typescript");

function buildPrivateNamesMap(props) {
  const privateNamesMap = new Map();

  for (const prop of props) {
    if (prop.isPrivate()) {
      const {
        name
      } = prop.node.key.id;
      const update = privateNamesMap.has(name) ? privateNamesMap.get(name) : {
        id: prop.scope.generateUidIdentifier(name),
        static: prop.node.static,
        method: !prop.isProperty()
      };

      if (prop.isClassPrivateMethod()) {
        if (prop.node.kind === "get") {
          update.getId = prop.scope.generateUidIdentifier(`get_${name}`);
        } else if (prop.node.kind === "set") {
          update.setId = prop.scope.generateUidIdentifier(`set_${name}`);
        } else if (prop.node.kind === "method") {
          update.methodId = prop.scope.generateUidIdentifier(name);
        }
      }

      privateNamesMap.set(name, update);
    }
  }

  return privateNamesMap;
}

function buildPrivateNamesNodes(privateNamesMap, privateFieldsAsProperties, state) {
  const initNodes = [];

  for (const [name, value] of privateNamesMap) {
    const {
      static: isStatic,
      method: isMethod,
      getId,
      setId
    } = value;
    const isAccessor = getId || setId;

    const id = _core.types.cloneNode(value.id);

    let init;

    if (privateFieldsAsProperties) {
      init = _core.types.callExpression(state.addHelper("classPrivateFieldLooseKey"), [_core.types.stringLiteral(name)]);
    } else if (!isStatic) {
      init = _core.types.newExpression(_core.types.identifier(!isMethod || isAccessor ? "WeakMap" : "WeakSet"), []);
    }

    if (init) {
      (0, _helperAnnotateAsPure.default)(init);
      initNodes.push(_core.template.statement.ast`var ${id} = ${init}`);
    }
  }

  return initNodes;
}

function privateNameVisitorFactory(visitor) {
  const privateNameVisitor = Object.assign({}, visitor, {
    Class(path) {
      const {
        privateNamesMap
      } = this;
      const body = path.get("body.body");
      const visiblePrivateNames = new Map(privateNamesMap);
      const redeclared = [];

      for (const prop of body) {
        if (!prop.isPrivate()) continue;
        const {
          name
        } = prop.node.key.id;
        visiblePrivateNames.delete(name);
        redeclared.push(name);
      }

      if (!redeclared.length) {
        return;
      }

      path.get("body").traverse(nestedVisitor, Object.assign({}, this, {
        redeclared
      }));
      path.traverse(privateNameVisitor, Object.assign({}, this, {
        privateNamesMap: visiblePrivateNames
      }));
      path.skipKey("body");
    }

  });

  const nestedVisitor = _core.traverse.visitors.merge([Object.assign({}, visitor), _helperEnvironmentVisitor.default]);

  return privateNameVisitor;
}

const privateNameVisitor = privateNameVisitorFactory({
  PrivateName(path, {
    noDocumentAll
  }) {
    const {
      privateNamesMap,
      redeclared
    } = this;
    const {
      node,
      parentPath
    } = path;

    if (!parentPath.isMemberExpression({
      property: node
    }) && !parentPath.isOptionalMemberExpression({
      property: node
    })) {
      return;
    }

    const {
      name
    } = node.id;
    if (!privateNamesMap.has(name)) return;
    if (redeclared && redeclared.includes(name)) return;
    this.handle(parentPath, noDocumentAll);
  }

});

function unshadow(name, scope, innerBinding) {
  while ((_scope = scope) != null && _scope.hasBinding(name) && !scope.bindingIdentifierEquals(name, innerBinding)) {
    var _scope;

    scope.rename(name);
    scope = scope.parent;
  }
}

const privateInVisitor = privateNameVisitorFactory({
  BinaryExpression(path) {
    const {
      operator,
      left,
      right
    } = path.node;
    if (operator !== "in") return;
    if (!_core.types.isPrivateName(left)) return;
    const {
      privateFieldsAsProperties,
      privateNamesMap,
      redeclared
    } = this;
    const {
      name
    } = left.id;
    if (!privateNamesMap.has(name)) return;
    if (redeclared && redeclared.includes(name)) return;
    unshadow(this.classRef.name, path.scope, this.innerBinding);

    if (privateFieldsAsProperties) {
      const {
        id
      } = privateNamesMap.get(name);
      path.replaceWith(_core.template.expression.ast`
        Object.prototype.hasOwnProperty.call(${right}, ${_core.types.cloneNode(id)})
      `);
      return;
    }

    const {
      id,
      static: isStatic
    } = privateNamesMap.get(name);

    if (isStatic) {
      path.replaceWith(_core.template.expression.ast`${right} === ${this.classRef}`);
      return;
    }

    path.replaceWith(_core.template.expression.ast`${_core.types.cloneNode(id)}.has(${right})`);
  }

});
const privateNameHandlerSpec = {
  memoise(member, count) {
    const {
      scope
    } = member;
    const {
      object
    } = member.node;
    const memo = scope.maybeGenerateMemoised(object);

    if (!memo) {
      return;
    }

    this.memoiser.set(object, memo, count);
  },

  receiver(member) {
    const {
      object
    } = member.node;

    if (this.memoiser.has(object)) {
      return _core.types.cloneNode(this.memoiser.get(object));
    }

    return _core.types.cloneNode(object);
  },

  get(member) {
    const {
      classRef,
      privateNamesMap,
      file,
      innerBinding
    } = this;
    const {
      name
    } = member.node.property.id;
    const {
      id,
      static: isStatic,
      method: isMethod,
      methodId,
      getId,
      setId
    } = privateNamesMap.get(name);
    const isAccessor = getId || setId;

    if (isStatic) {
      const helperName = isMethod && !isAccessor ? "classStaticPrivateMethodGet" : "classStaticPrivateFieldSpecGet";
      unshadow(classRef.name, member.scope, innerBinding);
      return _core.types.callExpression(file.addHelper(helperName), [this.receiver(member), _core.types.cloneNode(classRef), _core.types.cloneNode(id)]);
    }

    if (isMethod) {
      if (isAccessor) {
        if (!getId && setId) {
          if (file.availableHelper("writeOnlyError")) {
            return _core.types.sequenceExpression([this.receiver(member), _core.types.callExpression(file.addHelper("writeOnlyError"), [_core.types.stringLiteral(`#${name}`)])]);
          }

          console.warn(`@babel/helpers is outdated, update it to silence this warning.`);
        }

        return _core.types.callExpression(file.addHelper("classPrivateFieldGet"), [this.receiver(member), _core.types.cloneNode(id)]);
      }

      return _core.types.callExpression(file.addHelper("classPrivateMethodGet"), [this.receiver(member), _core.types.cloneNode(id), _core.types.cloneNode(methodId)]);
    }

    return _core.types.callExpression(file.addHelper("classPrivateFieldGet"), [this.receiver(member), _core.types.cloneNode(id)]);
  },

  boundGet(member) {
    this.memoise(member, 1);
    return _core.types.callExpression(_core.types.memberExpression(this.get(member), _core.types.identifier("bind")), [this.receiver(member)]);
  },

  set(member, value) {
    const {
      classRef,
      privateNamesMap,
      file
    } = this;
    const {
      name
    } = member.node.property.id;
    const {
      id,
      static: isStatic,
      method: isMethod,
      setId,
      getId
    } = privateNamesMap.get(name);
    const isAccessor = getId || setId;

    if (isStatic) {
      const helperName = isMethod && !isAccessor ? "classStaticPrivateMethodSet" : "classStaticPrivateFieldSpecSet";
      return _core.types.callExpression(file.addHelper(helperName), [this.receiver(member), _core.types.cloneNode(classRef), _core.types.cloneNode(id), value]);
    }

    if (isMethod) {
      if (setId) {
        return _core.types.callExpression(file.addHelper("classPrivateFieldSet"), [this.receiver(member), _core.types.cloneNode(id), value]);
      }

      return _core.types.sequenceExpression([this.receiver(member), value, _core.types.callExpression(file.addHelper("readOnlyError"), [_core.types.stringLiteral(`#${name}`)])]);
    }

    return _core.types.callExpression(file.addHelper("classPrivateFieldSet"), [this.receiver(member), _core.types.cloneNode(id), value]);
  },

  destructureSet(member) {
    const {
      classRef,
      privateNamesMap,
      file
    } = this;
    const {
      name
    } = member.node.property.id;
    const {
      id,
      static: isStatic
    } = privateNamesMap.get(name);

    if (isStatic) {
      try {
        var helper = file.addHelper("classStaticPrivateFieldDestructureSet");
      } catch (_unused) {
        throw new Error("Babel can not transpile `[C.#p] = [0]` with @babel/helpers < 7.13.10, \n" + "please update @babel/helpers to the latest version.");
      }

      return _core.types.memberExpression(_core.types.callExpression(helper, [this.receiver(member), _core.types.cloneNode(classRef), _core.types.cloneNode(id)]), _core.types.identifier("value"));
    }

    return _core.types.memberExpression(_core.types.callExpression(file.addHelper("classPrivateFieldDestructureSet"), [this.receiver(member), _core.types.cloneNode(id)]), _core.types.identifier("value"));
  },

  call(member, args) {
    this.memoise(member, 1);
    return (0, _helperOptimiseCallExpression.default)(this.get(member), this.receiver(member), args, false);
  },

  optionalCall(member, args) {
    this.memoise(member, 1);
    return (0, _helperOptimiseCallExpression.default)(this.get(member), this.receiver(member), args, true);
  }

};
const privateNameHandlerLoose = {
  get(member) {
    const {
      privateNamesMap,
      file
    } = this;
    const {
      object
    } = member.node;
    const {
      name
    } = member.node.property.id;
    return _core.template.expression`BASE(REF, PROP)[PROP]`({
      BASE: file.addHelper("classPrivateFieldLooseBase"),
      REF: _core.types.cloneNode(object),
      PROP: _core.types.cloneNode(privateNamesMap.get(name).id)
    });
  },

  set() {
    throw new Error("private name handler with loose = true don't need set()");
  },

  boundGet(member) {
    return _core.types.callExpression(_core.types.memberExpression(this.get(member), _core.types.identifier("bind")), [_core.types.cloneNode(member.node.object)]);
  },

  simpleSet(member) {
    return this.get(member);
  },

  destructureSet(member) {
    return this.get(member);
  },

  call(member, args) {
    return _core.types.callExpression(this.get(member), args);
  },

  optionalCall(member, args) {
    return _core.types.optionalCallExpression(this.get(member), args, true);
  }

};

function transformPrivateNamesUsage(ref, path, privateNamesMap, {
  privateFieldsAsProperties,
  noDocumentAll,
  innerBinding
}, state) {
  if (!privateNamesMap.size) return;
  const body = path.get("body");
  const handler = privateFieldsAsProperties ? privateNameHandlerLoose : privateNameHandlerSpec;
  (0, _helperMemberExpressionToFunctions.default)(body, privateNameVisitor, Object.assign({
    privateNamesMap,
    classRef: ref,
    file: state
  }, handler, {
    noDocumentAll,
    innerBinding
  }));
  body.traverse(privateInVisitor, {
    privateNamesMap,
    classRef: ref,
    file: state,
    privateFieldsAsProperties,
    innerBinding
  });
}

function buildPrivateFieldInitLoose(ref, prop, privateNamesMap) {
  const {
    id
  } = privateNamesMap.get(prop.node.key.id.name);
  const value = prop.node.value || prop.scope.buildUndefinedNode();
  return _core.template.statement.ast`
    Object.defineProperty(${ref}, ${_core.types.cloneNode(id)}, {
      // configurable is false by default
      // enumerable is false by default
      writable: true,
      value: ${value}
    });
  `;
}

function buildPrivateInstanceFieldInitSpec(ref, prop, privateNamesMap, state) {
  const {
    id
  } = privateNamesMap.get(prop.node.key.id.name);
  const value = prop.node.value || prop.scope.buildUndefinedNode();
  {
    if (!state.availableHelper("classPrivateFieldInitSpec")) {
      return _core.template.statement.ast`${_core.types.cloneNode(id)}.set(${ref}, {
        // configurable is always false for private elements
        // enumerable is always false for private elements
        writable: true,
        value: ${value},
      })`;
    }
  }
  const helper = state.addHelper("classPrivateFieldInitSpec");
  return _core.template.statement.ast`${helper}(
    ${_core.types.thisExpression()},
    ${_core.types.cloneNode(id)},
    {
      writable: true,
      value: ${value}
    },
  )`;
}

function buildPrivateStaticFieldInitSpec(prop, privateNamesMap) {
  const privateName = privateNamesMap.get(prop.node.key.id.name);
  const {
    id,
    getId,
    setId,
    initAdded
  } = privateName;
  const isAccessor = getId || setId;
  if (!prop.isProperty() && (initAdded || !isAccessor)) return;

  if (isAccessor) {
    privateNamesMap.set(prop.node.key.id.name, Object.assign({}, privateName, {
      initAdded: true
    }));
    return _core.template.statement.ast`
      var ${_core.types.cloneNode(id)} = {
        // configurable is false by default
        // enumerable is false by default
        // writable is false by default
        get: ${getId ? getId.name : prop.scope.buildUndefinedNode()},
        set: ${setId ? setId.name : prop.scope.buildUndefinedNode()}
      }
    `;
  }

  const value = prop.node.value || prop.scope.buildUndefinedNode();
  return _core.template.statement.ast`
    var ${_core.types.cloneNode(id)} = {
      // configurable is false by default
      // enumerable is false by default
      writable: true,
      value: ${value}
    };
  `;
}

function buildPrivateMethodInitLoose(ref, prop, privateNamesMap) {
  const privateName = privateNamesMap.get(prop.node.key.id.name);
  const {
    methodId,
    id,
    getId,
    setId,
    initAdded
  } = privateName;
  if (initAdded) return;

  if (methodId) {
    return _core.template.statement.ast`
        Object.defineProperty(${ref}, ${id}, {
          // configurable is false by default
          // enumerable is false by default
          // writable is false by default
          value: ${methodId.name}
        });
      `;
  }

  const isAccessor = getId || setId;

  if (isAccessor) {
    privateNamesMap.set(prop.node.key.id.name, Object.assign({}, privateName, {
      initAdded: true
    }));
    return _core.template.statement.ast`
      Object.defineProperty(${ref}, ${id}, {
        // configurable is false by default
        // enumerable is false by default
        // writable is false by default
        get: ${getId ? getId.name : prop.scope.buildUndefinedNode()},
        set: ${setId ? setId.name : prop.scope.buildUndefinedNode()}
      });
    `;
  }
}

function buildPrivateInstanceMethodInitSpec(ref, prop, privateNamesMap, state) {
  const privateName = privateNamesMap.get(prop.node.key.id.name);
  const {
    getId,
    setId,
    initAdded
  } = privateName;
  if (initAdded) return;
  const isAccessor = getId || setId;

  if (isAccessor) {
    return buildPrivateAccessorInitialization(ref, prop, privateNamesMap, state);
  }

  return buildPrivateInstanceMethodInitalization(ref, prop, privateNamesMap, state);
}

function buildPrivateAccessorInitialization(ref, prop, privateNamesMap, state) {
  const privateName = privateNamesMap.get(prop.node.key.id.name);
  const {
    id,
    getId,
    setId
  } = privateName;
  privateNamesMap.set(prop.node.key.id.name, Object.assign({}, privateName, {
    initAdded: true
  }));
  {
    if (!state.availableHelper("classPrivateFieldInitSpec")) {
      return _core.template.statement.ast`
      ${id}.set(${ref}, {
        get: ${getId ? getId.name : prop.scope.buildUndefinedNode()},
        set: ${setId ? setId.name : prop.scope.buildUndefinedNode()}
      });
    `;
    }
  }
  const helper = state.addHelper("classPrivateFieldInitSpec");
  return _core.template.statement.ast`${helper}(
    ${_core.types.thisExpression()},
    ${_core.types.cloneNode(id)},
    {
      get: ${getId ? getId.name : prop.scope.buildUndefinedNode()},
      set: ${setId ? setId.name : prop.scope.buildUndefinedNode()}
    },
  )`;
}

function buildPrivateInstanceMethodInitalization(ref, prop, privateNamesMap, state) {
  const privateName = privateNamesMap.get(prop.node.key.id.name);
  const {
    id
  } = privateName;
  {
    if (!state.availableHelper("classPrivateMethodInitSpec")) {
      return _core.template.statement.ast`${id}.add(${ref})`;
    }
  }
  const helper = state.addHelper("classPrivateMethodInitSpec");
  return _core.template.statement.ast`${helper}(
    ${_core.types.thisExpression()},
    ${_core.types.cloneNode(id)}
  )`;
}

function buildPublicFieldInitLoose(ref, prop) {
  const {
    key,
    computed
  } = prop.node;
  const value = prop.node.value || prop.scope.buildUndefinedNode();
  return _core.types.expressionStatement(_core.types.assignmentExpression("=", _core.types.memberExpression(ref, key, computed || _core.types.isLiteral(key)), value));
}

function buildPublicFieldInitSpec(ref, prop, state) {
  const {
    key,
    computed
  } = prop.node;
  const value = prop.node.value || prop.scope.buildUndefinedNode();
  return _core.types.expressionStatement(_core.types.callExpression(state.addHelper("defineProperty"), [ref, computed || _core.types.isLiteral(key) ? key : _core.types.stringLiteral(key.name), value]));
}

function buildPrivateStaticMethodInitLoose(ref, prop, state, privateNamesMap) {
  const privateName = privateNamesMap.get(prop.node.key.id.name);
  const {
    id,
    methodId,
    getId,
    setId,
    initAdded
  } = privateName;
  if (initAdded) return;
  const isAccessor = getId || setId;

  if (isAccessor) {
    privateNamesMap.set(prop.node.key.id.name, Object.assign({}, privateName, {
      initAdded: true
    }));
    return _core.template.statement.ast`
      Object.defineProperty(${ref}, ${id}, {
        // configurable is false by default
        // enumerable is false by default
        // writable is false by default
        get: ${getId ? getId.name : prop.scope.buildUndefinedNode()},
        set: ${setId ? setId.name : prop.scope.buildUndefinedNode()}
      })
    `;
  }

  return _core.template.statement.ast`
    Object.defineProperty(${ref}, ${id}, {
      // configurable is false by default
      // enumerable is false by default
      // writable is false by default
      value: ${methodId.name}
    });
  `;
}

function buildPrivateMethodDeclaration(prop, privateNamesMap, privateFieldsAsProperties = false) {
  const privateName = privateNamesMap.get(prop.node.key.id.name);
  const {
    id,
    methodId,
    getId,
    setId,
    getterDeclared,
    setterDeclared,
    static: isStatic
  } = privateName;
  const {
    params,
    body,
    generator,
    async
  } = prop.node;
  const isGetter = getId && !getterDeclared && params.length === 0;
  const isSetter = setId && !setterDeclared && params.length > 0;
  let declId = methodId;

  if (isGetter) {
    privateNamesMap.set(prop.node.key.id.name, Object.assign({}, privateName, {
      getterDeclared: true
    }));
    declId = getId;
  } else if (isSetter) {
    privateNamesMap.set(prop.node.key.id.name, Object.assign({}, privateName, {
      setterDeclared: true
    }));
    declId = setId;
  } else if (isStatic && !privateFieldsAsProperties) {
    declId = id;
  }

  return _core.types.functionDeclaration(_core.types.cloneNode(declId), params, body, generator, async);
}

const thisContextVisitor = _core.traverse.visitors.merge([{
  ThisExpression(path, state) {
    state.needsClassRef = true;
    path.replaceWith(_core.types.cloneNode(state.classRef));
  },

  MetaProperty(path) {
    const meta = path.get("meta");
    const property = path.get("property");
    const {
      scope
    } = path;

    if (meta.isIdentifier({
      name: "new"
    }) && property.isIdentifier({
      name: "target"
    })) {
      path.replaceWith(scope.buildUndefinedNode());
    }
  }

}, _helperEnvironmentVisitor.default]);

const innerReferencesVisitor = {
  ReferencedIdentifier(path, state) {
    if (path.scope.bindingIdentifierEquals(path.node.name, state.innerBinding)) {
      state.needsClassRef = true;
      path.node.name = state.classRef.name;
    }
  }

};

function replaceThisContext(path, ref, getSuperRef, file, isStaticBlock, constantSuper, innerBindingRef) {
  var _state$classRef;

  const state = {
    classRef: ref,
    needsClassRef: false,
    innerBinding: innerBindingRef
  };
  const replacer = new _helperReplaceSupers.default({
    methodPath: path,
    constantSuper,
    file,
    refToPreserve: ref,
    getSuperRef,

    getObjectRef() {
      state.needsClassRef = true;
      return _core.types.isStaticBlock != null && _core.types.isStaticBlock(path.node) || path.node.static ? ref : _core.types.memberExpression(ref, _core.types.identifier("prototype"));
    }

  });
  replacer.replace();

  if (isStaticBlock || path.isProperty()) {
    path.traverse(thisContextVisitor, state);
  }

  if (innerBindingRef != null && (_state$classRef = state.classRef) != null && _state$classRef.name && state.classRef.name !== (innerBindingRef == null ? void 0 : innerBindingRef.name)) {
    path.traverse(innerReferencesVisitor, state);
  }

  return state.needsClassRef;
}

function isNameOrLength({
  key,
  computed
}) {
  if (key.type === "Identifier") {
    return !computed && (key.name === "name" || key.name === "length");
  }

  if (key.type === "StringLiteral") {
    return key.value === "name" || key.value === "length";
  }

  return false;
}

function buildFieldsInitNodes(ref, superRef, props, privateNamesMap, state, setPublicClassFields, privateFieldsAsProperties, constantSuper, innerBindingRef) {
  let needsClassRef = false;
  let injectSuperRef;
  const staticNodes = [];
  const instanceNodes = [];
  const pureStaticNodes = [];
  const getSuperRef = _core.types.isIdentifier(superRef) ? () => superRef : () => {
    var _injectSuperRef;

    (_injectSuperRef = injectSuperRef) != null ? _injectSuperRef : injectSuperRef = props[0].scope.generateUidIdentifierBasedOnNode(superRef);
    return injectSuperRef;
  };

  for (const prop of props) {
    prop.isClassProperty() && ts.assertFieldTransformed(prop);
    const isStatic = !(_core.types.isStaticBlock != null && _core.types.isStaticBlock(prop.node)) && prop.node.static;
    const isInstance = !isStatic;
    const isPrivate = prop.isPrivate();
    const isPublic = !isPrivate;
    const isField = prop.isProperty();
    const isMethod = !isField;
    const isStaticBlock = prop.isStaticBlock == null ? void 0 : prop.isStaticBlock();

    if (isStatic || isMethod && isPrivate || isStaticBlock) {
      const replaced = replaceThisContext(prop, ref, getSuperRef, state, isStaticBlock, constantSuper, innerBindingRef);
      needsClassRef = needsClassRef || replaced;
    }

    switch (true) {
      case isStaticBlock:
        {
          const blockBody = prop.node.body;

          if (blockBody.length === 1 && _core.types.isExpressionStatement(blockBody[0])) {
            staticNodes.push(blockBody[0]);
          } else {
            staticNodes.push(_core.template.statement.ast`(() => { ${blockBody} })()`);
          }

          break;
        }

      case isStatic && isPrivate && isField && privateFieldsAsProperties:
        needsClassRef = true;
        staticNodes.push(buildPrivateFieldInitLoose(_core.types.cloneNode(ref), prop, privateNamesMap));
        break;

      case isStatic && isPrivate && isField && !privateFieldsAsProperties:
        needsClassRef = true;
        staticNodes.push(buildPrivateStaticFieldInitSpec(prop, privateNamesMap));
        break;

      case isStatic && isPublic && isField && setPublicClassFields:
        if (!isNameOrLength(prop.node)) {
          needsClassRef = true;
          staticNodes.push(buildPublicFieldInitLoose(_core.types.cloneNode(ref), prop));
          break;
        }

      case isStatic && isPublic && isField && !setPublicClassFields:
        needsClassRef = true;
        staticNodes.push(buildPublicFieldInitSpec(_core.types.cloneNode(ref), prop, state));
        break;

      case isInstance && isPrivate && isField && privateFieldsAsProperties:
        instanceNodes.push(buildPrivateFieldInitLoose(_core.types.thisExpression(), prop, privateNamesMap));
        break;

      case isInstance && isPrivate && isField && !privateFieldsAsProperties:
        instanceNodes.push(buildPrivateInstanceFieldInitSpec(_core.types.thisExpression(), prop, privateNamesMap, state));
        break;

      case isInstance && isPrivate && isMethod && privateFieldsAsProperties:
        instanceNodes.unshift(buildPrivateMethodInitLoose(_core.types.thisExpression(), prop, privateNamesMap));
        pureStaticNodes.push(buildPrivateMethodDeclaration(prop, privateNamesMap, privateFieldsAsProperties));
        break;

      case isInstance && isPrivate && isMethod && !privateFieldsAsProperties:
        instanceNodes.unshift(buildPrivateInstanceMethodInitSpec(_core.types.thisExpression(), prop, privateNamesMap, state));
        pureStaticNodes.push(buildPrivateMethodDeclaration(prop, privateNamesMap, privateFieldsAsProperties));
        break;

      case isStatic && isPrivate && isMethod && !privateFieldsAsProperties:
        needsClassRef = true;
        staticNodes.unshift(buildPrivateStaticFieldInitSpec(prop, privateNamesMap));
        pureStaticNodes.push(buildPrivateMethodDeclaration(prop, privateNamesMap, privateFieldsAsProperties));
        break;

      case isStatic && isPrivate && isMethod && privateFieldsAsProperties:
        needsClassRef = true;
        staticNodes.unshift(buildPrivateStaticMethodInitLoose(_core.types.cloneNode(ref), prop, state, privateNamesMap));
        pureStaticNodes.push(buildPrivateMethodDeclaration(prop, privateNamesMap, privateFieldsAsProperties));
        break;

      case isInstance && isPublic && isField && setPublicClassFields:
        instanceNodes.push(buildPublicFieldInitLoose(_core.types.thisExpression(), prop));
        break;

      case isInstance && isPublic && isField && !setPublicClassFields:
        instanceNodes.push(buildPublicFieldInitSpec(_core.types.thisExpression(), prop, state));
        break;

      default:
        throw new Error("Unreachable.");
    }
  }

  return {
    staticNodes: staticNodes.filter(Boolean),
    instanceNodes: instanceNodes.filter(Boolean),
    pureStaticNodes: pureStaticNodes.filter(Boolean),

    wrapClass(path) {
      for (const prop of props) {
        prop.remove();
      }

      if (injectSuperRef) {
        path.scope.push({
          id: _core.types.cloneNode(injectSuperRef)
        });
        path.set("superClass", _core.types.assignmentExpression("=", injectSuperRef, path.node.superClass));
      }

      if (!needsClassRef) return path;

      if (path.isClassExpression()) {
        path.scope.push({
          id: ref
        });
        path.replaceWith(_core.types.assignmentExpression("=", _core.types.cloneNode(ref), path.node));
      } else if (!path.node.id) {
        path.node.id = ref;
      }

      return path;
    }

  };
}