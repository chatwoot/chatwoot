import { mount } from '@vue/test-utils';
import ContextMenu from '../ContextMenu.vue';

const mountMenu = (props = {}) =>
  mount(ContextMenu, {
    props: { x: 10, y: 20, ...props },
    slots: { default: '<button class="inside">Inside</button>' },
    global: {
      stubs: { TeleportWithDirection: { template: '<div><slot /></div>' } },
    },
  });

describe('ContextMenu', () => {
  it('closes when focus leaves the menu', async () => {
    const wrapper = mountMenu();

    await wrapper
      .find('[tabindex="0"]')
      .trigger('focusout', { relatedTarget: document.body });

    expect(wrapper.emitted('close')).toHaveLength(1);
  });

  it('stays open while focus moves within the menu', async () => {
    const wrapper = mountMenu();

    await wrapper
      .find('[tabindex="0"]')
      .trigger('focusout', { relatedTarget: wrapper.find('.inside').element });

    expect(wrapper.emitted('close')).toBeUndefined();
  });

  it('ignores focus loss when closeOnFocusOut is disabled', async () => {
    const wrapper = mountMenu({ closeOnFocusOut: false });

    await wrapper
      .find('[tabindex="0"]')
      .trigger('focusout', { relatedTarget: document.body });

    expect(wrapper.emitted('close')).toBeUndefined();
  });
});
