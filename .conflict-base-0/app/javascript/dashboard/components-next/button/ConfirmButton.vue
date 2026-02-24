<script setup>
import { ref, computed } from 'vue';
import Button from './Button.vue';

const props = defineProps({
  label: { type: [String, Number], default: '' },
  confirmLabel: { type: [String, Number], default: '' },
  color: { type: String, default: 'blue' },
  confirmColor: { type: String, default: 'ruby' },
  confirmHint: { type: String, default: '' },
  variant: { type: String, default: null },
  size: { type: String, default: null },
  justify: { type: String, default: null },
  icon: { type: [String, Object, Function], default: '' },
  trailingIcon: { type: Boolean, default: false },
  isLoading: { type: Boolean, default: false },
});

const emit = defineEmits(['click']);

const isConfirmMode = ref(false);
const isClicked = ref(false);

const currentLabel = computed(() => {
  return isConfirmMode.value ? props.confirmLabel : props.label;
});

const currentColor = computed(() => {
  return isConfirmMode.value ? props.confirmColor : props.color;
});
const resetConfirmMode = () => {
  isConfirmMode.value = false;
  isClicked.value = false;
};

const handleClick = () => {
  if (!isConfirmMode.value) {
    isConfirmMode.value = true;
  } else {
    isClicked.value = true;
    emit('click');
    setTimeout(resetConfirmMode, 400);
  }
};
</script>

<template>
  <div
    class="relative"
    :class="{
      'animate-bounce-complete': isClicked,
    }"
  >
    <Button
      type="button"
      :label="currentLabel"
      :color="currentColor"
      :variant="variant"
      :size="size"
      :justify="justify"
      :icon="icon"
      :trailing-icon="trailingIcon"
      :is-loading="isLoading"
      @click="handleClick"
      @blur="resetConfirmMode"
    >
      <template v-if="$slots.default" #default>
        <slot />
      </template>
      <template v-if="$slots.icon" #icon>
        <slot name="icon" />
      </template>
    </Button>
    <div
      v-if="isConfirmMode && confirmHint"
      class="absolute mt-1 w-full text-[10px] text-center text-n-slate-10"
    >
      {{ confirmHint }}
    </div>
  </div>
</template>

<style scoped>
@keyframes bounce-complete {
  0% {
    transform: scale(0.95);
  }
  50% {
    transform: scale(1.02);
  }
  100% {
    transform: scale(1);
  }
}

.animate-bounce-complete {
  animation: bounce-complete 0.2s cubic-bezier(0.68, -0.55, 0.265, 1.55);
}
</style>
