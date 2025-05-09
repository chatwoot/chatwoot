<template>
  <header
    class="flex justify-between py-3 px-5 w-full"
    :style="{ backgroundColor: color }"
  >
    <div class="flex items-center gap-3">
      <button
        v-if="showBackButton"
        class="shadow-md rounded-lg flex h-7 w-7 justify-center items-center"
        :style="{ color: 'var(--text-color)' }"
        @click="onBackButtonClick"
      >
        <fluent-icon icon="chevron-left" size="24" />
      </button>
      <img
        v-if="avatarUrl"
        class="h-8 w-8 rounded-[4px]"
        :src="avatarUrl"
        alt="avatar"
      />
      <div>
        <div
          class="font-medium text-base leading-4 flex items-center"
          :style="{ color: 'var(--text-color)' }"
        >
          <span
            v-dompurify-html="title"
            class="mr-1 text-sm leading-5 font-bold"
          />
          <div
            :class="`h-2 w-2 rounded-full
              ${isOnline ? 'bg-green-500' : 'hidden'}`"
          />
        </div>
        <div
          class="text-[11px] leading-3"
          :style="{ color: 'var(--text-color)' }"
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
import nextAvailabilityTime from 'widget/mixins/nextAvailabilityTime';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import HeaderActions from './HeaderActions.vue';
import routerMixin from 'widget/mixins/routerMixin';
import darkMixin from 'widget/mixins/darkModeMixin.js';

export default {
  name: 'ChatHeader',
  components: {
    FluentIcon,
    HeaderActions,
  },
  mixins: [nextAvailabilityTime, availabilityMixin, routerMixin, darkMixin],
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
    color: {
      type: String,
      default: '',
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
  },
  methods: {
    onBackButtonClick() {
      this.replaceRoute('home');
    },
  },
};
</script>
