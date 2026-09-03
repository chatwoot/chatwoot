import { flushPromises, mount } from '@vue/test-utils';
import Button from 'dashboard/components-next/button/Button.vue';
import FaqImportDialog from './FaqImportDialog.vue';

const { create, confirm, downloadInvalidRows, useAlert } = vi.hoisted(() => ({
  create: vi.fn(),
  confirm: vi.fn(),
  downloadInvalidRows: vi.fn(),
  useAlert: vi.fn(),
}));

vi.mock('dashboard/api/captain/faqImports', () => ({
  default: { create, confirm, downloadInvalidRows },
}));

vi.mock('dashboard/composables', () => ({ useAlert }));

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key }),
}));

const DialogStub = {
  props: {
    disableDismissal: {
      type: Boolean,
      default: false,
    },
  },
  methods: { close: vi.fn() },
  template: '<div><slot /><slot name="footer" /></div>',
};

const preview = {
  id: 9,
  original_filename: 'faqs.csv',
  row_count: 3,
  invalid_row_count: 1,
  rows: [
    {
      row_number: 2,
      question: 'Existing question',
      answer: 'Imported answer',
      existing_answer: 'Existing answer',
      state: 'existing',
      error: null,
    },
    {
      row_number: 3,
      question: 'New question',
      answer: 'New answer',
      state: 'valid',
      error: null,
    },
    {
      row_number: 4,
      question: '',
      answer: 'Missing a question',
      state: 'invalid',
      error: 'Question is required.',
    },
  ],
};

const zeroReadyPreview = {
  ...preview,
  row_count: 2,
  rows: [preview.rows[0], preview.rows[2]],
};

const mountDialog = () =>
  mount(FaqImportDialog, {
    props: { assistantId: 42 },
    global: {
      mocks: { $t: key => key },
      stubs: { Dialog: DialogStub, Icon: true },
    },
  });

const selectFile = async wrapper => {
  const file = new File(['question,answer\nQuestion,Answer'], 'faqs.csv', {
    type: 'text/csv',
  });
  const input = wrapper.get('input[type="file"]');
  Object.defineProperty(input.element, 'files', {
    configurable: true,
    value: [file],
  });
  await input.trigger('change');
  return file;
};

const findButton = (wrapper, label) =>
  wrapper.findAllComponents(Button).find(item => item.props('label') === label);

const clickButton = (wrapper, label) =>
  findButton(wrapper, label).trigger('click');

const deferred = () => {
  let resolve;
  const promise = new Promise(resolvePromise => {
    resolve = resolvePromise;
  });
  return { promise, resolve };
};

