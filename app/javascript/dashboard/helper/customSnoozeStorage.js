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

    // Check if the saved time is still in the future (within 7 days of when it was saved)
    const now = Date.now();
    const savedAt = data.savedAt;
    const sevenDaysInMs = 7 * 24 * 60 * 60 * 1000;

    // If saved more than 7 days ago, consider it stale
    if (now - savedAt > sevenDaysInMs) {
      localStorage.removeItem(LAST_CUSTOM_SNOOZE_KEY);
      return null;
    }

    return data.timestamp;
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error('Failed to get custom snooze time:', error);
    localStorage.removeItem(LAST_CUSTOM_SNOOZE_KEY);
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
    return date.toLocaleString();
  } catch (error) {
    return null;
  }
};
