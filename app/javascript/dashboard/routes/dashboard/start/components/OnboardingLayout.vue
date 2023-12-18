<template>
  <section
    class="relative h-screen px-8 py-12 dark:text-white bg-woot-25 dark:bg-slate-900"
  >
    <div class="absolute inset-0 w-full h-screen overflow-hidden">
      <img
        id="bg-grad"
        src="/onboarding/bg-gradient.png"
        class="w-full opacity-50 dark:mix-blend-color"
      />
    </div>
    <div class="relative max-w-lg mx-auto">
      <div
        id="steps"
        class="rounded-md w-48 -left-52 dark:shadow-[#000] p-1 border shadow-sm border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 absolute grid gap-1"
      >
        <h6
          class="px-2 pt-1 font-bold tracking-widest uppercase text-xxs text-slate-500"
        >
          Get Started
        </h6>
        <onboarding-step
          v-for="(step, index) in steps"
          :key="step.name"
          v-bind="step"
          :step-number="index + 1"
        />
      </div>
      <div
        id="modal-body"
        class="dark:shadow-[#000] rounded-md mx-auto p-9 border shadow border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900"
      >
        <h2 class="text-lg font-bold tracking-tight">
          <slot name="title">
            {{ title }}
          </slot>
        </h2>
        <slot name="body">
          <p class="mt-2 text-sm dark:text-slate-200">
            {{ body }}
          </p>
        </slot>
        <div class="mt-8">
          <slot />
        </div>
      </div>
    </div>
  </section>
</template>

<script>
import OnboardingStep from './OnboardingStep.vue';

const UISteps = [
  {
    name: 'profile',
    title: 'Setup Profile',
    isActive: false,
    isComplete: false,
  },
  {
    name: 'company',
    title: 'Setup Company',
    isActive: false,
    isComplete: false,
  },
  {
    name: 'invite',
    title: 'Invite your team',
    isActive: false,
    isComplete: false,
  },
  {
    name: 'founders-note',
    title: "Founder's Note",
    hidden: true,
    isActive: false,
    isComplete: false,
  },
];

export default {
  components: {
    OnboardingStep,
  },
  props: {
    title: {
      type: String,
      default: '',
    },
    body: {
      type: String,
      default: '',
    },
    currentStep: {
      type: String,
      required: true,
    },
  },
  computed: {
    steps() {
      let foundCurrentStep = false;

      return UISteps.map(step => {
        if (step.name === this.currentStep) {
          foundCurrentStep = true;
        }

        return {
          ...step,
          isActive: step.name === this.currentStep,
          isComplete: !foundCurrentStep,
        };
      });
    },
  },
};
</script>
