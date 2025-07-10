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

const { t } = useI18n();

const getProgressClass = index => {
  if (props.currentStep === index + 2) {
    return 'progress-line-nextStep';
  }
  if (props.currentStep > index + 2) {
    return 'progress-line-completed';
  }
  return 'progress-line-not-completed';
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
          (props.currentStep == step.props.stepNumber
            ? 'scale-[1.3] bg-n-brand'
            : 'scale-100 ',
          props.currentStep >= step.props.stepNumber
            ? 'bg-n-brand'
            : 'bg-slate-600')
        "
      >
        <Icon :icon="step.icon.src" :class="step.icon.class" />
      </div>
      <!--Line-->
      <div class="relative w-full">
        <div
          v-if="index < Object.values(props.steps).length - 1"
          class="absolute -top-12 bg-slate-200 left-1/2 h-1 w-full -z-8"
          :class="getProgressClass(index)"
        />
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

d
<style scoped>
.progress-line-nextStep::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  height: 100%;
  width: 0%;
  background-color: theme('colors.n.brand');
  animation: fillLine 0.5s ease-in-out forwards;
}

.progress-line-completed::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  height: 100%;
  width: 100%;
  background-color: theme('colors.n.brand');
}

.progress-line-not-completed::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  height: 100%;
  width: 0%;
  background-color: transparent;
}

@keyframes fillLine {
  to {
    width: 100%;
  }
}
</style>
