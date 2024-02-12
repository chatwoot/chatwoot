<template>
  <div class="h-full w-full dark:bg-slate-900 relative">
    <div
      class="absolute inset-0 h-full w-full bg-white dark:bg-slate-900 bg-[radial-gradient(var(--w-100)_1px,transparent_1px)] dark:bg-[radial-gradient(var(--w-800)_1px,transparent_1px)] [background-size:16px_16px] z-0"
    />
    <div
      class="absolute h-full w-full overlay-gradient top-0 left-0 blur-[3px]"
    />

    <svg
      width="528"
      height="96"
      viewBox="0 0 528 96"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      <defs>
        <mask id="cutoutMask">
          <path
            d="M263.999 65.0769C293.048 65.0769 317.641 45.9499 325.929 19.5735C329.219 9.10348 337.794 0 348.744 0H508.172C519.122 0 527.999 8.89875 527.999 19.8759V95.5C527.999 95.5 519.122 95.5 508.172 95.5H263.999H-0.000976562V19.8759C-0.000976562 8.89877 8.87604 0 19.8264 0H179.254C190.204 0 198.779 9.10349 202.069 19.5735C210.357 45.9499 234.95 65.0769 263.999 65.0769Z"
            fill="#FCFCFD"
          />
        </mask>
      </defs>
    </svg>

    <div v-show="!isLoading" class="flex h-full relative z-50">
      <div
        class="flex-1 min-h-[640px] inline-flex items-center h-full justify-center overflow-auto py-6"
      >
        <div
          class="relative bg-white dark:bg-slate-800 before:bg-white dark:before:bg-slate-800 px-16 pt-8 pb-16 max-w-[528px] w-full rounded-3xl signup-box"
        >
          <div class="absolute -top-[116px] right-0 left-0 w-24 h-24 mx-auto">
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
import Spinner from 'shared/components/Spinner.vue';

export default {
  components: {
    SignupForm,
    Spinner,
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
.signup-box::before {
  width: 100%;
  height: 200px;
  content: '';
  display: block;
  left: 0;
  top: -66px;
  position: absolute;
  -webkit-mask-image: url('#cutoutMask');
  mask-image: url('#cutoutMask');
}
</style>
