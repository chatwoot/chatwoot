<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useDetectKeyboardLayout } from 'dashboard/composables/useDetectKeyboardLayout';
import { SHORTCUT_KEYS, KEYS } from './constants';
import {
  LAYOUT_QWERTZ,
  keysToModifyInQWERTZ,
} from 'shared/helpers/KeyboardHelpers';
import Hotkey from 'dashboard/components/base/Hotkey.vue';

defineProps({ show: Boolean });
defineEmits(['close']);

const { t } = useI18n();
const currentLayout = ref(null);

const title = computed(
  () => item => t(`KEYBOARD_SHORTCUTS.TITLE.${item.label}`)
);

// Added this function to check if the keySet needs a shift key
// This is used to display the shift key in the modal
// If the current layout is QWERTZ and the keySet contains a key that needs a shift key
// If layout is QWERTZ then we add the Shift+keysToModify to fix an known issue
// https://github.com/chatwoot/chatwoot/issues/9492
const needsShiftKey = computed(
  () => keySet =>
    currentLayout.value === LAYOUT_QWERTZ &&
    keySet.some(key => keysToModifyInQWERTZ.has(key))
);

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
              {{ KEYS.WIN }}
            </Hotkey>
            <Hotkey custom-class="min-h-[28px] min-w-[36px] key">
              {{ KEYS.SLASH }}
            </Hotkey>
          </div>
        </div>
      </div>

      <div class="grid grid-cols-2 px-8 pt-0 pb-8 gap-x-5 gap-y-3">
        <div
          v-for="shortcut in SHORTCUT_KEYS"
          :key="shortcut.id"
          class="flex justify-between items-center min-w-[25rem]"
        >
          <h5 class="text-sm text-slate-800 min-w-[36px] dark:text-slate-100">
            {{ title(shortcut) }}
          </h5>
          <div class="flex items-center gap-2 mb-1 ml-2">
            <template v-if="needsShiftKey(shortcut.keySet)">
              <Hotkey custom-class="min-h-[28px] min-w-[36px] key">
                {{ KEYS.SHIFT }}
              </Hotkey>
            </template>

            <template v-for="(key, index) in shortcut.displayKeys" :key="index">
              <template v-if="key !== KEYS.SLASH">
                <Hotkey
                  custom-class="min-h-[28px] min-w-[36px] key normal-case"
                >
                  {{ key }}
                </Hotkey>
              </template>
              <span
                v-else
                class="flex items-center text-sm font-semibold text-slate-800 dark:text-slate-100"
              >
                {{ key }}
              </span>
            </template>
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
