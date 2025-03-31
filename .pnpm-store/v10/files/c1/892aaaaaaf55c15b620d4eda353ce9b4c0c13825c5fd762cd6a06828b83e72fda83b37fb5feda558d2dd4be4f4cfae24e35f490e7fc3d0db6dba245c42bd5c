import { isThenable } from '../utils/is-thenable';
export var createTaskGroup = function () {
    var taskCompletionPromise;
    var resolvePromise;
    var count = 0;
    return {
        done: function () { return taskCompletionPromise; },
        run: function (op) {
            var returnValue = op();
            if (isThenable(returnValue)) {
                if (++count === 1) {
                    taskCompletionPromise = new Promise(function (res) { return (resolvePromise = res); });
                }
                returnValue.finally(function () { return --count === 0 && resolvePromise(); });
            }
            return returnValue;
        },
    };
};
//# sourceMappingURL=task-group.js.map