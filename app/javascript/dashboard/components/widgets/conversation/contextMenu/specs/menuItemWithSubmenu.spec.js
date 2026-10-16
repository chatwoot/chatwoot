import { shallowMount } from '@vue/test-utils';
import MenuItemWithSubmenu from '../menuItemWithSubmenu.vue';

describe('MenuItemWithSubmenu', () => {
  const defaultProps = {
    option: {
      label: 'Labels',
      icon: 'tag',
    },
    subMenuAvailable: true,
  };

  it('renders submenu with scrollable class by default', () => {
    const wrapper = shallowMount(MenuItemWithSubmenu, {
      props: defaultProps,
      slots: {
        default: '<div class="content">Submenu content</div>',
      },
    });

    const submenu = wrapper.find('.submenu');
    expect(submenu.exists()).toBe(true);
    expect(submenu.classes()).toContain('overflow-y-auto');
    expect(submenu.classes()).toContain('max-h-[15rem]');
    expect(submenu.classes()).not.toContain('overflow-hidden');
  });

  it('renders submenu with overflow-hidden and flex-col when scrollable is false', () => {
    const wrapper = shallowMount(MenuItemWithSubmenu, {
      props: {
        ...defaultProps,
        scrollable: false,
      },
      slots: {
        default: '<div class="content">Submenu content</div>',
      },
    });

    const submenu = wrapper.find('.submenu');
    expect(submenu.exists()).toBe(true);
    expect(submenu.classes()).toContain('overflow-hidden');
    expect(submenu.classes()).toContain('flex');
    expect(submenu.classes()).toContain('flex-col');
    expect(submenu.classes()).not.toContain('overflow-y-auto');
  });

  it('does not render submenu when subMenuAvailable is false', () => {
    const wrapper = shallowMount(MenuItemWithSubmenu, {
      props: {
        ...defaultProps,
        subMenuAvailable: false,
      },
    });

    const submenu = wrapper.find('.submenu');
    expect(submenu.exists()).toBe(false);
  });

  it('emits open on mouseenter and click', async () => {
    const wrapper = shallowMount(MenuItemWithSubmenu, {
      props: defaultProps,
    });
    await wrapper.trigger('mouseenter');
    expect(wrapper.emitted('open')).toBeTruthy();
    await wrapper.trigger('click');
    expect(wrapper.emitted('open').length).toBe(2);
  });
});
