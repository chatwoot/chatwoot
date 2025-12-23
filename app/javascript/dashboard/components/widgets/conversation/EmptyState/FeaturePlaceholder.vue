<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import Hotkey from 'dashboard/components/base/Hotkey.vue';

const { t } = useI18n();

const keyShortcuts = computed(() => [
  {
    key: 'K',
    description: t('CONVERSATION.EMPTY_STATE.CMD_BAR'),
  },
  {
    key: '/',
    description: t('CONVERSATION.EMPTY_STATE.KEYBOARD_SHORTCUTS'),
  },
]);
</script>

<template>
  <div class="flex xl:flex-row flex-col items-center gap-3 mt-9">
    <template
      v-for="(keyShortcut, index) in keyShortcuts"
      :key="keyShortcut.key"
    >
      <div class="flex items-center gap-2">
        <div class="flex items-center gap-2">
          <Hotkey custom-class="!text-lg"> ⌘ </Hotkey>
          <Hotkey>
            {{ keyShortcut.key }}
          </Hotkey>
        </div>
        <span class="text-sm font-420 text-center text-n-slate-11">
          {{ keyShortcut.description }}
        </span>
      </div>
      <div
        v-if="index < keyShortcuts.length - 1"
        class="xl:block hidden w-px h-4 rounded-lg bg-n-strong ltr:ml-1 ltr:mr-2 rtl:mr-1 rtl:ml-2"
      />
    </template>
  </div>
</template>
