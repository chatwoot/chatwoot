<template>
  <section
    class="h-screen px-8 dark:text-white bg-[#FCFCFD] dark:bg-slate-900 flex items-center justify-center"
  >
    <spinner v-if="!showIntroHeader" class="absolute inset-0" />
    <div
      v-else
      :class="[
        'relative max-w-[1440px] w-full mx-auto flex gap-16 h-screen justify-center',
        `bg-[url('/assets/images/dashboard/onboarding/intro.svg')]`,
        `dark:bg-[url('/assets/images/dashboard/onboarding/intro-dark.svg')]`,
        `bg-no-repeat bg-[left_bottom_-100px] bg-[length:500px]`,
      ]"
    >
      <div class="relative w-5/12 h-screen py-20">
        <div class="z-0 mb-10">
          <img
            :src="globalConfig.logo"
            :alt="globalConfig.installationName"
            class="block w-auto h-8 dark:hidden"
          />
          <img
            v-if="globalConfig.logoDark"
            :src="globalConfig.logoDark"
            :alt="globalConfig.installationName"
            class="hidden w-auto h-8 dark:block"
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
        class="relative flex justify-center w-7/12 pt-20 overflow-hidden h-fit"
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

<script>
import { mapGetters } from 'vuex';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';

import Spinner from 'shared/components/Spinner.vue';
import OnboardingStep from './OnboardingStep.vue';
import { UISteps } from './constants';

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
        this.currentStep === 'onboarding_setup_company' ||
        this.currentStep === 'onboarding_invite_team'
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
      const { display_name: displayName, name } = this.currentUser;
      return displayName || name;
    },
    accountDetails() {
      return this.getAccount(this.currentAccountId);
    },
  },
  watch: {
    watch: {
      $route() {
        this.showIntroHeader = false;
        this.showLoading = true;

        setTimeout(() => {
          this.showIntroHeader = true;
        }, 10);
      },
    },
  },
  mounted() {
    this.showIntroHeader = true;
    this.showLoading = true;
  },
  beforeDestroy() {
    this.showIntroHeader = false;
  },
};
</script>
<style scoped>
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
