<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import inboxMixin from 'shared/mixins/inboxMixin';
import SettingsSection from 'dashboard/components/SettingsSection.vue';
import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';
import BusinessDay from './BusinessDay.vue';
import {
  timeSlotParse,
  timeSlotTransform,
  defaultTimeSlot,
  timeZoneOptions,
} from '../helpers/businessHour';
import NextButton from 'dashboard/components-next/button/Button.vue';

const DEFAULT_TIMEZONE = {
  label: 'Pacific Time (US & Canada) (GMT-07:00)',
  value: 'America/Los_Angeles',
};

export default {
  components: {
    SettingsSection,
    BusinessDay,
    NextButton,
    WootMessageEditor,
  },
  mixins: [inboxMixin],
  props: {
    inbox: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      isBusinessHoursEnabled: false,
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
    ...mapGetters({ uiFlags: 'inboxes/getUIFlags' }),
    hasError() {
      if (!this.isBusinessHoursEnabled) return false;
      return this.timeSlots.filter(slot => slot.from && !slot.valid).length > 0;
    },
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
      this.unavailableMessage = unavailableMessage || '';
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
        useAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      } catch (error) {
        useAlert(error.message || this.$t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE'));
      }
    },
  },
};
</script>

<template>
  <div class="mx-8">
    <SettingsSection
      :title="$t('INBOX_MGMT.BUSINESS_HOURS.TITLE')"
      :sub-title="$t('INBOX_MGMT.BUSINESS_HOURS.SUBTITLE')"
    >
      <form @submit.prevent="updateInbox">
        <label for="toggle-business-hours" class="toggle-input-wrap">
          <input
            v-model="isBusinessHoursEnabled"
            type="checkbox"
            class="ltr:mr-2 rtl:ml-2"
            name="toggle-business-hours"
          />
          {{ $t('INBOX_MGMT.BUSINESS_HOURS.TOGGLE_AVAILABILITY') }}
        </label>
        <p class="mb-4 text-slate-700 dark:text-slate-300">
          {{ $t('INBOX_MGMT.BUSINESS_HOURS.TOGGLE_HELP') }}
        </p>
        <div v-if="isBusinessHoursEnabled" class="mb-6">
          <div>
            <label class="unavailable-input-wrap">
              {{ $t('INBOX_MGMT.BUSINESS_HOURS.UNAVAILABLE_MESSAGE_LABEL') }}
            </label>
            <div
              v-if="isRichEditorEnabled"
              class="px-4 py-0 mx-0 mt-0 mb-4 rounded-lg outline outline-1 outline-n-weak hover:outline-n-slate-6 dark:hover:outline-n-slate-6 bg-n-alpha-black2"
            >
              <WootMessageEditor
                v-model="unavailableMessage"
                enable-variables
                is-format-mode
                :min-height="4"
              />
            </div>
            <textarea v-else v-model="unavailableMessage" type="text" />
          </div>
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
        <NextButton
          type="submit"
          :label="$t('INBOX_MGMT.BUSINESS_HOURS.UPDATE')"
          :is-loading="uiFlags.isUpdating"
          :disabled="hasError"
        />
      </form>
    </SettingsSection>
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
