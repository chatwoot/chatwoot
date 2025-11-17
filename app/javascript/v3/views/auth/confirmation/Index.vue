<script>
import { mapGetters } from 'vuex';
import { useBranding } from 'shared/composables/useBranding';
import { DEFAULT_REDIRECT_URL } from 'dashboard/constants/globals';
import { verifyPasswordToken } from '../../../api/auth';
import Spinner from 'shared/components/Spinner.vue';

export default {
  components: { Spinner },
  props: {
    confirmationToken: {
      type: String,
      default: '',
    },
  },
  setup() {
    const { replaceInstallationName } = useBranding();
    return { replaceInstallationName };
  },
  computed: {
    ...mapGetters({ globalConfig: 'globalConfig/get' }),
  },
  mounted() {
    this.confirmToken();
  },
  methods: {
    async confirmToken() {
      try {
        await verifyPasswordToken({
          confirmationToken: this.confirmationToken,
        });
        window.location = DEFAULT_REDIRECT_URL;
      } catch (error) {
        window.location = DEFAULT_REDIRECT_URL;
      }
    },
  },
};
</script>

<template>
  <div
    class="flex items-center justify-center min-h-screen h-full bg-n-background w-full"
  >
    <div class="text-center">
      <img
        :src="globalConfig.logo"
        :alt="globalConfig.installationName"
        class="block w-auto h-8 mx-auto dark:hidden mb-4"
      />
      <img
        v-if="globalConfig.logoDark"
        :src="globalConfig.logoDark"
        :alt="globalConfig.installationName"
        class="hidden w-auto h-8 mx-auto dark:block mb-4"
      />
      <div class="flex items-center justify-center">
        <Spinner color-scheme="primary" size="" />
        <div class="ml-2 text-n-slate-11">{{ $t('CONFIRM_EMAIL') }}</div>
      </div>
    </div>
  </div>
</template>
