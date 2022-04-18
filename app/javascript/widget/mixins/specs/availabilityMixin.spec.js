import { createWrapper } from '@vue/test-utils';
import availabilityMixin from '../availability';
import Vue from 'vue';

global.chatwootWebChannel = {
  workingHoursEnabled: true,
  workingHours: [
    {
      day_of_week: 3,
      closed_all_day: false,
      open_hour: 8,
      open_minutes: 30,
      close_hour: 17,
      close_minutes: 35,
      open_all_day: false,
    },
    {
      day_of_week: 4,
      closed_all_day: false,
      open_hour: 8,
      open_minutes: 30,
      close_hour: 17,
      close_minutes: 30,
      open_all_day: false,
    },
  ],
  utcOffset: '-07:00',
};

describe('availabilityMixin', () => {
  it('returns valid isInBetweenWorkingHours if in different timezone', () => {
    const Component = {
      render() {},
      mixins: [availabilityMixin],
    };
    jest
      .useFakeTimers('modern')
      .setSystemTime(new Date('Thu Apr 14 2022 06:04:46 GMT+0530'));
    const Constructor = Vue.extend(Component);
    const vm = new Constructor().$mount();
    const wrapper = createWrapper(vm);
    expect(wrapper.vm.isInBetweenTheWorkingHours).toBe(true);
    jest.useRealTimers();
  });

  it('returns valid isInBetweenWorkingHours if in same timezone', () => {
    global.chatwootWebChannel.utcOffset = '+05:30';
    const Component = {
      render() {},
      mixins: [availabilityMixin],
    };
    jest
      .useFakeTimers('modern')
      .setSystemTime(new Date('Thu Apr 14 2022 09:01:46 GMT+0530'));
    const Constructor = Vue.extend(Component);
    const wrapper = createWrapper(new Constructor().$mount());
    expect(wrapper.vm.isInBetweenTheWorkingHours).toBe(true);
    jest.useRealTimers();
  });
});
