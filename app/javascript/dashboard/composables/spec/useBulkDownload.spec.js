import { vi } from 'vitest';
import { useBulkDownload } from '../useBulkDownload';

vi.mock('@chatwoot/utils', () => ({
  downloadFile: vi.fn(),
}));

import { downloadFile } from '@chatwoot/utils';

describe('useBulkDownload', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  const createAttachment = (id, type = 'image') => ({
    id,
    data_url: `https://example.com/file${id}.${type}`,
    file_type: type,
    extension: type,
  });

  it('returns initial state with isDownloading as false', () => {
    const { isDownloading, downloadProgress } = useBulkDownload();

    expect(isDownloading.value).toBe(false);
    expect(downloadProgress.value).toEqual({ current: 0, total: 0 });
  });

  it('downloads files sequentially', async () => {
    downloadFile.mockResolvedValue(undefined);

    const { downloadAllFiles } = useBulkDownload();
    const attachments = [
      createAttachment(1),
      createAttachment(2),
      createAttachment(3),
    ];

    const downloadPromise = downloadAllFiles(attachments);

    vi.advanceTimersByTimeAsync(250);

    const result = await downloadPromise;

    expect(downloadFile).toHaveBeenCalledTimes(3);
    expect(result).toEqual({ success: 3, failed: 0 });
  });

  it('updates download progress during download', async () => {
    downloadFile.mockResolvedValue(undefined);

    const { downloadAllFiles, downloadProgress } = useBulkDownload();
    const attachments = [createAttachment(1), createAttachment(2)];

    const downloadPromise = downloadAllFiles(attachments);

    expect(downloadProgress.value.total).toBe(2);

    vi.advanceTimersByTimeAsync(50);
    expect(downloadProgress.value.current).toBe(1);

    vi.advanceTimersByTimeAsync(150);
    expect(downloadProgress.value.current).toBe(2);

    await downloadPromise;
  });

  it('handles download errors gracefully', async () => {
    downloadFile.mockRejectedValueOnce(new Error('Network error'));
    downloadFile.mockResolvedValueOnce(undefined);

    const { downloadAllFiles } = useBulkDownload();
    const attachments = [createAttachment(1), createAttachment(2)];

    vi.advanceTimersByTimeAsync(150);
    const result = await downloadAllFiles(attachments);

    expect(result).toEqual({ success: 1, failed: 1 });
  });

  it('returns early with empty attachments', async () => {
    const { downloadAllFiles, isDownloading } = useBulkDownload();

    const result = await downloadAllFiles([]);

    expect(downloadFile).not.toHaveBeenCalled();
    expect(result).toEqual({ success: 0, failed: 0 });
    expect(isDownloading.value).toBe(false);
  });

  it('resets state after download completes', async () => {
    downloadFile.mockResolvedValue(undefined);

    const { downloadAllFiles, isDownloading, downloadProgress } =
      useBulkDownload();
    const attachments = [createAttachment(1)];

    vi.advanceTimersByTimeAsync(50);
    await downloadAllFiles(attachments);

    expect(isDownloading.value).toBe(false);
    expect(downloadProgress.value).toEqual({ current: 0, total: 0 });
  });
});
