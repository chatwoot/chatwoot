<script>
import availabilityMixin from 'widget/mixins/availability';
import nextAvailabilityTime from 'widget/mixins/nextAvailabilityTime';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import HeaderActions from './HeaderActions.vue';
import routerMixin from 'widget/mixins/routerMixin';
import { useDarkMode } from 'widget/composables/useDarkMode';

export default {
  name: 'ChatHeader',
  components: {
    FluentIcon,
    HeaderActions,
  },
  mixins: [nextAvailabilityTime, availabilityMixin, routerMixin],
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
  setup() {
    const { getThemeClass } = useDarkMode();
    return { getThemeClass };
  },
  computed: {
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

<template>
  <header
    class="flex justify-between w-full p-5"
    :class="getThemeClass('bg-white', 'dark:bg-slate-900')"
  >
    <div class="flex items-center">
      <button
        v-if="showBackButton"
        class="px-2 -ml-3"
        @click="onBackButtonClick"
      >
        <FluentIcon
          icon="chevron-left"
          size="24"
          :class="getThemeClass('text-black-900', 'dark:text-slate-50')"
        />
      </button>
      <img
        v-if="avatarUrl"
        class="w-8 h-8 mr-3 rounded-full"
        :src="avatarUrl"
        alt="avatar"
      />
      <div>
        <div
          class="flex items-center text-base font-medium leading-4"
          :class="getThemeClass('text-black-900', 'dark:text-slate-50')"
        >
          <span v-dompurify-html="title" class="mr-1" />
          <div
            :class="`h-2 w-2 rounded-full
              ${isOnline ? 'bg-green-500' : 'hidden'}`"
          />
        </div>
        <div
          class="mt-1 text-xs leading-3"
          :class="getThemeClass('text-black-700', 'dark:text-slate-400')"
        >
          {{ replyWaitMessage }}
        </div>
      </div>
    </div>
    <HeaderActions :show-popout-button="showPopoutButton" />
  </header>
</template>
