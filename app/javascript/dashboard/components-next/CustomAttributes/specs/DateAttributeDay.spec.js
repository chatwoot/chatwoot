import { mount } from '@vue/test-utils';
import DateAttribute from '../DateAttribute.vue';

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key }),
}));

// The suite runs in UTC, where every reading agrees; run this file with
// TZ=America/Sao_Paulo and TZ=Asia/Kolkata too when touching it.
describe('DateAttribute', () => {
  it.each([
    ['UTC midnight from the contact page', '2026-03-07T00:00:00.000Z', 7],
    ['local midnight from the sidebar', new Date(2026, 2, 7).toISOString(), 7],
  ])('edits the day it shows (%s)', async (_, value, day) => {
    const wrapper = mount(DateAttribute, {
      props: { attribute: { value } },
      global: { directives: { onClickOutside: {} } },
    });
    expect(wrapper.text()).toBe(`3/${day}/2026`);

    await wrapper.find('span').trigger('click');
    expect(wrapper.find('input[type="date"]').element.value).toBe(
      `2026-03-0${day}`
    );
  });
});
