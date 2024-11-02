<script setup>
import { ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useDetectKeyboardLayout } from 'dashboard/composables/useDetectKeyboardLayout';
import { SHORTCUT_KEYS } from './constants';
import {
  LAYOUT_QWERTZ,
  keysToModifyInQWERTZ,
} from 'shared/helpers/KeyboardHelpers';
import Hotkey from 'dashboard/components/base/Hotkey.vue';

defineProps({
  show: {
    type: Boolean,
    default: false,
  },
});

defineEmits(['close']);

const { t } = useI18n();

const shortcutKeys = SHORTCUT_KEYS;
const currentLayout = ref(null);

const title = item => t(`KEYBOARD_SHORTCUTS.TITLE.${item.label}`);

// Added this function to check if the keySet needs a shift key
// This is used to display the shift key in the modal
// If the current layout is QWERTZ and the keySet contains a key that needs a shift key
// If layout is QWERTZ then we add the Shift+keysToModify to fix an known issue
// https://github.com/chatwoot/chatwoot/issues/9492
const needsShiftKey = keySet => {
  return (
    currentLayout.value === LAYOUT_QWERTZ &&
    keySet.some(key => keysToModifyInQWERTZ.has(key))
  );
};

onMounted(async () => {
  currentLayout.value = await useDetectKeyboardLayout();
});
</script>

<template>
  <woot-modal :show="show" size="medium" :on-close="() => $emit('close')">
    <div class="flex flex-col h-auto overflow-auto">
      <woot-modal-header
        :header-title="$t('SIDEBAR_ITEMS.KEYBOARD_SHORTCUTS')"
      />
      <div class="grid grid-cols-2 px-8 pt-0 pb-4 mt-6 gap-x-5 gap-y-3">
        <div class="flex justify-between items-center min-w-[25rem]">
          <h5 class="text-sm text-slate-800 dark:text-slate-100">
            {{ $t('KEYBOARD_SHORTCUTS.TOGGLE_MODAL') }}
          </h5>
          <div class="flex items-center gap-2 mb-1 ml-2">
            <Hotkey custom-class="min-h-[28px] min-w-[60px] normal-case key">
              {{ $t('KEYBOARD_SHORTCUTS.KEYS.WINDOWS_KEY_AND_COMMAND_KEY') }}
            </Hotkey>
            <Hotkey custom-class="min-h-[28px] min-w-[36px] key">
              {{ $t('KEYBOARD_SHORTCUTS.KEYS.FORWARD_SLASH_KEY') }}
            </Hotkey>
          </div>
        </div>
      </div>

      <div class="grid grid-cols-2 px-8 pt-0 pb-8 gap-x-5 gap-y-3">
        <div class="flex justify-between items-center min-w-[25rem]">
          <h5 class="text-sm text-slate-800 dark:text-slate-100">
            {{ $t('KEYBOARD_SHORTCUTS.TITLE.OPEN_CONVERSATION') }}
          </h5>
          <div class="flex items-center gap-2 mb-1 ml-2">
            <div class="flex gap-2">
              <Hotkey custom-class="min-h-[28px] min-w-[60px] normal-case key">
                {{ $t('KEYBOARD_SHORTCUTS.KEYS.ALT_OR_OPTION_KEY') }}
              </Hotkey>
              <Hotkey custom-class="min-h-[28px] w-9 key"> {{ 'J' }} </Hotkey>
              <span
                class="flex items-center text-sm font-semibold text-slate-800 dark:text-slate-100"
              >
                {{ $t('KEYBOARD_SHORTCUTS.KEYS.FORWARD_SLASH_KEY') }}
              </span>
            </div>
            <Hotkey custom-class="min-h-[28px] min-w-[60px] normal-case key">
              {{ $t('KEYBOARD_SHORTCUTS.KEYS.ALT_OR_OPTION_KEY') }}
            </Hotkey>
            <Hotkey custom-class="w-9 key"> {{ 'K' }} </Hotkey>
          </div>
        </div>

        <div class="flex justify-between items-center min-w-[25rem]">
          <h5 class="text-sm text-slate-800 dark:text-slate-100">
            {{ $t('KEYBOARD_SHORTCUTS.TITLE.RESOLVE_AND_NEXT') }}
          </h5>
          <div class="flex items-center gap-2 mb-1 ml-2">
            <Hotkey custom-class="min-h-[28px] min-w-[60px] normal-case key">
              {{ $t('KEYBOARD_SHORTCUTS.KEYS.WINDOWS_KEY_AND_COMMAND_KEY') }}
            </Hotkey>
            <Hotkey custom-class="min-h-[28px] min-w-[60px] normal-case key">
              {{ $t('KEYBOARD_SHORTCUTS.KEYS.ALT_OR_OPTION_KEY') }}
            </Hotkey>
            <Hotkey custom-class="w-9 key"> {{ 'E' }} </Hotkey>
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
          <div class="flex items-center gap-2 mb-1 ml-2">
            <Hotkey
              v-if="needsShiftKey(shortcutKey.keySet)"
              custom-class="min-h-[28px] min-w-[36px] key"
            >
              {{ 'Shift' }}
            </Hotkey>
            <Hotkey
              :class="{ 'min-w-[60px]': shortcutKey.firstKey !== 'Up' }"
              custom-class="min-h-[28px] normal-case key"
            >
              {{ shortcutKey.firstKey }}
            </Hotkey>
            <Hotkey
              :class="{ 'normal-case': shortcutKey.secondKey === 'Down' }"
              custom-class="min-h-[28px] min-w-[36px] key"
            >
              {{ shortcutKey.secondKey }}
            </Hotkey>
          </div>
        </div>
      </div>
    </div>
  </woot-modal>
</template>

<style scoped>
.key {
  @apply py-2 px-2.5 font-semibold text-xs text-slate-700 dark:text-slate-100 bg-slate-75 dark:bg-slate-900 shadow border-b-2 rtl:border-l-2 ltr:border-r-2 border-slate-200 dark:border-slate-700;
}
</style>
