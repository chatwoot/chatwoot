<template>
  <div class="mx-8">
    <settings-section
      :title="'Set Agent Business Hours'"
      :sub-title="'Configure business hours when agents cannot mark themselves offline'"
    >
      <form @submit.prevent="updateSettings">
        <label for="toggle-business-hours" class="toggle-input-wrap">
          <input
            v-model="isBusinessHoursEnabled"
            type="checkbox"
            class="ltr:mr-2 rtl:ml-2"
            name="toggle-business-hours"
          />
          Enable business hours for agent availability
        </label>
        <p class="text-slate-700 dark:text-slate-300 mb-4">
          With business hours enabled, agents will not be able to mark
          themselves offline during the configured working hours, ensuring
          adequate coverage during business hours.
        </p>

        <div v-if="isBusinessHoursEnabled" class="mb-6">
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
              :close-on-select="true"
              :placeholder="$t('INBOX_MGMT.BUSINESS_HOURS.DAY.CHOOSE')"
              :allow-empty="false"
            />
          </div>

          <label>
            {{ $t('INBOX_MGMT.BUSINESS_HOURS.WEEKLY_TITLE') }}
          </label>
          <business-day
            v-for="timeSlot in timeSlots"
            :key="timeSlot.day"
            :day-name="dayNames[timeSlot.day]"
            :time-slot="timeSlot"
            @update="data => onSlotUpdate(timeSlot.day, data)"
          />
        </div>
        <woot-submit-button
          :button-text="$t('INBOX_MGMT.BUSINESS_HOURS.UPDATE')"
          :loading="isUpdating"
          :disabled="hasError"
        />
      </form>
    </settings-section>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import SettingsSection from 'dashboard/components/SettingsSection.vue';
import BusinessDay from '../../calling/components/BusinessDay.vue';
import {
  timeSlotParse,
  timeSlotTransform,
  defaultTimeSlot,
  timeZoneOptions,
} from '../../calling/helpers/businessHour';

const DEFAULT_TIMEZONE = {
  label: 'Pacific Time (US & Canada) (GMT-07:00)',
  value: 'America/Los_Angeles',
};

export default {
  components: {
    SettingsSection,
    BusinessDay,
  },
  mixins: [alertMixin],
  props: {
    accountId: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      isBusinessHoursEnabled: false,
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
      isUpdating: false,
    };
  },
  computed: {
    ...mapGetters({
      getAccount: 'accounts/getAccount',
    }),
    hasError() {
      if (!this.isBusinessHoursEnabled) return false;
      return this.timeSlots.filter(slot => slot.from && !slot.valid).length > 0;
    },
    timeZones() {
      return [...timeZoneOptions()];
    },
  },
  mounted() {
    this.setDefaults();
  },
  methods: {
    setDefaults() {
      const { custom_attributes } = this.getAccount(this.accountId);
      const settings = custom_attributes?.agent_availability_settings;

      if (settings) {
        this.isBusinessHoursEnabled = settings.business_hours_enabled || false;

        if (settings.timezone) {
          this.timeZone =
            this.timeZones.find(item => item.value === settings.timezone) ||
            DEFAULT_TIMEZONE;
        }

        if (settings.working_hours && settings.working_hours.length) {
          this.timeSlots = timeSlotParse(settings.working_hours);
        }
      }
    },
    onSlotUpdate(slotIndex, slotData) {
      this.timeSlots = this.timeSlots.map(item =>
        item.day === slotIndex ? slotData : item
      );
    },
    async updateSettings() {
      try {
        this.isUpdating = true;

        const agentAvailabilitySettings = {
          business_hours_enabled: this.isBusinessHoursEnabled,
          timezone: this.timeZone.value,
          working_hours: timeSlotTransform(this.timeSlots),
        };

        await this.$store.dispatch('accounts/update', {
          agent_availability_settings: agentAvailabilitySettings,
        });

        this.showAlert('Business hours updated successfully');
      } catch (error) {
        this.showAlert(
          error.message ||
            "We couldn't update business hours. Please try again later."
        );
      } finally {
        this.isUpdating = false;
      }
    },
  },
};
</script>

<style lang="scss" scoped>
.timezone-input-wrap {
  @apply max-w-[37.5rem];

  &::v-deep .multiselect {
    @apply mt-2;
  }
}

.toggle-input-wrap {
  @apply flex items-center mb-2;
}
</style>
