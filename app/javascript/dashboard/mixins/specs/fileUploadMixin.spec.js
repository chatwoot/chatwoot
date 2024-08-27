import Vue from 'vue';
import { useAlert } from 'dashboard/composables';
import fileUploadMixin from 'dashboard/mixins/fileUploadMixin';

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
  let vm;

  beforeEach(() => {
    vm = new Vue(fileUploadMixin);
    vm.isATwilioSMSChannel = false;
    vm.globalConfig = {
      directUploadsEnabled: true,
    };
    vm.accountId = 123;
    vm.currentChat = {
      id: 456,
    };
    vm.currentUser = {
      access_token: 'token',
    };
    vm.$t = vi.fn(message => message);
    vm.showAlert = vi.fn();
    vm.attachFile = vi.fn();
  });

  it('should call onDirectFileUpload when direct uploads are enabled', () => {
    vm.onDirectFileUpload = vi.fn();
    vm.onFileUpload({});
    expect(vm.onDirectFileUpload).toHaveBeenCalledWith({});
  });

  it('should call onIndirectFileUpload when direct uploads are disabled', () => {
    vm.globalConfig.directUploadsEnabled = false;
    vm.onIndirectFileUpload = vi.fn();
    vm.onFileUpload({});
    expect(vm.onIndirectFileUpload).toHaveBeenCalledWith({});
  });

  describe('onDirectFileUpload', () => {
    it('returns early if no file is provided', () => {
      const returnValue = vm.onDirectFileUpload(null);
      expect(returnValue).toBeUndefined();
    });

    it('shows an alert if the file size exceeds the maximum limit', () => {
      const fakeFile = { size: 999999999 };
      vm.onDirectFileUpload(fakeFile);
      expect(useAlert).toHaveBeenCalledWith(expect.any(String));
    });
  });

  describe('onIndirectFileUpload', () => {
    it('returns early if no file is provided', () => {
      const returnValue = vm.onIndirectFileUpload(null);
      expect(returnValue).toBeUndefined();
    });

    it('shows an alert if the file size exceeds the maximum limit', () => {
      const fakeFile = { size: 999999999 };
      vm.onIndirectFileUpload(fakeFile);
      expect(useAlert).toHaveBeenCalledWith(expect.any(String));
    });
  });
});
