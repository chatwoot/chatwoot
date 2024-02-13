<template>
  <section
    class="relative min-h-screen px-8 dark:text-white bg-[#FCFCFD] dark:bg-slate-900 flex items-center justify-center bg-[url('/assets/images/dashboard/onboarding/intro.svg')] dark:bg-[url('/assets/images/dashboard/onboarding/intro-dark.svg')] bg-[length:715px_555px] bg-no-repeat bg-[left_calc(-56px)_bottom_calc(-133px)]"
  >
    <div
      class="relative max-w-[1440px] w-full mx-auto flex gap-16 min-h-[80vh] justify-center"
    >
      <div class="relative w-5/12 px-16 py-[88px] mt-10">
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
          <transition name="fade">
            <h1
              v-show="showIntroHeader"
              class="font-bold dark:text-white text-slate-900 text-[40px] leading-[56px] whitespace-pre-line"
            >
              {{ intro }}
            </h1>
          </transition>
        </div>
        <transition name="slide-fade">
          <div v-if="showIntroHeader" id="steps" class="z-0">
            <onboarding-step
              v-for="(step, index) in steps"
              :key="step.name"
              v-bind="step"
              :step-number="index + 1"
              :icon="step.icon"
            />
          </div>
        </transition>
      </div>
      <div
        class="relative w-7/12 py-[88px] flex justify-center overflow-hidden h-fit"
      >
        <div
          class="absolute inset-0 h-full w-full bg-white dark:bg-slate-900 bg-[radial-gradient(var(--w-200)_1px,transparent_1px)] [background-size:16px_16px]"
        />
        <div
          class="absolute h-full w-full overlay-gradient top-0 left-0 scale-y-110 blur-[3px]"
        />

        <transition name="slide-fade">
          <router-view />
        </transition>
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
    name: 'onboarding_setup_profile',
    title: 'Setup Profile',
    icon: 'person',
    isActive: false,
    isComplete: false,
  },
  {
    name: 'onboarding_setup_company',
    title: 'Setup Company',
    icon: 'toolbox',
    isActive: false,
    isComplete: false,
  },
  {
    name: 'onboarding_invite_team',
    title: 'Invite your team',
    icon: 'people-team',
    isActive: false,
    isComplete: false,
  },
  // {
  //   name: 'onboarding_founders_note',
  //   title: "Founder's Note",
  //   icon: '',
  //   hidden: true,
  //   isActive: false,
  //   isComplete: false,
  // },
];
export default {
  components: {
    OnboardingStep,
  },
  mixins: [globalConfigMixin],
  data() {
    return {
      showIntroHeader: false,
    };
  },
  computed: {
    currentStep() {
      return this.$route.name;
    },
    intro() {
      if (
        this.currentStep === 'onboarding_setup_company' ||
        this.currentStep === 'onboarding_invite_team'
      ) {
        return this.$t('ONBOARDING.COMPANY.PAGE_TITLE', {
          userName: this.userName,
        });
      }

      return this.$t('ONBOARDING.PROFILE.INTRO');
    },
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
    userName() {
      return this.currentUser.name;
    },
    ...mapGetters({
      globalConfig: 'globalConfig/get',
      currentUser: 'getCurrentUser',
    }),
  },
  watch: {
    watch: {
      $route() {
        this.showIntroHeader = false;
        setTimeout(() => {
          this.showIntroHeader = true;
        }, 10);
      },
    },
  },
  mounted() {
    this.showIntroHeader = true;
  },
  beforeDestroy() {
    this.showIntroHeader = false;
  },
};
</script>
<style scoped>
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
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.5s;
}
.fade-enter, .fade-leave-to /* .fade-leave-active below version 2.1.8 */ {
  opacity: 0;
}
/* Enter and leave animations can use different */
/* durations and timing functions.              */
.slide-fade-enter-active {
  transition: all 0.5s ease;
}
.slide-fade-leave-active {
  position: absolute;
  transition: all 0.4s cubic-bezier(1, 0.5, 0.8, 1);
}
.slide-fade-enter, .slide-fade-leave-to
/* .slide-fade-leave-active below version 2.1.8 */ {
  transform: translateY(10px);
  opacity: 0;
}
</style>
