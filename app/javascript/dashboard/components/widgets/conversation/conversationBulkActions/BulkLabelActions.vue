<script setup>
import { ref, useTemplateRef, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import { useToggle } from '@vueuse/core';
import { vOnClickOutside } from '@vueuse/components';

import NextButton from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';

const props = defineProps({
  type: {
    type: String,
    default: 'conversation',
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
  disabled: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['assign']);

const { t } = useI18n();

const labels = useMapGetter('labels/getLabels');

const containerRef = useTemplateRef('containerRef');
const [showDropdown, toggleDropdown] = useToggle(false);
const selectedLabels = ref([]);

const isTypeContact = computed(() => props.type === 'contact');

const buttonLabel = computed(() =>
  props.type === 'contact' ? t('CONTACTS_BULK_ACTIONS.ASSIGN_LABELS') : ''
);

const isLabelSelected = labelTitle => {
  return selectedLabels.value.includes(labelTitle);
};

const labelMenuItems = computed(() => {
  return labels.value.map(label => ({
    action: 'select',
    value: label.title,
    label: label.title,
    color: label.color,
    id: label.id,
    isSelected: isLabelSelected(label.title),
  }));
});

const toggleLabelSelection = labelTitle => {
  const index = selectedLabels.value.indexOf(labelTitle);
  if (index > -1) {
    selectedLabels.value.splice(index, 1);
  } else {
    selectedLabels.value.push(labelTitle);
  }
};

const handleAssign = () => {
  if (selectedLabels.value.length > 0) {
    emit('assign', selectedLabels.value);
    toggleDropdown(false);
    selectedLabels.value = [];
  }
};

const handleDismiss = () => {
  selectedLabels.value = [];
  toggleDropdown(false);
};
</script>

<template>
  <div ref="containerRef" class="relative">
    <NextButton
      v-tooltip="isTypeContact ? '' : $t('BULK_ACTION.LABELS.ASSIGN_LABELS')"
      :label="buttonLabel"
      icon="i-lucide-tag"
      slate
      :size="isTypeContact ? 'sm' : 'xs'"
      ghost
      :class="{
        'bg-n-alpha-2': showDropdown,
        '[&>span:nth-child(2)]:hidden md:[&>span:nth-child(2)]:inline w-fit !text-n-blue-11 [&>span]:!text-n-blue-11 !px-2':
          isTypeContact,
      }"
      :disabled="disabled || isLoading"
      :is-loading="isLoading"
      @click="toggleDropdown()"
    />
    <Transition
      :enter-active-class="
        !isTypeContact
          ? 'transition-all duration-150 ease-out origin-bottom'
          : 'transition-all duration-150 ease-out origin-top'
      "
      enter-from-class="opacity-0 scale-95"
      enter-to-class="opacity-100 scale-100"
      :leave-active-class="
        !isTypeContact
          ? 'transition-all duration-100 ease-in origin-bottom'
          : 'transition-all duration-100 ease-in origin-top'
      "
      leave-from-class="opacity-100 scale-100"
      leave-to-class="opacity-0 scale-95"
    >
      <DropdownMenu
        v-if="showDropdown"
        v-on-click-outside="[handleDismiss, { ignore: [containerRef] }]"
        :menu-items="labelMenuItems"
        show-search
        :search-placeholder="t('BULK_ACTION.SEARCH_INPUT_PLACEHOLDER')"
        class="w-60 max-h-80"
        :class="{
          'ltr:-right-[6.5rem] rtl:-left-[6.5rem] ltr:2xl:right-0 rtl:2xl:left-0 bottom-8':
            !isTypeContact,
          'ltr:right-0 rtl:left-0 mb-1 top-10': isTypeContact,
        }"
        @action="item => toggleLabelSelection(item.value)"
      >
        <template #thumbnail="{ item }">
          <span
            class="rounded-md h-3 w-3 flex-shrink-0 border border-solid border-n-weak"
            :style="{ backgroundColor: item.color }"
          />
        </template>

        <template #trailing-icon="{ item }">
          <Icon
            v-if="isLabelSelected(item.value)"
            icon="i-lucide-check"
            class="size-4 text-n-blue-11 flex-shrink-0"
          />
        </template>

        <template #footer>
          <div
            class="sticky bottom-0 rounded-b-md px-2 py-2 z-20 bg-n-alpha-3 backdrop-blur-[4px]"
          >
            <NextButton
              sm
              class="w-full [&>span:nth-child(2)]:hidden md:[&>span:nth-child(2)]:inline-flex"
              :label="t('BULK_ACTION.LABELS.ASSIGN_SELECTED_LABELS')"
              :disabled="!selectedLabels.length"
              @click="handleAssign"
            />
          </div>
        </template>
      </DropdownMenu>
    </Transition>
  </div>
</template>
