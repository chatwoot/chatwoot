<script setup>
import { useTemplateRef, computed, ref } from 'vue';
import { useI18n, I18nT } from 'vue-i18n';
import { useToggle } from '@vueuse/core';
import { vOnClickOutside } from '@vueuse/components';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useOrderedMacros } from 'dashboard/composables/useOrderedMacros';

import Button from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';

const props = defineProps({
  conversationCount: {
    type: Number,
    required: true,
  },
});

const emit = defineEmits(['execute']);

const { t } = useI18n();
const store = useStore();

const containerRef = useTemplateRef('containerRef');
const [showDropdown, toggleDropdown] = useToggle(false);
const selectedMacro = ref(null);

const { orderedMacros } = useOrderedMacros();
const macrosUiFlags = useMapGetter('macros/getUIFlags');

const isExecuting = computed(() => macrosUiFlags.value.isExecuting);
const isLoading = computed(
  () => macrosUiFlags.value.isFetching && !orderedMacros.value.length
);

const macroMenuItems = computed(() =>
  orderedMacros.value.map(macro => ({
    action: 'select',
    value: macro.id,
    label: macro.name,
    isSelected: selectedMacro.value?.id === macro.id,
  }))
);

const handleToggleDropdown = () => {
  if (!showDropdown.value) store.dispatch('macros/get');
  toggleDropdown();
};

const handleSelectMacro = item => {
  selectedMacro.value = orderedMacros.value.find(
    macro => macro.id === item.value
  );
};

const handleExecute = () => {
  if (isExecuting.value) return;
  emit('execute', selectedMacro.value);
  selectedMacro.value = null;
  toggleDropdown(false);
};

const handleCancel = () => {
  selectedMacro.value = null;
};

const handleDismiss = () => {
  selectedMacro.value = null;
  toggleDropdown(false);
};
</script>

<template>
  <div ref="containerRef" class="relative">
    <Button
      v-tooltip="$t('BULK_ACTION.MACROS.EXECUTE_MACRO')"
      icon="i-lucide-toy-brick"
      slate
      xs
      ghost
      :class="{ 'bg-n-alpha-2': showDropdown }"
      @click="handleToggleDropdown"
    />
    <Transition
      enter-active-class="transition-all duration-150 ease-out origin-bottom"
      enter-from-class="opacity-0 scale-95"
      enter-to-class="opacity-100 scale-100"
      leave-active-class="transition-all duration-100 ease-in origin-bottom"
      leave-from-class="opacity-100 scale-100"
      leave-to-class="opacity-0 scale-95"
    >
      <DropdownMenu
        v-if="showDropdown"
        v-on-click-outside="[handleDismiss, { ignore: [containerRef] }]"
        :menu-items="macroMenuItems"
        :is-loading="isLoading"
        show-search
        :search-placeholder="t('BULK_ACTION.SEARCH_INPUT_PLACEHOLDER')"
        empty-state-message="MACROS.LIST.404"
        class="end-2 bottom-8 w-60 max-h-80"
        @action="handleSelectMacro"
      >
        <template v-if="selectedMacro" #footer>
          <div
            class="pt-2 pb-2 px-2 border-t border-n-weak sticky bottom-0 rounded-b-md z-20 bg-n-alpha-3 backdrop-blur-[4px]"
          >
            <div class="flex flex-col gap-2">
              <I18nT
                keypath="BULK_ACTION.MACROS.EXECUTE_CONFIRMATION_LABEL"
                tag="p"
                class="text-xs text-n-slate-11 px-1 mb-0"
                :plural="props.conversationCount"
              >
                <template #n>
                  <strong class="text-n-slate-12">
                    {{ props.conversationCount }}
                  </strong>
                </template>
                <template #macroName>
                  <strong class="text-n-slate-12">
                    {{ selectedMacro.name }}
                  </strong>
                </template>
              </I18nT>
              <div class="flex gap-2">
                <Button
                  sm
                  faded
                  slate
                  class="flex-1"
                  :label="t('BULK_ACTION.CANCEL')"
                  @click="handleCancel"
                />
                <Button
                  sm
                  class="flex-1"
                  :label="t('BULK_ACTION.YES')"
                  :disabled="isExecuting"
                  :is-loading="isExecuting"
                  @click="handleExecute"
                />
              </div>
            </div>
          </div>
        </template>
      </DropdownMenu>
    </Transition>
  </div>
</template>
