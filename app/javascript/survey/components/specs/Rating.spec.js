import { mount } from '@vue/test-utils';
import { describe, expect, it } from 'vitest';
import Rating from '../Rating.vue';

const mountRating = (props = {}) =>
  mount(Rating, {
    props,
    global: { mocks: { $t: key => key } },
  });

describe('Rating', () => {
  it('labels every face, so a screen reader announces the rating and not the glyph', () => {
    const buttons = mountRating().findAll('button');

    expect(buttons).toHaveLength(5);
    expect(buttons.map(b => b.attributes('aria-label'))).toEqual([
      'CSAT.RATINGS.POOR',
      'CSAT.RATINGS.FAIR',
      'CSAT.RATINGS.AVERAGE',
      'CSAT.RATINGS.GOOD',
      'CSAT.RATINGS.EXCELLENT',
    ]);
    expect(buttons[0].find('span').attributes('aria-hidden')).toBe('true');
  });

  it('emits the value that was clicked', async () => {
    const wrapper = mountRating();

    await wrapper.findAll('button')[3].trigger('click');

    expect(wrapper.emitted('selectRating')).toEqual([[4]]);
  });

  it('marks only the selected face as pressed', () => {
    const buttons = mountRating({ selectedRating: 2 }).findAll('button');

    expect(buttons.map(b => b.attributes('aria-pressed'))).toEqual([
      'false',
      'true',
      'false',
      'false',
      'false',
    ]);
  });

  // Disabled on the element itself, not pointer-events: none, so the buttons also leave the
  // tab order instead of being focusable but inert.
  it('disables the buttons rather than swallowing their clicks', async () => {
    const wrapper = mountRating({ isDisabled: true });
    const button = wrapper.findAll('button')[0];

    expect(button.attributes('disabled')).toBeDefined();

    await button.trigger('click');

    expect(wrapper.emitted('selectRating')).toBeUndefined();
  });

  it('is a real button, so it never submits a form it happens to sit in', () => {
    expect(mountRating().find('button').attributes('type')).toBe('button');
  });
});
