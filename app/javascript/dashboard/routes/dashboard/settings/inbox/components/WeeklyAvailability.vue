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
          <label class="timezone-input-wrap">
            {{ $t('INBOX_MGMT.BUSINESS_HOURS.TIMEZONE_LABEL') }}
            <multiselect
              v-model="timeZone"
              :options="[]"
              deselect-label=""
              select-label=""
              selected-label=""
              :placeholder="$t('INBOX_MGMT.BUSINESS_HOURS.DAY.CHOOSE')"
              :allow-empty="false"
            />
          </label>
          <label>
            {{ $t('INBOX_MGMT.BUSINESS_HOURS.WEEKLY_TITLE') }}
          </label>
          <business-day
            v-for="timeSlot in timeSlots"
            :key="timeSlot.day"
            :day-name="dayNames[timeSlot.day]"
            :time-slot="timeSlots[timeSlot.day]"
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

const defaultWeek = [
  {
    day: 0,
    to: '',
    from: '',
    valid: false,
  },
  {
    day: 1,
    to: '',
    from: '',
    valid: false,
  },
  {
    day: 2,
    to: '',
    from: '',
    valid: false,
  },
  {
    day: 3,
    to: '',
    from: '',
    valid: false,
  },
  {
    day: 4,
    to: '',
    from: '',
    valid: false,
  },
  {
    day: 5,
    to: '',
    from: '',
    valid: false,
  },
  {
    day: 6,
    to: '',
    from: '',
    valid: false,
  },
];

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
      timeZone: '',
      dayNames: [
        'Sunday',
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
      ],
      timeSlots: [...defaultWeek],
    };
  },
  computed: {
    ...mapGetters({ uiFlags: 'inboxes/getUIFlags' }),
    hasError() {
      if (!this.isBusinessHoursEnabled) return false;
      return this.timeSlots.filter(slot => slot.from && !slot.valid).length > 0;
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
        working_hours_enabled: isEnabled = '',
        out_of_office_message: unavailableMessage = this.$t(
          'INBOX_MGMT.BUSINESS_HOURS.UNAVAILABLE_MESSAGE_DEFAULT'
        ),
        working_hours: timeSlots = [...defaultWeek],
        time_zone: timeZone,
      } = this.inbox;
      this.isBusinessHoursEnabled = isEnabled;
      this.unavailableMessage = unavailableMessage;
      this.timeSlots = timeSlots;
      this.timeZone = timeZone;
    },
    onSlotUpdate(slotIndex, slotData) {
      this.timeSlots = this.timeSlots.map((item, index) =>
        index === slotIndex ? slotData : item
      );
    },
    async updateInbox() {
      try {
        const payload = {
          id: this.inbox.id,
          formData: false,
          channel: {
            working_hours_enabled: this.isBusinessHoursEnabled,
            out_of_office_message: this.unavailableMessage,
            working_hours: this.timeSlots,
            time_zone: this.timeZone,
          },
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
