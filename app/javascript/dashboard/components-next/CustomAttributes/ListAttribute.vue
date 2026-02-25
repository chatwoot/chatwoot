<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToggle } from '@vueuse/core';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import Button from 'dashboard/components-next/button/Button.vue';

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
  <div
    class="flex items-center w-full min-w-0 gap-2"
    :class="{
      'justify-start': isEditingView,
      'justify-end': !isEditingView,
    }"
  >
    <div
      v-on-clickaway="() => toggleAttributeListDropdown(false)"
      class="relative flex items-center"
    >
      <span
        class="min-w-0 text-sm"
        :class="{
          'cursor-pointer text-n-slate-11 hover:text-n-slate-12 py-2 select-none font-medium':
            !isEditingView,
          'text-n-slate-12 truncate flex-1': isEditingView,
        }"
        @click="toggleAttributeListDropdown(!props.isEditingView)"
      >
        {{
          attribute.value ||
          t('CONTACTS_LAYOUT.SIDEBAR.ATTRIBUTES.TRIGGER.SELECT')
        }}
      </span>
      <DropdownMenu
        v-if="showAttributeListDropdown"
        :menu-items="attributeListMenuItems"
        show-search
        class="w-48 mt-2 top-full"
        :class="{
          'ltr:right-0 rtl:left-0': !isEditingView,
          'ltr:left-0 rtl:right-0': isEditingView,
        }"
        @action="handleAttributeAction($event)"
      />
    </div>

    <div v-if="isEditingView" class="flex items-center gap-1">
      <Button
        variant="faded"
        color="slate"
        icon="i-lucide-pencil"
        size="xs"
        class="flex-shrink-0 opacity-0 group-hover/attribute:opacity-100 hover:no-underline"
        @click="toggleAttributeListDropdown()"
      />
      <Button
        variant="faded"
        color="ruby"
        icon="i-lucide-trash"
        size="xs"
        class="flex-shrink-0 opacity-0 group-hover/attribute:opacity-100 hover:no-underline"
        @click="emit('delete')"
      />
    </div>
  </div>
</template>
