import { mount, flushPromises } from '@vue/test-utils';
import { nextTick } from 'vue';
import HeaderImageInput from '../HeaderImageInput.vue';

describe('HeaderImageInput', () => {
  let originalImage;
  let imageInstances;

  beforeEach(() => {
    imageInstances = [];
    originalImage = global.Image;
    global.Image = class {
      constructor() {
        imageInstances.push(this);
      }
    };
    vi.useFakeTimers();
  });

  afterEach(() => {
    global.Image = originalImage;
    vi.useRealTimers();
  });

  const mountComponent = () =>
    mount(HeaderImageInput, {
      props: { modelValue: '' },
      global: { mocks: { $t: key => key } },
    });

  it('emits invalid immediately while the URL check is still debounced', async () => {
    const wrapper = mountComponent();

    await wrapper.setProps({ modelValue: 'https://example.com/image.jpg' });

    expect(wrapper.emitted('update:valid').at(-1)[0]).toBe(false);
  });

  it('emits valid once the debounced check confirms the image loads', async () => {
    const wrapper = mountComponent();

    await wrapper.setProps({ modelValue: 'https://example.com/image.jpg' });
    vi.advanceTimersByTime(500);
    await flushPromises();

    expect(imageInstances).toHaveLength(1);
    imageInstances[0].onload();
    await nextTick();

    expect(wrapper.emitted('update:valid').at(-1)[0]).toBe(true);
  });

  it('emits invalid once the debounced check confirms the image fails to load', async () => {
    const wrapper = mountComponent();

    await wrapper.setProps({ modelValue: 'https://example.com/broken.jpg' });
    vi.advanceTimersByTime(500);
    await flushPromises();

    expect(imageInstances).toHaveLength(1);
    imageInstances[0].onerror();
    await nextTick();

    expect(wrapper.emitted('update:valid').at(-1)[0]).toBe(false);
  });

  it('emits valid immediately when the field is cleared', async () => {
    const wrapper = mountComponent();

    await wrapper.setProps({ modelValue: 'https://example.com/image.jpg' });
    await wrapper.setProps({ modelValue: '' });

    expect(wrapper.emitted('update:valid').at(-1)[0]).toBe(true);
  });
});
