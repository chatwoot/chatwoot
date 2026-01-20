<script>
import { mapGetters } from 'vuex';
import { useBranding } from 'shared/composables/useBranding';
import SignupForm from './components/Signup/Form.vue';
import Testimonials from './components/Testimonials/Index.vue';
import Spinner from 'shared/components/Spinner.vue';
import LanguageSelect from '../../../components/Form/LanguageSelect.vue';

export default {
  components: {
    SignupForm,
    Spinner,
    Testimonials,
    LanguageSelect,
  },
  setup() {
    const { replaceInstallationName } = useBranding();
    return { replaceInstallationName };
  },
  data() {
    return {
      isLoading: false,
      selectedLocale: this.getBrowserDefaultLocale(),
    };
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
  mounted() {
    // Set initial locale from browser default
    this.selectedLocale = this.getBrowserDefaultLocale();
  },
  methods: {
    getBrowserDefaultLocale() {
      const enabledLanguages = window.chatwootConfig?.enabledLanguages || [];
      const browserLang = navigator.language || navigator.userLanguage || 'en';
      const normalizedLang = browserLang.replace('-', '_');

      // Try exact match first (e.g., pt_BR)
      const exactMatch = enabledLanguages.find(
        lang => lang.iso_639_1_code === normalizedLang
      );
      if (exactMatch) return exactMatch.iso_639_1_code;

      // Try base language match (e.g., pt)
      const baseLang = normalizedLang.split('_')[0];
      const baseMatch = enabledLanguages.find(
        lang => lang.iso_639_1_code === baseLang
      );
      if (baseMatch) return baseMatch.iso_639_1_code;

      // Default to current i18n locale or English
      return window.chatwootConfig?.selectedLocale || 'en';
    },
    resizeContainers() {
      this.isLoading = false;
    },
    onLocaleChange(locale) {
      this.selectedLocale = locale;
      // Update the page locale immediately
      this.$root.$i18n.locale = locale;
    },
  },
};
</script>

<template>
  <div class="w-full h-full bg-n-background">
    <div v-show="!isLoading" class="flex h-full min-h-screen items-center">
      <div
        class="flex-1 min-h-[640px] inline-flex items-center h-full justify-center overflow-auto py-6"
      >
        <div class="px-8 max-w-[560px] w-full overflow-auto">
          <div class="mb-4 flex items-start justify-between">
            <div>
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
              <h2
                class="mt-6 text-3xl font-medium text-left mb-7 text-n-slate-12"
              >
                {{ $t('REGISTER.TRY_WOOT') }}
              </h2>
            </div>
            <div class="flex-shrink-0 w-40">
              <LanguageSelect
                v-model="selectedLocale"
                @change="onLocaleChange"
              />
            </div>
          </div>
          <SignupForm :locale="selectedLocale" />
          <div class="px-1 text-sm text-n-slate-12">
            {{ $t('REGISTER.HAVE_AN_ACCOUNT') }}
            <router-link class="text-link text-n-brand ml-1" to="/app/login">
              {{ replaceInstallationName($t('LOGIN.TITLE')) }}
            </router-link>
          </div>
        </div>
      </div>
      <Testimonials
        v-if="isAChatwootInstance"
        class="flex-1"
        @resize-containers="resizeContainers"
      />
    </div>
    <div
      v-show="isLoading"
      class="flex items-center min-h-screen justify-center w-full h-full"
    >
      <Spinner color-scheme="primary" size="" />
    </div>
  </div>
</template>
