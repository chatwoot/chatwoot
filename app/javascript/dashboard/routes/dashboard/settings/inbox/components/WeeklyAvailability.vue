<template>
  <div class="settings--content">
    <settings-section
      :title="$t('INBOX_MGMT.BUSINESS_HOURS.TITLE')"
      :sub-title="$t('INBOX_MGMT.BUSINESS_HOURS.SUBTITLE')"
    >
      <form @submit.prevent="updateInbox">
        <label for="toggle-business-hours" class="toggle-input-wrap">
          <input
            v-model="isBusinessHoursEnabled"
            type="checkbox"
            name="toggle-business-hours"
          />
          {{ $t('INBOX_MGMT.BUSINESS_HOURS.TOGGLE_AVAILABILITY') }}
        </label>
        <p>{{ $t('INBOX_MGMT.BUSINESS_HOURS.TOGGLE_HELP') }}</p>
        <div v-if="isBusinessHoursEnabled" class="business-hours-wrap">
          <label class="unavailable-input-wrap">
            {{ $t('INBOX_MGMT.BUSINESS_HOURS.UNAVAILABLE_MESSAGE_LABEL') }}
            <textarea v-model="unavailableMessage" type="text" />
          </label>
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
          :loading="uiFlags.isUpdatingInbox"
          :disabled="hasError"
        />
      </form>
    </settings-section>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import SettingsSection from 'dashboard/components/SettingsSection';
import BusinessDay from './BusinessDay';
import {
  timeSlotParse,
  timeSlotTransform,
  defaultTimeSlot,
  timeZoneOptions,
} from '../helpers/businessHour';

const DEFAULT_TIMEZONE = {
  label: 'America/Los_Angeles',
  key: 'America/Los_Angeles',
};

export default {
  components: {
    SettingsSection,
    BusinessDay,
  },
  mixins: [alertMixin],
  props: {
    inbox: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      isBusinessHoursEnabled: false,
      unavailableMessage: this.$t(
        'INBOX_MGMT.BUSINESS_HOURS.UNAVAILABLE_MESSAGE_DEFAULT'
      ),
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
    ...mapGetters({ uiFlags: 'inboxes/getUIFlags' }),
    hasError() {
      if (!this.isBusinessHoursEnabled) return false;
      return this.timeSlots.filter(slot => slot.from && !slot.valid).length > 0;
    },
    timeZones() {
      return [...timeZoneOptions()];
    },
  },
  watch: {
    inbox() {
      this.setDefaults();
    },
  },
  mounted() {
    this.setDefaults();
  },
  methods: {
    setDefaults() {
      const {
        working_hours_enabled: isEnabled = false,
        out_of_office_message: unavailableMessage,
        working_hours: timeSlots = [],
        timezone: timeZone,
      } = this.inbox;
      const slots = timeSlotParse(timeSlots).length
        ? timeSlotParse(timeSlots)
        : defaultTimeSlot;
      this.isBusinessHoursEnabled = isEnabled;
      this.unavailableMessage =
        unavailableMessage ||
        this.$t('INBOX_MGMT.BUSINESS_HOURS.UNAVAILABLE_MESSAGE_DEFAULT');
      this.timeSlots = slots;
      this.timeZone =
        this.timeZones.find(item => timeZone === item.value) ||
        DEFAULT_TIMEZONE;
    },
    onSlotUpdate(slotIndex, slotData) {
      this.timeSlots = this.timeSlots.map(item =>
        item.day === slotIndex ? slotData : item
      );
    },
    async updateInbox() {
      try {
        const payload = {
          id: this.inbox.id,
          formData: false,
          working_hours_enabled: this.isBusinessHoursEnabled,
          out_of_office_message: this.unavailableMessage,
          working_hours: timeSlotTransform(this.timeSlots),
          timezone: this.timeZone.value,
          channel: {},
        };
        await this.$store.dispatch('inboxes/updateInbox', payload);
        this.showAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      } catch (error) {
        this.showAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      }
    },
  },
};
</script>
<style lang="scss" scoped>
.timezone-input-wrap {
  max-width: 60rem;

  &::v-deep .multiselect {
    margin-top: var(--space-small);
  }
}

.unavailable-input-wrap {
  max-width: 60rem;

  textarea {
    min-height: var(--space-jumbo);
    margin-top: var(--space-small);
  }
}

.business-hours-wrap {
  margin-bottom: var(--space-medium);
}
</style>
