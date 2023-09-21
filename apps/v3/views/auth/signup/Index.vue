<template>
  <div class="h-full w-full dark:bg-slate-900">
    <div v-show="!isLoading" class="flex h-full">
      <div
        class="flex-1 min-h-[640px] inline-flex items-center h-full justify-center overflow-auto py-6"
      >
        <div class="px-8 max-w-[560px] w-full overflow-auto">
          <div class="mb-4">
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
            <h2
              class="mb-7 mt-6 text-left text-3xl font-medium text-slate-900 dark:text-woot-50"
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
