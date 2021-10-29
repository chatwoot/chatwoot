<template>
  <div class="start-conversation-wrap">
    <div class="flex items-center justify-between">
      <div>
        <h4>
          {{
            isOnline
              ? $t('TEAM_AVAILABILITY.ONLINE')
              : $t('TEAM_AVAILABILITY.OFFLINE')
          }}
        </h4>
        <p class="text-xs text-slate-500 mb-0">
          {{
            isOnline ? replyWaitMeessage : $t('TEAM_AVAILABILITY.OFFLINE_BODY')
          }}
        </p>
      </div>
      <available-agents v-if="isOnline" :agents="availableAgents" />
    </div>
    <div class="flex items-center justify-center w-full mt-1">
      <start-conversation-button />
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import { getContrastingTextColor } from '@chatwoot/utils';

import AvailableAgents from 'widget/components/AvailableAgents.vue';
import StartConversationButton from 'widget/components/StartConversationButton';

import configMixin from 'widget/mixins/configMixin';
import availabilityMixin from 'widget/mixins/availability';

export default {
  name: 'TeamAvailability',
  components: {
    AvailableAgents,
    StartConversationButton,
  },
  mixins: [configMixin, availabilityMixin],
  props: {
    availableAgents: {
      type: Array,
      default: () => [],
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
    availableAgentNames() {
      const names = this.availableAgents.map(agent => agent.name);
      if (names.length > 2)
        return this.$t('TEAM_AVAILABILITY.MANY_AGENTS', {
          agentName: names[0],
          remainingAgentsCount: names.length - 1,
        });
      if (names.length > 1)
        return this.$t('TEAM_AVAILABILITY.TWO_AGENTS', {
          agentNameOne: names[0],
          agentNameTwo: names[1],
        });
      if (names.length === 1)
        return this.$t('TEAM_AVAILABILITY.SINGLE_AGENT', {
          agentName: names[0],
        });
      return this.$t('TEAM_AVAILABILITY.ONLINE');
    },
    availableAgentNamesStyle() {
      return { color: this.widgetColor };
    },
  },
  methods: {
    startConversation() {
      this.$emit('start-conversation');
    },
  },
};
</script>
<style lang="scss" scoped>
.start-conversation-wrap {
  @apply flex;
  @apply flex-col;
  @apply justify-center;
  @apply mx-4;
  @apply p-3;
  @apply bg-slate-25;
  @apply border border-solid;
  @apply border-slate-75;
  @apply rounded-xl;
}

.agent-names-online {
  @apply text-sm	text-slate-800;
  @apply mt-2;

  &::v-deep > span {
    @apply font-medium;
    @apply text-woot-700;
  }
}
</style>
