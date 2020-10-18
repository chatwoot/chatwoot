<template>
  <div class="px-4">
    <div class="flex items-center justify-between mb-4">
      <div class="text-black-700">
        <div class="text-base leading-5 font-medium mb-1">
          {{ teamAvailabilityStatus }}
        </div>
        <div class="text-xs leading-4 mt-1">
          {{ replyTimeStatus }}
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
import teamAvailabilityMixin from 'widget/mixins/teamAvailabilityMixin';

export default {
  name: 'TeamAvailability',
  components: {
    AvailableAgents,
    WootButton,
  },
  mixins: [configMixin, teamAvailabilityMixin],
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
  },
  methods: {
    startConversation() {
      this.$emit('start-conversation');
    },
  },
};
</script>
