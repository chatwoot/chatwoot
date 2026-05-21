<script setup>
import { computed, ref, watch } from 'vue';
import Button from 'dashboard/components-next/button/Button.vue';
import CardLayout from 'dashboard/components-next/CardLayout.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';
import InlineInput from 'dashboard/components-next/inline-input/InlineInput.vue';

const props = defineProps({
  id: {
    type: Number,
    required: true,
  },
  content: {
    type: String,
    required: true,
  },
  selectable: {
    type: Boolean,
    default: false,
  },
  isSelected: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['select', 'hover', 'edit', 'delete']);

const modelValue = computed({
  get: () => props.isSelected,
  set: () => emit('select', props.id),
});

const isEditing = ref(false);
const editedContent = ref(props.content);

// Local content to display to avoid flicker until parent prop updates on inline edit
const localContent = ref(props.content);

// Keeps localContent in sync when parent updates content prop
watch(
  () => props.content,
  newVal => {
    localContent.value = newVal;
  }
);

const startEdit = () => {
  isEditing.value = true;
  editedContent.value = props.content;
};

const saveEdit = () => {
  isEditing.value = false;
  // Update local content
  localContent.value = editedContent.value;
  emit('edit', { id: props.id, content: editedContent.value });
};
</script>

<template>
  <CardLayout
    selectable
    class="relative [&>div]:!py-5 [&>div]:ltr:!pr-4 [&>div]:rtl:!pl-4"
    layout="row"
    @mouseenter="emit('hover', true)"
    @mouseleave="emit('hover', false)"
  >
    <div v-show="selectable" class="absolute top-6 ltr:left-3 rtl:right-3">
      <Checkbox v-model="modelValue" />
    </div>
    <InlineInput
      v-if="isEditing"
      v-model="editedContent"
      focus-on-mount
      @keyup.enter="saveEdit"
    />
    <span v-else class="flex items-center gap-2 text-sm text-n-slate-12">
      {{ localContent }}
    </span>
    <div class="flex items-center gap-2">
      <Button icon="i-lucide-pen" slate xs ghost @click="startEdit" />
      <span class="w-px h-4 bg-n-weak" />
      <Button
        icon="i-lucide-trash"
        slate
        xs
        ghost
        @click="emit('delete', id)"
      />
    </div>
  </CardLayout>
</template>
