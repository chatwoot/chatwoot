<template>
  <div class="px-5 pb-5 responsive-container">
    <div class="flex items-center justify-between mb-4">
      <div
        class="max-w-xs"
        :class="$dm('text-black-700', 'dark:text-slate-50')"
      >
        <div class="text-base leading-5 font-medium mb-1">
          {{
            isOnline
              ? $t('TEAM_AVAILABILITY.ONLINE')
              : $t('TEAM_AVAILABILITY.OFFLINE')
          }}
        </div>
        <div class="text-xs leading-4 mt-1">
          {{ replyWaitMessage }}
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
      {{
        hasConversation ? $t('CONTINUE_CONVERSATION') : $t('START_CONVERSATION')
      }}
    </custom-button>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import { getContrastingTextColor } from '@chatwoot/utils';
import nextAvailabilityTime from 'widget/mixins/nextAvailabilityTime';
import AvailableAgents from 'widget/components/AvailableAgents.vue';
import CustomButton from 'shared/components/Button';
import configMixin from 'widget/mixins/configMixin';
import availabilityMixin from 'widget/mixins/availability';
import darkMixin from 'widget/mixins/darkModeMixin.js';

export default {
  name: 'TeamAvailability',
  components: {
    AvailableAgents,
    CustomButton,
  },
  mixins: [configMixin, nextAvailabilityTime, availabilityMixin, darkMixin],
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
      this.$emit('start-conversation');
    },
  },
};
</script>

<style scoped lang="scss">
@import '~widget/assets/scss/variables.scss';

.responsive-container {
  max-width: $break-point-tablet;
  margin: 0 auto;
  width: 100%;
}
</style>
