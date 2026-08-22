<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useStore } from 'vuex';
import { useToggle } from '@vueuse/core';
import { vOnClickOutside } from '@vueuse/components';
import { useMapGetter } from 'dashboard/composables/store.js';

import ReportHeader from './components/ReportHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import RangeSelector from 'dashboard/components-next/captain/pageComponents/overview/RangeSelector.vue';
import TopIntentsCard from 'dashboard/components-next/captain/pageComponents/overview/TopIntentsCard.vue';
import CaptainAssistant from 'dashboard/api/captain/assistant';

const store = useStore();
const assistants = useMapGetter('captainAssistants/getRecords');

const selectedAssistantId = ref(null);
const selectedRange = ref('7');
const intents = ref(null);
const isFetchingIntents = ref(false);

const [showAssistantDropdown, toggleAssistantDropdown] = useToggle();

// Default to the first available assistant once the list loads.
watch(
  assistants,
  list => {
    if (!list?.length) return;
    if (
      !selectedAssistantId.value ||
      !list.some(a => a.id === selectedAssistantId.value)
    ) {
      selectedAssistantId.value = list[0].id;
    }
  },
  { immediate: true }
);

const selectedAssistant = computed(
  () => assistants.value?.find(a => a.id === selectedAssistantId.value) || null
);

const assistantMenuSections = computed(() => ({
  items: (assistants.value || []).map(assistant => ({
    label: assistant.name,
    value: assistant.id,
    action: 'select',
    isSelected: assistant.id === selectedAssistantId.value,
  })),
}));

const selectAssistant = assistant => {
  selectedAssistantId.value = assistant.value;
  toggleAssistantDropdown(false);
};

const fetchIntents = async () => {
  if (!selectedAssistantId.value) return;
  isFetchingIntents.value = true;
  intents.value = null;
  try {
    const { data } = await CaptainAssistant.getIntents({
      assistantId: selectedAssistantId.value,
      range: selectedRange.value,
    });
    intents.value = data;
  } catch {
    intents.value = { total_intents: 0, total_questions: 0, intents: [] };
  } finally {
    isFetchingIntents.value = false;
  }
};

watch([selectedAssistantId, selectedRange], fetchIntents, { immediate: true });

onMounted(() => {
  store.dispatch('captainAssistants/get');
});
</script>

<template>
  <div class="flex flex-col gap-4">
    <ReportHeader :header-title="$t('CAPTAIN.INTENTS_REPORT.HEADER')" />

    <div
      v-if="!assistants || assistants.length === 0"
      class="py-2 text-sm text-n-slate-11"
    >
      {{ $t('CAPTAIN.INTENTS_REPORT.NO_ASSISTANTS') }}
    </div>

    <template v-else>
      <div class="flex flex-wrap items-center gap-3">
        <div
          v-on-click-outside="() => toggleAssistantDropdown(false)"
          class="relative flex items-center"
        >
          <Button
            sm
            slate
            faded
            trailing-icon
            icon="i-lucide-chevron-down"
            :label="
              selectedAssistant
                ? selectedAssistant.name
                : $t('CAPTAIN.INTENTS_REPORT.SELECT_ASSISTANT')
            "
            class="rounded-md"
            @click="toggleAssistantDropdown()"
          />
          <DropdownMenu
            v-if="showAssistantDropdown"
            :menu-sections="assistantMenuSections"
            class="mt-1 ltr:left-0 rtl:right-0 top-full min-w-[16rem]"
            @action="selectAssistant"
          />
        </div>

        <RangeSelector v-model="selectedRange" />
      </div>

      <TopIntentsCard
        :intents="
          intents ?? { total_intents: 0, total_questions: 0, intents: [] }
        "
        :loading="isFetchingIntents"
      />
    </template>
  </div>
</template>
