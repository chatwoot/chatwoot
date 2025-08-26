<script setup>
import { computed } from 'vue';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';

const props = defineProps({
  config: {
    type: Object,
    default: () => ({}),
  },
});

const { formatMessage } = useMessageFormatter();

const isDefaultScreen = computed(() => {
  return (
    props.config.isDefaultScreen &&
    ((props.config.welcomeHeading &&
      props.config.welcomeHeading.length !== 0) ||
      (props.config.welcomeTagLine && props.config.welcomeTagline.length !== 0))
  );
});
</script>

<template>
  <div
    class="rounded-t-lg flex-shrink-0 transition-[max-height] duration-300"
    :class="
      isDefaultScreen
        ? 'bg-n-slate-2 dark:bg-n-solid-1 px-4 py-5'
        : 'bg-n-slate-2 dark:bg-n-solid-1 p-4'
    "
  >
    <div class="relative top-px">
      <div class="flex items-start justify-start">
        <div
          v-if="config.logo"
          class="flex flex-col items-center mr-2"
        >
          <img
            :src="config.logo"
            class="rounded-full logo"
            :class="!isDefaultScreen ? 'h-8 w-8 mb-1' : 'h-12 w-12 mb-2'"
          />
          <div
            v-if="config.avatarName"
            class="text-xs text-slate-500 dark:text-slate-300 text-center"
          >
            {{ config.avatarName }}
          </div>
        </div>

        <div v-if="!isDefaultScreen" class="flex flex-col">
          <div class="flex items-center justify-start gap-1">
            <span
              v-if="config.dealerName"
              class="font-semibold dark:text-blue-300 text-base"
            >
              {{ config.dealerName }}
            </span>
            <span
              v-else
              class="text-base font-medium leading-3 text-slate-900 dark:text-white"
            >
              {{ config.websiteName }}
            </span>
            <div
              v-if="config.isOnline"
              class="w-2 h-2 bg-green-500 rounded-full"
            ></div>
          </div>

          <span
            v-if="!config.dealerTagline"
            class="mt-1 text-xs text-slate-600 dark:text-slate-400"
          >
            {{ config.replyTime }}
          </span>
          <span
            v-else
            class="text-xs text-blue-500 dark:text-blue-200 mb-1"
          >
            {{ config.dealerTagline }}
        </span>
        </div>
      </div>

      <div v-if="isDefaultScreen" class="overflow-auto max-h-60">
        <h2 class="mb-2 text-2xl break-words text-n-slate-12">
          {{ config.welcomeHeading }}
        </h2>
        <p
          v-dompurify-html="formatMessage(config.welcomeTagline)"
          class="text-sm break-words text-n-slate-11 [&_a]:!text-n-slate-11 [&_a]:underline"
        />
      </div>
    </div>
  </div>
</template>
