import { ref } from 'vue';

export const useLoadWithRetry = (config = {}) => {
  const maxRetry = config.maxRetry || 3;
  const backoff = config.backoff || 1000;
  const type = config.type || '';

  const isLoaded = ref(false);
  const hasError = ref(false);
  const loadedUrl = ref('');

  const loadWithRetry = async url => {
    const attemptLoad = urlToLoad => {
      return new Promise((resolve, reject) => {
        let media;
        if (type === 'image') {
          media = new Image();
          media.onload = () => resolve();
          media.onerror = () => reject(new Error('Failed to load image'));
        } else if (type === 'audio') {
          media = new Audio();
          media.onloadedmetadata = () => resolve();
          media.onerror = () => reject(new Error('Failed to load audio'));
        } else {
          fetch(urlToLoad)
            .then(res => {
              if (res.ok) resolve();
              else reject(new Error('Failed to load resource'));
            })
            .catch(err => reject(err));
          return;
        }
        media.src = urlToLoad;
      });
    };

    const sleep = ms => {
      return new Promise(resolve => {
        setTimeout(resolve, ms);
      });
    };

    const retry = async (attempt = 0) => {
      try {
        const urlObj = new URL(url);
        urlObj.searchParams.set('t', Date.now());
        const urlWithTimestamp = urlObj.toString();

        await attemptLoad(urlWithTimestamp);

        hasError.value = false;
        loadedUrl.value = urlWithTimestamp;
        isLoaded.value = true;
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
    loadedUrl,
  };
};
