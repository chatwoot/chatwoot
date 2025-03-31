"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.createTaskGroup = void 0;
var is_thenable_1 = require("../utils/is-thenable");
var createTaskGroup = function () {
    var taskCompletionPromise;
    var resolvePromise;
    var count = 0;
    return {
        done: function () { return taskCompletionPromise; },
        run: function (op) {
            var returnValue = op();
            if ((0, is_thenable_1.isThenable)(returnValue)) {
                if (++count === 1) {
                    taskCompletionPromise = new Promise(function (res) { return (resolvePromise = res); });
                }
                returnValue.finally(function () { return --count === 0 && resolvePromise(); });
            }
            return returnValue;
        },
    };
};
exports.createTaskGroup = createTaskGroup;
//# sourceMappingURL=task-group.js.map