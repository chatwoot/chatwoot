import { h } from 'vue';
import { mount } from '@vue/test-utils';
import DropdownContainer from '../DropdownContainer.vue';

const mountDropdown = () =>
  mount(DropdownContainer, {
    slots: {
      trigger: ({ toggle }) =>
        h('button', { 'data-testid': 'trigger', onClick: toggle }, 'Open'),
      default: '<ul data-testid="menu"><li>Item</li></ul>',
    },
    global: { provide: {} },
    attachTo: document.body,
  });

const pressEscape = () => {
  const event = new KeyboardEvent('keydown', {
    key: 'Escape',
    bubbles: true,
    cancelable: true,
  });
  document.body.dispatchEvent(event);
  return event;
};

const mountNested = () => {
  const inner = h(
    DropdownContainer,
    { 'data-testid': 'inner', onClose: () => {} },
    {
      trigger: ({ toggle }) =>
        h('button', { 'data-testid': 'inner-trigger', onClick: toggle }, 'Sub'),
      default: () => h('ul', { 'data-testid': 'inner-menu' }, 'Status'),
    }
  );
  return mount(DropdownContainer, {
    slots: {
      trigger: ({ toggle }) =>
        h('button', { 'data-testid': 'trigger', onClick: toggle }, 'Open'),
      default: () => inner,
    },
    attachTo: document.body,
  });
};

describe('DropdownContainer', () => {
  it('closes an open menu on Escape and marks the Escape as handled', async () => {
    const wrapper = mountDropdown();
    await wrapper.get('[data-testid="trigger"]').trigger('click');

    const event = pressEscape();
    await wrapper.vm.$nextTick();

    expect(wrapper.emitted('close')).toHaveLength(1);
    expect(event.defaultPrevented).toBe(true);
    wrapper.unmount();
  });

  it('leaves an Escape alone while the menu is closed', async () => {
    const wrapper = mountDropdown();

    const event = pressEscape();
    await wrapper.vm.$nextTick();

    expect(event.defaultPrevented).toBe(false);
    expect(wrapper.emitted('close')).toBeUndefined();
    wrapper.unmount();
  });

  it('closes only the innermost open menu on each Escape', async () => {
    const wrapper = mountNested();
    await wrapper.get('[data-testid="trigger"]').trigger('click');
    await wrapper.get('[data-testid="inner-trigger"]').trigger('click');
    const inner = wrapper
      .findAllComponents(DropdownContainer)
      .find(dropdown => dropdown.vm !== wrapper.vm);

    const first = pressEscape();
    await wrapper.vm.$nextTick();

    expect(first.defaultPrevented).toBe(true);
    expect(inner.emitted('close')).toHaveLength(1);
    expect(wrapper.emitted('close')).toBeUndefined();

    pressEscape();
    await wrapper.vm.$nextTick();

    expect(wrapper.emitted('close')).toHaveLength(1);
    wrapper.unmount();
  });

  it('hands focus back to the trigger when Escape closes the menu', async () => {
    const wrapper = mount(DropdownContainer, {
      slots: {
        trigger: ({ toggle }) =>
          h('div', [
            h('button', { 'data-testid': 'trigger', onClick: toggle }, 'Open'),
          ]),
        default: () => h('input', { 'data-testid': 'search' }),
      },
      attachTo: document.body,
    });
    await wrapper.get('[data-testid="trigger"]').trigger('click');
    wrapper.get('[data-testid="search"]').element.focus();

    pressEscape();
    await wrapper.vm.$nextTick();

    expect(document.activeElement).toBe(
      wrapper.get('[data-testid="trigger"]').element
    );
    wrapper.unmount();
  });
});
