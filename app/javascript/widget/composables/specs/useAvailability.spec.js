import { ref } from 'vue';
import { useAvailability } from '../useAvailability';
import {
  getWorkingHoursInfo,
  getNextAvailableTime,
} from 'widget/helpers/availabilityHelpers';

// Mock the vue-i18n library for translations
vi.mock('vue-i18n', () => ({
  useI18n: () => ({
    // Mock translation function that returns the key or interpolated string
    t: vi.fn((key, params) => {
      // If params with time value provided, append it to the key
      if (params?.time) {
        return `${key} ${params.time}`;
      }
      // Otherwise just return the translation key
      return key;
    }),
  }),
}));

// Mock the availability helper functions
vi.mock('widget/helpers/availabilityHelpers', () => ({
  getWorkingHoursInfo: vi.fn(),
  getNextAvailableTime: vi.fn(),
}));

describe('useAvailability', () => {
  let originalWindow;

  beforeEach(() => {
    vi.clearAllMocks();

    originalWindow = global.window;

    global.window = {
      ...originalWindow,
      chatwootWebChannel: {
        workingHours: [],
        timezone: 'UTC',
        locale: 'en',
        utcOffset: 'UTC',
        workingHoursEnabled: false,
        replyTime: 'in_a_few_hours',
        outOfOfficeMessage: '',
      },
    };
  });

  afterEach(() => {
    global.window = originalWindow;
  });

  describe('configuration', () => {
    it('should use default values when chatwootWebChannel is not defined', () => {
      delete global.window.chatwootWebChannel;

      getWorkingHoursInfo.mockReturnValue({
        enabled: false,
        isInWorkingHours: true,
      });
      getNextAvailableTime.mockReturnValue({ type: 'BACK_IN_SOME_TIME' });

      const { channelConfig, workingHoursEnabled, replyTime } =
        useAvailability();

      expect(channelConfig.value).toEqual({}); // Empty object when no config
      expect(workingHoursEnabled).toBe(false); // Default to disabled
      expect(replyTime).toBe('in_a_few_hours'); // Default reply time
    });

    it('should use channel configuration when available', () => {
      const mockConfig = {
        workingHours: [{ day_of_week: 1, open_hour: 9, close_hour: 17 }],
        timezone: 'Asia/Kolkata',
        locale: 'hi',
        utcOffset: '+05:30',
        workingHoursEnabled: true,
        replyTime: 'in_a_few_minutes',
        outOfOfficeMessage: 'We are on vacation',
      };
      global.window.chatwootWebChannel = mockConfig;

      getWorkingHoursInfo.mockReturnValue({
        enabled: true,
        isInWorkingHours: true,
      });
      getNextAvailableTime.mockReturnValue({ type: 'BACK_IN_SOME_TIME' });

      const { channelConfig, outOfOfficeMessage } = useAvailability();

      expect(channelConfig.value).toEqual(mockConfig);
      expect(outOfOfficeMessage).toBe('We are on vacation');
    });

    it('should fallback timezone to utcOffset when timezone is not set', () => {
      // Set only utcOffset, not timezone
      global.window.chatwootWebChannel = {
        utcOffset: '+02:00',
      };

      getWorkingHoursInfo.mockReturnValue({
        enabled: false,
        isInWorkingHours: true,
      });

      useAvailability();

      expect(getWorkingHoursInfo).toHaveBeenCalledWith(
        [], // Empty working hours array
        '+02:00', // UTC offset used as fallback
        false // Working hours not enabled
      );
    });
  });

  describe('online status', () => {
    it('should be online when agents are available and working hours disabled', () => {
      global.window.chatwootWebChannel = {
        workingHoursEnabled: false,
      };
      getWorkingHoursInfo.mockReturnValue({
        enabled: false,
        isInWorkingHours: true,
      });

      const availableAgents = ref([{ id: 1 }, { id: 2 }]);
      const { isOnline } = useAvailability(availableAgents);
      expect(isOnline.value).toBe(true);
    });

    it('should be offline when no agents available and working hours disabled', () => {
      global.window.chatwootWebChannel = {
        workingHoursEnabled: false,
      };
      getWorkingHoursInfo.mockReturnValue({
        enabled: false,
        isInWorkingHours: true,
      });

      const availableAgents = ref([]);
      const { isOnline } = useAvailability(availableAgents);
      expect(isOnline.value).toBe(false);
    });

    it('should use working hours when enabled regardless of agent availability', () => {
      global.window.chatwootWebChannel = {
        workingHoursEnabled: true,
      };

      // Mock helper to return outside working hours
      getWorkingHoursInfo.mockReturnValue({
        enabled: true,
        isInWorkingHours: false, // Not in working hours
      });

      const availableAgents = ref([{ id: 1 }]);
      const { isOnline } = useAvailability(availableAgents);

      // Should be offline despite agents because outside working hours
      expect(isOnline.value).toBe(false);
    });

    it('should be online during working hours when enabled', () => {
      global.window.chatwootWebChannel = {
        workingHoursEnabled: true,
      };

      // Mock helper to return in working hours
      getWorkingHoursInfo.mockReturnValue({
        enabled: true,
        isInWorkingHours: true, // In working hours
      });

      const { isOnline, isInBusinessHours } = useAvailability();

      // Should be online during working hours
      expect(isOnline.value).toBe(true);
      expect(isInBusinessHours).toBe(true);
    });
  });

  describe('reply time status', () => {
    it('should return translated reply time', () => {
      // Set specific reply time
      global.window.chatwootWebChannel = {
        replyTime: 'in_a_few_minutes',
      };

      getWorkingHoursInfo.mockReturnValue({
        enabled: false,
        isInWorkingHours: true,
      });

      const { replyTimeStatus } = useAvailability();

      // Should return translation key in uppercase
      expect(replyTimeStatus.value).toBe('REPLY_TIME.IN_A_FEW_MINUTES');
    });
  });

  describe('reply wait message', () => {
    describe('when working hours disabled', () => {
      beforeEach(() => {
        global.window.chatwootWebChannel = {
          workingHoursEnabled: false,
          replyTime: 'in_a_few_hours',
        };
      });

      it('should show reply time when online', () => {
        getWorkingHoursInfo.mockReturnValue({
          enabled: false,
          isInWorkingHours: true,
        });

        const availableAgents = ref([{ id: 1 }]);
        const { replyWaitMessage } = useAvailability(availableAgents);

        // Should show reply time when online
        expect(replyWaitMessage.value).toBe('REPLY_TIME.IN_A_FEW_HOURS');
      });

      it('should show offline message when no agents', () => {
        getWorkingHoursInfo.mockReturnValue({
          enabled: false,
          isInWorkingHours: true,
        });

        const availableAgents = ref([]);
        const { replyWaitMessage } = useAvailability(availableAgents);

        // Should show offline message
        expect(replyWaitMessage.value).toBe('TEAM_AVAILABILITY.OFFLINE');
      });
    });

    describe('when working hours enabled', () => {
      beforeEach(() => {
        global.window.chatwootWebChannel = {
          workingHoursEnabled: true,
          replyTime: 'in_a_few_minutes',
        };
      });

      it('should show offline when all days closed', () => {
        // Mock helper to return all days closed
        getWorkingHoursInfo.mockReturnValue({
          enabled: true,
          isInWorkingHours: false,
          allClosed: true, // All days are closed
        });

        const { replyWaitMessage } = useAvailability();

        // Should show offline message
        expect(replyWaitMessage.value).toBe('TEAM_AVAILABILITY.OFFLINE');
      });

      it('should show reply time when in working hours', () => {
        getWorkingHoursInfo.mockReturnValue({
          enabled: true,
          isInWorkingHours: true, // Currently open
          allClosed: false,
        });

        const { replyWaitMessage } = useAvailability();

        // Should show reply time when open
        expect(replyWaitMessage.value).toBe('REPLY_TIME.IN_A_FEW_MINUTES');
      });

      it('should show next available time when outside working hours', () => {
        getWorkingHoursInfo.mockReturnValue({
          enabled: true,
          isInWorkingHours: false, // Currently closed
          allClosed: false,
        });

        // Mock next available time calculation
        getNextAvailableTime.mockReturnValue({
          type: 'BACK_AT',
          value: '09:00', // Opens at 9 AM
        });

        const { replyWaitMessage } = useAvailability();

        // Should show when back with time
        expect(replyWaitMessage.value).toBe('REPLY_TIME.BACK_AT 09:00');
      });

      it('should handle BACK_IN_SOME_TIME without parameters', () => {
        getWorkingHoursInfo.mockReturnValue({
          enabled: true,
          isInWorkingHours: false,
          allClosed: false,
        });

        // Mock next available time as unknown
        getNextAvailableTime.mockReturnValue({
          type: 'BACK_IN_SOME_TIME', // No specific time
        });

        const { replyWaitMessage } = useAvailability();

        // Should show generic message without time parameter
        expect(replyWaitMessage.value).toBe('REPLY_TIME.BACK_IN_SOME_TIME');
      });

      it('should handle BACK_IN with time parameter', () => {
        getWorkingHoursInfo.mockReturnValue({
          enabled: true,
          isInWorkingHours: false,
          allClosed: false,
        });

        // Mock next available time as relative hours
        getNextAvailableTime.mockReturnValue({
          type: 'BACK_IN',
          value: '2 hours', // Back in 2 hours
        });

        const { replyWaitMessage } = useAvailability();

        // Should show message with time parameter
        expect(replyWaitMessage.value).toBe('REPLY_TIME.BACK_IN 2 hours');
      });

      it('should handle BACK_ON with day parameter', () => {
        getWorkingHoursInfo.mockReturnValue({
          enabled: true,
          isInWorkingHours: false,
          allClosed: false,
        });

        // Mock next available time as specific day
        getNextAvailableTime.mockReturnValue({
          type: 'BACK_ON',
          value: 'tomorrow', // Back tomorrow
        });
        const { replyWaitMessage } = useAvailability();

        // Should show message with day parameter
        expect(replyWaitMessage.value).toBe('REPLY_TIME.BACK_ON tomorrow');
      });
    });
  });

  describe('reactivity', () => {
    it('should update when available agents change', () => {
      // Configure with working hours disabled
      global.window.chatwootWebChannel = {
        workingHoursEnabled: false,
      };

      // Mock helper to return disabled state
      getWorkingHoursInfo.mockReturnValue({
        enabled: false,
        isInWorkingHours: true,
      });

      // Create reactive ref for agents
      const availableAgents = ref([]);
      // Call composable with reactive agents
      const { isOnline } = useAvailability(availableAgents);

      // Initially offline (no agents)
      expect(isOnline.value).toBe(false);

      // Add agents to the reactive ref
      availableAgents.value = [{ id: 1 }];
      // Should now be online
      expect(isOnline.value).toBe(true);

      // Remove agents from the reactive ref
      availableAgents.value = [];
      // Should be offline again
      expect(isOnline.value).toBe(false);
    });
  });

  describe('edge cases', () => {
    it('should handle undefined available agents', () => {
      getWorkingHoursInfo.mockReturnValue({
        enabled: false,
        isInWorkingHours: true,
      });

      const { isOnline } = useAvailability();

      // Should default to offline when no agents provided
      expect(isOnline.value).toBe(false);
    });

    it('should handle null available agents', () => {
      getWorkingHoursInfo.mockReturnValue({
        enabled: false,
        isInWorkingHours: true,
      });

      const availableAgents = ref(null);
      const { isOnline } = useAvailability(availableAgents);

      // Should handle null
      expect(isOnline.value).toBe(false);
    });

    it('should provide all expected return values', () => {
      // Mock helper return value
      getWorkingHoursInfo.mockReturnValue({
        enabled: true,
        isInWorkingHours: true,
      });

      // Call composable
      const result = useAvailability();

      // Check all expected properties exist
      expect(result).toHaveProperty('isOnline');
      expect(result).toHaveProperty('isInBusinessHours');
      expect(result).toHaveProperty('replyWaitMessage');
      expect(result).toHaveProperty('replyTimeStatus');
      expect(result).toHaveProperty('outOfOfficeMessage');
      expect(result).toHaveProperty('channelConfig');
      expect(result).toHaveProperty('workingHoursEnabled');
      expect(result).toHaveProperty('replyTime');
    });
  });

  describe('integration scenarios', () => {
    it('should correctly handle Monday morning before opening', () => {
      // Configure for Monday morning scenario
      global.window.chatwootWebChannel = {
        workingHoursEnabled: true,
        workingHours: [{ day_of_week: 1, open_hour: 9, close_hour: 17 }],
        replyTime: 'in_a_few_minutes',
      };

      // Mock Monday at 8 AM (before opening)
      getWorkingHoursInfo.mockReturnValue({
        enabled: true,
        isInWorkingHours: false, // Not open yet
        allClosed: false,
        currentDay: 1, // Monday
        currentHour: 8,
        currentMinute: 0,
      });

      // Mock next available time (1 hour until opening)
      getNextAvailableTime.mockReturnValue({
        type: 'BACK_IN',
        value: '1 hour',
      });

      const { isOnline, replyWaitMessage } = useAvailability();

      expect(isOnline.value).toBe(false);
      // Should show when back online
      expect(replyWaitMessage.value).toBe('REPLY_TIME.BACK_IN 1 hour');
    });

    it('should correctly handle weekend when office is closed', () => {
      // Configure for weekday working hours only
      global.window.chatwootWebChannel = {
        workingHoursEnabled: true,
        workingHours: [
          { day_of_week: 1, open_hour: 9, close_hour: 17 }, // Monday
          { day_of_week: 2, open_hour: 9, close_hour: 17 }, // Tuesday
          { day_of_week: 3, open_hour: 9, close_hour: 17 }, // Wednesday
          { day_of_week: 4, open_hour: 9, close_hour: 17 }, // Thursday
          { day_of_week: 5, open_hour: 9, close_hour: 17 }, // Friday
        ],
        replyTime: 'in_a_few_hours',
      };

      // Mock Saturday
      getWorkingHoursInfo.mockReturnValue({
        enabled: true,
        isInWorkingHours: false, // Weekend - closed
        allClosed: false,
        currentDay: 6, // Saturday
      });

      // Mock next available time (Monday)
      getNextAvailableTime.mockReturnValue({
        type: 'BACK_ON',
        value: 'Monday',
      });

      const { isOnline, replyWaitMessage } = useAvailability();

      // Should be offline on weekend
      expect(isOnline.value).toBe(false);
      // Should show when back (Monday)
      expect(replyWaitMessage.value).toBe('REPLY_TIME.BACK_ON Monday');
    });
  });
});
