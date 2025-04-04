<script>
import { mapGetters } from 'vuex';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';

import Spinner from 'shared/components/Spinner.vue';
import OnboardingStep from './OnboardingStep.vue';
import { UISteps, API_ONBOARDING_STEP_ROUTE } from './constants';

export default {
  components: {
    Spinner,
    OnboardingStep,
  },
  mixins: [globalConfigMixin],
  data() {
    return {
      showIntroHeader: false,
      showLoading: true,
    };
  },
  computed: {
    ...mapGetters({
      globalConfig: 'globalConfig/get',
      currentUser: 'getCurrentUser',
      currentAccountId: 'getCurrentAccountId',
      getAccount: 'accounts/getAccount',
    }),
    currentStep() {
      return this.$route.name;
    },
    intro() {
      if (
        this.currentStep === 'onboarding_add_agent' ||
        this.currentStep === 'onboarding_setup_inbox'
      ) {
        return this.$t('START_ONBOARDING.COMPANY.PAGE_TITLE', {
          userName: this.userName,
        });
      }
      return this.$t('START_ONBOARDING.PROFILE.INTRO');
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
    accountDetails() {
      return this.getAccount(this.currentAccountId);
    },
  },
  watch: {
    $route() {
      this.showIntroHeader = false;
      this.showLoading = true;
      setTimeout(() => {
        this.showIntroHeader = true;
      }, 10);
    },
    accountDetails() {
      // this.navigateToSavedStep();
    },
  },
  mounted() {
    this.showIntroHeader = true;
    this.showLoading = true;
    // this.navigateToSavedStep();
  },
  beforeUnmount() {
    this.showIntroHeader = false;
  },
  methods: {
    navigateToSavedStep() {
      if (!this.accountDetails) return;
      const { custom_attributes: { onboarding_step: savedStep } = {} } =
        this.accountDetails;
      const stepName = API_ONBOARDING_STEP_ROUTE[savedStep];
      if (
        stepName &&
        stepName !== this.currentStep &&
        this.currentStep !== 'app'
      ) {
        this.showLoading = false;
        this.$router.replace({ name: stepName });
      } else if (!stepName) {
        this.showLoading = false;
        this.$router.replace({ name: 'home' });
      }
    },
  },
};
</script>

<template>
  <section
    class="relative min-h-screen px-8 dark:text-white bg-[#FCFCFD] dark:bg-slate-900 flex items-center justify-center"
  >
    <spinner v-if="!showIntroHeader" class="absolute inset-0" />
    <div
      v-else
      class="relative max-w-[1440px] w-full mx-auto flex gap-16 min-h-[80vh] justify-center"
    >
      <div
        class="relative w-5/12 px-16 py-[88px] bg-[url('/assets/images/dashboard/onboarding/light.svg')] dark:bg-[url('/assets/images/dashboard/onboarding/dark.svg')] bg-contain bg-no-repeat bg-[left_calc(-0px)_bottom_calc(-136px)] xl:min-h-[875px] 2xl:min-h-[1205px]"
      >
        <div class="mb-10 z-0">
          <img
            :src="globalConfig.logo"
            :alt="globalConfig.installationName"
            class="h-14 w-auto block dark:hidden logo-image"
          />
          <img
            v-if="globalConfig.logoDark"
            :src="globalConfig.logoDark"
            :alt="globalConfig.installationName"
            class="h-14 w-auto hidden dark:block logo-image"
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
          class="absolute inset-0 h-full w-full bg-[#FCFCFD] dark:bg-slate-900 bg-[radial-gradient(var(--w-200)_1px,transparent_1px)] [background-size:16px_16px]"
        />
        <div
          class="absolute h-full w-full bg-onboarding-gradient dark:bg-onboarding-gradient-dark top-0 left-0 scale-y-110 blur-[3px]"
        />
        <transition name="slide-fade">
          <router-view />
        </transition>
      </div>
    </div>
  </section>
</template>

<style scoped>
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.5s;
}
.fade-enter,
.fade-leave-to {
  opacity: 0;
}
.slide-fade-enter-active {
  transition: all 0.5s ease;
}
.slide-fade-leave-active {
  position: absolute;
  transition: all 0.4s cubic-bezier(1, 0.5, 0.8, 1);
}
.slide-fade-enter,
.slide-fade-leave-to {
  transform: translateY(10px);
  opacity: 0;
}

.logo-container {
  margin-left: -3rem;
}

.logo-image {
  position: relative;
  margin-left: -3rem;
  left: -16px;
}
</style>
