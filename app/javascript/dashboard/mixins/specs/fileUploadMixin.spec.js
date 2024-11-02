import { shallowMount } from '@vue/test-utils';
import { useAlert } from 'dashboard/composables';
import fileUploadMixin from 'dashboard/mixins/fileUploadMixin';
import { checkFileSizeLimit } from 'shared/helpers/FileHelper';
import { reactive } from 'vue';

vi.mock('shared/helpers/FileHelper', () => ({
  checkFileSizeLimit: vi.fn(),
}));

vi.mock('activestorage', () => ({
  DirectUpload: vi.fn().mockImplementation(() => ({
    create: vi.fn(),
  })),
}));

vi.mock('dashboard/composables', () => ({
  useAlert: vi.fn(),
}));

describe('FileUploadMixin', () => {
  let wrapper;
  let mockGlobalConfig;
  let mockCurrentChat;
  let mockCurrentUser;

  beforeEach(() => {
    mockGlobalConfig = reactive({
      directUploadsEnabled: true,
    });

    mockCurrentChat = reactive({
      id: 456,
    });

    mockCurrentUser = reactive({
      access_token: 'token',
    });

    wrapper = shallowMount({
      mixins: [fileUploadMixin],
      data() {
        return {
          globalConfig: mockGlobalConfig,
          currentChat: mockCurrentChat,
          currentUser: mockCurrentUser,
          isATwilioSMSChannel: false,
        };
      },
      methods: {
        attachFile: vi.fn(),
        showAlert: vi.fn(),
        $t: msg => msg,
      },
      template: '<div />',
    });
  });

  it('should call onDirectFileUpload when direct uploads are enabled', () => {
    wrapper.vm.onDirectFileUpload = vi.fn();
    wrapper.vm.onFileUpload({});
    expect(wrapper.vm.onDirectFileUpload).toHaveBeenCalledWith({});
  });

  it('should call onIndirectFileUpload when direct uploads are disabled', () => {
    wrapper.vm.globalConfig.directUploadsEnabled = false;
    wrapper.vm.onIndirectFileUpload = vi.fn();
    wrapper.vm.onFileUpload({});
    expect(wrapper.vm.onIndirectFileUpload).toHaveBeenCalledWith({});
  });

  describe('onDirectFileUpload', () => {
    it('returns early if no file is provided', () => {
      const returnValue = wrapper.vm.onDirectFileUpload(null);
      expect(returnValue).toBeUndefined();
    });

    it('shows an alert if the file size exceeds the maximum limit', () => {
      const fakeFile = { size: 999999999 };
      checkFileSizeLimit.mockReturnValue(false); // Mock exceeding file size
      wrapper.vm.onDirectFileUpload(fakeFile);
      expect(useAlert).toHaveBeenCalledWith(expect.any(String));
    });
  });

  describe('onIndirectFileUpload', () => {
    it('returns early if no file is provided', () => {
      const returnValue = wrapper.vm.onIndirectFileUpload(null);
      expect(returnValue).toBeUndefined();
    });

    it('shows an alert if the file size exceeds the maximum limit', () => {
      const fakeFile = { size: 999999999 };
      checkFileSizeLimit.mockReturnValue(false); // Mock exceeding file size
      wrapper.vm.onIndirectFileUpload(fakeFile);
      expect(useAlert).toHaveBeenCalledWith(expect.any(String));
    });
  });
});
