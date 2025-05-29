<script setup>
import { ref, computed, onMounted } from 'vue';
import Button from './Button.vue';

const props = defineProps({
  label: { type: [String, Number], default: '' },
  confirmLabel: { type: [String, Number], default: '' },
  color: { type: String, default: 'blue' },
  confirmColor: { type: String, default: 'ruby' },
  variant: { type: String, default: null },
  size: { type: String, default: null },
  justify: { type: String, default: null },
  icon: { type: [String, Object, Function], default: '' },
  trailingIcon: { type: Boolean, default: false },
  isLoading: { type: Boolean, default: false },
  holdDuration: { type: Number, default: 2500 },
});

const emit = defineEmits(['click']);

const isConfirmMode = ref(false);
const isHolding = ref(false);
const progress = ref(0);
const progressAnimation = ref(null);

const currentLabel = computed(() => {
  return isConfirmMode.value ? props.confirmLabel : props.label;
});

const currentColor = computed(() => {
  return isConfirmMode.value ? props.confirmColor : props.color;
});

const handleClick = () => {
  if (!isConfirmMode.value) {
    isConfirmMode.value = true;
  }
};

const stopHold = () => {
  if (progressAnimation.value) {
    cancelAnimationFrame(progressAnimation.value);
  }
  isHolding.value = false;
  progress.value = 0;
};

const resetConfirmMode = () => {
  stopHold();
  isConfirmMode.value = false;
};

const completeHold = () => {
  emit('click');
  resetConfirmMode();
};

const startHold = () => {
  if (!isConfirmMode.value) return;

  isHolding.value = true;
  progress.value = 0;

  const startTime = Date.now();

  const updateProgress = () => {
    const elapsed = Date.now() - startTime;
    const newProgress = Math.min((elapsed / props.holdDuration) * 100, 100);
    progress.value = newProgress;
    if (newProgress >= 100) {
      completeHold();
    } else {
      progressAnimation.value = requestAnimationFrame(updateProgress);
    }
  };

  progressAnimation.value = requestAnimationFrame(updateProgress);
};

onMounted(() => {
  return () => {
    if (progressAnimation.value) {
      cancelAnimationFrame(progressAnimation.value);
    }
  };
});
</script>

<template>
  <div class="relative">
    <Button
      :label="currentLabel"
      :color="currentColor"
      :variant="variant"
      :size="size"
      :justify="justify"
      :icon="icon"
      :trailing-icon="trailingIcon"
      :is-loading="isLoading"
      @click="handleClick"
      @mousedown="startHold"
      @mouseup="stopHold"
      @mouseleave="resetConfirmMode"
      @blur="resetConfirmMode"
    >
      <template v-if="$slots.default" #default>
        <slot />
      </template>
      <template v-if="$slots.icon" #icon>
        <slot name="icon" />
      </template>
    </Button>

    <!-- Progress overlay -->
    <div
      v-if="isConfirmMode"
      class="absolute inset-0 rounded-lg overflow-hidden pointer-events-none"
    >
      <div
        class="h-full bg-white bg-opacity-10 transition-all duration-75 ease-linear"
        :style="{ width: `${progress}%` }"
      />
    </div>
  </div>
</template>
