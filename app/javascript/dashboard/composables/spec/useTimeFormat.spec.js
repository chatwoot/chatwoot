import { ref } from 'vue';
import { useTimeFormat } from '../useTimeFormat';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';

vi.mock('dashboard/composables/useUISettings');
vi.mock('dashboard/composables', () => ({
  useAlert: vi.fn(message => message),
}));
vi.mock('vue-i18n');

describe('useTimeFormat', () => {
  const mockUISettings = ref({ time_format: '12h' });
  const mockUpdateUISettings = vi.fn().mockResolvedValue(undefined);
  const mockTranslate = vi.fn(key => key);

  beforeEach(() => {
    vi.clearAllMocks();

    useUISettings.mockReturnValue({
      uiSettings: mockUISettings,
      updateUISettings: mockUpdateUISettings,
    });

    useI18n.mockReturnValue({ t: mockTranslate });

    mockUISettings.value = { time_format: '12h' };
  });

  describe('timeFormatOptions', () => {
    it('returns two options with correct values', () => {
      const { timeFormatOptions } = useTimeFormat();
      expect(timeFormatOptions.value).toHaveLength(2);
      expect(timeFormatOptions.value.map(o => o.value)).toEqual(['12h', '24h']);
    });

    it('each option has a value and label', () => {
      const { timeFormatOptions } = useTimeFormat();
      timeFormatOptions.value.forEach(option => {
        expect(option).toHaveProperty('value');
        expect(option).toHaveProperty('label');
      });
    });

    it('uses translated labels', () => {
      mockTranslate.mockImplementation(key => {
        const map = {
          'PROFILE_SETTINGS.FORM.INTERFACE_SECTION.TIME_FORMAT.OPTIONS.TWELVE_HOUR':
            '12-hour (1:30 PM)',
          'PROFILE_SETTINGS.FORM.INTERFACE_SECTION.TIME_FORMAT.OPTIONS.TWENTY_FOUR_HOUR':
            '24-hour (13:30)',
        };
        return map[key] || key;
      });

      const { timeFormatOptions } = useTimeFormat();
      expect(timeFormatOptions.value[0].label).toBe('12-hour (1:30 PM)');
      expect(timeFormatOptions.value[1].label).toBe('24-hour (13:30)');
    });
  });

  describe('currentTimeFormat', () => {
    it('returns the value from ui settings', () => {
      const { currentTimeFormat } = useTimeFormat();
      expect(currentTimeFormat.value).toBe('12h');
    });

    it('defaults to 12h when not set', () => {
      mockUISettings.value = {};
      const { currentTimeFormat } = useTimeFormat();
      expect(currentTimeFormat.value).toBe('12h');
    });

    it('reflects 24h when set', () => {
      mockUISettings.value = { time_format: '24h' };
      const { currentTimeFormat } = useTimeFormat();
      expect(currentTimeFormat.value).toBe('24h');
    });

    it('is reactive to ui settings changes', () => {
      const { currentTimeFormat } = useTimeFormat();
      expect(currentTimeFormat.value).toBe('12h');

      mockUISettings.value = { time_format: '24h' };
      expect(currentTimeFormat.value).toBe('24h');
    });
  });

  describe('is24HourFormat', () => {
    it('is false when format is 12h', () => {
      const { is24HourFormat } = useTimeFormat();
      expect(is24HourFormat.value).toBe(false);
    });

    it('is true when format is 24h', () => {
      mockUISettings.value = { time_format: '24h' };
      const { is24HourFormat } = useTimeFormat();
      expect(is24HourFormat.value).toBe(true);
    });

    it('is false when no format is saved', () => {
      mockUISettings.value = {};
      const { is24HourFormat } = useTimeFormat();
      expect(is24HourFormat.value).toBe(false);
    });
  });

  describe('shortTimeFormat', () => {
    it('returns h:mm a for 12h', () => {
      const { shortTimeFormat } = useTimeFormat();
      expect(shortTimeFormat.value).toBe('h:mm a');
    });

    it('returns HH:mm for 24h', () => {
      mockUISettings.value = { time_format: '24h' };
      const { shortTimeFormat } = useTimeFormat();
      expect(shortTimeFormat.value).toBe('HH:mm');
    });
  });

  describe('fullTimestampFormat', () => {
    it('returns LLL d, h:mm a for 12h', () => {
      const { fullTimestampFormat } = useTimeFormat();
      expect(fullTimestampFormat.value).toBe('LLL d, h:mm a');
    });

    it('returns LLL d, HH:mm for 24h', () => {
      mockUISettings.value = { time_format: '24h' };
      const { fullTimestampFormat } = useTimeFormat();
      expect(fullTimestampFormat.value).toBe('LLL d, HH:mm');
    });

    it('is reactive to format changes', () => {
      const { fullTimestampFormat } = useTimeFormat();
      expect(fullTimestampFormat.value).toBe('LLL d, h:mm a');

      mockUISettings.value = { time_format: '24h' };
      expect(fullTimestampFormat.value).toBe('LLL d, HH:mm');
    });
  });

  describe('updateTimeFormat', () => {
    it('calls updateUISettings with the new format', async () => {
      const { updateTimeFormat } = useTimeFormat();
      await updateTimeFormat('24h');
      expect(mockUpdateUISettings).toHaveBeenCalledWith({ time_format: '24h' });
    });

    it('shows a success alert on update', async () => {
      const { updateTimeFormat } = useTimeFormat();
      await updateTimeFormat('24h');
      expect(useAlert).toHaveBeenCalledWith(
        'PROFILE_SETTINGS.FORM.INTERFACE_SECTION.TIME_FORMAT.UPDATE_SUCCESS'
      );
    });

    it('shows an error alert when update fails', async () => {
      mockUpdateUISettings.mockRejectedValueOnce(new Error('Network error'));
      const { updateTimeFormat } = useTimeFormat();
      await updateTimeFormat('24h');
      expect(useAlert).toHaveBeenCalledWith(
        'PROFILE_SETTINGS.FORM.INTERFACE_SECTION.TIME_FORMAT.UPDATE_ERROR'
      );
    });

    it('does not show success alert when update fails', async () => {
      mockUpdateUISettings.mockRejectedValueOnce(new Error('Network error'));
      const { updateTimeFormat } = useTimeFormat();
      await updateTimeFormat('24h');
      expect(useAlert).not.toHaveBeenCalledWith(
        'PROFILE_SETTINGS.FORM.INTERFACE_SECTION.TIME_FORMAT.UPDATE_SUCCESS'
      );
    });

    it('works when switching back to 12h', async () => {
      mockUISettings.value = { time_format: '24h' };
      const { updateTimeFormat } = useTimeFormat();
      await updateTimeFormat('12h');
      expect(mockUpdateUISettings).toHaveBeenCalledWith({ time_format: '12h' });
    });
  });
});
