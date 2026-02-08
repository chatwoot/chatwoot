<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';
import DropdownContainer from 'next/dropdown-menu/base/DropdownContainer.vue';
import DropdownSection from 'next/dropdown-menu/base/DropdownSection.vue';
import DropdownBody from 'next/dropdown-menu/base/DropdownBody.vue';
import DropdownItem from 'next/dropdown-menu/base/DropdownItem.vue';

const props = defineProps({
  assistants: {
    type: Array,
    required: true,
  },
  activeAssistant: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['setAssistant']);

const { t } = useI18n();

const activeAssistantLabel = computed(() => {
  return props.activeAssistant
    ? props.activeAssistant.name
    : t('CAPTAIN.COPILOT.SELECT_ASSISTANT');
});
</script>

<template>
  <div>
    <DropdownContainer>
      <template #trigger="{ toggle, isOpen }">
        <Button
          :label="activeAssistantLabel"
          icon="i-woot-captain"
          ghost
          slate
          xs
          :class="{ 'bg-n-alpha-2': isOpen }"
          @click="toggle"
        />
      </template>
      <DropdownBody class="bottom-9 min-w-64 z-50" strong>
        <DropdownSection class="max-h-80 overflow-scroll">
          <DropdownItem
            v-for="assistant in assistants"
            :key="assistant.id"
            class="!items-start !gap-1 flex-col cursor-pointer"
            @click="() => emit('setAssistant', assistant)"
          >
            <template #label>
              <div class="flex gap-1 justify-between w-full">
                <div class="items-start flex gap-1 flex-col">
                  <span class="text-n-slate-12 text-sm">
                    {{ assistant.name }}
                  </span>
                  <span class="line-clamp-2 text-n-slate-11 text-xs">
                    {{ assistant.description }}
                  </span>
                </div>

                <div
                  v-if="assistant.id === activeAssistant?.id"
                  class="flex items-center justify-center flex-shrink-0 w-4 h-4 rounded-full bg-n-slate-12 dark:bg-n-slate-11"
                >
                  <i
                    class="i-lucide-check text-white dark:text-n-slate-1 size-3"
                  />
                </div>
              </div>
            </template>
          </DropdownItem>
        </DropdownSection>
      </DropdownBody>
    </DropdownContainer>
  </div>
</template>
