import { fail } from 'jest';

function runAssertions(ctx, func) {
  try {
    const message = func() || '';
    return {
      message: typeof message === 'function' ? message : () => message,
      pass: true,
    };
  } catch (e) {
    return {
      pass: false,
      message: () => e.message || e,
    };
  }
}

function assert(expr, failMessage) {
  if (!expr) {
    const finalMessage =
      typeof failMessage === 'function' ? failMessage() : failMessage;
    throw new Error(finalMessage);
  }
}

function prettyPrint(obj) {
  return JSON.stringify(obj, null, 2);
}

async function sleep(ms) {
  return new Promise(resolve => {
    window.setTimeout(() => {
      resolve();
    }, ms);
  });
}

function assertHasKeys(obj, keys, msg) {
  assert(obj, 'actual is not set');
  assert(typeof obj === 'object', 'actual is not an object');
  assert(
    (() => {
      const objectKeys = Object.keys(obj);
      return keys.reduce(
        (acc, cur) => acc && objectKeys.indexOf(cur) > -1,
        true
      );
    })(),
    msg
  );
  return msg;
}

function notFor(self) {
  return self.isNot ? ' not ' : ' ';
}

function testIsInstance(actual, ctor) {
  assert(actual !== undefined, 'actual is undefined');
  assert(actual !== null, 'actual is null');
  assert(
    actual instanceof ctor,
    `Expected instance of ${Object.prototype.toString.call(
      ctor
    )} but got ${actual}`
  );
}

async function runAssertionsAsync(ctx, func) {
  try {
    await func();
    return {
      message: () => '',
      pass: !ctx.isNot,
    };
  } catch (e) {
    return {
      pass: false,
      message: () => e.message || e,
    };
  }
}

