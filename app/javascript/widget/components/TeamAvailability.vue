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
            isInBetweenTheWorkingHours ? replyTimeStatus : outOfOfficeMessage
          }}
        </div>
      </div>
      <available-agents
        v-if="isInBetweenTheWorkingHours"
        :agents="availableAgents"
      />
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
import {
  buildDateFromTime,
  formatDigitToString,
} from 'shared/helpers/DateHelper';
import WootButton from 'shared/components/Button';
import configMixin from 'widget/mixins/configMixin';
import compareAsc from 'date-fns/compareAsc';

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

      const { utcOffset } = this.channelConfig;
      const startTime = buildDateFromTime(
        formatDigitToString(openHour),
        formatDigitToString(openMinute),
        utcOffset
      );
      const endTime = buildDateFromTime(
        formatDigitToString(closeHour),
        formatDigitToString(closeMinute),
        utcOffset
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
  },
};
</script>
