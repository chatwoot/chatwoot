import { flushPromises, mount } from '@vue/test-utils';
import { useAlert } from 'dashboard/composables';
import { uploadFile } from 'dashboard/helper/uploadHelper';
import CannedResponseFiles from '../CannedResponseFiles.vue';

vi.mock('dashboard/composables', () => ({
  useAlert: vi.fn(),
}));

vi.mock('dashboard/composables/store', () => ({
  useMapGetter: () => ({ value: { maximumFileUploadSize: 1 } }),
}));

vi.mock('dashboard/helper/uploadHelper', () => ({
  uploadFile: vi.fn(),
}));

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key }),
}));

const png = new File(['image'], 'dashboard.png', { type: 'image/png' });
const pdf = new File(['guide'], 'guide.pdf', { type: 'application/pdf' });

const savedFile = {
  signed_id: 'signed-saved',
  filename: 'saved.pdf',
  content_type: 'application/pdf',
  byte_size: 2048,
  file_url: '/saved.pdf',
};

const mountFiles = (files = []) => {
  const wrapper = mount(CannedResponseFiles, {
    props: {
      modelValue: files,
      'onUpdate:modelValue': modelValue => wrapper.setProps({ modelValue }),
    },
    global: { directives: { tooltip: {} } },
  });
  return wrapper;
};

const selectFiles = async (wrapper, files) => {
  const input = wrapper.find('input[type="file"]');
  Object.defineProperty(input.element, 'files', {
    value: files,
    configurable: true,
  });
  await input.trigger('change');
};

describe('CannedResponseFiles', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    uploadFile.mockImplementation(file =>
      Promise.resolve({
        blobId: `signed-${file.name}`,
        fileUrl: `/${file.name}`,
      })
    );
  });

  it('adds every file of a selection once it is uploaded', async () => {
    const wrapper = mountFiles([savedFile]);

    await selectFiles(wrapper, [png, pdf]);
    await flushPromises();

    expect(wrapper.props('modelValue')).toEqual([
      savedFile,
      {
        signed_id: 'signed-dashboard.png',
        filename: 'dashboard.png',
        content_type: 'image/png',
        byte_size: png.size,
        file_url: '/dashboard.png',
      },
      {
        signed_id: 'signed-guide.pdf',
        filename: 'guide.pdf',
        content_type: 'application/pdf',
        byte_size: pdf.size,
        file_url: '/guide.pdf',
      },
    ]);
  });

  it('rejects a file type that cannot be attached to a reply', async () => {
    const wrapper = mountFiles();
    const installer = new File(['binary'], 'installer.exe', {
      type: 'application/x-msdownload',
    });

    await selectFiles(wrapper, [installer]);

    expect(useAlert).toHaveBeenCalledWith(
      'CANNED_MGMT.FILES.TYPE_NOT_SUPPORTED'
    );
    expect(uploadFile).not.toHaveBeenCalled();
    expect(wrapper.props('modelValue')).toEqual([]);
  });

  it('rejects a file over the upload size limit', async () => {
    const wrapper = mountFiles();
    const largeFile = new File(['a'.repeat(2 * 1024 * 1024)], 'large.pdf', {
      type: 'application/pdf',
    });

    await selectFiles(wrapper, [largeFile]);

    expect(useAlert).toHaveBeenCalledWith('CONVERSATION.FILE_SIZE_LIMIT');
    expect(uploadFile).not.toHaveBeenCalled();
  });

  it('drops a file when its upload fails', async () => {
    uploadFile.mockRejectedValue(new Error('Network Error'));
    const wrapper = mountFiles([savedFile]);

    await selectFiles(wrapper, [pdf]);
    await flushPromises();

    expect(wrapper.props('modelValue')).toEqual([savedFile]);
    expect(useAlert).toHaveBeenCalledWith('CANNED_MGMT.FILES.UPLOAD_ERROR');
  });
});
