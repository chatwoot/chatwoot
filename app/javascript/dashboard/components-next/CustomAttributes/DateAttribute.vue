<!-- Attribute type "Date" -->
<script setup>
import { ref, computed } from 'vue';
import { parseISO } from 'date-fns';
import { useI18n } from 'vue-i18n';
import Input from 'dashboard/components-next/input/Input.vue';
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

const isEditingValue = ref(false);
const editedValue = ref(props.attribute.value || '');

const defaultDateValue = computed({
  get() {
    const existingDate = editedValue.value ?? props.attribute.value;
    if (existingDate) return new Date(existingDate).toISOString().slice(0, 10);
    return isEditingValue.value ? new Date().toISOString().slice(0, 10) : '';
  },
  set(value) {
    editedValue.value = value ? new Date(value).toISOString() : value;
  },
});

const formattedDate = computed(() => {
  return props.attribute.value
    ? new Date(props.attribute.value).toLocaleDateString()
    : t('CONTACTS_LAYOUT.SIDEBAR.ATTRIBUTES.TRIGGER.INPUT');
});

const toggleEditValue = value => {
  isEditingValue.value =
    typeof value === 'boolean' ? value : !isEditingValue.value;

  if (isEditingValue.value && !editedValue.value) {
    editedValue.value = new Date().toISOString();
  }
};

const handleInputUpdate = async () => {
  emit('update', parseISO(editedValue.value));
  isEditingValue.value = false;
};
</script>

<template>
  <div
    class="flex items-center w-full gap-2"
    :class="{
      'justify-start': isEditingView,
      'justify-end': !isEditingView,
    }"
  >
    <span
      v-if="!isEditingValue"
      class="text-sm"
      :class="{
        'cursor-pointer text-n-slate-11 hover:text-n-slate-12 py-2 select-none font-medium':
          !isEditingView,
        'text-n-slate-12': isEditingView,
      }"
      @click="toggleEditValue(!isEditingView)"
    >
      {{ formattedDate }}
    </span>

    <div
      v-if="isEditingView && !isEditingValue"
      class="flex items-center gap-1"
    >
      <Button
        variant="faded"
        color="slate"
        icon="i-lucide-pencil"
        size="xs"
        class="flex-shrink-0 opacity-0 group-hover/attribute:opacity-100 hover:no-underline"
        @click="toggleEditValue(true)"
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

    <div
      v-if="isEditingValue"
      v-on-clickaway="() => toggleEditValue(false)"
      class="flex items-center w-full"
    >
      <Input
        v-model="defaultDateValue"
        type="date"
        class="w-full"
        autofocus
        custom-input-class="h-8 rounded-r-none !border-n-brand"
        @keyup.enter="handleInputUpdate"
      />
      <Button
        icon="i-lucide-check"
        color="blue"
        size="sm"
        class="flex-shrink-0 rounded-l-none"
        @click="handleInputUpdate"
      />
    </div>
  </div>
</template>
