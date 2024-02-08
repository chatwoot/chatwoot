<template>
  <div class="h-full w-full dark:bg-slate-900 relative">
    <div
      class="absolute inset-0 h-full w-full bg-white dark:bg-slate-900 bg-[radial-gradient(var(--w-100)_1px,transparent_1px)] dark:bg-[radial-gradient(var(--w-800)_1px,transparent_1px)] [background-size:16px_16px] z-0"
    />
    <div
      class="absolute h-full w-full overlay-gradient top-0 left-0 blur-[3px]"
    />
    <div v-show="!isLoading" class="flex h-full relative z-50">
      <div
        class="flex-1 min-h-[640px] inline-flex items-center h-full justify-center overflow-auto py-6"
      >
        <div
          class="relative px-16 py-[104px] max-w-[528px] bg-[url('/assets/images/dashboard/onboarding/signup-card-box.svg')] dark:bg-[url('/assets/images/dashboard/onboarding/signup-card-box-dark.svg')] bg-contain bg-top bg-no-repeat w-full overflow-aut rounded-3xl"
        >
          <div class="absolute -top-12 right-0 left-0 w-24 h-24 mx-auto">
            <img
              :src="globalConfig.logoThumbnail"
              :alt="globalConfig.installationName"
              class="h-24 w-24 block"
              :class="{ 'dark:hidden': globalConfig.logoDarkThumbnail }"
            />
            <img
              v-if="globalConfig.logoDarkThumbnail"
              :src="globalConfig.logoDarkThumbnail"
              :alt="globalConfig.installationName"
              class="h-8 w-auto hidden dark:block"
            />
          </div>
          <div class="mb-8">
            <h2
              class="text-center text-3xl tracking-wide font-medium text-slate-900 dark:text-woot-50"
            >
              {{ $t('REGISTER.TRY_WOOT') }}
            </h2>
          </div>
          <signup-form />
          <div class="text-sm text-slate-800 dark:text-woot-50 px-1">
            <span>{{ $t('REGISTER.HAVE_AN_ACCOUNT') }}</span>
            <router-link class="text-link" to="/app/login">
              {{
                useInstallationName(
                  $t('LOGIN.TITLE'),
                  globalConfig.installationName
                )
              }}
            </router-link>
          </div>
        </div>
      </div>
      <testimonials
        v-if="isAChatwootInstance"
        class="flex-1"
        @resize-containers="resizeContainers"
      />
    </div>
    <div
      v-show="isLoading"
      class="flex items-center justify-center h-full w-full"
    >
      <spinner color-scheme="primary" size="" />
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';
import SignupForm from './components/Signup/Form.vue';
import Testimonials from './components/Testimonials/Index.vue';
import Spinner from 'shared/components/Spinner.vue';

export default {
  components: {
    SignupForm,
    Spinner,
    Testimonials,
  },
  mixins: [globalConfigMixin],
  data() {
    return { isLoading: false };
  },
  computed: {
    ...mapGetters({ globalConfig: 'globalConfig/get' }),
    isAChatwootInstance() {
      return this.globalConfig.installationName === 'Chatwoot';
    },
  },
  beforeMount() {
    this.isLoading = this.isAChatwootInstance;
  },
  methods: {
    resizeContainers() {
      this.isLoading = false;
    },
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
