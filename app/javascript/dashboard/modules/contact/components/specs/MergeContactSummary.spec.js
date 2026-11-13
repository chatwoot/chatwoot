import { mount } from '@vue/test-utils';
import VueDOMPurifyHTML from 'vue-dompurify-html';
import { withFullI18n } from 'test-i18n';
import { domPurifyConfig } from 'shared/helpers/HTMLSanitizer';
import MergeContactSummary from '../MergeContactSummary.vue';

withFullI18n();

const mountSummary = props =>
  mount(MergeContactSummary, {
    props,
    global: { plugins: [[VueDOMPurifyHTML, domPurifyConfig]] },
  });

describe('MergeContactSummary', () => {
  it('renders contact names in bold', () => {
    const wrapper = mountSummary({
      primaryContactName: 'Jane Doe',
      parentContactName: 'John Smith',
    });

    const names = wrapper.findAll('strong').map(node => node.text());
    expect(names).toEqual(['Jane Doe', 'Jane Doe', 'John Smith']);
  });

  it('renders markup in contact names as text', () => {
    const markup = '<form><input name="field"></form><img src="x">';
    const wrapper = mountSummary({
      primaryContactName: markup,
      parentContactName: `${markup} & Co`,
    });

    expect(wrapper.find('form').exists()).toBe(false);
    expect(wrapper.find('input').exists()).toBe(false);
    expect(wrapper.find('img').exists()).toBe(false);
    const names = wrapper.findAll('strong').map(node => node.text());
    expect(names).toEqual([markup, markup, `${markup} & Co`]);
  });

  it('renders when the contact has no name', () => {
    const wrapper = mountSummary({
      primaryContactName: null,
      parentContactName: 'John Smith',
    });

    const names = wrapper.findAll('strong').map(node => node.text());
    expect(names).toEqual(['', '', 'John Smith']);
  });
});
