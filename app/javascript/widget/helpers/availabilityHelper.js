const daysOfWeek = [
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
];

// Function to find the next available time
const findNextAvailableTime = (
  working_hours,
  currentDayOfWeek,
  currentHour,
  currentMinutes
) => {
  let nextAvailableTime = null;

  // Find the next available time for today
  const todayHours = working_hours.filter(
    hours =>
      hours.day_of_week === currentDayOfWeek &&
      !hours.closed_all_day &&
      (hours.open_hour > currentHour ||
        (hours.open_hour === currentHour &&
          hours.open_minutes > currentMinutes))
  );

  // Loop through today's hours to find the earliest available time
  todayHours.forEach(hours => {
    if (
      nextAvailableTime === null ||
      hours.open_hour < nextAvailableTime.hour ||
      (hours.open_hour === nextAvailableTime.hour &&
        hours.open_minutes < nextAvailableTime.minutes)
    ) {
      nextAvailableTime = {
        hour: hours.open_hour,
        minutes: hours.open_minutes,
        day: 'today',
      };
    }
  });

  // If no available time for today, find the next available time for the next day(s)
  if (nextAvailableTime === null) {
    let nextDaysHours = working_hours.filter(
      hours => hours.day_of_week > currentDayOfWeek && !hours.closed_all_day
    );

    // If there are no available hours for the next day, consider hours for the following days
    if (nextDaysHours.length === 0) {
      nextDaysHours = working_hours.filter(
        hours => hours.day_of_week < currentDayOfWeek && !hours.closed_all_day
      );
    }

    // Find the earliest available time among the next day(s)
    let nextDay = null;
    for (let i = 0; i < 7; i += 1) {
      nextDay = nextDaysHours.find(hours => hours.day_of_week === i);
      if (nextDay) {
        break;
      }
    }

    // If there's an available time for the next day(s), set it as next available time
    if (nextDay) {
      nextAvailableTime = {
        hour: nextDay.open_hour,
        minutes: nextDay.open_minutes,
        day: nextDay.day_of_week,
      };
    }
  }

  return nextAvailableTime;
};

// Function to get the next availability message
export const getNextAvailabilityMessage = (working_hours, currentTime) => {
  const currentDayOfWeek = currentTime.getDay(); // 0 for Sunday, 1 for Monday, ...
  const currentHour = currentTime.getHours();
  const currentMinutes = currentTime.getMinutes();
  const nextAvailableTime = findNextAvailableTime(
    working_hours,
    currentDayOfWeek,
    currentHour,
    currentMinutes
  );

  // Calculate the time difference
  if (nextAvailableTime !== null) {
    const differenceInMinutes =
      nextAvailableTime.hour * 60 +
      nextAvailableTime.minutes -
      (currentHour * 60 + currentMinutes);
    const differenceInHours = Math.floor(differenceInMinutes / 60);

    // Check if the next available time is tomorrow
    if (nextAvailableTime.day === currentDayOfWeek + 1) {
      return `We will be back online tomorrow`;
    }

    // Check if the next available time is on a specific day
    if (nextAvailableTime.day !== 'today') {
      return `We will be back online on ${daysOfWeek[nextAvailableTime.day]}`;
    }

    // Generate appropriate message based on time difference
    if (differenceInMinutes <= 1) {
      return 'We will be back online in less than a minute.';
    }
    if (differenceInMinutes < 60) {
      return `We will be back online in ${differenceInMinutes} minutes.`;
    }
    if (differenceInMinutes < 1440) {
      return `We will be back online in ${differenceInHours} hours`;
    }
  }
  return 'No available time found in working hours.';
};
