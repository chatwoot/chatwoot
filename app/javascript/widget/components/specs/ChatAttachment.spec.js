import { shallowMount } from '@vue/test-utils';
import { createStore } from 'vuex';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import FileUpload from 'vue-upload-component';
import { DirectUpload } from 'activestorage';

import { BUS_EVENTS } from 'shared/constants/busEvents';
import { emitter } from 'shared/helpers/mitt';
import ChatAttachment from '../ChatAttachment.vue';

vi.mock('shared/helpers/mitt', () => ({
  emitter: { emit: vi.fn() },
}));

vi.mock('activestorage', () => ({
  DirectUpload: vi.fn(function MockDirectUpload(file) {
    this.create = callback => callback(null, { signed_id: file.name });
  }),
}));

const createUpload = ({ name, type = 'image/png', size = 1024 } = {}) => ({
  file: { name, type, size },
  type,
});

const mountAttachment = ({ directUploadsEnabled = false } = {}) => {
  const onAttach = vi.fn().mockResolvedValue();
  const store = createStore({
    modules: {
      globalConfig: {
        namespaced: true,
        getters: {
          get: () => ({ maximumFileUploadSize: 1, directUploadsEnabled }),
        },
      },
    },
  });
  const wrapper = shallowMount(ChatAttachment, {
    props: { onAttach },
    global: { plugins: [store] },
  });
  const addFiles = files =>
    files.forEach(file =>
      wrapper.findComponent(FileUpload).vm.$emit('inputFile', file)
    );

  return { onAttach, addFiles };
};

describe('ChatAttachment', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    window.URL.createObjectURL = vi.fn(file => `blob:${file.name}`);
    window.chatwootWebChannel = { websiteToken: 'website-token' };
  });

  it('filters empty, unsupported, and oversized files independently', async () => {
    const { onAttach, addFiles } = mountAttachment();
    const validFile = createUpload({ name: 'valid.png' });

    addFiles([
      validFile,
      createUpload({ name: 'empty.png', size: 0 }),
      createUpload({ name: 'script.exe', type: 'application/x-msdownload' }),
      createUpload({ name: 'large.png', size: 2 * 1024 * 1024 }),
    ]);

    await vi.waitFor(() => expect(onAttach).toHaveBeenCalledTimes(1));
    expect(onAttach.mock.calls[0][0]).toEqual([
      expect.objectContaining({ file: validFile.file }),
    ]);
    expect(emitter.emit).toHaveBeenCalledWith(BUS_EVENTS.SHOW_ALERT, {
      message: 'FILE_TYPE_NOT_SUPPORTED',
    });
    expect(emitter.emit).toHaveBeenCalledWith(BUS_EVENTS.SHOW_ALERT, {
      message: 'FILE_SIZE_LIMIT',
    });
  });

  it('preserves every attachment in ordered messages of 15', async () => {
    const { onAttach, addFiles } = mountAttachment();
    const files = Array.from({ length: 32 }, (_, index) =>
      createUpload({ name: `${index}.png` })
    );

    addFiles(files);

    await vi.waitFor(() => expect(onAttach).toHaveBeenCalledTimes(3));
    expect(
      onAttach.mock.calls.map(([batch]) => batch.map(({ file }) => file.name))
    ).toEqual([
      files.slice(0, 15).map(({ file }) => file.name),
      files.slice(15, 30).map(({ file }) => file.name),
      files.slice(30).map(({ file }) => file.name),
    ]);
  });

  it('keeps the reply target for every message of one selection', async () => {
    const { onAttach, addFiles } = mountAttachment();
    // Mirrors ChatFooter: use the passed reply target (or the current one) and return it.
    onAttach.mockImplementation((_attachments, replyTo = 'reply-1') =>
      Promise.resolve(replyTo)
    );

    addFiles(
      Array.from({ length: 17 }, (_, index) =>
        createUpload({ name: `${index}.png` })
      )
    );

    await vi.waitFor(() => expect(onAttach).toHaveBeenCalledTimes(2));
    expect(onAttach.mock.calls[0][1]).toBeUndefined();
    expect(onAttach.mock.calls[1][1]).toBe('reply-1');
  });

  it('uploads directly and sends overflow files in additional messages', async () => {
    const { onAttach, addFiles } = mountAttachment({
      directUploadsEnabled: true,
    });

    addFiles(
      Array.from({ length: 17 }, (_, index) =>
        createUpload({ name: `${index}.png` })
      )
    );

    await vi.waitFor(() => expect(onAttach).toHaveBeenCalledTimes(2));
    expect(DirectUpload).toHaveBeenCalledTimes(17);
    expect(onAttach.mock.calls[0][0]).toHaveLength(15);
    expect(onAttach.mock.calls[1][0]).toHaveLength(2);
    expect(onAttach.mock.calls[0][0][0]).toEqual(
      expect.objectContaining({ file: '0.png', fileType: 'image' })
    );
  });
});
