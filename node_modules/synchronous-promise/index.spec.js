/*
* linting omitted on spec mainly because jslint doesn"t seem to allow the
* mocha expression-like syntax
*/
"use strict";
const expect = require("chai").expect,
  sut = require("./index"),
  SynchronousPromise = sut.SynchronousPromise;

describe("synchronous-promise", function () {
  it("should be constructable", function () {
    expect(SynchronousPromise).to.exist;
    expect(new SynchronousPromise(function () {
    })).to.exist;
  });
  it("should have a then function", function () {
    expect(SynchronousPromise.prototype.then).to.be.a("function");
  });
  it("should have a catch function", function () {
    expect(SynchronousPromise.prototype.catch).to.be.a("function");
  });

  function create(ctor) {
    return new SynchronousPromise(ctor);
  }

  function createResolved(data) {
    return SynchronousPromise.resolve(data);
  }

  function createRejected(data) {
    return SynchronousPromise.reject(data);
  }

  describe("then", function () {
    it("when resolved, should return a new resolved promise", function () {
      const sut = createResolved();
      expect(sut.then(null, function () {
      })).to.be.instanceOf(SynchronousPromise);
    });

    it("should return the new resolved promise v2", function () {
      const result = createResolved().then(function () {
        /* purposely don't return anything */
      });
      expect(result).to.be.instanceOf(SynchronousPromise);
    });

    it("should return a new rejected promise", function () {
      const sut = createRejected();
      expect(sut.then(function () {
      })).to.be.instanceOf(SynchronousPromise);
    });

    it("should return a new rejected promise v2", function () {
      const result = createRejected().then(function () {
        /* purposely don't return anything */
      });
      expect(result).to.be.instanceOf(SynchronousPromise)
    });

    it("should bring the first resolve value into the first then", function () {
      const initial = "123";
      let captured = null;
      createResolved(initial).then(function (data) {
        captured = data;
      });
      expect(captured).to.equal(initial);
    });

    it("should call into the immediate catch function when the function given to then throws", function () {
      const sut = createResolved(),
        expected = "the error";
      let received = null;
      sut.then(function () {
        throw new Error(expected);
      }).catch(function (err) {
        received = err;
      });
      expect(received.message).to.equal(expected);
    });

    it(`should allow re-throwing in a .catch and re-catching later`, () => {
      // Arrange
      const sut = createResolved(),
        error1 = "moo";
      let received = null;
      const expected = "moo-cow";
      // Act
      sut.then(function () {
        throw new Error(error1);
      }).catch(function (err) {
        debugger;
        throw new Error(err.message + "-cow");
      }).catch(function (err) {
        received = err.message;
      });
      // Assert
      expect(received).to.equal(expected);
    });

    it("should call the catch from a rejection invoke", () => {
      // Arrange
      const expected = "moo",
        sut = new SynchronousPromise(function (resolve, reject) {
          reject(expected);
        });
      let captured = null;
      // Act
      sut.catch(function (e) {
        captured = e;
      });
      // Assert
      expect(captured).to.equal(expected);
    });

    it("should call into the later catch function when the function given to then throws", function () {
      const sut = createResolved(),
        expected = "the error";
      let received = null;
      sut.then(function () {
        throw new Error(expected);
      }).then(function () {
        return 42;  // not a thrower
      }).catch(function (err) {
        received = err;
      });

      expect(received.message).to.equal(expected);
    });

    it("should prefer to call into onRejected over the .catch handler on failure", function () {
      const sut = createResolved(),
        expected = "the error";
      let captured = null,
        catchCaptured = null;
      sut.then(function () {
        throw expected;
      }, function (e) {
        captured = e;
      }).catch(function (e) {
        console.log(".catch handler");
        catchCaptured = e;
      });

      expect(captured).to.equal(expected);
      expect(catchCaptured).to.be.null;
    });

    it("should bring the first rejected value into the first onRejected then handler", function () {
      const initial = new Error("123");
      let captured = null;
      createRejected(initial).then(function () {
      }, function (e) {
        captured = e
      });
      expect(captured).to.equal(initial);
    });

    it("should resolve when the first resolution is a resolved promise", function () {
      const initial = createResolved("123");
      let captured = null;
      createResolved(initial).then(function (data) {
        captured = data;
      });
      expect(captured).to.equal("123");
    });

    it("should catch when the first resolution is a rejected promise", function () {
      const initial = createRejected("123");
      let captured = null;
      createResolved(initial).catch(function (data) {
        captured = data;
      });
      expect(captured).to.equal("123");
    });

    it("should catch when a subsequent resolution returns a rejected promise", function () {
      const initial = createResolved("123");
      let captured = null;
      const expected = "le error";
      initial.then(function () {
        return createRejected(expected);
      }).catch(function (e) {
        captured = e;
      });

      expect(captured).to.equal(expected);
    });

    it("should run a simple chain", function () {
      const initial = "123",
        second = "abc";
      let captured = null;
      createResolved(initial).then(function () {
        return createResolved(second);
      }).then(function (data) {
        captured = data;
      });
      expect(captured).to.equal(second);
    });

    it("should run a longer chain", function () {
      const initial = "123",
        second = "abc",
        third = "---",
        expected = second + third;
      let captured = null;
      createResolved(initial).then(function () {
        return createResolved(second);
      }).then(function () {
        return second;
      }).then(function (data) {
        captured = data + third;
      });
      expect(captured).to.equal(expected);
    });

    it("should run a longer chain v2", function () {
      const initial = "123",
        second = "abc",
        third = "---",
        expected = second + third;
      let captured = null;
      createResolved(initial).then(function () {
        return createResolved(second);
      }).then(function () {
        return createResolved(second);
      }).then(function (data) {
        captured = data + third;
      });
      expect(captured).to.equal(expected);
    });

    it("should run a longer chain v3", function () {
      const initial = "123",
        second = "abc",
        third = "---",
        expected = second + third;
      let captured = null;
      createResolved(initial).then(function () {
        return second;
      }).then(function () {
        return createResolved(second);
      }).then(function (data) {
        captured = data + third;
      });
      expect(captured).to.equal(expected);
    });

    it("should resolve when the ctor function resolves", function () {
      let providedResolve = null,
        captured = null;
      const expected = "xyz",
        promise = create(function (resolve) {
          providedResolve = resolve;
        }).then(function (data) {
          captured = data;
        });
      expect(promise).to.exist;
      expect(captured).to.be.null;
      expect(providedResolve).to.be.a("function");
      providedResolve(expected);
      expect(captured).to.equal(expected);
    });

    it("should resolve the same value from the same promise multiple times", () => {
      // Arrange
      const expected = "multi-pass",
        sut = SynchronousPromise.resolve(expected);
      let captured1 = null,
        captured2 = null;
      // Act
      sut.then(result => captured1 = result);
      sut.then(result => captured2 = result);
      // Assert
      expect(captured1).to.equal(expected);
      expect(captured2).to.equal(expected);
    });

    describe(`es6 native Promise compatibility`, () => {
      it(`should pass on the prior result when no function provided`, async () => {
        // Arrange
        // Act
        const result = await SynchronousPromise.resolve("expected")
          .then();
        // Assert
        expect(result)
          .to.equal("expected");
      });
    });
  });

  describe("catch", function () {
    it("should be called if the initial reject is called", function () {
      const expected = "123";
      let captured = null;
      createRejected(expected).catch(function (e) {
        captured = e;
      });
      expect(captured).to.equal(expected);
    });

    it("should call handler if the promise resolves", function () {
      // Arrange
      const sut = SynchronousPromise.unresolved();
      let resolved = false,
        caught = false;
      // Act
      sut.then(() => resolved = true).catch(() => caught = true);
      sut.resolve();
      // Assert
      expect(resolved).to.be.true;
      expect(caught).to.be.false;
    });

    it("should be called on a delayed rejection", function () {
      let providedReject = null,
        captured = null;
      const expected = "123",
        promise = create(function (resolve, reject) {
          providedReject = reject;
        }).catch(function (e) {
          captured = e;
        });
      expect(promise).to.exist;
      expect(captured).to.be.null;
      expect(providedReject).to.be.a("function");
      providedReject(expected);
      expect(captured).to.equal(expected);
    });

    it("should return a resolved promise if doesn't throw an error", function () {
      const promise = createRejected("123"),
        result = promise.catch(function (data) {
          expect(data).to.equal("123");
        });

      expect(result).to.exist;
      expect(result).to.be.instanceOf(SynchronousPromise);
      expect(result.status).to.be.equal("resolved");
    });

    it("should not interfere with a later then if there is no error", function () {
      let captured = null;
      const expected = "123";
      let capturedError = null;
      createResolved(expected).catch(function (e) {
        capturedError = e;
      }).then(function (data) {
        captured = data;
      });

      expect(capturedError).to.be.null;
      expect(captured).to.equal(expected);
    });

    it("should not be called if the promise is handled successful by a previous onRejected handler", function () {
      const expected = new Error("123"),
        notExpected = new Error("Not expected");
      let capturedError = null;
      createRejected(expected).then(
        function () {
        },
        function (e) {
          capturedError = e
        })
        .catch(function () {
          /* purposely don't return anything */
          capturedError = notExpected;
        });

      expect(capturedError).to.equal(expected);
    });

    it("should prevent the handlers after the error from being called", function () {
      let captured = null;
      createResolved("123").catch(function (e) {
      }).then(function () {
        throw "foo";
      }).then(function () {
        captured = "abc";
      });

      expect(captured).to.be.null;
    });

    it("should re-catch if a catch handler returns a rejected promise", function (done) {
      // Arrange
      const expected = "123",
        pausedRejectedPromise = SynchronousPromise.reject(expected).pause();
      let capturedA = null,
        capturedB = null;

      pausedRejectedPromise.catch(function (e) {
        capturedA = e;
        // prove that this works even from an async promise
        return Promise.reject(e);
      }).catch(function (e) {
        capturedB = e;
      });

      // Act
      pausedRejectedPromise.resume();

      // Assert
      setTimeout(function () {
        try {
          expect(capturedA).to.equal(expected);
          expect(capturedB).to.equal(expected);
          done();
        } catch (e) {
          done(e);
        }
      }, 100);
    });

    it("should re-catch if a then onRejected handler returns a rejected promise", function (done) {
      // Arrange
      const expected = "123",
        pausedRejectedPromise = SynchronousPromise.reject(expected).pause();
      let capturedA = null,
        capturedB = null;

      pausedRejectedPromise.then(function () {
        /* purposely don't return anything */
      }, function (e) {
        capturedA = e;
        // prove that this works even from an async promise
        return Promise.reject(e);
      }).catch(function (e) {
        capturedB = e;
      });

      // Act
      pausedRejectedPromise.resume();

      // Assert
      setTimeout(function () {
        expect(capturedA).to.equal(expected);
        expect(capturedB).to.equal(expected);
        done();
      }, 100);
    });

    it("should continue if a catch handler returns a resolved promise", function (done) {
      // Arrange
      const expected = "123",
        pausedRejectedPromise = SynchronousPromise.reject(expected).pause();
      let capturedA = null,
        capturedB = null,
        secondResolve;

      pausedRejectedPromise.catch(function (e) {
        capturedA = e;
        // prove that this works even from an async promise
        return Promise.resolve("456");
      }).catch(function (e) {
        capturedB = e;
      }).then(function (data) {
        secondResolve = data;
      });

      // Act
      pausedRejectedPromise.resume();

      // Assert
      setTimeout(function () {
        try {
          expect(capturedA).to.equal(expected);
          expect(capturedB).to.be.null;
          expect(secondResolve).to.equal("456");
          done();
        } catch (e) {
          done(e);
        }
      }, 100);
    });
  });

  describe("prototype pause", function () {
    it("should exist as a function on the prototype", function () {
      expect(SynchronousPromise.prototype.pause).to.be.a("function");
    });

    it("should return the promise", function () {
      const
        promise = createResolved("123"),
        result = promise.pause();
      expect(result).to.equal(promise);
    });

    it("should prevent resolution from continuing at that point", function () {
      let calls = 0;
      createResolved("123").then(function () {
        return calls++;
      }).pause().then(function () {
        return calls++;
      });
      expect(calls).to.equal(1);
    });

    it("should prevent rejection from being caught at that point", function () {
      let calls = 0;
      createRejected("123").pause().catch(function () {
        calls++;
      });
      expect(calls).to.equal(0);
    });

    it("should prevent rejection from continuing past at that point", function () {
      let calls = 0,
        captured = null;

      createRejected("123").then(function () {
        // should not be called
        calls++;
      }).catch(function (e) {
        captured = e;
      }).pause().then(function () {
        calls++;
      });

      expect(captured).to.equal("123");
      expect(calls).to.equal(0);
    });

    describe("starting paused", function () {
      it("should return a promise in paused state with no initial data and being resolved on resume", function () {
        let captured = undefined;
        const promise = SynchronousPromise.resolve().pause().then(function () {
          return "moo";
        }).then(function (data) {
          captured = data;
        });
        expect(captured).to.be.undefined;
        promise.resume();
        expect(captured).to.equal("moo");
      });

      it("should return a promise in paused state with no initial data and being rejected on resume", function () {
        let captured = undefined;
        const expected = new Error("moon"),
          promise = SynchronousPromise.resolve().pause().then(function () {
            throw expected
          }).catch(function (e) {
            captured = e;
          });
        expect(captured).to.be.undefined;
        promise.resume();
        expect(captured).to.equal(expected);
      });

      it("should return a promise in paused state with no initial data and being resolved after a catch on resume", function () {
        let captured = undefined;
        const error = new Error("moon"),
          promise = SynchronousPromise.resolve().pause().then(function () {
            throw error
          }).catch(function (e) {
            return e.message;
          }).then(function (m) {
            captured = m;
          });
        expect(captured).to.be.undefined;
        promise.resume();
        expect(captured).to.equal("moon");
      });
    });
  });
  describe("resume", function () {
    it("should exist as a function on the prototype", function () {
      expect(SynchronousPromise.prototype.resume).to.be.a("function");
    });

    it("should return the promise", function () {
      const promise = createResolved("123").pause(),
        result = promise.resume();
      expect(result).to.equal(promise);
    });

    it("should not barf if the promise is not already paused", function () {
      const promise = createResolved("123");
      expect(function () {
        promise.resume();
      }).not.to.throw;
    });

    it("should resume resolution operations after the last pause", function () {
      let calls = 0;
      const promise = createResolved("123").then(function () {
        return calls++;
      }).pause().then(function () {
        return calls++;
      });
      expect(calls).to.equal(1);
      promise.resume();
      expect(calls).to.equal(2);
    });

    it("should resume rejection operations after the last pause", function () {
      let calls = 0,
        captured = null;
      const expected = "die, scum!",
        promise = createResolved("123").then(function () {
          throw expected;
        }).pause().then(function () {
          return calls++;
        }).catch(function (e) {
          captured = e;
        });
      expect(calls).to.equal(0);
      expect(captured).to.be.null;
      promise.resume();
      expect(calls).to.equal(0);
      expect(captured).to.equal(expected);
    });

    it("should resume a promise which was started rejected as rejected", function () {
      let calls = 0,
        captured = null;
      const expected = "it\"s the end of the world!",
        promise = SynchronousPromise.reject(expected).pause().then(function () {
          calls++;
        }).catch(function (e) {
          captured = e;
        });
      expect(calls).to.equal(0);
      expect(captured).to.be.null;
      promise.resume();
      expect(calls).to.equal(0);
      expect(captured).to.equal(expected);
    });
  });
  describe("static resolve", function () {
    it("should be a function", function () {
      expect(SynchronousPromise.resolve).to.be.a("function");
    });

    it("should return a resolved promise", function () {
      const expected = "foo",
        result = SynchronousPromise.resolve(expected);
      expect(result.status).to.equal("resolved");
      let captured = null;
      result.then(function (data) {
        captured = data;
      });
      expect(captured).to.equal(expected);
    });
  });
  describe("static reject", function () {
    it("should be a function", function () {
      expect(SynchronousPromise.reject).to.be.a("function");
    });

    it("should return a rejected promise", function () {
      const expected = "moo",
        result = SynchronousPromise.reject(expected);
      expect(result.status).to.equal("rejected");
      let captured = null;
      result.catch(function (err) {
        captured = err;
      });
      expect(captured).to.equal(expected);
    });
  });

  describe("static all", function () {
    it("should be a function", function () {
      expect(SynchronousPromise.all).to.be.a("function")
    });

    it("should resolve with all values from given resolved promises as variable args", function () {
      const p1 = createResolved("abc"),
        p2 = createResolved("123"),
        all = SynchronousPromise.all(p1, p2);
      let captured = null;

      all.then(function (data) {
        captured = data;
      });

      expect(captured).to.have.length(2);
      expect(captured).to.contain("abc");
      expect(captured).to.contain("123");
    });

    it("should resolve with all values from given promise or none promise variable args", function () {
      const all = SynchronousPromise.all(["123", createResolved("abc")]);
      let captured = null;

      all.then(function (data) {
        captured = data;
      });

      expect(captured).to.have.length(2);
      expect(captured).to.contain("abc");
      expect(captured).to.contain("123");
    });

    it("should resolve with all values from given resolved promises as an array", function () {
      const p1 = createResolved("abc"),
        p2 = createResolved("123"),
        all = SynchronousPromise.all([p1, p2]);
      let captured = null;

      all.then(function (data) {
        captured = data;
      });

      expect(captured).to.have.length(2);
      expect(captured).to.contain("abc");
      expect(captured).to.contain("123");
    });

    it("should resolve empty promise array", function () {
      const all = SynchronousPromise.all([]);
      let captured = null;

      all.then(function (data) {
        captured = data;
      });

      expect(captured).to.have.length(0);
    });

    it("should resolve with values in the correct order", function () {
      let resolve1 = undefined,
        resolve2 = undefined,
        captured = undefined;

      const p1 = create(function (resolve) {
        resolve1 = resolve;
      });

      const p2 = create(function (resolve) {
        resolve2 = resolve;
      });

      SynchronousPromise.all([p1, p2]).then(function (data) {
        captured = data;
      });

      resolve2("a");
      resolve1("b");

      expect(captured).to.deep.equal(["b", "a"]);
    });

    it("should reject if any promise rejects", function () {
      const p1 = createResolved("abc"),
        p2 = createRejected("123"),
        all = SynchronousPromise.all(p1, p2);
      let capturedData = null,
        capturedError = null;
      all.then(function (data) {
        capturedData = data;
      }).catch(function (err) {
        capturedError = err;
      });
      expect(capturedData).to.be.null;
      expect(capturedError).to.equal("123");
    });
  });

  describe("static any", function () {
    it("should be a function", function () {
      expect(SynchronousPromise.any).to.be.a("function")
    });

    it("should resolve with first value from given resolved promises as variable args", function () {
      const p1 = createResolved("abc"),
        p2 = createResolved("123"),
        any = SynchronousPromise.any(p1, p2);
      let captured = null;

      any.then(function (data) {
        captured = data;
      });

      expect(captured).to.equal("abc");
    });

    it("should resolve with first value from given promise or none promise variable args", function () {
      const any = SynchronousPromise.any(["123", createResolved("abc")]);
      let captured = null;

      any.then(function (data) {
        captured = data;
      });

      expect(captured).to.equal("123");
    });

    it("should reject empty promise array", function () {
      const any = SynchronousPromise.any([]);
      let capturedData = null,
        capturedError = null;

      any.then(function (data) {
        capturedData = data;
      }, function (err) {
        capturedError = err;
      });

      expect(capturedData).to.be.null;
      expect(capturedError).to.have.property("errors");
      expect(capturedError).property("errors").to.have.length(0);
    });

    it("should resolve if any promise resolves", function () {
      const p1 = createResolved("abc"),
        p2 = createRejected("123"),
        any = SynchronousPromise.any(p1, p2);
      let capturedData = null,
        capturedError = null;
      any.then(function (data) {
        capturedData = data;
      }).catch(function (err) {
        capturedError = err;
      });

      expect(capturedData).to.equal("abc");
      expect(capturedError).to.be.null;
    });

    it("should reject if all promises reject", function () {
      const p1 = createRejected("abc"),
        p2 = createRejected("123"),
        any = SynchronousPromise.any(p1, p2);
      let capturedData = null,
        capturedError = null;
      any.then(function (data) {
        capturedData = data;
      }).catch(function (err) {
        capturedError = err;
      });

      expect(capturedData).to.be.null;
      expect(capturedError).to.have.property("errors");
      expect(capturedError).property("errors").to.have.length(2);
      expect(capturedError).property("errors").to.contain("abc");
      expect(capturedError).property("errors").to.contain("123");
    });

    it("should reject with values in the correct order", function () {
      let reject1 = undefined,
        reject2 = undefined,
        capturedError = undefined;

      const p1 = create(function (resolve, reject) {
        reject1 = reject;
      });

      const p2 = create(function (resolve, reject) {
        reject2 = reject;
      });

      SynchronousPromise.any([p1, p2]).catch(function (data) {
        capturedError = data;
      });

      reject2("a");
      reject1("b");

      expect(capturedError).to.have.property("errors");
      expect(capturedError).property("errors").to.deep.equal(["b", "a"]);
    });

    describe("in browsers supporting AggregateError", function() {

      // Used to restore previous global.window value
      let windowRef = null;
  
      /** Mock of AggregateError */
      class AggregateError extends Error {
        constructor(errors, message) {
          super(message);
          this.name = "AggregateError";
          this.errors = errors;
        }
      }
  
      beforeEach(function() {
        // Mock window object with AggregateError
        windowRef = global.window;
        global.window = { AggregateError };
      });
  
      afterEach(function () {
        // Restore window object
        global.window = windowRef;
        windowRef = null;
      });
  
      it("should reject with AggregateError for empty promise array", function () {
        const anyEmpty = SynchronousPromise.any([]);
        let capturedError = null;
        anyEmpty.catch(function (err) {
          capturedError = err;
        });

        expect(capturedError).to.be.instanceOf(AggregateError);
      });

      it("should reject with AggregateError for rejected promises as variable args", function () {
        const p1 = createRejected("abc"),
          any = SynchronousPromise.any(p1);
        let capturedError = null;
        any.catch(function (err) {
          capturedError = err;
        });
  
        expect(capturedError).to.be.instanceOf(AggregateError);
      });
    });
  });

  describe("static allSettled", function () {
    it("should be a function", function () {
      expect(SynchronousPromise.allSettled).to.be.a("function")
    });

    it("should resolve with all values from given resolved promises as variable args", function () {
      const p1 = createResolved("abc"),
        p2 = createResolved("123"),
        allSettled = SynchronousPromise.allSettled(p1, p2);
      let captured = null;

      allSettled.then(function (data) {
        captured = data;
      });

      expect(captured).to.have.length(2);
      expect(captured).to.deep.contain({ status: "fulfilled", value: "abc" });
      expect(captured).to.deep.contain({ status: "fulfilled", value: "123" });
    });

    it("should resolve with all values from given rejected promises as variable args", function () {
      const error1 = new Error("error1");
      const error2 = new Error("error2");
      const p1 = createRejected(error1),
        p2 = createRejected(error2),
        allSettled = SynchronousPromise.allSettled(p1, p2);
      let captured = null;

      allSettled.then(function (data) {
        captured = data;
      });

      expect(captured).to.have.length(2);
      expect(captured).to.deep.contain({ status: "rejected", reason: error1 });
      expect(captured).to.deep.contain({ status: "rejected", reason: error2 });
    });

    it("should resolve with all values from given promise or none promise variable args", function () {
      const allSettled = SynchronousPromise.allSettled(["123", createResolved("abc")]);
      let captured = null;

      allSettled.then(function (data) {
        captured = data;
      });

      expect(captured).to.have.length(2);
      expect(captured).to.deep.contain({ status: "fulfilled", value: "abc" });
      expect(captured).to.deep.contain({ status: "fulfilled", value: "123" });
    });

    it("should resolve with all values from given resolved promises as an array", function () {
      const p1 = createResolved("abc"),
        p2 = createResolved("123"),
        allSettled = SynchronousPromise.allSettled([p1, p2]);
      let captured = null;

      allSettled.then(function (data) {
        captured = data;
      });

      expect(captured).to.have.length(2);
      expect(captured).to.deep.contain({ status: "fulfilled", value: "abc" });
      expect(captured).to.deep.contain({ status: "fulfilled", value: "123" });
    });

    it("should resolve empty promise array", function () {
      const allSettled = SynchronousPromise.allSettled([]);
      let captured = null;

      allSettled.then(function (data) {
        captured = data;
      });

      expect(captured).to.have.length(0);
    });

    it("should resolve with values in the correct order", function () {
      let resolve1 = undefined,
        resolve2 = undefined,
        captured = undefined;

      const p1 = create(function (resolve) {
        resolve1 = resolve;
      });

      const p2 = create(function (resolve) {
        resolve2 = resolve;
      });

      SynchronousPromise.allSettled([p1, p2]).then(function (data) {
        captured = data;
      });

      resolve2("a");
      resolve1("b");

      expect(captured).to.deep.equal([
        { status: "fulfilled", value: "b" },
        { status: "fulfilled", value: "a" }
      ]);
    });

    it("should only resolve after all promises are settled", function () {
      const p1 = createResolved("abc"),
        p2 = createRejected("123"),
        allSettled = SynchronousPromise.allSettled(p1, p2);
      let capturedData = null;
      allSettled.then(function (data) {
        capturedData = data;
      });

      expect(capturedData).to.have.length(2);
    });
  });

  describe("static unresolved", function () {
    it("should exist as a function", function () {
      // Arrange
      // Act
      // Assert
      expect(SynchronousPromise.unresolved).to.exist;
      expect(SynchronousPromise.unresolved).to.be.a("function");
    });

    it("should return a new SynchronousPromise", function () {
      // Arrange
      // Act
      const result1 = SynchronousPromise.unresolved(),
        result2 = SynchronousPromise.unresolved();
      // Assert
      expect(result1).to.exist;
      expect(result2).to.exist;
      expect(Object.getPrototypeOf(result1)).to.equal(SynchronousPromise.prototype);
      expect(Object.getPrototypeOf(result2)).to.equal(SynchronousPromise.prototype);
      expect(result1).not.to.equal(result2);
    });

    describe("result", function () {
      it("should not be resolved or rejected", function () {
        // Arrange
        let resolved = false,
          rejected = false;
        // Act
        SynchronousPromise.unresolved().then(function () {
          resolved = true;
        }).catch(function () {
          rejected = true;
        });
        // Assert
        expect(resolved).to.be.false;
        expect(rejected).to.be.false;
      });

      describe("resolve", function () {
        it("should be a function", function () {
          // Arrange
          // Act
          const sut = SynchronousPromise.unresolved();
          // Assert
          expect(sut.resolve).to.exist;
          expect(sut.resolve).to.be.a("function");
        });

        it("should resolve the promise when invoked", function () {
          // Arrange
          let resolved = undefined,
            error = undefined;
          const sut = SynchronousPromise.unresolved().then(function (result) {
              resolved = result;
            }).catch(function (err) {
              error = err;
            }),
            expected = {key: "value"};
          // Act
          debugger;
          sut.resolve(expected);
          // Assert
          expect(resolved).to.equal(expected);
          expect(error).not.to.exist;
        });

        it("should resolve all thens when invoked", () => {
          // Arrange
          const sut = SynchronousPromise.unresolved();
          let captured1 = undefined,
            captured2 = undefined;
          const next1 = sut.then(result => captured1 = result),
            next2 = sut.then(result => captured2 = result),
            expected = "cake-moo";
          expect(next1).to.exist;
          expect(next2).to.exist;
          // Act
          sut.resolve(expected);
          // Assert
          expect(captured1).to.equal(expected);
          expect(captured2).to.equal(expected);
        });
      });
      describe("reject property", function () {
        it("should be a function", function () {
          // Arrange
          // Act
          const sut = SynchronousPromise.unresolved();
          // Assert
          expect(sut.reject).to.exist;
          expect(sut.reject).to.be.a("function");
        });

        it("should reject the promise when invoked", function () {
          // Arrange
          let resolved = undefined,
            error = undefined;
          const sut = SynchronousPromise.unresolved().then(function (result) {
              resolved = result;
            }).catch(function (err) {
              error = err;
            }),
            expected = {key: "value"};
          // Act
          sut.reject(expected);
          // Assert
          expect(error).to.equal(expected);
          expect(resolved).not.to.exist;
        });
      });

      describe("with timeout in ctor", () => {
        it("should complete when the timeout does", (done) => {
          // Arrange
          let captured;
          // Act
          new SynchronousPromise(function (resolve) {
            setTimeout(function () {
              resolve("moo");
            }, 0);
          }).then(function (result) {
            captured = result;
          });
          // Assert
          setTimeout(function () {
            expect(captured).to.equal("moo");
            done();
          }, 500);
        });
      });
    });
  });
  describe(`finally`, () => {
    it(`should call the provided function when the promise resolves`, async () => {
      // Arrange
      let called = false;
      // Act
      SynchronousPromise.resolve("foo").finally(function () {
        called = true;
      });
      // Assert
      expect(called).to.be.true;
    });

    it(`should call the provided function when the promise rejects`, async () => {
      // Arrange
      let called = false;
      // Act
      SynchronousPromise.reject("foo").finally(function () {
        called = true;
      });
      // Assert
    });

    it(`should call the provided function when the promise is rejected then caught`, async () => {
      // Arrange
      let catchCalled = false,
        finallyCalled = false;
      // Act
      SynchronousPromise.reject("error")
        .catch(function () {
          catchCalled = true;
        }).finally(function () {
        finallyCalled = true;
      });
      // Assert
      expect(catchCalled).to.be.true;
      expect(finallyCalled).to.be.true;
    });

    it(`should start a new promise chain after resolution, with non-throwing finally`, async () => {
      // Arrange
      let captured = null;
      // Act
      SynchronousPromise.resolve("first value")
        .finally(function () {
          return "second value";
        }).then(function (data) {
        captured = data;
      });
      // Assert
      expect(captured).to.equal("first value");
    });

    it(`should start a new promise chain after resolution, with resolving finally`, async () => {
      // Arrange
      let captured = null;
      // Act
      SynchronousPromise.resolve("first value")
        .finally(function () {
          return SynchronousPromise.resolve("second value");
        }).then(function (data) {
        captured = data;
      });
      // Assert
      expect(captured).to.equal("first value");
    });

    it(`should start a new promise chain after resolution, with throwing finally`, async () => {
      // Arrange
      let captured = null;
      // Act
      SynchronousPromise.reject("first error")
        .finally(function () {
          throw "finally data";
        }).catch(function (data) {
        captured = data;
      });
      // Assert
      expect(captured).to.equal("finally data");
    });

    it(`should start a new promise chain after resolution, with rejecting finally`, async () => {
      // Arrange
      let captured = null;
      // Act
      SynchronousPromise.reject("first error")
        .finally(function () {
          return SynchronousPromise.reject("finally data");
        }).catch(function (data) {
        captured = data;
      });
      // Assert
      expect(captured).to.equal("finally data");
    });

    it(`should start a new promise chain after rejection, with non-throwing finally`, async () => {
      // Arrange
      let called = false;
      // Act
      SynchronousPromise.reject("le error")
        .finally(function () {
        }).then(function () {
        called = true;
      });
      // Assert
      expect(called).to.be.true;
    });

    it(`should start a new promise chain after rejection, with resolving finally`, async () => {
      // Arrange
      let captured = null;
      let capturedErr = null;
      // Act
      SynchronousPromise.reject("le error")
        .finally(function () {
          return SynchronousPromise.resolve("le data");
        }).then(function (data) {
        captured = data;
      }).catch(function(err) {
        capturedErr = err;
      });
      // Assert
      expect(captured).to.be.null;
      expect(capturedErr).to.equal("le error");
    });

    it(`should start a new promise chain after rejection, with throwing finally`, async () => {
      // Arrange
      let finallyError = null;
      // Act
      SynchronousPromise.reject("another error")
        .finally(function () {
          throw "moo cakes";
        }).catch(function (err) {
        finallyError = err;
      });
      // Assert
      expect(finallyError).to.equal("moo cakes");
    });

    it(`should start a new promise chain after rejection, with rejecting finally`, async () => {
      // Arrange
      let finallyError = null;
      // Act
      SynchronousPromise.reject("another error")
        .finally(function () {
          return SynchronousPromise.reject("moo cakes");
        }).catch(function (err) {
        finallyError = err;
      });
      // Assert
      expect(finallyError).to.equal("moo cakes");
    });

    describe(`issues`, () => {
      it(`should be called after one then from resolved()`, async () => {
        // Arrange
        const events = [];
        // Act
        SynchronousPromise.resolve("initial")
          .then(result => {
            events.push(result);
            events.push("then");
          }).finally(() => {
          events.push("finally");
        });
        // Assert
        expect(events).to.eql(
          ["initial", "then", "finally"]
        );
      });

      it(`should be called after two thens from resolved()`, async () => {
        // Arrange
        const events = [];
        // Act
        SynchronousPromise.resolve("initial")
          .then(result => {
            events.push(result);
            events.push("then1");
            return "then1";
          }).then(result => {
          events.push(`then2 received: ${result}`);
          events.push("then2");
          console.log(events);
        }).finally(() => {
          events.push("finally");
        });
        // Assert
        expect(events).to.eql(
          ["initial", "then1", "then2 received: then1", "then2", "finally"]
        );
      });

      it(`should not be called from an unresolved promise`, async () => {
        // Arrange
        const events = [];
        // Act
        SynchronousPromise.unresolved()
          .then(result => {
            debugger;
            events.push(`result: ${result}`)
          })
          .catch(() => events.push("catch"))
          .finally(() => events.push("finally"));
        // Assert
        expect(events).to.be.empty;
      });

      it(`should not be run if chain is paused`, async () => {
        // Arrange
        const events = [];

        const promise = SynchronousPromise.resolve("init")
          .then((result) => {
            events.push(`result: ${result}`)
          })
          .pause()
          .then(() => {
            events.push("resumed")
          })
          .finally(() => {
            events.push("finally")
          });
        expect(events).to.eql(["result: init"]);
        // Act
        promise.resume();
        // Assert
        expect(events).to.eql(["result: init", "resumed", "finally"]);
      });

      it(`should pass the result onto the next .then`, async () => {
        // Arrange
        // Act
        const result = await SynchronousPromise.resolve("expected")
          .finally(r => r);
        // Assert
        expect(result)
          .to.equal("expected");
      });

      it(`should pass result onto next .then when no finally handler`, async () => {
        // Arrange
        // Act
        const result = await SynchronousPromise.resolve("expected")
          .finally();
        // Assert
        expect(result).to.equal("expected");
      });

      it(`should pass last result onto next .then when finally has an empty handler fn`, async () => {
        // Arrange
        // Act
        const result = await SynchronousPromise.resolve("expected")
          .finally(() => {});
        // Assert
        expect(result)
          .to.equal("expected");
      });

      describe(`imported specs from blalasaadri`, () => {
        // these relate to https://github.com/fluffynuts/synchronous-promise/issues/15
        // reported by https://github.com/blalasaadri
        describe("SynchronousPromise", () => {
          describe("new SynchronousPromise", () => {
            it("calls .then() after being resolved", () => {
              const events = [];

              new SynchronousPromise((resolve) => {
                events.push("init");
                resolve("resolve")
              }).then(result => {
                events.push(`result: ${result}`)
              })
                .then(() => {
                  events.push("then")
                });

              expect(events)
                .to.eql(["init", "result: resolve", "then"])
            });

            it("calls .catch() but not previous .then()s after being rejected", () => {
              const events = [];

              new SynchronousPromise((resolve, reject) => {
                events.push("init");
                reject("reject")
              }).then(result => {
                events.push(`result: ${result}`)
              })
                .then(() => {
                  events.push("then")
                })
                .catch(error => {
                  events.push(`error: ${error}`)
                });

              expect(events)
                .to.eql(["init", "error: reject"])
            });

            it("calls .finally() after .then()", () => {
              const events = [];

              new SynchronousPromise((resolve) => {
                resolve("init")
              }).then(result => {
                events.push(`result: ${result}`)
              })
                .then(() => {
                  events.push("then")
                })
                .finally(() => {
                  events.push("finally")
                });

              expect(events)
                .to.eql(["result: init", "then", "finally"])
            });

            it("calls .finally() after .catch()", () => {
              const events = [];

              new SynchronousPromise((resolve, reject) => {
                reject("init")
              }).then(result => {
                events.push(`result: ${result}`)
              })
                .then(() => {
                  events.push("then")
                })
                .catch(error => {
                  events.push(`error: ${error}`)
                })
                .finally(() => {
                  events.push("finally")
                });

              expect(events)
                .to.eql(["error: init", "finally"])
            })
          });

          describe("SynchronousPromise.unresolved", () => {
            describe("calls .then() only after being resolved", () => {
              it("calls nothing before promise.resolve is called", () => {
                const events = [];

                SynchronousPromise.unresolved()
                  .then((result) => {
                    events.push(`result: ${result}`)
                  })
                  .then(() => {
                    events.push("then")
                  });

                expect(events).to.eql([])
              });

              it("calls .then() once promise.resolve is called", () => {
                const events = [];

                const promise = SynchronousPromise.unresolved()
                  .then((result) => {
                    events.push(`result: ${result}`)
                  })
                  .then(() => {
                    events.push("then")
                  });
                promise.resolve("resolve");

                expect(events).to.eql(["result: resolve", "then"])
              })
            });

            it("calls .catch() but not previous .then()s after being rejected", () => {
              const events = [];

              const promise = SynchronousPromise.unresolved()
                .then((result) => {
                  events.push(`result: ${result}`)
                })
                .then(() => {
                  events.push("then")
                })
                .catch(error => {
                  events.push(`error: ${error}`)
                });
              promise.reject("reject");

              expect(events)
                .to.eql(["error: reject"])
            });

            describe("calls .finally() after .then()", () => {
              it("calls nothing before promise.resolve is called", () => {
                const events = [];

                SynchronousPromise.unresolved()
                  .then((result) => {
                    events.push(`result: ${result}`)
                  })
                  .then(() => {
                    events.push("then")
                  })
                  .finally(() => {
                    events.push("finally")
                  });

                expect(events)
                  .not.to.contain("finally");
                expect(events)
                  .to.eql([])
              });

              it("calls .then() and .finally() once promise.resolve is called", () => {
                const events = [];

                const promise = SynchronousPromise.unresolved()
                  .then((result) => {
                    events.push(`result: ${result}`)
                  })
                  .then(() => {
                    events.push("then")
                  })
                  .finally(() => {
                    events.push("finally")
                  });
                promise.resolve("resolve");

                expect(events)
                  .not.to.eql(["finally", "result: undefined", "then"]);
                expect(events)
                  .to.eql(["result: resolve", "then", "finally"])
              })
            });

            describe("calls .finally() after .catch()", () => {
              it("calls nothing before promise.reject is called", () => {
                const events = [];

                SynchronousPromise.unresolved()
                  .then((result) => {
                    events.push(`result: ${result}`)
                  })
                  .catch(() => {
                    events.push("catch")
                  })
                  .finally(() => {
                    events.push("finally")
                  });

                expect(events)
                  .not.to.contain("finally");
                expect(events)
                  .to.eql([])
              });

              it("calls .catch() and .finally() once promise.reject is called", () => {
                const events = [];

                const promise = SynchronousPromise.unresolved()
                  .then((result) => {
                    events.push(`result: ${result}`)
                  })
                  .catch((error) => {
                    events.push(`error: ${error}`)
                  })
                  .finally(() => {
                    events.push("finally")
                  });
                promise.reject("reject");

                expect(events)
                  .not.to.eql(["finally", "result: undefined"]);
                expect(events)
                  .to.eql(["error: reject", "finally"])
              })
            })
          });

          describe("SynchronousPromise.resolve(...).pause", () => {
            describe("calls .then() only after being resolved", () => {
              it("calls nothing after the initial initialization before promise.resume is called", () => {
                const events = [];

                SynchronousPromise.resolve("init")
                  .then((result) => {
                    events.push(`result: ${result}`)
                  })
                  .pause()
                  .then(() => {
                    events.push("resumed")
                  });

                expect(events)
                  .to.eql(["result: init"])
              });

              it("calls .then() after the inital initialization after promise.resume is called", () => {
                const events = [];

                const promise = SynchronousPromise.resolve("init")
                  .then((result) => {
                    events.push(`result: ${result}`)
                  })
                  .pause()
                  .then(() => {
                    events.push("resumed")
                  });
                promise.resume();

                expect(events)
                  .to.eql(["result: init", "resumed"])
              })
            });

            describe("calls .catch() only after being resolved", () => {
              it("calls nothing after the inital initialization before promise.resume is called", () => {
                const events = [];

                SynchronousPromise.resolve("init")
                  .then((result) => {
                    events.push(`result: ${result}`);
                    throw Error("resumed")
                  })
                  .pause()
                  .catch(({message}) => {
                    events.push(`catch: ${message}`)
                  });

                expect(events)
                  .to.eql(["result: init"])
              });

              it("calls .catch() after the inital initialization after promise.resume is called", () => {
                const events = [];

                const promise = SynchronousPromise.resolve("init")
                  .then((result) => {
                    events.push(`result: ${result}`);
                    throw Error("resumed")
                  })
                  .pause()
                  .catch(({message}) => {
                    events.push(`catch: ${message}`)
                  });
                promise.resume();

                expect(events)
                  .to.eql(["result: init", "catch: resumed"])
              })
            });

            describe("calls .finally() after .then()", () => {
              it("calls nothing before promise.resume is called", () => {
                const events = [];

                SynchronousPromise.resolve("init")
                  .then((result) => {
                    events.push(`result: ${result}`)
                  })
                  .pause()
                  .then(() => {
                    events.push("resumed")
                  })
                  .finally(() => {
                    events.push("finally")
                  });

                expect(events)
                  .not.to.contain("finally");
                expect(events)
                  .to.eql(["result: init"])
              });

              it("calls .then() and .finally() once promise.resume is called", () => {
                const events = [];

                const promise = SynchronousPromise.resolve("init")
                  .then((result) => {
                    events.push(`result: ${result}`)
                  })
                  .pause()
                  .then(() => {
                    events.push("resumed")
                  })
                  .finally(() => {
                    events.push("finally")
                  });
                promise.resume();

                expect(events)
                  .not.to.eql(["result: init", "finally", "resumed"]);
                expect(events)
                  .to.eql(["result: init", "resumed", "finally"])
              })
            });

            describe("calls .finally() after .catch()", () => {
              it("calls nothing before promise.resume is called", () => {
                const events = [];

                SynchronousPromise.resolve("init")
                  .then((result) => {
                    events.push(`result: ${result}`);
                    throw Error("resumed")
                  })
                  .pause()
                  .catch(({message}) => {
                    events.push(`catch: ${message}`)
                  })
                  .finally(() => {
                    events.push("finally")
                  });

                expect(events)
                  .not.to.contain("finally");
                expect(events)
                  .to.eql(["result: init"])
              });

              it("calls .catch() and .finally() once promise.resume is called", () => {
                const events = [];

                const promise = SynchronousPromise.resolve("init")
                  .then((result) => {
                    events.push(`result: ${result}`);
                    throw Error("resumed")
                  })
                  .pause()
                  .catch(({message}) => {
                    events.push(`catch: ${message}`)
                  })
                  .finally(() => {
                    events.push("finally")
                  });
                promise.resume();

                expect(events)
                  .not.to.eql(["result: init", "finally", "catch: resumed"]);
                expect(events)
                  .to.eql(["result: init", "catch: resumed", "finally"])
              })
            })
          })
        })
      });

    });
  });
});
