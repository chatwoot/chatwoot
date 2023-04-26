import { shallowMount } from '@vue/test-utils';
import nextAvailabilityTimeMixin from '../nextAvailabilityTime';

describe('nextAvailabilityTimeMixin', () => {
  let wrapper;
  const chatwootWebChannel = {
    workingHoursEnabled: true,
    workingHours: [
      {
        day_of_week: 0,
        open_hour: 9,
        open_minutes: 0,
        close_hour: 17,
      },
      {
        day_of_week: 1,
        open_hour: 9,
        open_minutes: 0,
        close_hour: 17,
      },
      {
        day_of_week: 2,
        open_hour: 9,
        open_minutes: 0,
        close_hour: 17,
      },
      {
        day_of_week: 3,
        open_hour: 9,
        open_minutes: 0,
        close_hour: 17,
      },
      {
        day_of_week: 4,
        open_hour: 9,
        open_minutes: 0,
        close_hour: 17,
      },
      {
        day_of_week: 5,
        open_hour: 9,
        open_minutes: 0,
        close_hour: 17,
      },
      {
        day_of_week: 6,
        open_hour: 9,
        open_minutes: 0,
        close_hour: 17,
      },
    ],
  };

  beforeAll(() => {
    window.chatwootWebChannel = chatwootWebChannel;
  });

  afterAll(() => {
    delete window.chatwootWebChannel;
  });

  beforeEach(() => {
    wrapper = shallowMount({}, { mixins: [nextAvailabilityTimeMixin] });
  });

  it('should return day names', () => {
    expect(wrapper.vm.dayNames).toEqual({
      0: 'Sunday',
      1: 'Monday',
      2: 'Tuesday',
      3: 'Wednesday',
      4: 'Thursday',
      5: 'Friday',
      6: 'Saturday',
    });
  });

  it('should return channelConfig', () => {
    expect(wrapper.vm.channelConfig).toEqual(chatwootWebChannel);
  });

  it('should return workingHoursEnabled', () => {
    expect(wrapper.vm.workingHoursEnabled).toBe(true);
  });

  it('should return workingHours', () => {
    expect(wrapper.vm.workingHours).toEqual(chatwootWebChannel.workingHours);
  });

  it('should return currentDayWorkingHours', () => {
    const currentDay = new Date().getDay();
    const expectedWorkingHours = chatwootWebChannel.workingHours.find(
      slot => slot.day_of_week === currentDay
    );
    expect(wrapper.vm.currentDayWorkingHours).toEqual(expectedWorkingHours);
  });

  it('should return nextDayWorkingHours', () => {
    const currentDay = new Date().getDay();
    const nextDay = currentDay === 6 ? 0 : currentDay + 1;
    const expectedWorkingHours = chatwootWebChannel.workingHours.find(
      slot => slot.day_of_week === nextDay
    );
    expect(wrapper.vm.nextDayWorkingHours).toEqual(expectedWorkingHours);
  });

  it('should return presentHour', () => {
    expect(wrapper.vm.presentHour).toBe(new Date().getHours());
  });

  it('should return presentMinute', () => {
    expect(wrapper.vm.presentMinute).toBe(new Date().getMinutes());
  });

  it('should return currentDay', () => {
    const date = new Date();
    const day = date.getDay();
    const currentDay = Object.keys(wrapper.vm.dayNames).find(
      key => wrapper.vm.dayNames[key] === wrapper.vm.dayNames[day]
    );
    expect(wrapper.vm.currentDay).toBe(Number(currentDay));
  });

  it('should return currentDayOpenHour', () => {
    expect(wrapper.vm.currentDayOpenHour).toBe(
      chatwootWebChannel.workingHours[wrapper.vm.currentDay].open_hour
    );
  });

  it('should return currentDayOpenMinutes', () => {
    expect(wrapper.vm.currentDayOpenMinute).toBe(
      chatwootWebChannel.workingHours[wrapper.vm.currentDay].open_minutes
    );
  });

  it('should return currentDayCloseHour', () => {
    expect(wrapper.vm.currentDayCloseHour).toBe(
      chatwootWebChannel.workingHours[wrapper.vm.currentDay].close_hour
    );
  });

  it('should return nextDayOpenHour', () => {
    const nextDay = wrapper.vm.currentDay === 6 ? 0 : wrapper.vm.currentDay + 1;
    expect(wrapper.vm.nextDayOpenHour).toBe(
      chatwootWebChannel.workingHours[nextDay].open_hour
    );
  });

  it('should return nextDayOpenMinutes', () => {
    const nextDay = wrapper.vm.currentDay === 6 ? 0 : wrapper.vm.currentDay + 1;
    expect(wrapper.vm.nextDayOpenMinute).toBe(
      chatwootWebChannel.workingHours[nextDay].open_minutes
    );
  });

  it('should return dayDiff', () => {
    const currentDay = wrapper.vm.currentDay;
    const nextDay = wrapper.vm.nextDayWorkingHours.day_of_week;
    const totalDays = 6;
    const expectedDayDiff =
      nextDay > currentDay
        ? nextDay - currentDay
        : totalDays - currentDay + nextDay;
    expect(wrapper.vm.dayDiff).toEqual(expectedDayDiff);
  });

  it('should return dayNameOfNextWorkingDay', () => {
    const nextDay = wrapper.vm.nextDayWorkingHours.day_of_week;
    const expectedDayName = wrapper.vm.dayNames[nextDay];
    expect(wrapper.vm.dayNameOfNextWorkingDay).toEqual(expectedDayName);
  });

  it('should return hoursAndMinutesBackInOnline', () => {
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
    const expectedHoursAndMinutes = wrapper.vm.getHoursAndMinutesUntilNextDayOpen(
      nextDayOpenHour,
      nextDayOpenMinute,
      currentDayCloseHour
    );
    expect(wrapper.vm.hoursAndMinutesBackInOnline).toEqual(
      expectedHoursAndMinutes
    );
  });
});
