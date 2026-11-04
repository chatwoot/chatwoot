import { mount } from '@vue/test-utils';
import Accordion from './Accordion.vue';

describe('Accordion', () => {
  it('exposes and updates its disclosure state accessibly', async () => {
    const wrapper = mount(Accordion, {
      props: { title: 'Test setup section' },
      slots: { default: 'Section content' },
    });
    const disclosure = wrapper.get('button');

    expect(disclosure.attributes('type')).toBe('button');
    expect(disclosure.attributes('aria-expanded')).toBe('false');
    expect(wrapper.text()).not.toContain('Section content');

    await disclosure.trigger('click');

    const contentId = disclosure.attributes('aria-controls');
    expect(disclosure.attributes('aria-expanded')).toBe('true');
    expect(wrapper.get(`#${contentId}`).text()).toBe('Section content');
  });

  it('reacts when the controlled default state changes', async () => {
    const wrapper = mount(Accordion, {
      props: { title: 'Test setup section', isOpen: false },
      slots: { default: 'Section content' },
    });

    await wrapper.setProps({ isOpen: true });

    expect(wrapper.get('button').attributes('aria-expanded')).toBe('true');
    expect(wrapper.text()).toContain('Section content');
  });
});
