<template>
  <woot-modal :show="show" size="medium" :on-close="() => $emit('close')">
    <div class="h-auto overflow-auto flex flex-col">
      <woot-modal-header
        :header-title="$t('SIDEBAR_ITEMS.KEYBOARD_SHORTCUTS')"
      />
      <div class="grid grid-cols-2 gap-x-5 gap-y-3 pt-0 px-8 pb-4 mt-6">
        <div class="flex justify-between items-center min-w-[25rem]">
          <h5 class="text-sm text-slate-800 dark:text-slate-100">
            {{ $t('KEYBOARD_SHORTCUTS.TOGGLE_MODAL') }}
          </h5>
          <div class="flex items-center mb-1 ml-2 gap-2">
            <hotkey custom-class="min-h-[28px] min-w-[60px] normal-case key">
              {{ $t('KEYBOARD_SHORTCUTS.KEYS.WINDOWS_KEY_AND_COMMAND_KEY') }}
            </hotkey>
            <hotkey custom-class="min-h-[28px] min-w-[36px] key">
              {{ $t('KEYBOARD_SHORTCUTS.KEYS.FORWARD_SLASH_KEY') }}
            </hotkey>
          </div>
        </div>
      </div>

      <div class="grid grid-cols-2 gap-x-5 gap-y-3 pt-0 px-8 pb-8">
        <div class="flex justify-between items-center min-w-[25rem]">
          <h5 class="text-sm text-slate-800 dark:text-slate-100">
            {{ $t('KEYBOARD_SHORTCUTS.TITLE.OPEN_CONVERSATION') }}
          </h5>
          <div class="flex items-center mb-1 ml-2 gap-2">
            <div class="flex gap-2">
              <hotkey custom-class="min-h-[28px] min-w-[60px] normal-case key">
                {{ $t('KEYBOARD_SHORTCUTS.KEYS.ALT_OR_OPTION_KEY') }}
              </hotkey>
              <hotkey custom-class="min-h-[28px] w-9 key"> J </hotkey>
              <span
                class="flex items-center font-semibold text-sm text-slate-800 dark:text-slate-100"
              >
                {{ $t('KEYBOARD_SHORTCUTS.KEYS.FORWARD_SLASH_KEY') }}
              </span>
            </div>
            <hotkey custom-class="min-h-[28px] min-w-[60px] normal-case key">
              {{ $t('KEYBOARD_SHORTCUTS.KEYS.ALT_OR_OPTION_KEY') }}
            </hotkey>
            <hotkey custom-class="w-9 key"> K </hotkey>
          </div>
        </div>

        <div class="flex justify-between items-center min-w-[25rem]">
          <h5 class="text-sm text-slate-800 dark:text-slate-100">
            {{ $t('KEYBOARD_SHORTCUTS.TITLE.RESOLVE_AND_NEXT') }}
          </h5>
          <div class="flex items-center mb-1 ml-2 gap-2">
            <hotkey custom-class="min-h-[28px] min-w-[60px] normal-case key">
              {{ $t('KEYBOARD_SHORTCUTS.KEYS.WINDOWS_KEY_AND_COMMAND_KEY') }}
            </hotkey>
            <hotkey custom-class="min-h-[28px] min-w-[60px] normal-case key">
              {{ $t('KEYBOARD_SHORTCUTS.KEYS.ALT_OR_OPTION_KEY') }}
            </hotkey>
            <hotkey custom-class="w-9 key"> E </hotkey>
          </div>
        </div>
        <div
          v-for="shortcutKey in shortcutKeys"
          :key="shortcutKey.id"
          class="flex justify-between items-center min-w-[25rem]"
        >
          <h5 class="text-sm text-slate-800 min-w-[36px] dark:text-slate-100">
            {{ title(shortcutKey) }}
          </h5>
          <div class="flex items-center mb-1 ml-2 gap-2">
            <hotkey
              :class="{ 'min-w-[60px]': shortcutKey.firstKey !== 'Up' }"
              custom-class="min-h-[28px] normal-case key"
            >
              {{ shortcutKey.firstKey }}
            </hotkey>
            <hotkey
              :class="{ 'normal-case': shortcutKey.secondKey === 'Down' }"
              custom-class="min-h-[28px] min-w-[36px] key"
            >
              {{ shortcutKey.secondKey }}
            </hotkey>
          </div>
        </div>
      </div>
    </div>
  </woot-modal>
</template>

<script>
import { SHORTCUT_KEYS } from './constants';
import Hotkey from 'dashboard/components/base/Hotkey.vue';

export default {
  components: {
    Hotkey,
  },
  props: {
    show: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      shortcutKeys: SHORTCUT_KEYS,
    };
  },
  methods: {
    title(item) {
      return this.$t(`KEYBOARD_SHORTCUTS.TITLE.${item.label}`);
    },
  },
};
</script>
<style scoped>
.key {
  @apply py-2 px-2.5 font-semibold text-xs text-slate-700 dark:text-slate-100 bg-slate-75 dark:bg-slate-900 shadow border-b-2 rtl:border-l-2 ltr:border-r-2 border-slate-200 dark:border-slate-700;
}
</style>
