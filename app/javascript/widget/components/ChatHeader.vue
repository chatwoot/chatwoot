<template>
  <header class="flex justify-between p-5 w-full">
    <div class="flex items-center">
      <button v-if="showBackButton" @click="onBackButtonClick">
        <fluent-icon icon="chevron-left" size="24" />
      </button>
      <img
        v-if="avatarUrl"
        class="h-8 w-8 rounded-full mr-3"
        :src="avatarUrl"
        alt="avatar"
      />
      <div>
        <div
          class="font-medium text-base flex items-center"
          :class="widgetTitleDarkMode"
        >
          <span class="mr-1" v-html="title" />
          <div
            :class="
              `h-2 w-2 rounded-full leading-4
              ${isOnline ? 'bg-green-500' : 'hidden'}`
            "
          />
        </div>
        <div class="text-xs mt-1" :class="waitMessageDarkMode">
          {{ replyWaitMessage }}
        </div>
      </div>
    </div>
    <header-actions :show-popout-button="showPopoutButton" />
  </header>
</template>

<script>
import { mapGetters } from 'vuex';

import availabilityMixin from 'widget/mixins/availability';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import HeaderActions from './HeaderActions';
import routerMixin from 'widget/mixins/routerMixin';
import isDarkOrWhiteOrAutoMode from 'widget/mixins/darkModeMixin.js';

export default {
  name: 'ChatHeader',
  components: {
    FluentIcon,
    HeaderActions,
  },
  mixins: [availabilityMixin, routerMixin, isDarkOrWhiteOrAutoMode],
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
    showBackButton: {
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
    widgetTitleDarkMode() {
      return this.isDarkOrWhiteOrAutoMode({
        dark: 'dark:text-slate-50',
        light: 'text-black-900',
      });
    },
    waitMessageDarkMode() {
      return this.isDarkOrWhiteOrAutoMode({
        dark: 'dark:text-slate-400',
        light: 'text-black-700',
      });
    },
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
      this.replaceRoute('home');
    },
  },
};
</script>
