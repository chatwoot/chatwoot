<script setup>
import { ref, watch } from 'vue';

import Switch from 'dashboard/components-next/switch/Switch.vue';
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
  outlined: {
    type: Boolean,
    default: false,
  },
  readOnly: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['update', 'delete']);

const attributeValue = ref(Boolean(props.attribute.value));

watch(
  () => props.attribute.value,
  val => {
    attributeValue.value = Boolean(val);
  }
);

const handleChange = value => {
  if (props.readOnly) {
    attributeValue.value = Boolean(props.attribute.value);
    return;
  }
  emit('update', value);
};
</script>

<template>
  <div class="flex items-center gap-2 shrink-0">
    <Switch v-model="attributeValue" @change="handleChange" />
    <Button
      v-if="isEditingView && !outlined && !readOnly"
      variant="faded"
      color="ruby"
      icon="i-lucide-trash"
      size="xs"
      class="flex-shrink-0 opacity-0 group-hover/attribute:opacity-100 hover:no-underline"
      @click="emit('delete')"
    />
  </div>
</template>
