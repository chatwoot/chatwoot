import { mount } from '@vue/test-utils';
import { vi } from 'vitest';
import AddCanned from '../AddCanned.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';

vi.mock('dashboard/composables', () => ({
  useAlert: vi.fn(),
}));

describe('AddCanned.vue', () => {
  const createStore = () => ({
    dispatch: vi.fn(() => Promise.resolve()),
  });

  const buildWrapper = (props = {}, store = createStore()) =>
    mount(AddCanned, {
      props: {
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
    const wrapper = buildWrapper({
      responseContent: 'Первая строка\n\n- пункт один',
    });

    expect(wrapper.findComponent(TextArea).exists()).toBe(true);
    expect(wrapper.vm.content).toBe('Первая строка\n\n- пункт один');
    expect(wrapper.html()).not.toContain('message-editor');
  });

  it('dispatches raw multiline content without editor transformation', async () => {
    const store = createStore();
    const wrapper = buildWrapper({}, store);
    const rawContent = 'Первая строка\n\n- пункт один\n- пункт два';

    await wrapper.setData({
      shortCode: 'test-format-check',
      content: rawContent,
    });

    wrapper.vm.addCannedResponse();

    expect(store.dispatch).toHaveBeenCalledWith('createCannedResponse', {
      short_code: 'test-format-check',
      content: rawContent,
    });
  });
});
