"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
function getTypeScriptPerformance(typescript) {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    return typescript.performance;
}
function connectTypeScriptPerformance(typescript, performance) {
    const typeScriptPerformance = getTypeScriptPerformance(typescript);
    if (typeScriptPerformance) {
        const { mark, measure } = typeScriptPerformance;
        const { enable, disable } = performance;
        typeScriptPerformance.mark = (name) => {
            mark(name);
            performance.mark(name);
        };
        typeScriptPerformance.measure = (name, startMark, endMark) => {
            measure(name, startMark, endMark);
            performance.measure(name, startMark, endMark);
        };
        return Object.assign(Object.assign({}, performance), { enable() {
                enable();
                typeScriptPerformance.enable();
            },
            disable() {
                disable();
                typeScriptPerformance.disable();
            } });
    }
    else {
        return performance;
    }
}
exports.connectTypeScriptPerformance = connectTypeScriptPerformance;
