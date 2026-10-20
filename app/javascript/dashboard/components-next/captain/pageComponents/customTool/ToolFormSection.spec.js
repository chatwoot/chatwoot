import { mount } from '@vue/test-utils';
import ToolFormSection from './ToolFormSection.vue';

const mountSection = (props = {}) =>
  mount(ToolFormSection, {
    props: { title: 'Headers', ...props },
    slots: { default: '<input data-test="field" />' },
  });

describe('ToolFormSection', () => {
  it('is collapsed by default and keeps its content mounted', () => {
    const wrapper = mountSection();

    expect(wrapper.find('button').attributes('aria-expanded')).toBe('false');
    expect(wrapper.find('[data-test="field"]').exists()).toBe(true);
    expect(wrapper.find('[data-test="field"]').isVisible()).toBe(false);
  });

  it('toggles open when the header is clicked', async () => {
    const wrapper = mountSection();

    await wrapper.find('button').trigger('click');

    expect(wrapper.emitted('update:open')[0]).toEqual([true]);
  });

  it('shows content and summary when open', () => {
    const wrapper = mountSection({ open: true, summary: '2' });

    expect(wrapper.find('button').attributes('aria-expanded')).toBe('true');
    expect(wrapper.find('[data-test="field"]').isVisible()).toBe(true);
    expect(wrapper.text()).toContain('Headers');
    expect(wrapper.text()).toContain('2');
  });
});
