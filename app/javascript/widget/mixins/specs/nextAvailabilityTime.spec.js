import { defineComponent, h } from 'vue';
import { mount } from '@vue/test-utils';
import nextAvailabilityTimeMixin from '../nextAvailabilityTime';

describe('nextAvailabilityTimeMixin', () => {
  const chatwootWebChannel = {
    workingHoursEnabled: true,
    workingHours: [
      {
        day_of_week: 0,
        open_hour: 9,
        closed_all_day: false,
        open_minutes: 0,
        close_hour: 17,
      },
      {
        day_of_week: 1,
        open_hour: 9,
        closed_all_day: false,
        open_minutes: 0,
        close_hour: 17,
      },
      {
        day_of_week: 2,
        open_hour: 9,
        closed_all_day: false,
        open_minutes: 0,
        close_hour: 17,
      },
      {
        day_of_week: 3,
        open_hour: 9,
        closed_all_day: false,
        open_minutes: 0,
        close_hour: 17,
      },
      {
        day_of_week: 4,
        open_hour: 9,
        closed_all_day: false,
        open_minutes: 0,
        close_hour: 17,
      },
      {
        day_of_week: 5,
        open_hour: 9,
        closed_all_day: false,
        open_minutes: 0,
        close_hour: 17,
      },
      {
        day_of_week: 6,
        open_hour: 9,
        closed_all_day: false,
        open_minutes: 0,
        close_hour: 17,
      },
    ],
  };

  let Component;

  beforeEach(() => {
    Component = defineComponent({
      mixins: [nextAvailabilityTimeMixin],
      render() {
        return h('div');
      },
    });
    window.chatwootWebChannel = chatwootWebChannel;
  });

  afterEach(() => {
    delete window.chatwootWebChannel;
  });

  beforeEach(() => {
    vi.useRealTimers();
  });

  it('should return day names', () => {
    const wrapper = mount(Component);
    wrapper.vm.dayNames = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    expect(wrapper.vm.dayNames).toEqual([
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ]);
  });

  it('should return channelConfig', () => {
    const wrapper = mount(Component);
    expect(wrapper.vm.channelConfig).toEqual(chatwootWebChannel);
  });

  it('should return workingHours', () => {
    const wrapper = mount(Component);
    expect(wrapper.vm.workingHours).toEqual(chatwootWebChannel.workingHours);
  });

  it('should return currentDayWorkingHours', () => {
    const currentDay = new Date().getDay();
    const expectedWorkingHours = chatwootWebChannel.workingHours.find(
      slot => slot.day_of_week === currentDay
    );
    const wrapper = mount(Component);
    wrapper.vm.dayNames = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    expect(wrapper.vm.currentDayWorkingHours).toEqual(expectedWorkingHours);
  });

  it('should return nextDayWorkingHours', () => {
    const currentDay = new Date().getDay();
    const nextDay = currentDay === 6 ? 0 : currentDay + 1;
    const expectedWorkingHours = chatwootWebChannel.workingHours.find(
      slot => slot.day_of_week === nextDay
    );
    const wrapper = mount(Component);
    wrapper.vm.dayNames = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    expect(wrapper.vm.nextDayWorkingHours).toEqual(expectedWorkingHours);
  });

  it('should return presentHour', () => {
    const wrapper = mount(Component);
    expect(wrapper.vm.presentHour).toBe(new Date().getHours());
  });

  it('should return presentMinute', () => {
    const wrapper = mount(Component);
    wrapper.vm.dayNames = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    expect(wrapper.vm.presentMinute).toBe(new Date().getMinutes());
  });

  it('should return currentDay', () => {
    const wrapper = mount(Component);
    wrapper.vm.dayNames = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    const date = new Date();
    const day = date.getDay();
    const currentDay = Object.keys(wrapper.vm.dayNames).find(
      key => wrapper.vm.dayNames[key] === wrapper.vm.dayNames[day]
    );
    expect(wrapper.vm.currentDay).toBe(Number(currentDay));
  });

  it('should return currentDayTimings', () => {
    const wrapper = mount(Component);
    wrapper.vm.dayNames = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    const {
      open_hour: openHour,
      open_minutes: openMinute,
      close_hour: closeHour,
    } = wrapper.vm.currentDayWorkingHours;
    expect(wrapper.vm.currentDayTimings).toEqual({
      openHour,
      openMinute,
      closeHour,
    });
  });

  it('should return nextDayTimings', () => {
    const wrapper = mount(Component);
    wrapper.vm.dayNames = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    const { open_hour: openHour, open_minutes: openMinute } =
      wrapper.vm.nextDayWorkingHours;

    expect(wrapper.vm.nextDayTimings).toEqual({
      openHour,
      openMinute,
    });
  });

  it('should return dayDiff', () => {
    const wrapper = mount(Component);
    wrapper.vm.dayNames = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    const currentDay = wrapper.vm.currentDay;
    const nextDay = wrapper.vm.nextDayWorkingHours.day_of_week;
    const totalDays = 6;
    const expectedDayDiff =
      nextDay > currentDay
        ? nextDay - currentDay - 1
        : totalDays - currentDay + nextDay;

    expect(wrapper.vm.dayDiff).toEqual(expectedDayDiff);
  });

  it('should return dayNameOfNextWorkingDay', () => {
    const wrapper = mount(Component);
    wrapper.vm.dayNames = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    const nextDay = wrapper.vm.nextDayWorkingHours.day_of_week;
    const expectedDayName = wrapper.vm.dayNames[nextDay];
    expect(wrapper.vm.dayNameOfNextWorkingDay).toEqual(expectedDayName);
  });

  it('should return hoursAndMinutesBackInOnline', () => {
    const wrapper = mount(Component);
    wrapper.vm.dayNames = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    const currentDayCloseHour =
      chatwootWebChannel.workingHours[wrapper.vm.currentDay].close_hour;
    const nextDayOpenHour =
      chatwootWebChannel.workingHours[
        wrapper.vm.currentDay === 6 ? 0 : wrapper.vm.currentDay + 1
      ].open_hour;
    const nextDayOpenMinute =
      chatwootWebChannel.workingHours[
        wrapper.vm.currentDay === 6 ? 0 : wrapper.vm.currentDay + 1
      ].open_minutes;
    const expectedHoursAndMinutes =
      wrapper.vm.getHoursAndMinutesUntilNextDayOpen(
        nextDayOpenHour,
        nextDayOpenMinute,
        currentDayCloseHour
      );
    expect(wrapper.vm.hoursAndMinutesBackInOnline).toEqual(
      expectedHoursAndMinutes
    );
  });

  it('should return getNextDay', () => {
    const wrapper = mount(Component);
    expect(wrapper.vm.getNextDay(6)).toBe(0);
  });

  it('should return in 30 minutes', () => {
    vi.useFakeTimers('modern').setSystemTime(
      new Date('Thu Apr 14 2022 14:04:46 GMT+0530')
    );
    const wrapper = mount(Component);
    wrapper.vm.dayNames = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];

    chatwootWebChannel.workingHours[4].open_hour = 18;
    chatwootWebChannel.workingHours[4].open_minutes = 0;
    chatwootWebChannel.workingHours[4].close_hour = 23;
    expect(wrapper.vm.timeLeftToBackInOnline).toBe('in 30 minutes');
  });

  it('should return in 2 hours', () => {
    vi.useFakeTimers('modern').setSystemTime(
      new Date('Thu Apr 14 2022 22:04:46 GMT+0530')
    );
    const wrapper = mount(Component);
    wrapper.vm.dayNames = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    chatwootWebChannel.workingHours[4].open_hour = 19;
    expect(wrapper.vm.timeLeftToBackInOnline).toBe('in 2 hours');
  });

  it('should return at 09:00 AM', () => {
    vi.useFakeTimers('modern').setSystemTime(
      new Date('Thu Apr 15 2022 22:04:46 GMT+0530')
    );
    const wrapper = mount(Component);
    wrapper.vm.dayNames = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    chatwootWebChannel.workingHours[4].open_hour = 10;
    expect(wrapper.vm.timeLeftToBackInOnline).toBe('at 09:00 AM');
  });

  it('should return tomorrow', () => {
    vi.useFakeTimers('modern').setSystemTime(
      new Date('Thu Apr 1 2022 23:04:46 GMT+0530')
    );
    const wrapper = mount(Component);
    wrapper.vm.dayNames = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    chatwootWebChannel.workingHours[4].open_hour = 9;
    chatwootWebChannel.workingHours[4].close_hour = 16;
    expect(wrapper.vm.timeLeftToBackInOnline).toBe('tomorrow');
  });

  it.skip('should return on Saturday', () => {
    vi.useFakeTimers('modern').setSystemTime(
      new Date('Thu Apr 14 2022 23:04:46 GMT+0530')
    );
    const wrapper = mount(Component);
    wrapper.vm.dayNames = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];

    chatwootWebChannel.workingHours[4].open_hour = 9;
    chatwootWebChannel.workingHours[4].close_hour = 16;
    chatwootWebChannel.workingHours[5].closed_all_day = true;
    expect(wrapper.vm.timeLeftToBackInOnline).toBe('on Saturday');
  });
});
