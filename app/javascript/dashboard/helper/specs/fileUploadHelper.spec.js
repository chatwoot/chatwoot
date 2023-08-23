import { onDirectFileUpload, onIndirectFileUpload } from '../fileUploadHelper';

describe('fileUploadHelper', () => {
  describe('onDirectFileUpload', () => {
    it('calls attachFile if file size is less than 40MB', () => {
      //   const attachFile = jest.fn();
      //   const showAlert = jest.fn();
      //   const file = { file: 'file', size: 100 };
      //   const isATwilioSMSChannel = false;
      //   const accountID = 1;
      //   const currentChatID = 1;
      //   onDirectFileUpload(
      //     file,
      //     isATwilioSMSChannel,
      //     attachFile,
      //     showAlert,
      //     accountID,
      //     currentChatID
      //   );
      //   expect(attachFile).toHaveBeenCalledWith({ file });
      //   expect(showAlert).not.toHaveBeenCalled();
    });

    it('calls showAlert if file size is greater than 40MB', () => {
      const attachFile = jest.fn();
      const showAlert = jest.fn();
      const file = { file: 'file', size: 50000000 };
      const isATwilioSMSChannel = false;
      const accountID = 1;
      const currentChatID = 1;

      onDirectFileUpload(
        file,
        isATwilioSMSChannel,
        attachFile,
        showAlert,
        accountID,
        currentChatID
      );

      expect(attachFile).not.toHaveBeenCalled();
      expect(showAlert).toHaveBeenCalledWith({ maxSize: 40 });
    });
  });

  describe('onIndirectFileUpload', () => {
    it('calls attachFile if file size is less than 40MB', () => {
      const attachFile = jest.fn();
      const showAlert = jest.fn();
      const file = { file: 'file', size: 100 };
      const isATwilioSMSChannel = false;

      onIndirectFileUpload(file, isATwilioSMSChannel, attachFile, showAlert);

      expect(attachFile).toHaveBeenCalledWith({ file });
      expect(showAlert).not.toHaveBeenCalled();
    });

    it('calls showAlert if file size is greater than 40MB', () => {
      const attachFile = jest.fn();
      const showAlert = jest.fn();
      const file = { file: 'file', size: 50000000 };
      const isATwilioSMSChannel = false;

      onIndirectFileUpload(file, isATwilioSMSChannel, attachFile, showAlert);

      expect(attachFile).not.toHaveBeenCalled();
      expect(showAlert).toHaveBeenCalledWith({ maxSize: 40 });
    });
  });
});
