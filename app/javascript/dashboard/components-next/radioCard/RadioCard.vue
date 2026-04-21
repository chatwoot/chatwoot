<script setup>
import Label from 'dashboard/components-next/label/Label.vue';

const props = defineProps({
  id: {
    type: String,
    required: true,
  },
  label: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    required: true,
  },
  isActive: {
    type: Boolean,
    default: false,
  },
  disabled: {
    type: Boolean,
    default: false,
  },
  disabledLabel: {
    type: String,
    default: '',
  },
  disabledMessage: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['select']);

const handleChange = () => {
  if (!props.isActive && !props.disabled) {
    emit('select', props.id);
  }
};
</script>

<template>
  <div
    class="cursor-pointer rounded-xl outline outline-1 p-4 transition-all duration-200 bg-s-surface py-4 ltr:pl-4 rtl:pr-4 ltr:pr-6 rtl:pl-6"
    :class="[
      disabled ? 'opacity-50 cursor-not-allowed' : 'cursor-pointer',
      isActive ? 'outline-s-brand' : 'outline-s-border',
      !disabled && !isActive ? 'hover:outline-s-border-strong' : '',
    ]"
    @click="handleChange"
  >
    <div class="flex flex-col gap-2 items-start">
      <div class="flex items-center justify-between w-full gap-3">
        <div class="flex items-center gap-2">
          <h3 class="text-heading-3 text-s-primary">
            {{ label }}
          </h3>
          <Label v-if="disabled" :label="disabledLabel" color="amber" compact />
        </div>
        <input
          :id="`${id}`"
          :checked="isActive"
          :value="id"
          :name="id"
          :disabled="disabled"
          type="radio"
          class="h-4 w-4 border-s-border text-s-brand focus:ring-s-brand focus:ring-offset-0 flex-shrink-0"
          @change="handleChange"
        />
      </div>
      <p class="text-body-main text-s-muted">
        {{ disabled && disabledMessage ? disabledMessage : description }}
      </p>
      <slot />
    </div>
  </div>
</template>
