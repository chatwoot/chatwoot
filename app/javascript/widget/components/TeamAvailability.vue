<template>
  <div class="px-6">
    <custom-button
      class="font-medium rounded-full"
      :bg-color="widgetColor"
      :text-color="textColor"
      @click="startConversation"
    >
      <i class="ion-send" />
      {{ $t('START_CONVERSATION') }}
    </custom-button>
    <div class="flex items-center justify-between my-1">
      <div class="text-black-600">
        <div class="text-xs">
          {{
            isOnline
              ? $t('TEAM_AVAILABILITY.ONLINE')
              : $t('TEAM_AVAILABILITY.OFFLINE')
          }}
        </div>
        <div class="text-xs">
          {{ replyWaitMeessage }}
        </div>
      </div>
      <available-agents v-if="isOnline" :agents="availableAgents" />
    </div>
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
