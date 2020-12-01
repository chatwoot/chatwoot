<template>
  <div class="px-4">
    <div
      v-if="channelConfig.workingHoursEnabled"
      class="flex items-center justify-between mb-4"
    >
      <div class="text-black-700">
        <div class="text-base leading-5 font-medium mb-1">
          {{
            isInBetweenTheWorkingHours
              ? $t('TEAM_AVAILABILITY.ONLINE')
              : $t('TEAM_AVAILABILITY.OFFLINE')
          }}
        </div>
        <div class="text-xs leading-4 mt-1">
          {{
            isInBetweenTheWorkingHours
              ? replyTimeStatus
              : 'The team will be back in 5 hours'
          }}
        </div>
      </div>
      <available-agents :agents="availableAgents" />
    </div>
    <woot-button
      class="font-medium"
      block
      :bg-color="widgetColor"
      :text-color="textColor"
      @click="startConversation"
    >
      {{ $t('START_CONVERSATION') }}
    </woot-button>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import AvailableAgents from 'widget/components/AvailableAgents.vue';
import { getContrastingTextColor } from 'shared/helpers/ColorHelper';
import WootButton from 'shared/components/Button';
import configMixin from 'widget/mixins/configMixin';
import format from 'date-fns/format';
import compareAsc from 'date-fns/compareAsc';
import parseISO from 'date-fns/parseISO';

export default {
  name: 'TeamAvailability',
  components: {
    AvailableAgents,
    WootButton,
  },
  mixins: [configMixin],
  props: {
    availableAgents: {
      type: Array,
      default: () => {},
    },
  },
  computed: {
    ...mapGetters({ widgetColor: 'appConfig/getWidgetColor' }),
    textColor() {
      return getContrastingTextColor(this.widgetColor);
    },
    isInBetweenTheWorkingHours() {
      const {
        closedAllDay,
        openHour,
        openMinute,
        closeHour,
        closeMinute,
      } = this.currentDayAvailability;

      if (closedAllDay) {
        return false;
      }
      const startTime = this.buildDate(
        this.formatDigitToString(openHour),
        this.formatDigitToString(openMinute)
      );
      const endTime = this.buildDate(
        this.formatDigitToString(closeHour),
        this.formatDigitToString(closeMinute)
      );

      if (
        compareAsc(new Date(), startTime) === 1 &&
        compareAsc(endTime, new Date()) === 1
      ) {
        return true;
      }

      return false;
    },
    currentDayAvailability() {
      const dayOfTheWeek = new Date().getDay();
      const [workingHourConfig = {}] = this.channelConfig.workingHours.filter(
        workingHour => workingHour.day_of_week === dayOfTheWeek
      );
      return {
        closedAllDay: workingHourConfig.closed_all_day,
        openHour: workingHourConfig.open_hour,
        openMinute: workingHourConfig.open_minutes,
        closeHour: workingHourConfig.close_hour,
        closeMinute: workingHourConfig.close_minutes,
      };
    },
  },
  methods: {
    startConversation() {
      this.$emit('start-conversation');
    },
    buildDate(hr, min) {
      const today = format(new Date(), 'yyyy-MM-dd');
      const timeString = `${today}T${hr}:${min}:00${this.channelConfig.utcOffset}`;
      return parseISO(timeString);
    },
    formatDigitToString(val) {
      return val > 9 ? `${val}` : `0${val}`;
    },
  },
};
</script>
