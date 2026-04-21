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
        ? 'bg-s-subtle dark:bg-s-surface px-4 py-5'
        : 'bg-s-subtle dark:bg-s-surface p-4'
    "
  >
    <div class="relative top-px">
      <div class="flex items-center justify-start">
        <img
          v-if="config.logo"
          :src="config.logo"
          class="mr-2 rounded-full logo"
          :class="!isDefaultScreen ? 'h-8 w-8 mb-1' : 'h-12 w-12 mb-2'"
        />
        <div v-if="!isDefaultScreen">
          <div class="flex items-center justify-start gap-1">
            <span class="text-base font-medium leading-3 text-s-primary">
              {{ config.websiteName }}
            </span>
            <div
              v-if="config.isOnline"
              class="w-2 h-2 bg-s-success rounded-full"
            />
          </div>
          <span class="mt-1 text-xs text-s-muted">
            {{ config.replyTime }}
          </span>
        </div>
      </div>
      <div v-if="isDefaultScreen" class="overflow-auto max-h-60">
        <h2 class="mb-2 text-2xl break-words text-s-primary">
          {{ config.welcomeHeading }}
        </h2>
        <p
          v-dompurify-html="formatMessage(config.welcomeTagline)"
          class="text-sm break-words text-s-muted [&_a]:!text-s-muted [&_a]:underline"
        />
      </div>
    </div>
  </div>
</template>
