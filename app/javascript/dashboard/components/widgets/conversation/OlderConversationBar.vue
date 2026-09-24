<script setup>
import Icon from 'dashboard/components-next/icon/Icon.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

defineProps({
  hasLatest: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['reply', 'goToLatest']);
</script>

<template>
  <div
    class="flex items-center h-11 text-sm border rounded-xl border-n-weak bg-n-alpha-1 backdrop-blur-md text-n-slate-11"
  >
    <button
      type="button"
      class="flex items-center flex-1 min-w-0 h-full gap-2 px-4 text-start transition-colors hover:text-n-slate-12 focus-visible:outline-none focus-visible:text-n-slate-12"
      @click="emit('reply')"
    >
      <Icon icon="i-lucide-pen-line" class="flex-shrink-0 size-4" />
      <span class="min-w-0 truncate">
        {{ $t('CONVERSATION.CONTACT_HISTORY.REPLY_TO_OLDER') }}
      </span>
    </button>
    <NextButton
      v-if="hasLatest"
      :label="$t('CONVERSATION.CONTACT_HISTORY.GO_TO_LATEST')"
      icon="i-lucide-chevrons-up"
      link
      xs
      class="flex-shrink-0 me-4 whitespace-nowrap"
      @click="emit('goToLatest')"
    />
  </div>
</template>
