import { shallowMount } from '@vue/test-utils';
import { describe, it, expect } from 'vitest';
import AIEnableBanner from '../AIEnableBanner.vue';

const mountWith = (props = {}) =>
  shallowMount(AIEnableBanner, {
    props: { aiEnable: true, ...props },
    global: {
      mocks: {
        $t: k => k,
      },
    },
  });

describe('AIEnableBanner.vue', () => {
  it('renders enabled state with bot icon and no ban overlay', () => {
    const wrapper = mountWith({ aiEnable: true });
    expect(wrapper.find('.i-lucide-bot').exists()).toBe(true);
    expect(wrapper.find('.i-lucide-ban').exists()).toBe(false);
  });

  it('renders disabled state with ban overlay', () => {
    const wrapper = mountWith({ aiEnable: false });
    expect(wrapper.find('.i-lucide-bot').exists()).toBe(true);
    expect(wrapper.find('.i-lucide-ban').exists()).toBe(true);
  });

  it('emits toggle-ai on click', async () => {
    const wrapper = mountWith({ aiEnable: true });
    await wrapper.trigger('click');
    expect(wrapper.emitted('toggle-ai')).toBeTruthy();
    expect(wrapper.emitted('toggle-ai').length).toBe(1);
  });
});
