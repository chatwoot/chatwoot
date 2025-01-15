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
          custom-class="w-8 h-6 text-lg font-medium text-n-slate-12 outline outline-n-container outline-1 bg-n-alpha-3"
        >
          ⌘
        </Hotkey>
        <Hotkey
          custom-class="w-8 h-6 text-xs font-medium text-n-slate-12 outline outline-n-container outline-1 bg-n-alpha-3"
        >
          {{ keyShortcut.key }}
        </Hotkey>
      </div>
      <span class="text-sm font-medium text-center text-n-slate-12">
        {{ keyShortcut.description }}
      </span>
    </div>
  </div>
</template>
