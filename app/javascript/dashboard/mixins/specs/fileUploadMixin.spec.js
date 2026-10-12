import { shallowMount } from '@vue/test-utils';
import { useAlert } from 'dashboard/composables';
import fileUploadMixin from 'dashboard/mixins/fileUploadMixin';
import { checkFileSizeLimit } from 'shared/helpers/FileHelper';
import { reactive } from 'vue';
import { DirectUpload } from 'activestorage';
import {
  optimizeImage,
  getLongestSide,
  ImageOptimizationError,
  IMAGE_OPTIMIZATION_ERRORS,
} from 'shared/helpers/imageOptimizer';
import { getImageOptimizationPolicy } from 'dashboard/helper/imageOptimizationPolicy';

vi.mock('shared/helpers/imageOptimizer', async importActual => ({
  ...(await importActual()),
  optimizeImage: vi.fn(),
  getLongestSide: vi.fn(),
}));

vi.mock('shared/helpers/FileHelper', () => ({
  checkFileSizeLimit: vi.fn(),
  resolveMaximumFileUploadSize: vi.fn(value => Number(value) || 40),
  DEFAULT_MAXIMUM_FILE_UPLOAD_SIZE: 40,
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
  let mockInbox;

  beforeEach(() => {
    mockInbox = reactive({ channel_type: 'Channel::Whatsapp' });
    mockGlobalConfig = reactive({
      directUploadsEnabled: true,
      maximumFileUploadSize: 40,
    });

    mockCurrentChat = reactive({
      id: 456,
    });

    mockCurrentUser = reactive({
      access_token: 'token',
    });

    wrapper = shallowMount(
      {
        mixins: [fileUploadMixin],
        data() {
          return {
            globalConfig: mockGlobalConfig,
            currentChat: mockCurrentChat,
            currentUser: mockCurrentUser,
            isATwilioSMSChannel: false,
            inbox: mockInbox,
            isOnPrivateNote: false,
          };
        },
        methods: {
          attachFile: vi.fn(),
          showAlert: vi.fn(),
          $t: msg => msg,
        },
        template: '<div />',
      },
      {
        global: { mocks: { $store: { getters: { getCurrentAccountId: 1 } } } },
      }
    );
  });

  it('should call onDirectFileUpload when direct uploads are enabled', async () => {
    wrapper.vm.onDirectFileUpload = vi.fn();
    await wrapper.vm.onFileUpload({});
    expect(wrapper.vm.onDirectFileUpload).toHaveBeenCalledWith({});
  });

  it('should call onIndirectFileUpload when direct uploads are disabled', async () => {
    wrapper.vm.globalConfig.directUploadsEnabled = false;
    wrapper.vm.onIndirectFileUpload = vi.fn();
    await wrapper.vm.onFileUpload({});
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

  describe('image optimization', () => {
    const MB = 1024 * 1024;
    const buildFile = (size, type = 'image/png') => {
      const native = { type, size, name: 'photo.png' };
      return { file: native, name: native.name, type, size };
    };
    const optimizedFile = {
      name: 'photo.jpg',
      type: 'image/jpeg',
      size: 1 * MB,
    };

    beforeEach(() => {
      vi.clearAllMocks();
      wrapper.vm.onDirectFileUpload = vi.fn();
      checkFileSizeLimit.mockReturnValue(true);
      optimizeImage.mockResolvedValue({
        file: optimizedFile,
        width: 1600,
        height: 900,
      });
      getLongestSide.mockResolvedValue(1000);
    });

    it('optimizes an oversized WhatsApp image with the policy and uploads the result', async () => {
      const file = buildFile(8 * MB);
      const policy = getImageOptimizationPolicy({
        inbox: mockInbox,
        mime: 'image/png',
        installationLimit: wrapper.vm.installationLimit,
      });
      await wrapper.vm.onFileUpload(file);

      expect(optimizeImage).toHaveBeenCalledWith(file.file, {
        maxBytes: policy.maxBytes,
        ladder: policy.standardLadder,
      });
      const uploaded = wrapper.vm.onDirectFileUpload.mock.calls[0][0];
      expect(uploaded.file).toBe(optimizedFile);
      expect(uploaded.type).toBe('image/jpeg');
      expect(uploaded.size).toBe(optimizedFile.size);
      expect(uploaded.originalFile).toBe(file);
    });

    it('uploads identical a compliant image without optimizing', async () => {
      const file = buildFile(1 * MB);
      await wrapper.vm.onFileUpload(file);

      expect(optimizeImage).not.toHaveBeenCalled();
      expect(wrapper.vm.onDirectFileUpload).toHaveBeenCalledWith(file);
    });

    it('optimizes an image within the size limit but with a long side above the standard max', async () => {
      getLongestSide.mockResolvedValue(4000);
      await wrapper.vm.onFileUpload(buildFile(1 * MB));
      expect(optimizeImage).toHaveBeenCalled();
    });

    it('raises and lowers the optimizing counter', async () => {
      let resolveOptimize;
      optimizeImage.mockReturnValue(
        new Promise(resolve => {
          resolveOptimize = resolve;
        })
      );
      const pending = wrapper.vm.onFileUpload(buildFile(8 * MB));
      await vi.waitFor(() => expect(wrapper.vm.optimizingImages).toBe(1));
      expect(wrapper.vm.isOptimizingImage).toBe(true);
      resolveOptimize({ file: optimizedFile });
      await pending;
      expect(wrapper.vm.optimizingImages).toBe(0);
      expect(wrapper.vm.isOptimizingImage).toBe(false);
    });

    it('alerts and does not upload when the image is too large', async () => {
      optimizeImage.mockRejectedValue(
        new ImageOptimizationError(IMAGE_OPTIMIZATION_ERRORS.TOO_LARGE)
      );
      await wrapper.vm.onFileUpload(buildFile(8 * MB));
      expect(useAlert).toHaveBeenCalledWith(
        'CONVERSATION.IMAGE_OPTIMIZATION.TOO_LARGE'
      );
      expect(wrapper.vm.onDirectFileUpload).not.toHaveBeenCalled();
      expect(wrapper.vm.optimizingImages).toBe(0);
    });

    it.each([
      [IMAGE_OPTIMIZATION_ERRORS.UNSUPPORTED, 'UNSUPPORTED'],
      [IMAGE_OPTIMIZATION_ERRORS.DECODE_FAILED, 'FAILED'],
    ])(
      'on %s with an original that fits, warns and uploads the original',
      async (code, key) => {
        getLongestSide.mockResolvedValue(4000);
        optimizeImage.mockRejectedValue(new ImageOptimizationError(code));
        const file = buildFile(1 * MB);
        await wrapper.vm.onFileUpload(file);
        expect(useAlert).toHaveBeenCalledWith(
          `CONVERSATION.IMAGE_OPTIMIZATION.${key}_USING_ORIGINAL`
        );
        expect(wrapper.vm.onDirectFileUpload).toHaveBeenCalledWith(file);
      }
    );

    it.each([
      [IMAGE_OPTIMIZATION_ERRORS.UNSUPPORTED, 'UNSUPPORTED'],
      [IMAGE_OPTIMIZATION_ERRORS.DECODE_FAILED, 'FAILED'],
    ])(
      'on %s with an original over the limit, warns and falls through to the size check',
      async (code, key) => {
        optimizeImage.mockRejectedValue(new ImageOptimizationError(code));
        const file = buildFile(8 * MB);
        await wrapper.vm.onFileUpload(file);
        expect(useAlert).toHaveBeenCalledWith(
          `CONVERSATION.IMAGE_OPTIMIZATION.${key}`
        );
        expect(wrapper.vm.onDirectFileUpload).toHaveBeenCalledWith(file);
      }
    );

    it('does not touch images in channels without a policy', async () => {
      mockInbox.channel_type = 'Channel::WebWidget';
      const file = buildFile(8 * MB);
      await wrapper.vm.onFileUpload(file);
      expect(optimizeImage).not.toHaveBeenCalled();
      expect(wrapper.vm.onDirectFileUpload).toHaveBeenCalledWith(file);
    });

    it('does not touch images in private notes', async () => {
      await wrapper.setData({ isOnPrivateNote: true });
      const file = buildFile(8 * MB);
      await wrapper.vm.onFileUpload(file);
      expect(optimizeImage).not.toHaveBeenCalled();
      expect(wrapper.vm.onDirectFileUpload).toHaveBeenCalledWith(file);
    });

    it('uploadDirectly resolves the blob', async () => {
      const blob = { signed_id: 'abc' };
      DirectUpload.mockImplementationOnce(() => ({
        create: cb => cb(null, blob),
      }));
      await expect(
        wrapper.vm.uploadDirectly({ file: buildFile(1 * MB).file })
      ).resolves.toBe(blob);
    });
  });
});
