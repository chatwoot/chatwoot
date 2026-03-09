<script setup>
import { ref } from 'vue';

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

const handleChange = value => {
  emit('update', value);
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
    <Switch v-model="attributeValue" @change="handleChange" />
    <Button
      v-if="isEditingView"
      variant="faded"
      color="ruby"
      icon="i-lucide-trash"
      size="xs"
      class="flex-shrink-0 opacity-0 group-hover/attribute:opacity-100 hover:no-underline"
      @click="emit('delete')"
    />
  </div>
</template>
