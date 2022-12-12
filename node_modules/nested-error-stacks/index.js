var inherits = require('util').inherits;

var NestedError = function (message, nested) {
    this.nested = nested;

    if (message instanceof Error) {
        nested = message;
    } else if (typeof message !== 'undefined') {
        Object.defineProperty(this, 'message', {
            value: message,
            writable: true,
            enumerable: false,
            configurable: true
        });
    }

    Error.captureStackTrace(this, this.constructor);
    var oldStackDescriptor = Object.getOwnPropertyDescriptor(this, 'stack');
    var stackDescriptor = buildStackDescriptor(oldStackDescriptor, nested);
    Object.defineProperty(this, 'stack', stackDescriptor);
};

function buildStackDescriptor(oldStackDescriptor, nested) {
    if (oldStackDescriptor.get) {
        return {
            get: function () {
                var stack = oldStackDescriptor.get.call(this);
                return buildCombinedStacks(stack, this.nested);
            }
        };
    } else {
        var stack = oldStackDescriptor.value;
        return {
            value: buildCombinedStacks(stack, nested)
        };
    }
}

function buildCombinedStacks(stack, nested) {
    if (nested) {
        stack += '\nCaused By: ' + nested.stack;
    }
    return stack;
}

inherits(NestedError, Error);
NestedError.prototype.name = 'NestedError';


module.exports = NestedError;
