import * as tinyspy from 'tinyspy';

const vitestSpy = Symbol.for("vitest.spy");
const mocks = /* @__PURE__ */ new Set();
function isMockFunction(fn2) {
  return typeof fn2 === "function" && "_isMockFunction" in fn2 && fn2._isMockFunction;
}
function getSpy(obj, method, accessType) {
  const desc = Object.getOwnPropertyDescriptor(obj, method);
  if (desc) {
    const fn2 = desc[accessType ?? "value"];
    if (typeof fn2 === "function" && vitestSpy in fn2) {
      return fn2;
    }
  }
}
function spyOn(obj, method, accessType) {
  const dictionary = {
    get: "getter",
    set: "setter"
  };
  const objMethod = accessType ? { [dictionary[accessType]]: method } : method;
  const currentStub = getSpy(obj, method, accessType);
  if (currentStub) {
    return currentStub;
  }
  const stub = tinyspy.internalSpyOn(obj, objMethod);
  return enhanceSpy(stub);
}
let callOrder = 0;
function enhanceSpy(spy) {
  const stub = spy;
  let implementation;
  let instances = [];
  let contexts = [];
  let invocations = [];
  const state = tinyspy.getInternalState(spy);
  const mockContext = {
    get calls() {
      return state.calls;
    },
    get contexts() {
      return contexts;
    },
    get instances() {
      return instances;
    },
    get invocationCallOrder() {
      return invocations;
    },
    get results() {
      return state.results.map(([callType, value]) => {
        const type = callType === "error" ? "throw" : "return";
        return { type, value };
      });
    },
    get settledResults() {
      return state.resolves.map(([callType, value]) => {
        const type = callType === "error" ? "rejected" : "fulfilled";
        return { type, value };
      });
    },
    get lastCall() {
      return state.calls[state.calls.length - 1];
    }
  };
  let onceImplementations = [];
  let implementationChangedTemporarily = false;
  function mockCall(...args) {
    instances.push(this);
    contexts.push(this);
    invocations.push(++callOrder);
    const impl = implementationChangedTemporarily ? implementation : onceImplementations.shift() || implementation || state.getOriginal() || (() => {
    });
    return impl.apply(this, args);
  }
  let name = stub.name;
  Object.defineProperty(stub, vitestSpy, {
    value: true,
    enumerable: false
  });
  stub.getMockName = () => name || "vi.fn()";
  stub.mockName = (n) => {
    name = n;
    return stub;
  };
  stub.mockClear = () => {
    state.reset();
    instances = [];
    contexts = [];
    invocations = [];
    return stub;
  };
  stub.mockReset = () => {
    stub.mockClear();
    implementation = undefined;
    onceImplementations = [];
    return stub;
  };
  stub.mockRestore = () => {
    stub.mockReset();
    state.restore();
    return stub;
  };
  stub.getMockImplementation = () => implementationChangedTemporarily ? implementation : onceImplementations.at(0) || implementation;
  stub.mockImplementation = (fn2) => {
    implementation = fn2;
    state.willCall(mockCall);
    return stub;
  };
  stub.mockImplementationOnce = (fn2) => {
    onceImplementations.push(fn2);
    return stub;
  };
  function withImplementation(fn2, cb) {
    const originalImplementation = implementation;
    implementation = fn2;
    state.willCall(mockCall);
    implementationChangedTemporarily = true;
    const reset = () => {
      implementation = originalImplementation;
      implementationChangedTemporarily = false;
    };
    const result = cb();
    if (result instanceof Promise) {
      return result.then(() => {
        reset();
        return stub;
      });
    }
    reset();
    return stub;
  }
  stub.withImplementation = withImplementation;
  stub.mockReturnThis = () => stub.mockImplementation(function() {
    return this;
  });
  stub.mockReturnValue = (val) => stub.mockImplementation(() => val);
  stub.mockReturnValueOnce = (val) => stub.mockImplementationOnce(() => val);
  stub.mockResolvedValue = (val) => stub.mockImplementation(() => Promise.resolve(val));
  stub.mockResolvedValueOnce = (val) => stub.mockImplementationOnce(() => Promise.resolve(val));
  stub.mockRejectedValue = (val) => stub.mockImplementation(() => Promise.reject(val));
  stub.mockRejectedValueOnce = (val) => stub.mockImplementationOnce(() => Promise.reject(val));
  Object.defineProperty(stub, "mock", {
    get: () => mockContext
  });
  state.willCall(mockCall);
  mocks.add(stub);
  return stub;
}
function fn(implementation) {
  const enhancedSpy = enhanceSpy(tinyspy.internalSpyOn({
    spy: implementation || function() {
    }
  }, "spy"));
  if (implementation) {
    enhancedSpy.mockImplementation(implementation);
  }
  return enhancedSpy;
}

export { fn, isMockFunction, mocks, spyOn };
