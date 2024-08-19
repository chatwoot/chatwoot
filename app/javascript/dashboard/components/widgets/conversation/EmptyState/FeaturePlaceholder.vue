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

<template>
  <div class="flex flex-col gap-2 mt-9">
    <div
      v-for="keyShortcut in keyShortcuts"
      :key="keyShortcut.key"
      class="flex items-center gap-2"
    >
      <div class="flex items-center gap-2">
        <Hotkey
          custom-class="w-8 h-6 text-sm font-medium border-b-2 text-slate-7000 dark:text-slate-100 bg-slate-100 dark:bg-slate-700 border-slate-300 dark:border-slate-500"
        >
          ⌘
        </Hotkey>
        <Hotkey
          custom-class="w-8 h-6 text-sm font-medium border-b-2 text-slate-700 dark:text-slate-100 bg-slate-100 dark:bg-slate-700 border-slate-300 dark:border-slate-500"
        >
          {{ keyShortcut.key }}
        </Hotkey>
      </div>
      <span
        class="text-sm font-medium text-center text-slate-700 dark:text-slate-300"
      >
        {{ keyShortcut.description }}
      </span>
    </div>
  </div>
</template>
