import { useFileUpload } from '../useFileUpload';
import { useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { DirectUpload } from 'activestorage';
import { checkFileSizeLimit } from 'shared/helpers/FileHelper';
import { MAXIMUM_FILE_UPLOAD_SIZE_TWILIO_SMS_CHANNEL } from 'shared/constants/messages';

vi.mock('dashboard/composables/store');
vi.mock('dashboard/composables', () => ({
  useAlert: vi.fn(message => message),
}));
vi.mock('vue-i18n');
vi.mock('activestorage');
vi.mock('shared/helpers/FileHelper');

describe('useFileUpload', () => {
  const mockAttachFile = vi.fn();
  const mockTranslate = vi.fn();

  const mockFile = {
    file: new File(['test'], 'test.jpg', { type: 'image/jpeg' }),
  };

  beforeEach(() => {
    vi.clearAllMocks();

    useMapGetter.mockImplementation(getter => {
      const getterMap = {
        getCurrentAccountId: { value: '123' },
        getCurrentUser: { value: { access_token: 'test-token' } },
        getSelectedChat: { value: { id: '456' } },
        'globalConfig/get': { value: { directUploadsEnabled: true } },
      };
      return getterMap[getter];
    });

    useI18n.mockReturnValue({ t: mockTranslate });
    checkFileSizeLimit.mockReturnValue(true);
  });

  it('should handle direct file upload when enabled', () => {
    const { onFileUpload } = useFileUpload({
      isATwilioSMSChannel: false,
      attachFile: mockAttachFile,
    });

    const mockBlob = { signed_id: 'test-blob' };
    DirectUpload.mockImplementation(() => ({
      create: callback => callback(null, mockBlob),
    }));

    onFileUpload(mockFile);

    expect(DirectUpload).toHaveBeenCalledWith(
      mockFile.file,
      '/api/v1/accounts/123/conversations/456/direct_uploads',
      expect.any(Object)
    );
    expect(mockAttachFile).toHaveBeenCalledWith({
      file: mockFile,
      blob: mockBlob,
    });
  });

  it('should handle indirect file upload when direct upload is disabled', () => {
    useMapGetter.mockImplementation(getter => {
      const getterMap = {
        getCurrentAccountId: { value: '123' },
        getCurrentUser: { value: { access_token: 'test-token' } },
        getSelectedChat: { value: { id: '456' } },
        'globalConfig/get': { value: { directUploadsEnabled: false } },
      };
      return getterMap[getter];
    });

    const { onFileUpload } = useFileUpload({
      isATwilioSMSChannel: false,
      attachFile: mockAttachFile,
    });

    onFileUpload(mockFile);

    expect(DirectUpload).not.toHaveBeenCalled();
    expect(mockAttachFile).toHaveBeenCalledWith({ file: mockFile });
  });

  it('should show alert when file size exceeds limit', () => {
    checkFileSizeLimit.mockReturnValue(false);
    mockTranslate.mockReturnValue('File size exceeds limit');

    const { onFileUpload } = useFileUpload({
      isATwilioSMSChannel: false,
      attachFile: mockAttachFile,
    });

    onFileUpload(mockFile);

    expect(useAlert).toHaveBeenCalledWith('File size exceeds limit');
    expect(mockAttachFile).not.toHaveBeenCalled();
  });

  it('should use different max file size for Twilio SMS channel', () => {
    const { onFileUpload } = useFileUpload({
      isATwilioSMSChannel: true,
      attachFile: mockAttachFile,
    });

    onFileUpload(mockFile);

    expect(checkFileSizeLimit).toHaveBeenCalledWith(
      mockFile,
      MAXIMUM_FILE_UPLOAD_SIZE_TWILIO_SMS_CHANNEL
    );
  });

  it('should handle direct upload errors', () => {
    const mockError = 'Upload failed';
    DirectUpload.mockImplementation(() => ({
      create: callback => callback(mockError, null),
    }));

    const { onFileUpload } = useFileUpload({
      isATwilioSMSChannel: false,
      attachFile: mockAttachFile,
    });

    onFileUpload(mockFile);

    expect(useAlert).toHaveBeenCalledWith(mockError);
    expect(mockAttachFile).not.toHaveBeenCalled();
  });

  it('should do nothing when file is null', () => {
    const { onFileUpload } = useFileUpload({
      isATwilioSMSChannel: false,
      attachFile: mockAttachFile,
    });

    onFileUpload(null);

    expect(checkFileSizeLimit).not.toHaveBeenCalled();
    expect(mockAttachFile).not.toHaveBeenCalled();
    expect(useAlert).not.toHaveBeenCalled();
  });
});
