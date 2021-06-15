<template>
  <div class="px-4">
    <div class="flex items-center justify-between mb-4">
      <div class="text-black-700">
        <div class="text-base leading-5 font-medium mb-1">
          {{
            isOnline
              ? $t('TEAM_AVAILABILITY.ONLINE')
              : $t('TEAM_AVAILABILITY.OFFLINE')
          }}
        </div>
        <div class="text-xs leading-4 mt-1">
          {{ replyWaitMeessage }}
        </div>
      </div>
      <available-agents v-if="isOnline" :agents="availableAgents" />
    </div>
    <custom-button
      class="font-medium"
      block
      :bg-color="widgetColor"
      :text-color="textColor"
      @click="startConversation"
    >
      {{ $t('START_CONVERSATION') }}
    </custom-button>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import { getContrastingTextColor } from '@chatwoot/utils';
import AvailableAgents from 'widget/components/AvailableAgents.vue';
import CustomButton from 'shared/components/Button';
import configMixin from 'widget/mixins/configMixin';
import availabilityMixin from 'widget/mixins/availability';

export default {
  name: 'TeamAvailability',
  components: {
    AvailableAgents,
    CustomButton,
  },
  mixins: [configMixin, availabilityMixin],
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
    isOnline() {
      const { workingHoursEnabled } = this.channelConfig;
      const anyAgentOnline = this.availableAgents.length > 0;

      if (workingHoursEnabled) {
        return this.isInBetweenTheWorkingHours;
      }
      return anyAgentOnline;
    },
    replyWaitMeessage() {
      const { workingHoursEnabled } = this.channelConfig;

      if (this.isOnline) {
        return this.replyTimeStatus;
      }
      if (workingHoursEnabled) {
        return this.outOfOfficeMessage;
      }
      return '';
    },
  },
  methods: {
    startConversation() {
      this.$emit('start-conversation');
    },
  },
};
</script>
