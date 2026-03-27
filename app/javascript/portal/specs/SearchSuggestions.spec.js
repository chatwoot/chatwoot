import { mount } from '@vue/test-utils';
import { describe, it, expect, vi } from 'vitest';
import SearchSuggestions from '../components/SearchSuggestions.vue';

vi.mock('dashboard/composables/useKeyboardNavigableList', () => ({
  useKeyboardNavigableList: vi.fn(() => ({})),
}));

vi.mock('shared/composables/useMessageFormatter', () => ({
  useMessageFormatter: () => ({
    highlightContent: content => content,
  }),
}));

describe('SearchSuggestions', () => {
  it('renders suggestion links from the backend-provided link field', () => {
    const wrapper = mount(SearchSuggestions, {
      props: {
        items: [
          {
            id: 1,
            title: 'Chatwoot Glossary',
            content: 'Access Token',
            link: '/hc/user-guide/articles/1677141565-chatwoot-glossary',
          },
        ],
        isLoading: false,
        searchTerm: 'chatwoot',
      },
      global: {
        directives: {
          dompurifyHtml: (element, binding) => {
            element.innerHTML = binding.value;
          },
        },
      },
    });

    expect(wrapper.find('a').attributes('href')).toBe(
      '/hc/user-guide/articles/1677141565-chatwoot-glossary'
    );
  });
});
