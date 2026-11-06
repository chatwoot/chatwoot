import { downloadFile } from '@chatwoot/utils';
import { useFileDownload } from 'dashboard/composables/useFileDownload';

vi.mock('@chatwoot/utils', () => ({
  downloadFile: vi.fn(),
}));

describe('useFileDownload', () => {
  const attachment = {
    url: 'https://chat.example.com/rails/active_storage/blobs/redirect/abc/voice.ogg',
    type: 'audio',
    extension: 'ogg',
  };

  beforeEach(() => {
    vi.clearAllMocks();
    vi.spyOn(window, 'open').mockImplementation(() => null);
  });

  it('downloads the file through downloadFile', async () => {
    downloadFile.mockResolvedValue();
    const { download } = useFileDownload();

    await download(attachment);

    expect(downloadFile).toHaveBeenCalledWith(attachment);
    expect(window.open).not.toHaveBeenCalled();
  });

  it('opens the url in a new tab when the download cannot be fetched', async () => {
    downloadFile.mockRejectedValue(new TypeError('Failed to fetch'));
    const { download } = useFileDownload();

    await expect(download(attachment)).resolves.toBeUndefined();

    expect(window.open).toHaveBeenCalledWith(
      attachment.url,
      '_blank',
      'noopener'
    );
  });
});
