import { shallowMount } from '@vue/test-utils';
import BusinessDay from '../BusinessDay.vue';

vi.mock('date-fns/parse', () => ({
  default: (time, _format, referenceDate) => {
    const [clock, period] = time.split(' ');
    const [hours, minutes] = clock.split(':').map(Number);
    const normalizedHours = (hours % 12) + (period === 'PM' ? 12 : 0);
    const date = new Date(referenceDate);

    date.setHours(normalizedHours, minutes, 0, 0);

    if (
      referenceDate.getMonth() === 2 &&
      referenceDate.getDate() === 8 &&
      normalizedHours === 2
    ) {
      date.setHours(3);
    }

    return date;
  },
}));

describe('BusinessDay', () => {
  beforeEach(() => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date(2026, 2, 8, 12));
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('keeps recurring wall-clock times stable on a DST transition day', () => {
    const wrapper = shallowMount(BusinessDay, {
      props: {
        dayName: 'Sunday',
      },
      global: {
        mocks: {
          $i18n: { locale: 'en-US' },
          $t: key => key,
        },
        stubs: {
          Icon: true,
          NextSelect: true,
        },
      },
    });

    const twoAmSlot = wrapper.vm.fromTimeSlots
      .flatMap(group => group.options)
      .find(slot => slot.value === '02:00 AM');

    expect(twoAmSlot.label).toBe('02:00 AM');
  });
});
