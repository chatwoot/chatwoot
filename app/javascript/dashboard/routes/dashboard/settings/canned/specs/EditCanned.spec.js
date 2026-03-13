import { mount } from '@vue/test-utils';
import { vi } from 'vitest';
import EditCanned from '../EditCanned.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';

vi.mock('dashboard/composables', () => ({
  useAlert: vi.fn(),
}));

describe('EditCanned.vue', () => {
  const createStore = () => ({
    dispatch: vi.fn(() => Promise.resolve()),
  });

  const buildWrapper = (props = {}, store = createStore()) =>
    mount(EditCanned, {
      props: {
        id: 42,
        edshortCode: 'test-format-check',
        edcontent: 'Первая строка\n\n- пункт один',
        onClose: vi.fn(),
        ...props,
      },
      global: {
        mocks: {
          $t: key => key,
          $store: store,
        },
        stubs: {
          'woot-modal-header': true,
        },
      },
    });

  it('uses a plain TextArea and seeds content from props', () => {
    const wrapper = buildWrapper();

    expect(wrapper.findComponent(TextArea).exists()).toBe(true);
    expect(wrapper.findComponent(Checkbox).exists()).toBe(true);
    expect(wrapper.vm.content).toBe('Первая строка\n\n- пункт один');
    expect(wrapper.vm.isPlainText).toBe(false);
    expect(wrapper.html()).not.toContain('message-editor');
  });

  it('seeds the persisted plain text flag from props', () => {
    const wrapper = buildWrapper({
      edcontentFormat: 'plain_text',
    });

    expect(wrapper.vm.isPlainText).toBe(true);
  });

  it('dispatches raw multiline content without editor transformation', async () => {
    const store = createStore();
    const wrapper = buildWrapper({}, store);
    const rawContent = 'Первая строка\n\n- пункт один\n- пункт два';

    await wrapper.setData({
      shortCode: 'test-format-check',
      content: rawContent,
      isPlainText: true,
    });

    wrapper.vm.editCannedResponse();

    expect(store.dispatch).toHaveBeenCalledWith('updateCannedResponse', {
      id: 42,
      short_code: 'test-format-check',
      content: rawContent,
      content_format: 'plain_text',
    });
  });
});
