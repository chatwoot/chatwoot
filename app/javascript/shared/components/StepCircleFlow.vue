<script setup>
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  steps: {
    type: Object,
    required: true,
  },
  currentStep: {
    type: Number,
    required: true,
  },
  stepsCompleted: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['update:currentStep']);

const { t } = useI18n();

const getProgressClass = index => {
  const currentStepIndex = props.currentStep - 1;

  if (currentStepIndex === index + 1) {
    return 'w-0 bg-n-brand animate-fillLine';
  }
  if (currentStepIndex > index) {
    return 'w-full bg-n-brand';
  }
  return 'w-0';
};

const handleStepClick = stepNumber => {
  emit('update:currentStep', stepNumber);
};
</script>

<template>
  <div class="flex justify-between gap-2">
    <div
      v-for="(step, index) in Object.values(props.steps)"
      :key="step.props.stepNumber"
      class="flex flex-col w-full items-center gap-4"
    >
      <!--Circle-->
      <div
        class="w-16 h-16 rounded-full flex items-center justify-center border-2 border-slate-200 transition-transform duration-[500ms] z-10"
        :class="
          currentStep == step.props.stepNumber
            ? [
                'scale-150',
                props.stepsCompleted[step.props.stepNumber]
                  ? 'bg-n-brand contrast-100'
                  : 'bg-n-slate-7',
              ]
            : [
                currentStep >= step.props.stepNumber
                  ? 'bg-n-brand contrast-100'
                  : 'bg-n-slate-7',
              ]
        "
      >
        <button
          class="transition-transform duration-300"
          :class="[
            step.props.stepNumber !== currentStep ? 'hover:scale-125' : '',
          ]"
          @click="handleStepClick(step.props.stepNumber)"
        >
          <Icon :icon="step.icon.src" :class="step.icon.class" />
        </button>
      </div>
      <!--Line-->
      <div class="relative w-full">
        <div
          v-if="index < Object.values(props.steps).length - 1"
          class="relative w-full h-1 -top-12"
        >
          <!-- Background Line -->
          <div
            class="absolute top-1/2 left-[50%] translate-x-0 translate-y-[-50%] h-1 w-full bg-slate-200 z-0"
          />

          <!-- Animated Line -->
          <div
            class="absolute top-1/2 left-[50%] translate-x-0 translate-y-[-50%] h-1 z-1"
            :class="getProgressClass(index)"
          />
        </div>
      </div>

      <!--Text-->
      <div class="flex flex-col text-center">
        <p
          class="text-sm text-slate-500 flex gap-2 items-center justify-center"
        >
          {{ t('STEP_CIRCLE_FLOW.STEP') }} {{ step.props.stepNumber
          }}<span
            v-if="props.stepsCompleted[step.props.stepNumber]"
            class="flex items-center justify-center"
          >
            <Icon icon="i-lucide-check" class="size-4 text-green-500" />
          </span>
        </p>
        <p class="text-sm font-semibold">{{ step.title }}</p>
        <p class="text-sm text-slate-500">{{ step.description }}</p>
      </div>
    </div>
  </div>
</template>
