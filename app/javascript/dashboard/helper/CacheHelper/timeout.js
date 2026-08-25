export const INDEXED_DB_OPERATION_TIMEOUT_MS = 2000;

export const withIndexedDBTimeout = promise => {
  let timeoutId;
  const timeout = new Promise((_, reject) => {
    timeoutId = setTimeout(() => {
      reject(new Error('IndexedDB operation timed out'));
    }, INDEXED_DB_OPERATION_TIMEOUT_MS);
  });

  return Promise.race([promise, timeout]).finally(() => {
    clearTimeout(timeoutId);
  });
};
