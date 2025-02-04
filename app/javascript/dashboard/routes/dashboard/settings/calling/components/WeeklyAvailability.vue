<template>
  <div class="mx-8">
    <settings-section
      :title="'Set your availability'"
      :sub-title="'Set your availability for inbound calls'"
    >
      <form @submit.prevent="updateInbox">
        <label for="toggle-business-hours" class="toggle-input-wrap">
          <input
            v-model="isBusinessHoursEnabled"
            type="checkbox"
            class="ltr:mr-2 rtl:ml-2"
            name="toggle-business-hours"
          />
          Enable business availability for calls
        </label>
        <p class="text-slate-700 dark:text-slate-300 mb-4">
          With business availability enabled, your inbound calls will be routed
          to the available agents only in available hours and callers will be
          warned with a message when the call is outside of the available hours.
        </p>

        <div
          v-if="isBusinessHoursEnabled && assignmentType === 'team'"
          class="mb-6"
        >
          <multiselect
            v-model="selectedTeam"
            :options="selectedTeams"
            deselect-label=""
            select-label=""
            selected-label=""
            track-by="id"
            label="name"
            placeholder="Select Team"
            :close-on-select="true"
            :allow-empty="false"
          />

          <p class="pb-1 text-sm not-italic text-slate-600 dark:text-slate-400">
            {{
              'Make sure agents in the teams are also added to the inboxes where call conversations happen'
            }}
          </p>
        </div>

        <div
          v-if="
            isBusinessHoursEnabled &&
            (assignmentType === 'agent' ||
              (assignmentType === 'team' && selectedTeam !== null))
          "
          class="mb-6"
        >
          <div class="max-w-[37.5rem]">
            <label class="unavailable-input-wrap">
              {{ 'Unavailable message for callers' }}
            </label>
            <textarea
              v-model="unavailableMessage"
              type="text"
              style="height: 8rem"
            />
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
          :loading="uiFlags.isUpdating"
          :disabled="hasError"
        />
      </form>
    </settings-section>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import inboxMixin from 'shared/mixins/inboxMixin';
import SettingsSection from 'dashboard/components/SettingsSection.vue';
import BusinessDay from './BusinessDay.vue';
import {
  timeSlotParse,
  timeSlotTransform,
  defaultTimeSlot,
  timeZoneOptions,
} from '../helpers/businessHour';

const DEFAULT_TIMEZONE = {
  label: 'Pacific Time (US & Canada) (GMT-07:00)',
  value: 'America/Los_Angeles',
};

export default {
  components: {
    SettingsSection,
    BusinessDay,
  },
  mixins: [alertMixin, inboxMixin],
  props: {
    assignmentType: {
      type: String,
      default: 'agent',
      required: true,
    },
    selectedTeams: {
      type: Array,
      default: () => [],
      required: true,
    },
    accountId: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      weeklyAvailability: {},
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
      selectedTeam: null,
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'inboxes/getUIFlags',
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
  watch: {
    inbox() {
      this.setDefaults();
    },
    selectedTeam: {
      immediate: true,
      async handler(newTeam, oldTeam) {
        if (this.assignmentType === 'team') {
          if (oldTeam) {
            // Save current team's settings before switching
            await this.saveTeamSettings(oldTeam.id);
          }
          if (newTeam) {
            this.loadTeamSettings(newTeam.id);
          }
        }
      },
    },
  },
  mounted() {
    this.setDefaults();
  },
  methods: {
    loadTeamSettings(teamId) {
      const teamSettings = this.weeklyAvailability[teamId] || {};
      const {
        out_of_office_message: unavailableMessage = '',
        working_hours: timeSlots = [],
        timezone: timeZone,
      } = teamSettings;

      const slots = timeSlotParse(timeSlots).length
        ? timeSlotParse(timeSlots)
        : defaultTimeSlot;

      this.unavailableMessage = unavailableMessage;
      this.timeSlots = slots;
      this.timeZone =
        this.timeZones.find(item => timeZone === item.value) ||
        DEFAULT_TIMEZONE;
    },
    setDefaults() {
      const { custom_attributes } = this.getAccount(this.accountId);

      this.weeklyAvailability =
        custom_attributes.calling_settings.weekly_availability || {};
      const { working_hours_enabled: isEnabled = false } =
        this.weeklyAvailability;
      this.isBusinessHoursEnabled = isEnabled;

      if (this.assignmentType === 'team') {
        // For team type, initialize with empty/default values
        this.unavailableMessage = '';
        this.timeSlots = [...defaultTimeSlot];
        this.timeZone = DEFAULT_TIMEZONE;
        // Team-specific settings will be loaded when a team is selected
        this.selectedTeam = this.selectedTeams[0];
        this.loadTeamSettings(this.selectedTeam.id);
        return;
      }

      // Original logic for agent type
      const {
        out_of_office_message: unavailableMessage,
        working_hours: timeSlots = [],
        timezone: timeZone,
      } = this.weeklyAvailability.base;
      const slots = timeSlotParse(timeSlots).length
        ? timeSlotParse(timeSlots)
        : defaultTimeSlot;
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
        const basePayload = {
          out_of_office_message: this.unavailableMessage,
          working_hours: timeSlotTransform(this.timeSlots),
          timezone: this.timeZone.value,
        };

        let payload;
        if (this.assignmentType === 'team') {
          // Save the current team's settings while preserving other teams' settings
          await this.saveTeamSettings(this.selectedTeam.id);
          payload = {
            ...this.weeklyAvailability, // Include all existing team settings
          };
        } else {
          payload = {
            base: basePayload,
          };
        }

        await this.$store.dispatch('accounts/update', {
          calling_settings: {
            weekly_availability: {
              ...payload,
              working_hours_enabled: this.isBusinessHoursEnabled,
            },
          },
        });

        this.showAlert(this.$t('Call Settings Updated Successfully'));
      } catch (error) {
        this.showAlert(
          error.message ||
            this.$t("We couldn't update call settings. Please try again later.")
        );
      }
    },
    async saveTeamSettings(teamId) {
      const currentSettings = {
        out_of_office_message: this.unavailableMessage,
        working_hours: timeSlotTransform(this.timeSlots),
        timezone: this.timeZone.value,
      };

      this.weeklyAvailability = {
        ...this.weeklyAvailability,
        [teamId]: currentSettings,
      };
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

::v-deep.message-editor {
  @apply border-0;
}

.unavailable-input-wrap {
  @apply max-w-[37.5rem];

  textarea {
    @apply min-h-[4rem] mt-2;
  }
}
</style>
