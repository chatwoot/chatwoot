import { oraPromise } from 'ora';

export async function lintingSpinner<T>(cb: () => Promise<T>): Promise<T> {
  return oraPromise(cb, {
    text: 'Linting...',
    spinner: 'clock',
    successText: 'Linting done.',
  });
}

export async function fixingSpinner<T>(cb: () => Promise<T>): Promise<T> {
  return oraPromise(cb, {
    text: 'Fixing...',
    spinner: 'clock',
    successText: 'Fixing done.',
  });
}

export async function undoingSpinner<T>(cb: () => Promise<T>): Promise<T> {
  return oraPromise(cb, {
    text: 'Undoing...',
    spinner: 'timeTravel',
    successText: 'Undoing done.',
  });
}
