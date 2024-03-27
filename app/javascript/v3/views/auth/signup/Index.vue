<template>
  <div class="flex w-full h-full overflow-hidden dark:bg-slate-900">
    <div
      class="flex flex-col items-center justify-center w-full px-8 pt-8 pb-16 bg-white dark:bg-slate-800 sm:px-16 md:w-2/5"
    >
      <div class="mx-auto mb-16">
        <img
          :src="globalConfig.logo"
          :alt="globalConfig.installationName"
          class="block h-8"
          :class="{ 'dark:hidden': globalConfig.logoDark }"
        />
        <img
          v-if="globalConfig.logoDark"
          :src="globalConfig.logoDark"
          :alt="globalConfig.installationName"
          class="hidden w-auto h-8 dark:block"
        />
      </div>
      <div class="mb-8">
        <h2
          class="text-3xl font-medium tracking-wide text-center text-slate-900 dark:text-woot-50"
        >
          <template v-if="isAChatwootInstance">
            {{ $t('REGISTER.TRY_WOOT_CLOUD') }}
          </template>
          <template v-else>
            {{ $t('REGISTER.TRY_WOOT') }}
          </template>
        </h2>
      </div>
      <signup-form class="max-w-[420px]" />
    </div>
    <div class="hidden w-3/5 h-screen md:block">
      <testimonials
        v-if="isAChatwootInstance"
        class="flex-1"
        @resize-containers="resizeContainers"
      />
      <div
        v-show="isLoading"
        class="flex items-center justify-center w-full h-full"
      >
        <spinner color-scheme="primary" />
      </div>
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
