const LAST_CUSTOM_SNOOZE_KEY = 'chatwoot_last_custom_snooze_time';

export const saveLastCustomSnoozeTime = snoozedUntil => {
  if (!snoozedUntil) return;

  try {
    localStorage.setItem(
      LAST_CUSTOM_SNOOZE_KEY,
      JSON.stringify({
        timestamp: snoozedUntil,
        savedAt: Date.now(),
      })
    );
    // Emit event to update command bar
    if (typeof window !== 'undefined' && window.emitter) {
      window.emitter.emit('CUSTOM_SNOOZE_TIME_CHANGED');
    }
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error('Failed to save custom snooze time:', error);
  }
};

export const getLastCustomSnoozeTime = () => {
  try {
    const stored = localStorage.getItem(LAST_CUSTOM_SNOOZE_KEY);
    if (!stored) return null;

    const data = JSON.parse(stored);
    const now = Date.now();
    const nowUnix = Math.floor(now / 1000);
    const savedAt = data.savedAt;
    const sevenDaysInMs = 7 * 24 * 60 * 60 * 1000;

    // Check if the saved time has already passed OR if it was saved more than 7 days ago
    const timeHasPassed = data.timestamp <= nowUnix;
    const tooOld = now - savedAt > sevenDaysInMs;

    if (timeHasPassed || tooOld) {
      localStorage.removeItem(LAST_CUSTOM_SNOOZE_KEY);
      // Emit event when data is cleared due to expiration
      if (typeof window !== 'undefined' && window.emitter) {
        window.emitter.emit('CUSTOM_SNOOZE_TIME_CHANGED');
      }
      return null;
    }

    return data.timestamp;
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error('Failed to get custom snooze time:', error);
    localStorage.removeItem(LAST_CUSTOM_SNOOZE_KEY);
    // Emit event when data is cleared due to error
    if (typeof window !== 'undefined' && window.emitter) {
      window.emitter.emit('CUSTOM_SNOOZE_TIME_CHANGED');
    }
    return null;
  }
};

export const hasLastCustomSnoozeTime = () => {
  return getLastCustomSnoozeTime() !== null;
};

export const formatLastCustomSnoozeTime = () => {
  const timestamp = getLastCustomSnoozeTime();
  if (!timestamp) return null;

  try {
    const date = new Date(timestamp * 1000); // Convert Unix timestamp to milliseconds

    // Format as "Sat, 23 Aug, 8.16pm"
    const dayOfWeek = date.toLocaleDateString('en-US', { weekday: 'short' });
    const day = date.getDate();
    const month = date.toLocaleDateString('en-US', { month: 'short' });

    // Format time as 8.16pm (with dots instead of colons)
    let hours = date.getHours();
    const minutes = date.getMinutes().toString().padStart(2, '0');
    const ampm = hours >= 12 ? 'pm' : 'am';

    // Convert to 12-hour format
    hours %= 12;
    if (hours === 0) hours = 12; // 12am/12pm instead of 0am/0pm

    const timeString = `${hours}.${minutes}${ampm}`;

    return `${dayOfWeek}, ${day} ${month}, ${timeString}`;
  } catch (error) {
    return null;
  }
};
