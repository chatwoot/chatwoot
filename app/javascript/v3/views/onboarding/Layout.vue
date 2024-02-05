<template>
  <section
    class="relative h-screen px-8 dark:text-white bg-[#FCFCFD] dark:bg-slate-900 flex items-center justify-center"
  >
    <div
      class="relative max-w-[1440px] w-full mx-auto flex justify-center gap-16"
    >
      <div
        class="relative w-4/12 px-16 py-[88px] bg-[url('/assets/images/dashboard/onboarding/intro.svg')] bg-contain bg-no-repeat bg-left-bottom"
      >
        <div class="mb-10 z-0">
          <img
            :src="globalConfig.logo"
            :alt="globalConfig.installationName"
            class="h-8 w-auto block dark:hidden"
          />
          <img
            v-if="globalConfig.logoDark"
            :src="globalConfig.logoDark"
            :alt="globalConfig.installationName"
            class="h-8 w-auto hidden dark:block"
          />
          <h1
            class="font-bold dark:text-white text-slate-900 text-[40px] tracking-[1%] leading-[56px] mt-6 mb-16"
          >
            <slot name="intro">
              {{ intro }}
            </slot>
          </h1>
        </div>
        <div id="steps" class="z-0">
          <onboarding-step
            v-for="(step, index) in steps"
            :key="step.name"
            v-bind="step"
            :step-number="index + 1"
            :icon="step.icon"
          />
        </div>
      </div>
      <div
        class="relative w-8/12 py-[88px] flex items-center justify-center overflow-hidden px-24"
      >
        <div
          class="absolute inset-0 h-full w-full bg-white dark:bg-slate-900 bg-[radial-gradient(var(--w-100)_1px,transparent_1px)] [background-size:16px_16px]"
        />
        <div
          class="absolute h-full w-full overlay-gradient top-0 left-0 scale-y-110 blur-[3px]"
        />
        <div
          id="modal-body"
          class="dark:shadow-[#000] rounded-3xl p-10 pt-14 border shadow border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 z-10 relative max-w-[560px]"
        >
          <h2
            class="font-bold text-[28px] leading-8 tracking-[2%] text-slate-900 dark:text-white"
          >
            <slot name="title">
              {{ title }}
            </slot>
          </h2>
          <slot name="body">
            <p
              class="text-base text-slate-600 leading-6 tracking-[-1.1%] mt-2 dark:text-slate-200"
            >
              {{ body }}
            </p>
          </slot>
          <div class="mt-10">
            <slot />
          </div>
        </div>
      </div>
    </div>
  </section>
</template>

<script>
import { mapGetters } from 'vuex';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';

import OnboardingStep from './OnboardingStep.vue';

const UISteps = [
  {
    name: 'profile',
    title: 'Setup Profile',
    icon: 'person',
    isActive: false,
    isComplete: false,
  },
  {
    name: 'company',
    title: 'Setup Company',
    icon: 'toolbox',
    isActive: false,
    isComplete: false,
  },
  {
    name: 'invite',
    title: 'Invite your team',
    icon: 'people-team',
    isActive: false,
    isComplete: false,
  },
  {
    name: 'founders-note',
    title: "Founder's Note",
    icon: '',
    hidden: true,
    isActive: false,
    isComplete: false,
  },
];
export default {
  components: {
    OnboardingStep,
  },
  mixins: [globalConfigMixin],
  props: {
    intro: {
      type: String,
      default: '',
    },
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
    ...mapGetters({ globalConfig: 'globalConfig/get' }),
  },
};
</script>
<style>
.overlay-gradient {
  background: linear-gradient(90deg, rgba(252, 252, 253, 0) 81.8%, #fcfcfd 100%),
    linear-gradient(270deg, rgba(252, 252, 253, 0) 76.93%, #fcfcfd 100%),
    linear-gradient(0deg, rgba(252, 252, 253, 0) 68.63%, #fcfcfd 100%),
    linear-gradient(180deg, rgba(252, 252, 253, 0) 73.2%, #fcfcfd 100%);
}
.dark .overlay-gradient {
  background: linear-gradient(270deg, rgba(24, 24, 26, 0) 76.93%, #151718 100%),
    linear-gradient(90deg, rgba(24, 24, 26, 0) 81.8%, #151718 100%),
    linear-gradient(0deg, rgba(24, 24, 26, 0) 68.63%, #151718 100%),
    linear-gradient(180deg, rgba(24, 24, 26, 0) 73.2%, #151718 100%);
}
</style>
