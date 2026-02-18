<script>
import { useAlert } from 'dashboard/composables';
import BusinessDay from '../inbox/components/BusinessDay.vue';
import {
  timeSlotParse,
  timeSlotTransform,
  defaultTimeSlot,
  timeZoneOptions,
} from '../inbox/helpers/businessHour';

const DEFAULT_TIMEZONE = {
  label: 'Pacific Time (US & Canada) (GMT-07:00)',
  value: 'America/Los_Angeles',
};

export default {
  components: {
    BusinessDay,
  },
  props: {
    user: {
      type: Object,
      default: () => ({}),
    },
    accountDefaults: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      unavailableMessage: '',
      timeZone: DEFAULT_TIMEZONE,
      dayNames: {
        0: 'Sunday',
        1: 'Monday',
        2: 'Tuesday',
        3: 'Wednesday',
        4: 'Thursday',
        5: 'Friday',
        6: 'Saturday',
      },
      timeSlots: [...defaultTimeSlot],
    };
  },
  computed: {
    timeZones() {
      return [...timeZoneOptions()];
    },
    isRichEditorEnabled() {
      if (
        this.isATwilioChannel ||
        this.isATwitterInbox ||
        this.isAFacebookInbox
      )
        return false;
      return true;
    },
  },
  watch: {
    user: {
      handler() {
        this.$nextTick(() => {
          this.setDefaults();
        });
      },
      deep: true,
    },
    accountDefaults: {
      handler(newVal) {
        if (newVal && (newVal.timezone || newVal.working_hours?.length)) {
          this.$nextTick(() => {
            this.setDefaults();
          });
        }
      },
      deep: true,
      immediate: true,
    },
  },
  mounted() {
    this.$nextTick(() => {
      this.setDefaults();
    });
  },
  methods: {
    setDefaults() {
      const user = this.user || {};
      const accountDef = this.accountDefaults || {};

      const userTimeSlots = user.working_hours;
      const userTimeZone = user.timezone;
      const accountTimeSlots = accountDef.working_hours || [];
      const accountTimeZone = accountDef.timezone;

      // Check if user has actual data configured
      // If no working_hours are set, the agent hasn't configured their schedule,
      // so treat timezone as unset too (API returns "UTC" as DB default)
      const hasUserTimeSlots = Array.isArray(userTimeSlots) && userTimeSlots.length > 0;
      const hasUserTimeZone = hasUserTimeSlots && userTimeZone != null && userTimeZone !== '';

      // Use user data first, fallback to account defaults, then to defaults
      const timeSlots = hasUserTimeSlots ? userTimeSlots : (accountTimeSlots.length > 0 ? accountTimeSlots : []);
      const timeZone = hasUserTimeZone ? userTimeZone : (accountTimeZone || null);

      const slots = timeSlotParse(timeSlots).length
        ? timeSlotParse(timeSlots)
        : defaultTimeSlot;
      this.timeSlots = slots.sort((a, b) => a.day - b.day);
      this.timeZone =
        this.timeZones.find(item => timeZone === item.value) ||
        DEFAULT_TIMEZONE;
    },
    onSlotUpdate(slotIndex, slotData) {
      this.timeSlots = this.timeSlots.map(item =>
        item.day === slotIndex ? slotData : item
      );
    },
    updateWeeklyAvailability() {
      try {
        const payload = {
          timezone: this.timeZone.value,
          working_hours: timeSlotTransform(this.timeSlots),
        };

        return payload;
      } catch (error) {
        useAlert(error.message || this.$t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE'));
        return null;
      }
    },
  },
};
</script>

<template>
  <div>
    <div class="mb-6">
      <div class="timezone-input-wrap">
        <label>
          {{ $t('INBOX_MGMT.BUSINESS_HOURS.TIMEZONE_LABEL') }}
        </label>
        <multiselect
          v-model="timeZone"
          :options="timeZones"
          deselect-label=""
          select-label=""
          selected-label=""
          track-by="value"
          label="label"
          close-on-select
          :placeholder="$t('INBOX_MGMT.BUSINESS_HOURS.DAY.CHOOSE')"
          :allow-empty="false"
        />
      </div>

      <label>
        {{ $t('INBOX_MGMT.BUSINESS_HOURS.WEEKLY_TITLE') }}
      </label>

      <BusinessDay
        v-for="timeSlot in timeSlots"
        :key="timeSlot.day"
        :day-name="dayNames[timeSlot.day]"
        :time-slot="timeSlot"
        @update="data => onSlotUpdate(timeSlot.day, data)"
      />
    </div>
  </div>
</template>

<style lang="scss" scoped>
.timezone-input-wrap {
  &::v-deep .multiselect {
    @apply mt-2;
  }
}

::v-deep.message-editor {
  @apply border-0;
}

.unavailable-input-wrap {
  textarea {
    @apply min-h-[4rem] mt-2;
  }
}
</style>
