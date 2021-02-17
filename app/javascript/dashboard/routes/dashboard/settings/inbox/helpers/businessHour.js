export const generateTimeSlots = (step = 15) => {
  const date = new Date(1970, 0, 1);
  const slots = [];
  while (date.getDate() === 1) {
    slots.push(
      date.toLocaleTimeString('en-US', {
        hour: '2-digit',
        minute: '2-digit',
        hour12: true,
      })
    );
    date.setMinutes(date.getMinutes() + step);
  }
  return slots;
};
