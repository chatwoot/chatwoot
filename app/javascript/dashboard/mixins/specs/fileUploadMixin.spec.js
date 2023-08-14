import fileUploadMixin from 'dashboard/mixins/fileUploadMixin';
import Vue from 'vue';

jest.mock('shared/helpers/FileHelper', () => ({
  checkFileSizeLimit: jest.fn(),
}));

jest.mock('activestorage', () => ({
  DirectUpload: jest.fn().mockImplementation(() => ({
    create: jest.fn(),
  })),
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
  });

  it('should call onDirectFileUpload when direct uploads are enabled', () => {
    vm.onDirectFileUpload = jest.fn();
    vm.onFileUpload({});
    expect(vm.onDirectFileUpload).toHaveBeenCalledWith({});
  });

  it('should call onIndirectFileUpload when direct uploads are disabled', () => {
    vm.globalConfig.directUploadsEnabled = false;
    vm.onIndirectFileUpload = jest.fn();
    vm.onFileUpload({});
    expect(vm.onIndirectFileUpload).toHaveBeenCalledWith({});
  });
});
