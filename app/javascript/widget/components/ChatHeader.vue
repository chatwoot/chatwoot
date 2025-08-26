<script>
import availabilityMixin from 'widget/mixins/availability';
import nextAvailabilityTime from 'widget/mixins/nextAvailabilityTime';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import HeaderActions from './HeaderActions.vue';
import routerMixin from 'widget/mixins/routerMixin';

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
    avatarName: {
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
    dealerName: {
      type: String,
      default: '',
    },
    dealerTagline: {
      type: String,
      default: '',
    },
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
  <header class="flex justify-between w-full p-5 bg-n-background gap-2">
    <div class="flex items-center">
      <button
        v-if="showBackButton"
        class="px-2 ltr:-ml-3 rtl:-mr-3"
        @click="onBackButtonClick"
      >
        <FluentIcon icon="chevron-left" size="24" class="text-n-slate-12" />
      </button>
      <div class="flex flex-col items-center ltr:mr-3 rtl:ml-3">
        <img
          v-if="avatarUrl"
          class="w-8 h-8 rounded-full"
          :src="avatarUrl"
          alt="avatar"
        />
        <div
          v-if="avatarName"
          class="font-semibold text-n-slate-11 dark:text-blue-300 text-xs mt-1"
        >
          {{ avatarName }}
        </div>
      </div>
      <div class="flex flex-col gap-1">
        <div
          class="flex items-center text-base font-medium leading-4 text-n-slate-12"
        >
          <span
            v-if="dealerName"
            class="font-semibold text-blue-700 dark:text-blue-300 ltr:mr-1 rtl:ml-1"
          >
            {{ dealerName }}
          </span>
          <span
            v-else
            v-dompurify-html="title"
            class="ltr:mr-1 rtl:ml-1"
          ></span>
          <div
            :class="`h-2 w-2 rounded-full
              ${isOnline ? 'bg-n-teal-10' : 'hidden'}`"
          />
        </div>

        <div v-if="dealerTagline" class="text-xs leading-3 text-n-slate-11">
          {{ dealerTagline }}
        </div>
        <div v-if="!dealerTagline" class="text-xs leading-3 text-n-slate-11">
          {{ replyWaitMessage }}
        </div>
      </div>
    </div>
    <HeaderActions :show-popout-button="showPopoutButton" />
  </header>
</template>
