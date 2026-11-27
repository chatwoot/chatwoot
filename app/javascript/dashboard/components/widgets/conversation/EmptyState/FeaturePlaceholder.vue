<script>
import Hotkey from 'dashboard/components/base/Hotkey.vue';

export default {
  components: {
    Hotkey,
  },
  props: {
    compact: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      commandKey: '⌘',
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
  <div
    v-if="compact"
    class="flex flex-wrap items-center justify-center gap-x-5 gap-y-1.5 mt-8"
  >
    <div
      v-for="keyShortcut in keyShortcuts"
      :key="keyShortcut.key"
      class="flex items-center gap-1.5 text-xs text-n-slate-10"
    >
      <Hotkey
        custom-class="h-5 px-1.5 gap-0.5 text-xs text-n-slate-11 outline outline-1 outline-n-weak bg-n-alpha-1"
      >
        <span class="text-sm">{{ commandKey }}</span>
        {{ keyShortcut.key }}
      </Hotkey>
      {{ keyShortcut.description }}
    </div>
  </div>
  <div v-else class="flex flex-col gap-2 mt-9">
    <div
      v-for="keyShortcut in keyShortcuts"
      :key="keyShortcut.key"
      class="flex items-center gap-2"
    >
      <div class="flex items-center gap-2">
        <Hotkey
          custom-class="w-8 h-6 text-lg font-medium text-n-slate-12 outline outline-n-container outline-1 bg-n-alpha-3"
        >
          {{ commandKey }}
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
