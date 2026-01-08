<script setup>
import { toRef } from 'vue';
import HeaderActions from './HeaderActions.vue';
import AvailabilityContainer from 'widget/components/Availability/AvailabilityContainer.vue';
import { useAvailability } from 'widget/composables/useAvailability';

const props = defineProps({
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
  availableAgents: {
    type: Array,
    default: () => [],
  },
  dealerName: {
    type: String,
    default: '',
  },
  dealerTagline: {
    type: String,
    default: '',
  },
});

const availableAgentsRef = toRef(props, 'availableAgents');
const { isOnline } = useAvailability(availableAgentsRef);
</script>

<template>
  <header class="flex justify-between w-full p-5 bg-n-background gap-2">
    <div class="flex items-center">
      <!-- <button
        v-if="showBackButton"
        class="px-2 ltr:-ml-3 rtl:-mr-3"
        @click="onBackButtonClick"
      >
        <FluentIcon icon="chevron-left" size="24" class="text-n-slate-12" />
      </button> -->
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
          <span v-else v-dompurify-html="title" class="ltr:mr-1 rtl:ml-1" />
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
        <AvailabilityContainer
          :agents="availableAgents"
          :show-header="false"
          :show-avatars="false"
          text-classes="text-xs leading-3"
        />
      </div>
    </div>
    <HeaderActions
      :show-popout-button="showPopoutButton"
      :show-end-conversation-button="showEndConversationButton"
    />
  </header>
</template>
