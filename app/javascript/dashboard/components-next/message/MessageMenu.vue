<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import NextButton from 'dashboard/components-next/button/Button.vue';
import DropdownContainer from 'next/dropdown-menu/base/DropdownContainer.vue';
import DropdownSection from 'next/dropdown-menu/base/DropdownSection.vue';
import DropdownBody from 'next/dropdown-menu/base/DropdownBody.vue';
import DropdownItem from 'next/dropdown-menu/base/DropdownItem.vue';

const emit = defineEmits(['openForward']);

const { t } = useI18n();

const menuItems = computed(() => {
  return [
    {
      label: t('CONVERSATION.MESSAGE_MENU.FORWARD_EMAIL'),
      value: 'forward',
    },
  ];
});
</script>

<template>
  <DropdownContainer>
    <template #trigger="{ toggle, isOpen }">
      <NextButton
        icon="i-lucide-ellipsis-vertical"
        xs
        slate
        faded
        :class="{ 'bg-n-alpha-2': isOpen }"
        @click="toggle"
      />
    </template>
    <DropdownBody class="top-0 -right-6 min-w-64 z-50" strong>
      <DropdownSection class="max-h-80 overflow-scroll">
        <DropdownItem
          v-for="item in menuItems"
          :key="item.value"
          class="!items-start !gap-1 flex-col cursor-pointer"
          @click="() => emit('openForward')"
        >
          <template #label>
            <div class="items-start flex gap-1 flex-col">
              <span class="text-n-slate-12 text-sm">
                {{ item.label }}
              </span>
            </div>
          </template>
        </DropdownItem>
      </DropdownSection>
    </DropdownBody>
  </DropdownContainer>
</template>
