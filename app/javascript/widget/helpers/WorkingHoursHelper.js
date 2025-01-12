const organizeByDay = workingHoursData => {
  return workingHoursData.reduce((acc, schedule) => {
    acc[schedule.dayOfWeek] = schedule;
    return acc;
  }, {});
};

const toMinutes = (hours, minutes = 0) => {
  return hours * 60 + (minutes || 0);
};

const calculateMinutesUntilOpen = (
  schedule,
  currentTimeInMinutes,
  dayOffset
) => {
  if (!schedule || schedule.closedAllDay) {
    return null;
  }

  let openHour = schedule.openHour;
  let openMinutes = schedule.openMinutes;

  if (schedule.openAllDay) {
    openHour = 0;
    openMinutes = 0;
  }

  const openTimeInMinutes = toMinutes(openHour, openMinutes);

  if (dayOffset === 0) {
    if (currentTimeInMinutes < openTimeInMinutes) {
      return openTimeInMinutes - currentTimeInMinutes;
    }

    return null;
  }

  return (
    toMinutes(24, 0) * dayOffset + openTimeInMinutes - currentTimeInMinutes
  );
};

class WorkingHours {
  constructor(workingHoursData) {
    this.workingHoursByDay = organizeByDay(workingHoursData);
  }

  isOpen(date) {
    const schedule = this.workingHoursByDay[date.getDay()];

    if (!schedule || schedule.closedAllDay) {
      return false;
    }

    if (schedule.openAllDay) {
      return true;
    }

    const currentMinutes = toMinutes(date.getHours(), date.getMinutes());
    const openMinutes = toMinutes(schedule.openHour, schedule.openMinutes);
    const closeMinutes = toMinutes(schedule.closeHour, schedule.closeMinutes);

    return currentMinutes >= openMinutes && currentMinutes <= closeMinutes;
  }

  openInMinutes(date) {
    if (this.isOpen(date)) {
      return 0;
    }

    const currentMinutes = toMinutes(date.getHours(), date.getMinutes());

    for (let i = 0; i < 7; i += 1) {
      const checkDate = new Date(date);
      checkDate.setDate(date.getDate() + i);

      const schedule = this.workingHoursByDay[checkDate.getDay()];
      const minutesUntilOpen = calculateMinutesUntilOpen(
        schedule,
        currentMinutes,
        i
      );

      if (minutesUntilOpen !== null) {
        return minutesUntilOpen;
      }
    }

    return -1;
  }
}

export default WorkingHours;
