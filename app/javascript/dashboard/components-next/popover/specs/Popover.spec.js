import { flushPromises, mount } from '@vue/test-utils';
import { h, ref } from 'vue';
import Popover from '../Popover.vue';

const belowMd = ref(false);

vi.mock('dashboard/composables/store', () => ({
  useMapGetter: () => ref(false),
}));

vi.mock('@vueuse/core', async importOriginal => ({
  ...(await importOriginal()),
  useBreakpoints: () => ({ smaller: () => belowMd }),
}));

describe('Popover', () => {
  let wrapper;

  const mountPopover = (props = {}) => {
    wrapper = mount(Popover, {
      props,
      slots: {
        default: '<button data-test="trigger">Open</button>',
        content: params =>
          h(
            'button',
            { 'data-test': 'panel-action', onClick: params.hide },
            'Panel'
          ),
      },
      global: {
        stubs: { teleport: true },
      },
      attachTo: document.body,
    });
    return wrapper;
  };

  const openPopover = async () => {
    await wrapper.find('[data-test="trigger"]').trigger('click');
    await flushPromises();
  };

  const desktopPopover = () => wrapper.find('.fixed[data-popover-content]');
  const mobileBackdrop = () => wrapper.find('[data-popover-backdrop]');

  beforeEach(() => {
    belowMd.value = false;
  });

  afterEach(() => {
    wrapper?.unmount();
    document.body.innerHTML = '';
  });

  describe('rendering and toggling', () => {
    it('renders the trigger slot and keeps the content hidden initially', () => {
      mountPopover();
      expect(wrapper.find('[data-test="trigger"]').exists()).toBe(true);
      expect(desktopPopover().exists()).toBe(false);
      expect(mobileBackdrop().exists()).toBe(false);
    });

    it('opens on trigger click and emits show', async () => {
      mountPopover();
      await openPopover();
      expect(desktopPopover().exists()).toBe(true);
      expect(wrapper.emitted('show')).toHaveLength(1);
      expect(wrapper.emitted('hide')).toBeUndefined();
    });

    it('renders the content slot inside the popover', async () => {
      mountPopover();
      await openPopover();
      expect(desktopPopover().find('[data-test="panel-action"]').exists()).toBe(
        true
      );
    });

    it('closes on a second trigger click and emits hide exactly once', async () => {
      mountPopover();
      await openPopover();
      await wrapper.find('[data-test="trigger"]').trigger('click');
      expect(desktopPopover().exists()).toBe(false);
      expect(wrapper.emitted('hide')).toHaveLength(1);
    });
  });

  describe('content slot hide', () => {
    it('closes when the slot invokes the provided hide function', async () => {
      mountPopover();
      await openPopover();
      await wrapper.find('[data-test="panel-action"]').trigger('click');
      expect(desktopPopover().exists()).toBe(false);
      expect(wrapper.emitted('hide')).toHaveLength(1);
    });
  });

  describe('exposed methods', () => {
    it('opens via show and closes via hide', async () => {
      mountPopover();
      await wrapper.vm.show();
      await flushPromises();
      expect(desktopPopover().exists()).toBe(true);
      wrapper.vm.hide();
      await flushPromises();
      expect(desktopPopover().exists()).toBe(false);
      expect(wrapper.emitted('show')).toHaveLength(1);
      expect(wrapper.emitted('hide')).toHaveLength(1);
    });

    it('toggles via toggle', async () => {
      mountPopover();
      await wrapper.vm.toggle();
      await flushPromises();
      expect(desktopPopover().exists()).toBe(true);
      await wrapper.vm.toggle();
      await flushPromises();
      expect(desktopPopover().exists()).toBe(false);
    });

    it('does not emit hide when already closed', async () => {
      mountPopover();
      wrapper.vm.hide();
      await flushPromises();
      expect(wrapper.emitted('hide')).toBeUndefined();
    });
  });

  describe('escape key', () => {
    const pressEscape = target =>
      (target || document).dispatchEvent(
        new KeyboardEvent('keydown', { key: 'Escape', bubbles: true })
      );

    it('closes on Escape while open', async () => {
      mountPopover();
      await openPopover();
      pressEscape();
      await flushPromises();
      expect(desktopPopover().exists()).toBe(false);
      expect(wrapper.emitted('hide')).toHaveLength(1);
    });

    it('does nothing on Escape while closed', async () => {
      mountPopover();
      await flushPromises();
      pressEscape();
      await flushPromises();
      expect(wrapper.emitted('hide')).toBeUndefined();
    });

    it('closes on Escape pressed inside its own content', async () => {
      mountPopover();
      await openPopover();
      pressEscape(wrapper.find('[data-test="panel-action"]').element);
      await flushPromises();
      expect(desktopPopover().exists()).toBe(false);
    });

    it('stays open on Escape pressed inside a nested overlay', async () => {
      mountPopover();
      await openPopover();
      const overlay = document.createElement('dialog');
      overlay.className = 'ProseMirror-prompt-backdrop';
      document.body.appendChild(overlay);
      pressEscape(overlay);
      await flushPromises();
      expect(desktopPopover().exists()).toBe(true);
      expect(wrapper.emitted('hide')).toBeUndefined();
    });
  });

  describe('click outside', () => {
    it('closes when clicking outside', async () => {
      mountPopover();
      await openPopover();
      document.body.click();
      await flushPromises();
      expect(desktopPopover().exists()).toBe(false);
      expect(wrapper.emitted('hide')).toHaveLength(1);
    });

    it('stays open when clicking inside the content', async () => {
      mountPopover();
      await openPopover();
      desktopPopover().element.click();
      await flushPromises();
      expect(desktopPopover().exists()).toBe(true);
      expect(wrapper.emitted('hide')).toBeUndefined();
    });
  });

  describe('mobile view', () => {
    it('renders a centered modal with backdrop below the md breakpoint', async () => {
      belowMd.value = true;
      mountPopover();
      await openPopover();
      expect(mobileBackdrop().exists()).toBe(true);
      expect(mobileBackdrop().find('[data-test="panel-action"]').exists()).toBe(
        true
      );
      expect(desktopPopover().exists()).toBe(false);
    });

    it('keeps the anchored popover below md when disableMobileView is set', async () => {
      belowMd.value = true;
      mountPopover({ disableMobileView: true });
      await openPopover();
      expect(mobileBackdrop().exists()).toBe(false);
      expect(desktopPopover().exists()).toBe(true);
    });
  });

  describe('close on scroll', () => {
    const scrollWithTriggerMovedBy = async offset => {
      await openPopover();
      wrapper.find('span').element.getBoundingClientRect = () => ({
        top: offset,
      });
      document.dispatchEvent(new Event('scroll'));
      await flushPromises();
    };

    it('closes when the trigger drifts beyond the threshold', async () => {
      mountPopover();
      await scrollWithTriggerMovedBy(100);
      expect(desktopPopover().exists()).toBe(false);
      expect(wrapper.emitted('hide')).toHaveLength(1);
    });

    it('stays open for small drift within the threshold', async () => {
      mountPopover();
      await scrollWithTriggerMovedBy(10);
      expect(desktopPopover().exists()).toBe(true);
    });

    it('stays open when closeOnScroll is disabled', async () => {
      mountPopover({ closeOnScroll: false });
      await scrollWithTriggerMovedBy(100);
      expect(desktopPopover().exists()).toBe(true);
    });
  });
});
