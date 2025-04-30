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
    class="relative min-h-screen px-8 dark:text-white bg-[#FCFCFD] dark:bg-slate-900 overflow-auto flex justify-center"
  >
    <Spinner v-if="!showIntroHeader" class="absolute inset-0" />

    <div
      v-else
      class="relative flex gap-16 w-full max-w-[1440px] overflow-x-auto"
    >
      <!-- Left Column -->
      <div
        class="relative min-w-[300px] shrink-0 px-16 flex flex-col justify-center"
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
          <div v-if="showIntroHeader" id="steps" class="z-0 onboarding-steps">
            <OnboardingStep
              v-for="(step, index) in steps"
              :key="step.name"
              v-bind="step"
              :step-number="index + 1"
              :icon="step.icon"
            />
          </div>
        </transition>
      </div>

      <!-- Right Column -->
      <div
        class="relative min-w-[300px] shrink-0 flex items-center justify-center overflow-hidden"
      >
        <div
          class="absolute h-full w-full bg-onboarding-gradient dark:bg-onboarding-gradient-dark top-0 left-0 scale-y-110 blur-[3px]"
        />
        <transition name="slide-fade">
          <router-view class="shadow-lg dark:shadow-gray-800" />
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

.logo-image {
  position: relative;
  margin-left: -3rem;
  left: -16px;
}

.onboarding-steps {
  position: relative;
}
</style>
