import { oraPromise } from 'ora';
export async function lintingSpinner(cb) {
    return oraPromise(cb, {
        text: 'Linting...',
        spinner: 'clock',
        successText: 'Linting done.',
    });
}
export async function fixingSpinner(cb) {
    return oraPromise(cb, {
        text: 'Fixing...',
        spinner: 'clock',
        successText: 'Fixing done.',
    });
}
export async function undoingSpinner(cb) {
    return oraPromise(cb, {
        text: 'Undoing...',
        spinner: 'timeTravel',
        successText: 'Undoing done.',
    });
}
//# sourceMappingURL=ora.js.map