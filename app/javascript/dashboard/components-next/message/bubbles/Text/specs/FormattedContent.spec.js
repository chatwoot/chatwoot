import { mount } from '@vue/test-utils';
import { computed } from 'vue';
import { describe, expect, it, vi } from 'vitest';
import FormattedContent from '../FormattedContent.vue';

vi.mock('../../../provider.js', () => ({
  useMessageContext: () => ({
    variant: computed(() => 'agent'),
    contentAttributes: computed(() => ({ format: 'plain_text' })),
  }),
}));

vi.mock('shared/helpers/MessageFormatter.js', () => ({
  default: class MockMessageFormatter {
    constructor(message) {
      this.formattedMessage = `<p>${message}</p>`;
    }
  },
}));

describe('FormattedContent.vue', () => {
  it('renders plain text literally when message format is plain_text', () => {
    const wrapper = mount(FormattedContent, {
      props: {
        content: 'Первая строка\n\n- пункт один',
      },
    });

    expect(wrapper.text()).toContain('Первая строка');
    expect(wrapper.text()).toContain('- пункт один');
    expect(wrapper.html()).not.toContain('<li>');
    expect(wrapper.find('.whitespace-pre-wrap').exists()).toBe(true);
  });
});
