import { defineComponent } from 'vue';
import { mount } from '@vue/test-utils';

import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from './Dialog.vue';

const OnClickOutsideStub = defineComponent({
  name: 'OnClickOutside',
  template: '<div @click="$emit(\'trigger\')"><slot /></div>',
});

const mountDialog = (props = {}) =>
  mount(Dialog, {
    props,
    global: {
      stubs: {
        OnClickOutside: OnClickOutsideStub,
        TeleportWithDirection: { template: '<div><slot /></div>' },
      },
    },
  });

describe('Dialog', () => {
  it('prevents Escape and outside click dismissal when disabled', async () => {
    const wrapper = mountDialog({ disableDismissal: true });
    const cancelEvent = new Event('cancel', { cancelable: true });

    wrapper.get('dialog').element.dispatchEvent(cancelEvent);
    wrapper.getComponent(OnClickOutsideStub).vm.$emit('trigger');
    await wrapper.vm.$nextTick();

    expect(cancelEvent.defaultPrevented).toBe(true);
    expect(wrapper.emitted('close')).toBeUndefined();
    expect(
      wrapper
        .findAllComponents(Button)
        .find(button => button.props('variant') === 'faded')
        .attributes('disabled')
    ).toBeDefined();
  });

  it('allows programmatic close when dismissal is disabled', () => {
    const wrapper = mountDialog({ disableDismissal: true });
    wrapper.get('dialog').element.close = vi.fn();

    wrapper.vm.close();

    expect(wrapper.emitted('close')).toHaveLength(1);
  });

  it('keeps outside click dismissal enabled by default', async () => {
    const wrapper = mountDialog();
    const dialog = wrapper.get('dialog').element;
    dialog.close = vi.fn();
    const queryDialogs = vi
      .spyOn(document, 'querySelectorAll')
      .mockReturnValue([dialog]);

    wrapper.getComponent(OnClickOutsideStub).vm.$emit('trigger');
    await wrapper.vm.$nextTick();

    expect(wrapper.emitted('close')).toHaveLength(1);
    queryDialogs.mockRestore();
  });
});
