<script setup>
import { ref, computed } from 'vue';

import Button from 'dashboard/components-next/button/Button.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';

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

const attributeValue = ref(Boolean(props.attribute.value));

const isAttributePresent = computed(() => {
  return (
    props.attribute.value !== undefined &&
    props.attribute.value !== null &&
    props.attribute.value !== ''
  );
});

const handleChange = value => {
  emit('update', value);
};

const handleDelete = () => {
  attributeValue.value = false;
  emit('delete');
};
</script>

<template>
  <div class="flex items-center w-full gap-2 justify-end">
    <Switch v-model="attributeValue" @change="handleChange" />
    <Button
      v-if="isEditingView && isAttributePresent"
      ghost
      ruby
      icon="i-lucide-trash"
      xs
      class="flex-shrink-0 !size-5 !rounded"
      @click="handleDelete"
    />
  </div>
</template>
