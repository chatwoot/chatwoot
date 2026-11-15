import { mount } from '@vue/test-utils';
import { withFullI18n } from 'test-i18n';
import CommandBarFooter from '../CommandBarFooter.vue';

// ninja-keys renders its own footer, in English only, unless the page fills
// the footer slot.
const ENGLISH_HINTS = [
  'to select',
  'to navigate',
  'to close',
  'move to parent',
];

const footerIn = locale => {
  withFullI18n(locale);
  return mount(CommandBarFooter).text();
};

describe('CommandBarFooter', () => {
  it('fills the ninja-keys footer slot', () => {
    withFullI18n('en');
    const wrapper = mount(CommandBarFooter);

    expect(wrapper.attributes('slot')).toBe('footer');
  });

  it.each(['pt_BR', 'es'])('says every hint in %s', locale => {
    const text = footerIn(locale);

    ENGLISH_HINTS.forEach(hint => expect(text).not.toContain(hint));
    expect(text).not.toMatch(/[A-Z]+[._][A-Z_.]+/);
  });

  it('keeps the four hints in English', () => {
    const text = footerIn('en');

    ENGLISH_HINTS.forEach(hint => expect(text).toContain(hint));
  });
});
