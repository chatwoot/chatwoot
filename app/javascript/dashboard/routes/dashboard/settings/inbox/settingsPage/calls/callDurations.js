// Select options for a setting saved in seconds, in whole minutes from two minutes up; a saved
// value outside the presets stays selectable
export const durationOptions = (t, presets, savedValue) =>
  [...new Set([...presets, savedValue])]
    .filter(seconds => Number.isInteger(seconds))
    .sort((a, b) => a - b)
    .map(seconds => {
      if (seconds === 0) {
        return { value: 0, label: t('INBOX_MGMT.CALL_SETTINGS.OFF') };
      }
      if (seconds > 60 && seconds % 60 === 0) {
        return {
          value: seconds,
          label: t('INBOX_MGMT.CALL_SETTINGS.MINUTES', seconds / 60),
        };
      }
      return {
        value: seconds,
        label: t('INBOX_MGMT.CALL_SETTINGS.SECONDS', { seconds }),
      };
    });
