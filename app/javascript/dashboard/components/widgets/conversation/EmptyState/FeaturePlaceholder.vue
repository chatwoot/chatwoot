<template>
  <div class="flex flex-col gap-2 mt-9">
    <div
      v-for="keyShortcut in keyShortcuts"
      :key="keyShortcut.key"
      class="flex gap-2 items-center"
    >
      <div class="flex gap-2 items-center">
        <hotkey
          custom-class="h-6 w-8 text-sm font-medium text-slate-700 dark:text-slate-100 bg-slate-100 dark:bg-slate-700 border-b-2 border-slate-300 dark:border-slate-500"
        >
          ⌘
        </hotkey>
        <hotkey
          custom-class="h-6 w-8 text-sm font-medium text-slate-700 dark:text-slate-100 bg-slate-100 dark:bg-slate-700 border-b-2 border-slate-300 dark:border-slate-500"
        >
          {{ keyShortcut.key }}
        </hotkey>
      </div>
      <span
        class="text-sm text-slate-700 dark:text-slate-300 font-medium text-center"
      >
        {{ keyShortcut.description }}
      </span>
    </div>
  </div>
</template>

<script>
import Hotkey from 'dashboard/components/base/Hotkey.vue';

export default {
  components: {
    Hotkey,
  },
  data() {
    return {
      keyShortcuts: [
        {
          key: 'K',
          description: this.$t('CONVERSATION.EMPTY_STATE.CMD_BAR'),
        },
        {
          key: '/',
          description: this.$t('CONVERSATION.EMPTY_STATE.KEYBOARD_SHORTCUTS'),
        },
      ],
    };
  },
};
</script>
