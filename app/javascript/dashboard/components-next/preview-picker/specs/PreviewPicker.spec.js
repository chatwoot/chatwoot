import { h } from 'vue';
import { mount } from '@vue/test-utils';
import VueDOMPurifyHTML from 'vue-dompurify-html';
import { domPurifyConfig } from 'shared/helpers/HTMLSanitizer';
import PreviewPicker from '../PreviewPicker.vue';

const refund = { id: 'refund', title: 'Refund', group: 'Billing' };
const greeting = { id: 'greeting', title: 'Greeting', group: 'General' };

const mountPicker = () =>
  mount(PreviewPicker, {
    props: { items: [refund, greeting], searchPlaceholder: 'Search macros' },
    slots: { preview: ({ item }) => h('p', `${item.title} in full`) },
    global: { plugins: [[VueDOMPurifyHTML, domPurifyConfig]] },
  });

const highlighted = wrapper =>
  wrapper.find('[role="option"][aria-selected="true"]');

describe('PreviewPicker', () => {
  it('points the search field at the new top match when the results change', async () => {
    const wrapper = mountPicker();
    const search = wrapper.find('[role="combobox"]');
    const firstMatch = search.attributes('aria-activedescendant');

    await wrapper.setProps({ items: [greeting] });

    expect(search.attributes('aria-activedescendant')).not.toBe(firstMatch);
    expect(search.attributes('aria-activedescendant')).toBe(
      highlighted(wrapper).attributes('id')
    );
  });

  it('describes the highlighted option with its preview', () => {
    const wrapper = mountPicker();
    const previewId = highlighted(wrapper).attributes('aria-describedby');

    expect(wrapper.find(`[id="${previewId}"]`).text()).toBe('Refund in full');
  });

  it('announces a search that finds nothing', async () => {
    const wrapper = mountPicker();
    const status = wrapper.find('[role="status"]');
    expect(status.text()).toBe('');

    await wrapper.setProps({ items: [], emptyLabel: 'No results found.' });

    expect(status.text()).toBe('No results found.');
  });
});
