import { computed } from 'vue';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';

const TIME_FORMAT_12H = '12h';
const TIME_FORMAT_24H = '24h';

export const useTimeFormat = () => {
  const { uiSettings, updateUISettings } = useUISettings();
  const { t } = useI18n();

  const timeFormatOptions = computed(() => [
    {
      value: TIME_FORMAT_12H,
      label: t(
        'PROFILE_SETTINGS.FORM.INTERFACE_SECTION.TIME_FORMAT.OPTIONS.TWELVE_HOUR'
      ),
    },
    {
      value: TIME_FORMAT_24H,
      label: t(
        'PROFILE_SETTINGS.FORM.INTERFACE_SECTION.TIME_FORMAT.OPTIONS.TWENTY_FOUR_HOUR'
      ),
    },
  ]);

  const currentTimeFormat = computed(
    () => uiSettings.value.time_format || TIME_FORMAT_12H
  );

  const is24HourFormat = computed(
    () => currentTimeFormat.value === TIME_FORMAT_24H
  );

  // Short time-only format used in message stamps
  const shortTimeFormat = computed(() =>
    is24HourFormat.value ? 'HH:mm' : 'h:mm a'
  );

  // Full date+time format used in tooltips and timestamps
  const fullTimestampFormat = computed(() =>
    is24HourFormat.value ? 'LLL d, HH:mm' : 'LLL d, h:mm a'
  );

  const updateTimeFormat = async format => {
    try {
      await updateUISettings({ time_format: format });
      useAlert(
        t('PROFILE_SETTINGS.FORM.INTERFACE_SECTION.TIME_FORMAT.UPDATE_SUCCESS')
      );
    } catch {
      useAlert(
        t('PROFILE_SETTINGS.FORM.INTERFACE_SECTION.TIME_FORMAT.UPDATE_ERROR')
      );
    }
  };

  return {
    timeFormatOptions,
    currentTimeFormat,
    is24HourFormat,
    shortTimeFormat,
    fullTimestampFormat,
    updateTimeFormat,
  };
};

export default useTimeFormat;
