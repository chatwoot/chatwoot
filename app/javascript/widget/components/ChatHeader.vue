<template>
  <header class="flex justify-between px-4 py-5 w-full">
    <div class="flex items-center">
      <svg
        width="24"
        height="24"
        fill="none"
        viewBox="0 0 24 24"
        xmlns="http://www.w3.org/2000/svg"
        class="mr-2 cursor-pointer"
        @click="onBackButtonClick"
      >
        <path
          d="M15.707 4.293a1 1 0 0 1 0 1.414L9.414 12l6.293 6.293a1 1 0 0 1-1.414 1.414l-7-7a1 1 0 0 1 0-1.414l7-7a1 1 0 0 1 1.414 0Z"
          fill="#212121"
        />
      </svg>
      <img
        v-if="avatarUrl"
        class="h-8 w-8 rounded-full mr-3"
        :src="avatarUrl"
        alt="avatar"
      />
      <div>
        <div class="text-black-900 font-medium text-base flex items-center">
          <span class="mr-1" v-html="title" />
          <div
            :class="
              `h-2 w-2 rounded-full leading-4
              ${isOnline ? 'bg-green-500' : 'hidden'}`
            "
          />
        </div>
        <div class="text-xs mt-1 text-black-700">
          {{ replyWaitMessage }}
        </div>
      </div>
    </div>
    <header-actions :show-popout-button="showPopoutButton" />
  </header>
</template>

<script>
import { mapGetters } from 'vuex';
import HeaderActions from './HeaderActions';
import availabilityMixin from 'widget/mixins/availability';

export default {
  name: 'ChatHeader',
  components: {
    HeaderActions,
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
    replyWaitMessage() {
      return this.isOnline
        ? this.replyTimeStatus
        : this.$t('TEAM_AVAILABILITY.OFFLINE');
    },
  },
  methods: {
    onBackButtonClick() {
      this.$router.replace({ name: 'home' });
    },
  },
};
</script>
