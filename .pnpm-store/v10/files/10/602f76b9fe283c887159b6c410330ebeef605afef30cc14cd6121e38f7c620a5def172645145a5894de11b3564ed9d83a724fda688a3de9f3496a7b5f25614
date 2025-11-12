export { A as AutomockedModule, b as AutospiedModule, a as ManualMockedModule, M as MockerRegistry, R as RedirectedModule } from './chunk-registry.js';

function mockObject(options, object, mockExports = {}) {
  const finalizers = new Array();
  const refs = new RefTracker();
  const define = (container, key, value) => {
    try {
      container[key] = value;
      return true;
    } catch {
      return false;
    }
  };
  const mockPropertiesOf = (container, newContainer) => {
    const containerType = getType(container);
    const isModule = containerType === "Module" || !!container.__esModule;
    for (const { key: property, descriptor } of getAllMockableProperties(
      container,
      isModule,
      options.globalConstructors
    )) {
      if (!isModule && descriptor.get) {
        try {
          Object.defineProperty(newContainer, property, descriptor);
        } catch {
        }
        continue;
      }
      if (isSpecialProp(property, containerType)) {
        continue;
      }
      const value = container[property];
      const refId = refs.getId(value);
      if (refId !== undefined) {
        finalizers.push(
          () => define(newContainer, property, refs.getMockedValue(refId))
        );
        continue;
      }
      const type = getType(value);
      if (Array.isArray(value)) {
        define(newContainer, property, []);
        continue;
      }
      const isFunction = type.includes("Function") && typeof value === "function";
      if ((!isFunction || value._isMockFunction) && type !== "Object" && type !== "Module") {
        define(newContainer, property, value);
        continue;
      }
      if (!define(newContainer, property, isFunction ? value : {})) {
        continue;
      }
      if (isFunction) {
        let mockFunction2 = function() {
          if (this instanceof newContainer[property]) {
            for (const { key, descriptor: descriptor2 } of getAllMockableProperties(
              this,
              false,
              options.globalConstructors
            )) {
              if (descriptor2.get) {
                continue;
              }
              const value2 = this[key];
              const type2 = getType(value2);
              const isFunction2 = type2.includes("Function") && typeof value2 === "function";
              if (isFunction2) {
                const original = this[key];
                const mock2 = spyOn(this, key).mockImplementation(original);
                const origMockReset = mock2.mockReset;
                mock2.mockRestore = mock2.mockReset = () => {
                  origMockReset.call(mock2);
                  mock2.mockImplementation(original);
                  return mock2;
                };
              }
            }
          }
        };
        if (!options.spyOn) {
          throw new Error(
            "[@vitest/mocker] `spyOn` is not defined. This is a Vitest error. Please open a new issue with reproduction."
          );
        }
        const spyOn = options.spyOn;
        const mock = spyOn(newContainer, property);
        if (options.type === "automock") {
          mock.mockImplementation(mockFunction2);
          const origMockReset = mock.mockReset;
          mock.mockRestore = mock.mockReset = () => {
            origMockReset.call(mock);
            mock.mockImplementation(mockFunction2);
            return mock;
          };
        }
        Object.defineProperty(newContainer[property], "length", { value: 0 });
      }
      refs.track(value, newContainer[property]);
      mockPropertiesOf(value, newContainer[property]);
    }
  };
  const mockedObject = mockExports;
  mockPropertiesOf(object, mockedObject);
  for (const finalizer of finalizers) {
    finalizer();
  }
  return mockedObject;
}
class RefTracker {
  idMap = /* @__PURE__ */ new Map();
  mockedValueMap = /* @__PURE__ */ new Map();
  getId(value) {
    return this.idMap.get(value);
  }
  getMockedValue(id) {
    return this.mockedValueMap.get(id);
  }
  track(originalValue, mockedValue) {
    const newId = this.idMap.size;
    this.idMap.set(originalValue, newId);
    this.mockedValueMap.set(newId, mockedValue);
    return newId;
  }
}
function getType(value) {
  return Object.prototype.toString.apply(value).slice(8, -1);
}
function isSpecialProp(prop, parentType) {
  return parentType.includes("Function") && typeof prop === "string" && ["arguments", "callee", "caller", "length", "name"].includes(prop);
}
function getAllMockableProperties(obj, isModule, constructors) {
  const { Map: Map2, Object: Object2, Function, RegExp, Array: Array2 } = constructors;
  const allProps = new Map2();
  let curr = obj;
  do {
    if (curr === Object2.prototype || curr === Function.prototype || curr === RegExp.prototype) {
      break;
    }
    collectOwnProperties(curr, (key) => {
      const descriptor = Object2.getOwnPropertyDescriptor(curr, key);
      if (descriptor) {
        allProps.set(key, { key, descriptor });
      }
    });
  } while (curr = Object2.getPrototypeOf(curr));
  if (isModule && !allProps.has("default") && "default" in obj) {
    const descriptor = Object2.getOwnPropertyDescriptor(obj, "default");
    if (descriptor) {
      allProps.set("default", { key: "default", descriptor });
    }
  }
  return Array2.from(allProps.values());
}
function collectOwnProperties(obj, collector) {
  const collect = typeof collector === "function" ? collector : (key) => collector.add(key);
  Object.getOwnPropertyNames(obj).forEach(collect);
  Object.getOwnPropertySymbols(obj).forEach(collect);
}

export { mockObject };
