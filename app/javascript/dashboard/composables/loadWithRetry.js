import { ref } from 'vue';

export const useLoadWithRetry = (config = {}) => {
  const maxRetry = config.max_retry || 3;
  const backoff = config.backoff || 1000;

  const isLoaded = ref(false);
  const hasError = ref(false);

  const loadWithRetry = async url => {
    const attemptLoad = () => {
      return new Promise((resolve, reject) => {
        const img = new Image();

        img.onload = () => {
          isLoaded.value = true;
          hasError.value = false;
          resolve();
        };

        img.onerror = () => {
          reject(new Error('Failed to load image'));
        };

        img.src = url;
      });
    };

    const sleep = ms => {
      return new Promise(resolve => {
        setTimeout(resolve, ms);
      });
    };

    const retry = async (attempt = 0) => {
      try {
        await attemptLoad();
      } catch (error) {
        if (attempt + 1 >= maxRetry) {
          hasError.value = true;
          isLoaded.value = false;
          return;
        }
        await sleep(backoff * (attempt + 1));
        await retry(attempt + 1);
      }
    };

    await retry();
  };

  return {
    isLoaded,
    hasError,
    loadWithRetry,
  };
};
