<script>
import EmptyStateCopilot from './EmptyStateCopilot.vue';
import FeaturePlaceholder from './FeaturePlaceholder.vue';

export default {
  components: { EmptyStateCopilot, FeaturePlaceholder },
  props: {
    message: {
      type: String,
      required: true,
    },
    showAskBar: {
      type: Boolean,
      default: false,
    },
  },
};
</script>

<template>
  <div class="flex flex-col items-center justify-center w-full h-full">
    <EmptyStateCopilot v-if="showAskBar" :message="message" />
    <template v-else>
      <img
        class="m-4 w-32 hidden dark:block"
        src="dashboard/assets/images/no-chat-dark.svg"
        alt="No Chat dark"
      />
      <img
        class="m-4 w-32 block dark:hidden"
        src="dashboard/assets/images/no-chat.svg"
        alt="No Chat"
      />
      <span class="text-sm text-n-slate-12 font-medium text-center">
        {{ message }}
        <br />
      </span>
    </template>
    <!-- Cmd bar, keyboard shortcuts placeholder -->
    <FeaturePlaceholder :compact="showAskBar" />
  </div>
</template>
