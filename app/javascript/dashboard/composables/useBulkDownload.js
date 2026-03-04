import { ref } from 'vue';
import { downloadFile } from '@chatwoot/utils';

const DOWNLOAD_DELAY_MS = 100;

export function useBulkDownload() {
  const isDownloading = ref(false);
  const downloadProgress = ref({ current: 0, total: 0 });

  const delay = ms =>
    new Promise(resolve => {
      setTimeout(resolve, ms);
    });

  // eslint-disable-next-line no-await-in-loop
  const downloadAllFiles = async (attachments = []) => {
    if (!attachments.length) return { success: 0, failed: 0 };

    isDownloading.value = true;
    downloadProgress.value = { current: 0, total: attachments.length };

    let successCount = 0;
    let failCount = 0;

    for (let i = 0; i < attachments.length; i += 1) {
      const attachment = attachments[i];
      downloadProgress.value.current = i + 1;

      try {
        const { data_url: url, file_type: type, extension } = attachment;
        // eslint-disable-next-line no-await-in-loop
        await downloadFile({ url, type, extension });
        successCount += 1;
      } catch {
        failCount += 1;
      }

      if (i < attachments.length - 1) {
        // eslint-disable-next-line no-await-in-loop
        await delay(DOWNLOAD_DELAY_MS);
      }
    }

    isDownloading.value = false;
    downloadProgress.value = { current: 0, total: 0 };

    return { success: successCount, failed: failCount };
  };

  return {
    isDownloading,
    downloadProgress,
    downloadAllFiles,
  };
}
