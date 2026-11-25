<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store.js';
import { useAssistantSwitcher } from './useAssistantSwitcher';

import Button from 'dashboard/components-next/button/Button.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';

const emit = defineEmits(['close', 'createAssistant']);

const { t } = useI18n();
const route = useRoute();
const { switchAssistant } = useAssistantSwitcher();

const assistants = useMapGetter('captainAssistants/getRecords');

const currentAssistantId = computed(() => route.params.assistantId);

const isAssistantActive = assistant => {
  return assistant.id === Number(currentAssistantId.value);
};

const handleAssistantChange = async assistant => {
  if (isAssistantActive(assistant)) return;

  await switchAssistant(assistant);

  emit('close');
};

const openCreateAssistantDialog = () => {
  emit('createAssistant');
  emit('close');
};
</script>

<template>
  <div
    class="pt-5 bg-n-alpha-3 backdrop-blur-[100px] outline outline-n-container outline-1 z-50 absolute w-[27.5rem] max-h-96 rounded-xl shadow-md flex flex-col gap-4"
  >
    <div
      class="flex items-center justify-between gap-4 px-6 pb-3 border-b border-n-alpha-2"
    >
      <div class="flex flex-col gap-1">
        <div class="flex items-center gap-2">
          <h2
            class="text-base font-medium cursor-pointer text-n-slate-12 w-fit hover:underline"
          >
            {{ t('CAPTAIN.ASSISTANT_SWITCHER.ASSISTANTS') }}
          </h2>
        </div>
        <p class="text-sm text-n-slate-11">
          {{ t('CAPTAIN.ASSISTANT_SWITCHER.SWITCH_ASSISTANT') }}
        </p>
      </div>
      <Button
        :label="t('CAPTAIN.ASSISTANT_SWITCHER.NEW_ASSISTANT')"
        color="slate"
        icon="i-lucide-plus"
        size="sm"
        class="!bg-n-alpha-2 hover:!bg-n-alpha-3"
        @click="openCreateAssistantDialog"
      />
    </div>
    <div
      v-if="assistants.length > 0"
      class="flex flex-col flex-1 min-h-0 gap-2 px-4 pb-3 overflow-y-auto overscroll-contain"
    >
      <Button
        v-for="assistant in assistants"
        :key="assistant.id"
        :label="assistant.name"
        variant="ghost"
        color="slate"
        trailing-icon
        :icon="isAssistantActive(assistant) ? 'i-lucide-check' : ''"
        class="!justify-end !px-2 !py-2 hover:!bg-n-alpha-2 [&>.i-lucide-check]:text-n-teal-10 h-9"
        size="sm"
        @click="handleAssistantChange(assistant)"
      >
        <span class="text-sm font-medium truncate text-n-slate-12">
          {{ assistant.name || '' }}
        </span>
        <Avatar
          v-if="assistant"
          :src="assistant.avatar_url"
          :name="assistant.name"
          :size="20"
          icon-name="i-woot-captain"
        />
      </Button>
    </div>
    <div v-else class="flex flex-col items-center gap-2 px-4 py-3">
      <p class="text-sm text-n-slate-11">
        {{ t('CAPTAIN.ASSISTANT_SWITCHER.EMPTY_LIST') }}
      </p>
    </div>
  </div>
</template>
