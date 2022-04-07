<template>
  <header
    class="flex justify-between p-5 w-full"
    :class="$dm('bg-white', 'dark:bg-slate-900')"
  >
    <div class="flex items-center">
      <button v-if="showBackButton" @click="onBackButtonClick">
        <fluent-icon
          icon="chevron-left"
          size="24"
          :class="$dm('text-black-900', 'dark:text-slate-50')"
        />
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
          :class="$dm('text-black-900', 'dark:text-slate-50')"
        >
          <span v-dompurify-html="title" class="mr-1" />
          <div
            :class="
              `h-2 w-2 rounded-full leading-4
              ${isOnline ? 'bg-green-500' : 'hidden'}`
            "
          />
        </div>
        <div
          class="text-xs mt-1"
          :class="$dm('text-black-700', 'dark:text-slate-400')"
        >
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
import darkMixin from 'widget/mixins/darkModeMixin.js';

export default {
  name: 'ChatHeader',
  components: {
    FluentIcon,
    HeaderActions,
  },
  mixins: [availabilityMixin, routerMixin, darkMixin],
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
