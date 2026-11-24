import { mount } from '@vue/test-utils';
import { createStore } from 'vuex';
import VueDOMPurifyHTML from 'vue-dompurify-html';
import { domPurifyConfig } from 'shared/helpers/HTMLSanitizer';
import CannedResponse from '../CannedResponse.vue';

const markup = '<form><input name=field></form><img src=x>';

const mountPicker = ({ searchKey = '', contactName = 'Jane Doe' } = {}) => {
  const store = createStore({
    getters: {
      getCannedResponses: () => [
        {
          id: 1,
          short_code: 'greet',
          content: 'Hello {{contact.name}}, thanks for writing in.',
        },
      ],
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
  it('does not match the contact name filled into a variable', () => {
    expect(listItem(mountPicker({ searchKey: 'jane' })).exists()).toBe(false);
  });

  it('highlights the search term in the title and preview', () => {
    const wrapper = mountPicker({ searchKey: 'hello' });

    const highlights = listItem(wrapper)
      .findAll('.text-n-blue-text')
      .map(node => node.text());
    expect(highlights).toEqual(['Hello']);
    expect(wrapper.text()).toContain('Hello Jane Doe, thanks for writing in.');
  });

  it.each(['', 'hello'])(
    'renders markup in variable values as text (search: "%s")',
    searchKey => {
      const wrapper = mountPicker({ searchKey, contactName: markup });

      const item = wrapper.find('.prose');
      expect(item.find('form').exists()).toBe(false);
      expect(item.find('input').exists()).toBe(false);
      expect(item.find('img').exists()).toBe(false);
      expect(item.text()).toContain(markup);
    }
  );
});
