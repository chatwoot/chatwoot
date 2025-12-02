<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToggle } from '@vueuse/core';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  attribute: {
    type: Object,
    required: true,
  },
  isEditingView: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['update', 'delete']);

const { t } = useI18n();

const [showAttributeListDropdown, toggleAttributeListDropdown] = useToggle();

const attributeListMenuItems = computed(() => {
  return (
    props.attribute.attributeValues?.map(value => ({
      label: value,
      value,
      action: 'select',
      isSelected: value === props.attribute.value,
    })) || []
  );
});

const handleAttributeAction = async action => {
  emit('update', action.value);
  toggleAttributeListDropdown(false);
};
</script>

<template>
  <div class="flex items-center w-full min-w-0 gap-1.5 justify-end">
    <div
      v-on-clickaway="() => toggleAttributeListDropdown(false)"
      class="relative flex items-center min-w-0 flex-1 justify-end gap-2 cursor-pointer"
      @click="toggleAttributeListDropdown()"
    >
      <span
        v-tooltip.top="{
          content: attribute.value,
          delay: { show: 1000, hide: 0 },
        }"
        class="min-w-0 text-sm truncate font-420"
        :class="{
          'text-n-slate-11 hover:text-n-slate-12 py-2 select-none font-medium':
            !isEditingView,
          'text-n-slate-12': isEditingView && attribute.value,
          'text-n-slate-10': isEditingView && !attribute.value,
        }"
      >
        {{
          attribute.value ||
          t('CONTACTS_LAYOUT.SIDEBAR.ATTRIBUTES.TRIGGER.SELECT')
        }}
      </span>
      <Icon
        :icon="
          showAttributeListDropdown
            ? 'i-lucide-chevron-up'
            : 'i-lucide-chevron-down'
        "
        class="text-n-slate-11 flex-shrink-0 size-4"
      />
      <DropdownMenu
        v-if="showAttributeListDropdown"
        :menu-items="attributeListMenuItems"
        show-search
        class="w-48 mt-2 top-full ltr:right-0 rtl:left-0"
        @action="handleAttributeAction($event)"
      />
    </div>

    <Button
      v-if="isEditingView && attribute.value"
      ghost
      ruby
      icon="i-lucide-trash"
      xs
      class="flex-shrink-0 !size-5 !rounded"
      @click="emit('delete')"
    />
  </div>
</template>
