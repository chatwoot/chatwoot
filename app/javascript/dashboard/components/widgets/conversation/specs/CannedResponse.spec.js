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
    const wrapper = mountPicker({ searchKey: 'jane' });

    expect(listItem(wrapper).exists()).toBe(false);
  });

  it('highlights the search term and fills variables only in the preview', () => {
    const wrapper = mountPicker({ searchKey: 'hello' });

    const highlights = listItem(wrapper)
      .findAll('.text-n-blue-text')
      .map(node => node.text());
    expect(highlights).toEqual(['Hello']);
    expect(listItem(wrapper).text()).toContain(
      'Hello {{contact.name}}, thanks for writing in.'
    );
    expect(wrapper.text()).toContain('Hello Jane Doe, thanks for writing in.');
  });

  it.each(['', 'hello'])(
    'renders markup in variable values as text (search: "%s")',
    searchKey => {
      const wrapper = mountPicker({ searchKey, contactName: markup });

      expect(wrapper.find('form').exists()).toBe(false);
      expect(wrapper.find('input[name="field"]').exists()).toBe(false);
      expect(wrapper.find('img').exists()).toBe(false);
      expect(wrapper.text()).toContain(markup);
    }
  );
});
