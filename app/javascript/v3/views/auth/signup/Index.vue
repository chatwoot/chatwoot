<template>
  <div class="flex h-full w-full dark:bg-slate-900 overflow-hidden">
    <div
      class="flex flex-col bg-white dark:bg-slate-800 px-8 sm:px-16 pt-8 pb-16 w-full md:w-2/5 items-center justify-center"
    >
      <div class="mx-auto mb-16">
        <img
          :src="globalConfig.logo"
          :alt="globalConfig.installationName"
          class="h-8 block"
          :class="{ 'dark:hidden': globalConfig.logoDark }"
        />
        <img
          v-if="globalConfig.logoDark"
          :src="globalConfig.logoDark"
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
      <signup-form class="max-w-[420px]" />
    </div>
    <div class="hidden md:block w-3/5 h-screen">
      <testimonials
        v-if="isAChatwootInstance"
        class="flex-1"
        @resize-containers="resizeContainers"
      />
      <div
        v-show="isLoading"
        class="flex items-center justify-center h-full w-full"
      >
        <spinner color-scheme="primary" size="" />
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
