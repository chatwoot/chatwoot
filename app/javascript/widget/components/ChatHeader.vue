<template>
  <header class="flex justify-between py-5 px-4 w-full box-border">
    <div class="flex align-middle">
      <header-back-button @click="onBackButtonClick" />
      <img
        v-if="avatarUrl"
        class="w-8 h-8 mr-3 rounded-full"
        :src="avatarUrl"
        alt="avatar"
      />
      <div>
        <h4 class="text-black-900 font-medium text-base flex items-center">
          <span class="mr-1" v-html="title" />
          <h4
            :class="
              `w-2 h-2 rounded-full leading-4 ${
                isOnline ? 'bg-green-500' : 'hidden'
              }`
            "
          />
        </h4>
        <div class="text-xs mt-1 text-black-700">
          {{ replyWaitMeessage }}
        </div>
      </div>
    </div>
    <header-actions :show-popout-button="showPopoutButton" />
  </header>
</template>

<script>
import { mapGetters } from 'vuex';

import HeaderBackButton from 'widget/components/HeaderBackButton';
import HeaderActions from './HeaderActions';
import availabilityMixin from 'widget/mixins/availability';

export default {
  name: 'ChatHeader',
  components: {
    HeaderActions,
    HeaderBackButton,
  },
  mixins: [availabilityMixin],
  props: {
    avatarUrl: {
      type: String,
      default: '',
    },
    title: {
      type: String,
      default: '',
    },
    showPopoutButton: {
      type: Boolean,
      default: false,
    },
    availableAgents: {
      type: Array,
      default: () => {},
    },
  },
  computed: {
    ...mapGetters({
      widgetColor: 'appConfig/getWidgetColor',
    }),
    isOnline() {
      const { workingHoursEnabled } = this.channelConfig;
      const anyAgentOnline = this.availableAgents.length > 0;

      if (workingHoursEnabled) {
        return this.isInBetweenTheWorkingHours;
      }
      return anyAgentOnline;
    },
    replyWaitMeessage() {
      return this.isOnline
        ? this.replyTimeStatus
        : this.$t('TEAM_AVAILABILITY.OFFLINE');
    },
  },
  methods: {
    onBackButtonClick() {
      this.$router.back();
    },
  },
};
</script>
