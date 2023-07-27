<template>
  <woot-modal :show="show" size="medium" :on-close="() => $emit('close')">
    <div class="h-auto overflow-auto flex flex-col">
      <woot-modal-header
        :header-title="$t('SIDEBAR_ITEMS.KEYBOARD_SHORTCUTS')"
      />
      <div class="grid grid-cols-2 gap-x-5 gap-y-3 pt-0 px-8 pb-8 mt-6">
        <div class="flex justify-between items-center min-w-[25rem]">
          <h5 class="text-sm text-slate-800 dark:text-slate-100">
            {{ $t('KEYBOARD_SHORTCUTS.TOGGLE_MODAL') }}
          </h5>
          <div class="flex items-center mb-1 ml-2">
            <p
              class="shortcut-key items-center rounded-md mr-2 py-2 px-2.5 bg-white dark:bg-slate-900 text-slate-800 dark:text-slate-100 font-semibold text-xs"
            >
              {{ $t('KEYBOARD_SHORTCUTS.KEYS.WINDOWS_KEY_AND_COMMAND_KEY') }}
            </p>
            <p
              class="shortcut-key items-center rounded-md mr-2 py-2 px-2.5 bg-white dark:bg-slate-900 text-slate-800 dark:text-slate-100 font-semibold text-xs flex justify-center min-w-[2rem] rtl:mr-0 rtl:ml-2"
            >
              {{ $t('KEYBOARD_SHORTCUTS.KEYS.FORWARD_SLASH_KEY') }}
            </p>
          </div>
        </div>
      </div>

      <div class="grid grid-cols-2 gap-x-5 gap-y-3 pt-0 px-8 pb-8">
        <div class="flex justify-between items-center min-w-[25rem]">
          <h5 class="text-sm text-slate-800 dark:text-slate-100">
            {{ $t('KEYBOARD_SHORTCUTS.TITLE.OPEN_CONVERSATION') }}
          </h5>
          <div class="flex items-center mb-1 ml-2">
            <div class="flex mr-2">
              <span
                class="items-center rounded-md mr-2 py-2 px-2.5 bg-white dark:bg-slate-900 text-slate-800 dark:text-slate-100 font-semibold text-xs"
              >
                {{ $t('KEYBOARD_SHORTCUTS.KEYS.ALT_OR_OPTION_KEY') }}
              </span>
              <span
                class="items-center rounded-md mr-2 py-2 px-2.5 bg-white dark:bg-slate-900 text-slate-800 dark:text-slate-100 font-semibold text-xs"
              >
                J
              </span>
              <span
                class="flex items-center font-semibold text-sm text-slate-800 dark:text-slate-100"
              >
                {{ $t('KEYBOARD_SHORTCUTS.KEYS.FORWARD_SLASH_KEY') }}
              </span>
            </div>
            <span
              class="items-center rounded-md mr-2 py-2 px-2.5 bg-white dark:bg-slate-900 text-slate-800 dark:text-slate-100 font-semibold text-xs"
            >
              {{ $t('KEYBOARD_SHORTCUTS.KEYS.ALT_OR_OPTION_KEY') }}
            </span>
            <span
              class="items-center rounded-md mr-2 py-2 px-2.5 bg-white dark:bg-slate-900 text-slate-800 dark:text-slate-100 font-semibold text-xs flex justify-center min-w-[2rem] rtl:mr-0 rtl:ml-2"
            >
              K
            </span>
          </div>
        </div>

        <div class="flex justify-between items-center min-w-[25rem]">
          <h5 class="text-sm text-slate-800 dark:text-slate-100">
            {{ $t('KEYBOARD_SHORTCUTS.TITLE.RESOLVE_AND_NEXT') }}
          </h5>
          <div class="flex items-center mb-1 ml-2">
            <span
              class="items-center rounded-md mr-2 py-2 px-2.5 bg-white dark:bg-slate-900 text-slate-800 dark:text-slate-100 font-semibold text-xs"
            >
              {{ $t('KEYBOARD_SHORTCUTS.KEYS.WINDOWS_KEY_AND_COMMAND_KEY') }}
            </span>
            <span
              class="items-center rounded-md mr-2 py-2 px-2.5 bg-white dark:bg-slate-900 text-slate-800 dark:text-slate-100 font-semibold text-xs"
            >
              {{ $t('KEYBOARD_SHORTCUTS.KEYS.ALT_OR_OPTION_KEY') }}
            </span>
            <span
              class="items-center rounded-md mr-2 py-2 px-2.5 bg-white dark:bg-slate-900 text-slate-800 dark:text-slate-100 font-semibold text-xs flex justify-center min-w-[2rem] rtl:mr-0 rtl:ml-2"
            >
              E
            </span>
          </div>
        </div>
        <div
          v-for="shortcutKey in shortcutKeys"
          :key="shortcutKey.id"
          class="flex justify-between items-center min-w-[25rem]"
        >
          <h5 class="text-sm text-slate-800 dark:text-slate-100">
            {{ title(shortcutKey) }}
          </h5>
          <div class="flex items-center mb-1 ml-2">
            <span
              class="items-center rounded-md mr-2 py-2 px-2.5 bg-white dark:bg-slate-900 text-slate-800 dark:text-slate-100 font-semibold text-xs"
            >
              {{ shortcutKey.firstkey }}
            </span>
            <span
              class="items-center rounded-md mr-2 py-2 px-2.5 bg-white dark:bg-slate-900 text-slate-800 dark:text-slate-100 font-semibold text-xs flex justify-center min-w-[2rem] rtl:mr-0 rtl:ml-2"
            >
              {{ shortcutKey.secondKey }}
            </span>
          </div>
        </div>
      </div>
    </div>
  </woot-modal>
</template>

<script>
import { mixin as clickaway } from 'vue-clickaway';
import { SHORTCUT_KEYS } from './constants';

export default {
  mixins: [clickaway],
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
<style lang="scss" scoped>
.shortcut-key {
  @apply py-2 px-2.5;
}
</style>
