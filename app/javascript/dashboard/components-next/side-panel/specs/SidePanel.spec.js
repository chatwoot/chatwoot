import { mount } from '@vue/test-utils';
import SidePanel from '../SidePanel.vue';

// Listeners registered with onKeyStroke outlive unmount in this test environment, so each test
// closes the panel it opened: a leftover open panel would take the next test's Escape.
const done = wrapper => {
  wrapper.vm.close();
  wrapper.unmount();
};

const mountOpenPanel = async () => {
  const wrapper = mount(SidePanel, {
    props: { title: 'Rule' },
    slots: { default: '<input data-testid="field" />' },
    global: {
      stubs: { TeleportWithDirection: { template: '<div><slot /></div>' } },
    },
    attachTo: document.body,
  });
  wrapper.vm.open();
  await wrapper.vm.$nextTick();
  return wrapper;
};

const pressEscapeFromDocument = () => {
  document.dispatchEvent(
    new KeyboardEvent('keydown', {
      key: 'Escape',
      bubbles: true,
      cancelable: true,
    })
  );
};

// Something inside the panel that handles Escape itself (a picker, a menu) marks the event, the
// way CaretAnchoredPicker does, from a listener on the document, which runs before the panel's.
const pressEscapeHandledInside = () => {
  const handled = event => event.preventDefault();
  document.addEventListener('keydown', handled, { once: true });
  pressEscapeFromDocument();
};

describe('SidePanel', () => {
  it('stays open when something inside already handled the Escape', async () => {
    const wrapper = await mountOpenPanel();

    pressEscapeHandledInside();
    await wrapper.vm.$nextTick();

    expect(wrapper.emitted('close')).toBeUndefined();
    done(wrapper);
  });

  it('closes on an Escape nothing else handled', async () => {
    const wrapper = await mountOpenPanel();

    pressEscapeFromDocument();
    await wrapper.vm.$nextTick();

    expect(wrapper.emitted('close')).toHaveLength(1);
    done(wrapper);
  });

  it('closes on the next Escape once the inner one was handled', async () => {
    const wrapper = await mountOpenPanel();
    pressEscapeHandledInside();
    await wrapper.vm.$nextTick();
    expect(wrapper.emitted('close')).toBeUndefined();

    pressEscapeFromDocument();
    await wrapper.vm.$nextTick();

    expect(wrapper.emitted('close')).toHaveLength(1);
    done(wrapper);
  });
});