beforeAll(() => {
  expect.extend({
    toHaveKeys(actual, ...expected) {
      return runAssertions(this, () => {
        assert(expected, 'keys are not set');
        const msg = () =>
          `expected\n${prettyPrint(actual)}\nto have keys\n${prettyPrint(
            expected
          )}`;
        return assertHasKeys(actual, expected, msg);
      });
    },
    toHaveKey(actual, expected) {
      return runAssertions(this, () => {
        assert(expected, 'key is not set');
        const msg = () =>
          `expected ${prettyPrint(actual)} to have key "${expected}"`;
        return assertHasKeys(actual, [expected], msg);
      });
    },
    toBeEquivalentTo(actual, expected) {
      return runAssertions(this, () => {
        const msg = () =>
          `expected collection equivalent to\n${prettyPrint(
            expected
          )}\nbut got\n${prettyPrint(actual)}`;
        assert(Array.isArray(actual), () => `${actual} is not an array`);
        assert(Array.isArray(expected), () => `${expected} is not an array`);
        assert(actual.length === expected.length, msg);
        assert(
          actual.reduce((acc, cur) => acc && expected.indexOf(cur) > -1, true),
          msg
        );
        return msg;
      });
    },
    toBePrototypical(actual) {
      return runAssertions(this, () => {
        const msg = () =>
          `expected${notFor(this)}prototype, but got ${prettyPrint(actual)}`;
        assert(actual, msg);
        assert(actual.prototype, msg);
        return msg;
      });
    },
    toBeAsyncFunction(actual) {
      return runAssertions(this, () => {
        const msg = () =>
          `expected${notFor(this)}async function but got ${prettyPrint(
            actual
          )}`;
        assert(
          Object.prototype.toString.call(actual) === '[object AsyncFunction]' ||
            Object.prototype.toString.call(actual) === '[object Function]',
          msg
        );
        return msg;
      });
    },
    toBePromiseLike(actual) {
      return runAssertions(this, () => {
        const err = moreInfo => {
          return `expected something${notFor(
            this
          )}promise-like, but got ${actual}${
            moreInfo ? '\n\t(' : ''
          }${moreInfo}${moreInfo ? ')' : ''}`;
        };

        assert(actual, err);
        assert(typeof actual === 'object', err);
        assert(
          actual.then && typeof actual.then === 'function',
          'should have a then function'
        );
        return () => err();
      });
    },
    toBeConstructor(actual) {
      return runAssertions(this, () => {
        const err = () => {
          return `expected ${actual}${notFor(this)}to be a constructor`;
        };

        assert(actual, err);
        assert(actual.prototype, err);
        return err;
      });
    },
    toBeA(actual, ctor) {
      return runAssertions(this, () => {
        testIsInstance(actual, ctor);
        return () =>
          `expected${notFor(
            this
          )}to get instance of ${ctor}, but received ${actual}`;
      });
    },
    toBeAn(actual, ctor) {
      return runAssertions(this, () => {
        testIsInstance(actual, ctor);
        return () =>
          `expected${notFor(
            this
          )}to get instance of ${ctor}, but received ${actual}`;
      });
    },
    toBeVueComponent(actual, withName) {
      return runAssertions(this, () => {
        assert(
          typeof actual.render === 'function',
          `actual does not have a render function -- are you sure it's a Vue component?`
        );
        assert(
          actual.name === withName,
          `Expected component${notFor(
            this
          )}to have name "${withName}", but found "${actual.name}"`
        );
        return () =>
          `Expected${notFor(
            this
          )}to receive a Vue component with name ${withName}`;
      });
    },
    toBeNumericInput(htmlElement) {
      return runAssertions(this, () => {
        const msg = () =>
          `Expected${notFor(this)}to receive numeric input but got: ${
            htmlElement.outerHTML
          }`;
        assert(htmlElement.type === 'number', msg);
        return msg;
      });
    },
    toHaveCssClass(actual, cssClass) {
      return runAssertions(this, () => {
        const msg = () =>
          `Expected ${actual.outerHTML}${notFor(
            this
          )}to have css class "${cssClass}"`;
        const el = actual.$el || actual;
        assert(el.classList.contains(cssClass), msg);
        return msg;
      });
    },
    toHaveBeenCalledOnce(actual) {
      return runAssertions(this, () => {
        if (this.isNot) {
          throw new Error(
            [
              "Negation of 'toHaveBeenCalledOnce' is ambiguous ",
              "(do you mean 'not at all' or 'any number except 1'?)",
            ].join('')
          );
        }
        expect(actual).toHaveBeenCalledTimes(1);
        return () => `Expected${notFor(this)}to have been called once`;
      });
    },
    toHaveBeenCalledOnceWith(actual, ...args) {
      return runAssertions(this, () => {
        expect(actual).toHaveBeenCalledTimes(1);
        expect(actual).toHaveBeenCalledWith(...args);
        return () =>
          `Expected${notFor(this)}to have been called once with ${args}`;
      });
    },
    toBeHidden(actual) {
      return runAssertions(this, () => {
        const msg = () =>
          `Expected '${actual.outerHTML}'${notFor(this)}to be hidden`;
        assert(actual, 'actual does not exist');
        assert(actual.style, 'actual may not be an html element?');
        assert(
          actual.style.display === 'none' ||
            actual.style.visibility === 'hidden' ||
            actual.style.visibility === 'collapse',
          msg
        );
        return msg;
      });
    },
    toBeVisible(htmlElement) {
      return runAssertions(this, () => {
        const msg = () =>
          `Expected '${htmlElement.outerHTML}'${notFor(this)}to be hidden`;
        assert(htmlElement, 'actual does not exist');
        assert(
          htmlElement.style.display !== 'none' &&
            htmlElement.style.visibility !== 'hidden' &&
            htmlElement.style.visibility !== 'collapse',
          msg
        );
        return msg;
      });
    },
    async toBeCompleted(actual) {
      return runAssertionsAsync(this, async () => {
        let completed = false;
        let state = 'pending';
        const msg = () =>
          `expected${notFor(this)}to complete promise (final state: ${state})`;
        actual
          .then(() => {
            state = 'resolved';
            completed = true;
          })
          .catch(() => {
            state = 'rejected';
            completed = true;
          });
        await sleep(50);
        if (completed && this.isNot) {
          fail(msg());
        } else if (!completed && !this.isNot) {
          fail(msg());
        }
      });
    },
    async toBeResolved(actual, message, timeoutMs) {
      return runAssertionsAsync(this, async () => {
        let resolved = null;
        const timeout = timeoutMs || 50;
        const msg = () =>
          `expected${notFor(this)}to resolve promise, but ${
            resolved === null ? 'it never completed' : 'it rejected'
          }${message ? `More info: ${message}` : ''}`;
        actual
          .then(() => {
            resolved = true;
          })
          .catch(() => {
            resolved = false;
          });
        let slept = 0;
        while (resolved === null && slept < timeout) {
          // eslint-disable-next-line no-await-in-loop
          await sleep(50);
          slept += 50;
        }
        if (resolved && this.isNot) {
          fail(msg());
        } else if (!resolved && !this.isNot) {
          fail(msg());
        }
      });
    },
    async toBeRejected(actual, message, timeoutMs) {
      return runAssertionsAsync(this, async () => {
        let rejected = null;
        const timeout = timeoutMs || 50;
        const msg = () =>
          `expected${notFor(this)}to reject promise, but ${
            rejected === null ? 'it never completed' : 'it resolved'
          }${message ? `More info: ${message}` : ''}`;
        actual
          .then(() => {
            rejected = false;
          })
          .catch(() => {
            rejected = true;
          });
        let slept = 0;
        while (rejected === null && slept < timeout) {
          // eslint-disable-next-line no-await-in-loop
          await sleep(50);
          slept += 50;
        }
        if (rejected && this.isNot) {
          fail(msg());
        } else if (!rejected && !this.isNot) {
          fail(msg());
        }
      });
    },
    toExist(actual) {
      return runAssertions(this, () => {
        const msg = () => `Expected ${actual}${notFor(this)}to exist`;
        assert(actual !== null && actual !== undefined, msg);
        return msg;
      });
    },
    toBeDisabled(actual) {
      return runAssertions(this, () => {
        const msg = () => `Expected ${actual}${notFor(this)}to be disabled`;
        assert(actual.disabled, msg);
        return msg;
      });
    },
    toHaveReceivedNoCallsAtAll(mockedObject) {
      return runAssertions(this, () => {
        const called = Object.getOwnPropertyNames(
          Object.getPrototypeOf(mockedObject)
        ).reduce((acc, cur) => {
          const prop = mockedObject[cur];
          if (typeof prop.mock === 'undefined') {
            return acc;
          }
          if (prop.mock.calls && prop.mock.calls.length) {
            acc.push(cur);
          }
          return acc;
        }, []);
        const msg = () =>
          `expected${notFor(
            this
          )}to have received any calls, but got ${called}`;
        assert(!called.length, msg);
        return msg;
      });
    },
    toHaveReceivedOnly(mockedObject, ...calls) {
      return runAssertions(this, () => {
        const called = Object.getOwnPropertyNames(
          Object.getPrototypeOf(mockedObject)
        ).reduce((acc, cur) => {
          const prop = mockedObject[cur];
          if (typeof prop.mock === 'undefined') {
            return acc;
          }
          if (
            prop.mock.calls &&
            prop.mock.calls.length &&
            calls.indexOf(cur) === -1
          ) {
            acc.push(cur);
          }
          return acc;
        }, []);
        const msg = () =>
          `expected${notFor(
            this
          )}to have received any calls, but got ${called}`;
        assert(!called.length, msg);
        return msg;
      });
    },
  });
});
