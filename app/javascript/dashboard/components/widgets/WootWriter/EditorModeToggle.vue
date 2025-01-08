<script setup>
import { computed } from 'vue';
import { REPLY_EDITOR_MODES } from './constants';

import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  mode: {
    type: String,
    default: REPLY_EDITOR_MODES.REPLY,
  },
});

defineEmits(['toggleMode']);

const isPrivate = computed(() => props.mode === REPLY_EDITOR_MODES.NOTE);
</script>

<template>
  <button
    class="flex items-center h-8 p-1 transition-all border rounded-full duration-600 bg-n-alpha-2 dark:bg-n-alpha-2 hover:bg-n-alpha-1 dark:hover:brightness-105 group relative transition-all duration-300 ease-in-out"
    :class="[
      isPrivate
        ? 'border-n-amber-12/10 dark:border-n-amber-3/30 w-[128px]'
        : 'border-n-weak dark:border-n-weak ',
    ]"
    @click="$emit('toggleMode')"
  >
    <div
      class="flex absolute items-center justify-center w-6 transition-all duration-200 rounded-full bg-n-alpha-black1 size-6 transition-all duration-300 ease-in-out"
      :class="[
        isPrivate
          ? 'ltr:translate-x-[94px] rtl:-translate-x-[94px]'
          : 'translate-x-0',
      ]"
    >
      <Icon
        :icon="
          isPrivate
            ? 'i-material-symbols-lock'
            : 'i-material-symbols-lock-open-rounded'
        "
        class="flex-shrink-0 size-3.5"
        :class="[
          isPrivate ? 'dark:text-n-amber-9 text-n-amber-11' : 'text-n-slate-10',
        ]"
      />
    </div>
    <span
      class="flex items-center text-sm font-medium transition-all duration-200 w-fit whitespace-nowrap"
      :class="[
        isPrivate
          ? 'text-n-amber-12 ltr:mr-7 ltr:ml-1.5 rtl:ml-7 rtl:mr-1.5'
          : 'text-n-slate-12 ltr:ml-7 ltr:mr-1.5 rtl:mr-7 rtl:ml-1.5',
      ]"
    >
      {{
        isPrivate
          ? $t('CONVERSATION.REPLYBOX.PRIVATE_NOTE')
          : $t('CONVERSATION.REPLYBOX.REPLY')
      }}
    </span>
  </button>
</template>
