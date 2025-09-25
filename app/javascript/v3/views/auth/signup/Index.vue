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

<template>
  <div class="w-full min-h-screen bg-background">
    <img src="v3/assets/images/Mascot-Laptop.png" alt="Mascot" class="z-50 absolute items-center top-1/3 right-2/3 h-[500px]"/>
    <div v-show="!isLoading" class="flex w-full">
      <div
        class="flex flex-col w-full p-5 md:p-8 overflow-x-hidden items-center justify-center"
      >
        <div class="w-full max-w-md mx-auto">
          <img
            src="v3/assets/images/logo.svg"
            alt="logo"
            class="block w-auto h-16 mx-auto mb-6"
          />

          <div class="mb-4">
            <h2
              class="text-3xl font-medium text-center mb-7 text-slate-900 dark:text-woot-50"
            >
              {{ $t('REGISTER.TRY_WOOT') }}
            </h2>
          </div>

          <SignupForm />

          <div
            class="px-1 mt-4 text-sm text-slate-800 dark:text-woot-50 text-center"
          >
            <span>{{ $t('REGISTER.HAVE_AN_ACCOUNT') }}</span>
            <router-link class="text-link" to="/app/login">
              {{ ' ' }}
              {{
                useInstallationName(
                  $t('LOGIN.SUBMIT'),
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
      class="flex items-center justify-center w-full h-full"
    >
      <Spinner color-scheme="primary" size="" />
    </div>
  </div>
</template>

<style scoped>
.bg-background {
  background: linear-gradient(
    to bottom right,
    rgba(255, 250, 199, 0.4),       
    rgba(217, 255, 228, 0.3),      
    rgba(34, 197, 94, 0.1)  
  );
  min-height: 100vh;
  height: auto;
}

.dark .bg-background {
  background: linear-gradient(
    to bottom right,
    rgba(15, 23, 42, 0.95),
    rgba(30, 41, 59, 0.9)
  );
  min-height: 100vh;
  height: auto;
}
</style>