import { beforeEach, describe, expect, it, vi } from 'vitest';

import { BUS_EVENTS } from 'shared/constants/busEvents';
import { emitter } from 'shared/helpers/mitt';
import ChatAttachment from '../ChatAttachment.vue';

vi.mock('shared/helpers/mitt', () => ({
  emitter: { emit: vi.fn() },
}));

const createUpload = ({ name, type = 'image/png', size = 1024 } = {}) => ({
  file: { name, type, size },
  type,
});

describe('ChatAttachment', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('getUploadableFiles', () => {
    it('filters empty, unsupported, and oversized files independently', () => {
      const validFile = createUpload({ name: 'valid.png' });
      const emptyFile = createUpload({ name: 'empty.png', size: 0 });
      const unsupportedFile = createUpload({
        name: 'script.exe',
        type: 'application/x-msdownload',
      });
      const oversizedFile = createUpload({
        name: 'large.png',
        size: 2 * 1024 * 1024,
      });
      const context = {
        fileUploadSizeLimit: 1,
        $t: vi.fn(key => key),
      };

      const result = ChatAttachment.methods.getUploadableFiles.call(context, [
        validFile,
        emptyFile,
        unsupportedFile,
        oversizedFile,
      ]);

      expect(result).toEqual([validFile]);
      expect(emitter.emit).toHaveBeenCalledWith(BUS_EVENTS.SHOW_ALERT, {
        message: 'FILE_TYPE_NOT_SUPPORTED',
      });
      expect(emitter.emit).toHaveBeenCalledWith(BUS_EVENTS.SHOW_ALERT, {
        message: 'FILE_SIZE_LIMIT',
      });
    });
  });

  describe('splitIntoUploadBatches', () => {
    it('preserves every attachment in ordered batches of 15', () => {
      const attachments = Array.from({ length: 32 }, (_, index) => index);

      expect(
        ChatAttachment.methods.splitIntoUploadBatches(attachments)
      ).toEqual([
        attachments.slice(0, 15),
        attachments.slice(15, 30),
        attachments.slice(30),
      ]);
    });
  });

  describe('onIndirectFileUpload', () => {
    it('sends overflow files as additional messages', async () => {
      const files = Array.from({ length: 17 }, (_, index) =>
        createUpload({ name: `${index}.png` })
      );
      const context = {
        getUploadableFiles: vi.fn(() => files),
        splitIntoUploadBatches: ChatAttachment.methods.splitIntoUploadBatches,
        processBatchesSequentially:
          ChatAttachment.methods.processBatchesSequentially,
        getLocalFileAttributes: vi.fn(file => ({
          thumbUrl: file.file.name,
          fileType: 'image',
        })),
        startUploadBatch: vi.fn(),
        finishUploadBatch: vi.fn(),
        attachFiles: vi.fn().mockResolvedValue(),
      };

      await ChatAttachment.methods.onIndirectFileUpload.call(context, files);

      expect(context.attachFiles).toHaveBeenCalledTimes(2);
      expect(context.attachFiles.mock.calls[0][0]).toHaveLength(15);
      expect(context.attachFiles.mock.calls[1][0]).toHaveLength(2);
      expect(
        context.attachFiles.mock.calls.flatMap(([batch]) => batch)
      ).toHaveLength(17);
    });
  });

  describe('onDirectFileUpload', () => {
    it('uploads and sends overflow files in additional messages', async () => {
      const files = Array.from({ length: 17 }, (_, index) =>
        createUpload({ name: `${index}.png` })
      );
      const context = {
        getUploadableFiles: vi.fn(() => files),
        splitIntoUploadBatches: ChatAttachment.methods.splitIntoUploadBatches,
        processBatchesSequentially:
          ChatAttachment.methods.processBatchesSequentially,
        uploadFileDirectly: vi.fn(file =>
          Promise.resolve({
            file: file.file.name,
            thumbUrl: file.file.name,
            fileType: 'image',
          })
        ),
        startUploadBatch: vi.fn(),
        finishUploadBatch: vi.fn(),
        attachFiles: vi.fn().mockResolvedValue(),
      };

      await ChatAttachment.methods.onDirectFileUpload.call(context, files);

      expect(context.uploadFileDirectly).toHaveBeenCalledTimes(17);
      expect(context.attachFiles).toHaveBeenCalledTimes(2);
      expect(context.attachFiles.mock.calls[0][0]).toHaveLength(15);
      expect(context.attachFiles.mock.calls[1][0]).toHaveLength(2);
    });
  });
});
