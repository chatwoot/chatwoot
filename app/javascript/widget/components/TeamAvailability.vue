<script>
import { mapGetters } from 'vuex';
import { getContrastingTextColor } from '@chatwoot/utils';
import nextAvailabilityTime from 'widget/mixins/nextAvailabilityTime';
import AvailableAgents from 'widget/components/AvailableAgents.vue';
import configMixin from 'widget/mixins/configMixin';
import availabilityMixin from 'widget/mixins/availability';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import { IFrameHelper } from 'widget/helpers/utils';
import { CHATWOOT_ON_START_CONVERSATION } from '../constants/sdkEvents';

export default {
  name: 'TeamAvailability',
  components: {
    AvailableAgents,
    FluentIcon,
  },
  mixins: [configMixin, nextAvailabilityTime, availabilityMixin],
  props: {
    availableAgents: {
      type: Array,
      default: () => {},
    },
    hasConversation: {
      type: Boolean,
      default: false,
    },
  },
  emits: ['startConversation'],

  computed: {
    ...mapGetters({
      widgetColor: 'appConfig/getWidgetColor',
    }),
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
  },
  methods: {
    startConversation() {
      this.$emit('startConversation');
      if (!this.hasConversation) {
        IFrameHelper.sendMessage({
          event: 'onEvent',
          eventIdentifier: CHATWOOT_ON_START_CONVERSATION,
          data: { hasConversation: false },
        });
      }
    },
  },
};
</script>

<template>
  <div class="p-4 bg-white rounded-md shadow-sm dark:bg-slate-700">
    <div class="flex items-center justify-between">
      <div class="">
        <div class="text-sm font-medium text-slate-700 dark:text-slate-50">
          {{
            isOnline
              ? $t('TEAM_AVAILABILITY.ONLINE')
              : $t('TEAM_AVAILABILITY.OFFLINE')
          }}
        </div>
        <div class="mt-1 text-sm text-slate-500 dark:text-slate-100">
          {{ replyWaitMessage }}
        </div>
      </div>
      <AvailableAgents v-if="isOnline" :agents="availableAgents" />
    </div>
    <button
      class="inline-flex items-center justify-between px-2 py-1 mt-2 -ml-2 text-sm font-medium leading-6 rounded-md text-slate-800 dark:text-slate-50 hover:bg-slate-25 dark:hover:bg-slate-800"
      :style="{ color: widgetColor }"
      @click="startConversation"
    >
      <span class="pr-2 text-sm">
        {{
          hasConversation
            ? $t('CONTINUE_CONVERSATION')
            : $t('START_CONVERSATION')
        }}
      </span>
      <FluentIcon icon="arrow-right" size="14" />
    </button>
  </div>
</template>