describe('FaqImportDialog', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('shows a fading question and answer example before file selection', async () => {
    const wrapper = mountDialog();
    const sample = wrapper.get('[data-testid="csv-format-sample"]');

    expect(sample.text()).toContain(
      'CAPTAIN.RESPONSES.IMPORT.SAMPLE.QUESTION_HEADER'
    );
    expect(sample.text()).toContain(
      'CAPTAIN.RESPONSES.IMPORT.SAMPLE.ANSWER_HEADER'
    );
    expect(sample.text()).toContain(
      'CAPTAIN.RESPONSES.IMPORT.SAMPLE.QUESTION_1'
    );
    expect(sample.attributes('class')).toContain('overflow-hidden');
    expect(sample.html()).toContain('mask-image:linear-gradient');

    await selectFile(wrapper);

    expect(wrapper.find('[data-testid="csv-format-sample"]').exists()).toBe(
      false
    );
  });

  it('uploads the CSV and shows a read-only preview', async () => {
    create.mockResolvedValueOnce({ data: preview });
    const wrapper = mountDialog();
    const file = await selectFile(wrapper);

    await clickButton(wrapper, 'CAPTAIN.RESPONSES.IMPORT.PREVIEW');
    await flushPromises();

    expect(create).toHaveBeenCalledWith({ assistantId: 42, file });
    expect(wrapper.text()).toContain('Existing question');
    expect(wrapper.text()).toContain('Existing answer');
    expect(wrapper.text()).toContain('Imported answer');
    expect(wrapper.text()).toContain('Question is required.');
    expect(wrapper.find('input[value="skip"]').element.checked).toBe(true);
    expect(
      wrapper.get('[role="radiogroup"]').attributes('aria-labelledby')
    ).toBe('faq-import-row-2 faq-import-question-2');
    expect(wrapper.find('input[type="text"]').exists()).toBe(false);
    expect(wrapper.find('textarea').exists()).toBe(false);
  });

  it('confirms existing FAQ overwrites by row number', async () => {
    create.mockResolvedValueOnce({ data: preview });
    confirm.mockResolvedValueOnce({ data: { id: 9, status: 'preparing' } });
    const wrapper = mountDialog();
    await selectFile(wrapper);
    await clickButton(wrapper, 'CAPTAIN.RESPONSES.IMPORT.PREVIEW');
    await flushPromises();

    await wrapper.get('input[value="overwrite"]').setValue(true);
    await clickButton(wrapper, 'CAPTAIN.RESPONSES.IMPORT.CONFIRM');
    await flushPromises();

    expect(confirm).toHaveBeenCalledWith({
      assistantId: 42,
      importId: 9,
      overwriteRowNumbers: [2],
    });
    expect(wrapper.emitted('confirmed')).toEqual([
      [{ id: 9, status: 'preparing' }],
    ]);
  });

  it('keeps existing FAQs set to Skip unless changed', async () => {
    create.mockResolvedValueOnce({ data: preview });
    confirm.mockResolvedValueOnce({ data: { id: 9, status: 'preparing' } });
    const wrapper = mountDialog();
    await selectFile(wrapper);
    await clickButton(wrapper, 'CAPTAIN.RESPONSES.IMPORT.PREVIEW');
    await flushPromises();

    await clickButton(wrapper, 'CAPTAIN.RESPONSES.IMPORT.CONFIRM');
    await flushPromises();

    expect(confirm).toHaveBeenCalledWith({
      assistantId: 42,
      importId: 9,
      overwriteRowNumbers: [],
    });
  });

  it('does not offer an import when no FAQs are ready', async () => {
    create.mockResolvedValueOnce({ data: zeroReadyPreview });
    const wrapper = mountDialog();
    await selectFile(wrapper);
    await clickButton(wrapper, 'CAPTAIN.RESPONSES.IMPORT.PREVIEW');
    await flushPromises();

    expect(findButton(wrapper, 'CAPTAIN.RESPONSES.IMPORT.CONFIRM')).toBeFalsy();
    expect(findButton(wrapper, 'CAPTAIN.RESPONSES.IMPORT.PREVIEW')).toBeFalsy();
    expect(confirm).not.toHaveBeenCalled();

    await wrapper.get('input[value="overwrite"]').setValue(true);

    expect(
      findButton(wrapper, 'CAPTAIN.RESPONSES.IMPORT.CONFIRM')
    ).toBeTruthy();
  });

  it('downloads invalid rows from the preview', async () => {
    const invalidRows = new Blob(['question,answer,error']);
    const createObjectURL = vi.fn(() => 'blob:invalid-rows');
    const revokeObjectURL = vi.fn();
    Object.defineProperty(URL, 'createObjectURL', {
      configurable: true,
      value: createObjectURL,
    });
    Object.defineProperty(URL, 'revokeObjectURL', {
      configurable: true,
      value: revokeObjectURL,
    });
    const click = vi
      .spyOn(HTMLAnchorElement.prototype, 'click')
      .mockImplementation(() => {});
    create.mockResolvedValueOnce({ data: preview });
    downloadInvalidRows.mockResolvedValueOnce({ data: invalidRows });
    const wrapper = mountDialog();
    await selectFile(wrapper);
    await clickButton(wrapper, 'CAPTAIN.RESPONSES.IMPORT.PREVIEW');
    await flushPromises();

    await clickButton(wrapper, 'CAPTAIN.RESPONSES.IMPORT.DOWNLOAD_INVALID');
    await flushPromises();

    expect(downloadInvalidRows).toHaveBeenCalledWith({
      assistantId: 42,
      importId: 9,
    });
    expect(createObjectURL).toHaveBeenCalledWith(invalidRows);
    expect(click).toHaveBeenCalledOnce();
    expect(revokeObjectURL).toHaveBeenCalledWith('blob:invalid-rows');
    click.mockRestore();
  });

  it('keeps the preview open while invalid rows are downloading', async () => {
    const pendingDownload = deferred();
    Object.defineProperty(URL, 'createObjectURL', {
      configurable: true,
      value: vi.fn(() => 'blob:invalid-rows'),
    });
    Object.defineProperty(URL, 'revokeObjectURL', {
      configurable: true,
      value: vi.fn(),
    });
    const click = vi
      .spyOn(HTMLAnchorElement.prototype, 'click')
      .mockImplementation(() => {});
    create.mockResolvedValueOnce({ data: preview });
    downloadInvalidRows.mockReturnValueOnce(pendingDownload.promise);
    const wrapper = mountDialog();
    await selectFile(wrapper);
    await clickButton(wrapper, 'CAPTAIN.RESPONSES.IMPORT.PREVIEW');
    await flushPromises();

    await clickButton(wrapper, 'CAPTAIN.RESPONSES.IMPORT.DOWNLOAD_INVALID');
    const uploadAnotherButton = findButton(
      wrapper,
      'CAPTAIN.RESPONSES.IMPORT.UPLOAD_ANOTHER'
    );

    expect(uploadAnotherButton.attributes('disabled')).toBeDefined();
    await uploadAnotherButton.trigger('click');
    expect(wrapper.text()).toContain('Existing question');

    pendingDownload.resolve({ data: new Blob(['question,answer,error']) });
    await flushPromises();
    click.mockRestore();
  });

  it('keeps the preview open while confirmation is pending', async () => {
    const pendingConfirmation = deferred();
    create.mockResolvedValueOnce({ data: preview });
    confirm.mockReturnValueOnce(pendingConfirmation.promise);
    const wrapper = mountDialog();
    await selectFile(wrapper);
    await clickButton(wrapper, 'CAPTAIN.RESPONSES.IMPORT.PREVIEW');
    await flushPromises();

    await clickButton(wrapper, 'CAPTAIN.RESPONSES.IMPORT.CONFIRM');
    const uploadAnotherButton = findButton(
      wrapper,
      'CAPTAIN.RESPONSES.IMPORT.UPLOAD_ANOTHER'
    );

    expect(uploadAnotherButton.attributes('disabled')).toBeDefined();
    expect(wrapper.getComponent(DialogStub).props('disableDismissal')).toBe(
      true
    );
    await uploadAnotherButton.trigger('click');
    expect(wrapper.text()).toContain('Existing question');

    pendingConfirmation.resolve({ data: { id: 9, status: 'preparing' } });
    await flushPromises();

    expect(wrapper.getComponent(DialogStub).props('disableDismissal')).toBe(
      false
    );
  });

  it('shows the validation error returned by the server', async () => {
    create.mockRejectedValueOnce({
      response: {
        data: {
          error:
            'The CSV must have exactly two columns named question and answer.',
        },
      },
    });
    const wrapper = mountDialog();
    await selectFile(wrapper);

    await clickButton(wrapper, 'CAPTAIN.RESPONSES.IMPORT.PREVIEW');
    await flushPromises();

    expect(useAlert).toHaveBeenCalledWith(
      'The CSV must have exactly two columns named question and answer.'
    );
  });
});
