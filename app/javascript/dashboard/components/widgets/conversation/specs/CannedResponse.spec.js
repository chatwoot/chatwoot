import { mount } from '@vue/test-utils';
import { createStore } from 'vuex';
import VueDOMPurifyHTML from 'vue-dompurify-html';
import { domPurifyConfig } from 'shared/helpers/HTMLSanitizer';
import CannedResponse from '../CannedResponse.vue';

const markup = '<form><input name=field></form><img src=x>';

const greeting = {
  id: 1,
  short_code: 'greet',
  content: 'Hello {{contact.name}}, thanks for writing in.',
};

const mountPicker = ({
  searchKey = '',
  contactName = 'Jane Doe',
  cannedResponses = [greeting],
} = {}) => {
  const store = createStore({
    getters: {
      getCannedResponses: () => cannedResponses,
      getUIFlags: () => ({ fetchingList: false }),
      'accounts/isRTL': () => false,
    },
    actions: { getCannedResponse: () => {} },
  });

  return mount(CannedResponse, {
    props: { searchKey, variables: { 'contact.name': contactName } },
    global: {
      plugins: [store, [VueDOMPurifyHTML, domPurifyConfig]],
      stubs: { teleport: true },
    },
  });
};

const listItem = wrapper => wrapper.find('li');

describe('CannedResponse', () => {
  it('highlights the search term in the title and preview', () => {
    const wrapper = mountPicker({ searchKey: 'jane' });

    const highlights = listItem(wrapper)
      .findAll('.text-n-blue-text')
      .map(node => node.text());
    expect(highlights).toEqual(['Jane']);
    expect(listItem(wrapper).text()).toContain(
      'Hello Jane Doe, thanks for writing in.'
    );
  });

  it.each(['', 'reply'])(
    'renders at most 50 matching responses (search: "%s")',
    searchKey => {
      const cannedResponses = Array.from({ length: 60 }, (_, index) => ({
        id: index + 1,
        short_code: `reply${index}`,
        content: `Reply number ${index}`,
      }));
      const wrapper = mountPicker({ searchKey, cannedResponses });

      expect(wrapper.findAll('li[role="option"]')).toHaveLength(50);
    }
  );

  it.each(['', 'hello'])(
    'renders markup in variable values as text (search: "%s")',
    searchKey => {
      const wrapper = mountPicker({ searchKey, contactName: markup });

      const item = listItem(wrapper);
      expect(item.find('form').exists()).toBe(false);
      expect(item.find('input').exists()).toBe(false);
      expect(item.find('img').exists()).toBe(false);
      expect(item.text()).toContain(markup);
    }
  );
});
