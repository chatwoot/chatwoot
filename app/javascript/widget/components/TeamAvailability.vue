<template>
  <div class="px-4">
    <div class="flex items-center justify-between mb-4">
      <div>
        <div class="text-base leading-5 text-black-700 font-medium mb-1">
          {{ teamAvailabilityStatus }}
        </div>
        <div class="text-xs leading-4 text-black-700">
          The team typically replies in a few minutes
        </div>
      </div>
      <available-agents :agents="availableAgents" />
    </div>
    <woot-button block :bg-color="widgetColor" :text-color="textColor">
      {{ $t('START_CONVERSATION') }}
    </woot-button>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import AvailableAgents from 'widget/components/AvailableAgents.vue';
import { getContrastingTextColor } from 'shared/helpers/ColorHelper';
import WootButton from 'shared/components/Button';
export default {
  name: 'TeamAvailability',
  components: {
    AvailableAgents,
    WootButton,
  },
  props: {
    availableAgents: {
      type: Array,
      default: () => {},
    },
  },
  computed: {
    ...mapGetters({
      widgetColor: 'appConfig/getWidgetColor',
    }),
    textColor() {
      return getContrastingTextColor(this.widgetColor);
    },
    teamAvailabilityStatus() {
      if (this.availableAgents.length) {
        return this.$t('TEAM_AVAILABILITY.ONLINE');
      }
      return this.$t('TEAM_AVAILABILITY.OFFLINE');
    },
  },
};
</script>
