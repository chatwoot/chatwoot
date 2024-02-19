<template>
  <div class="flex h-full w-full dark:bg-slate-900 relative overflow-hidden">
    <div
      class="absolute inset-0 h-full w-full bg-white dark:bg-slate-900 bg-[radial-gradient(var(--w-100)_1px,transparent_1px)] dark:bg-[radial-gradient(var(--w-800)_1px,transparent_1px)] [background-size:16px_16px] z-0"
    />
    <div
      class="absolute h-full w-full bg-signup-gradient dark:bg-signup-gradient-dark top-0 left-0 blur-[3px]"
    />

    <signup-box-SVG />

    <div class="flex w-full h-full z-50 items-center flex-col overflow-y-auto">
      <div class="flex justify-center h-full items-center my-16">
        <div class="min-h-[640px] shrink-1 grow-0 pt-24 pb-8">
          <div
            class="relative bg-white dark:bg-slate-800 before:bg-white before:border-slate-200 dark:before:border-slate-700 dark:before:bg-slate-800 px-16 pt-8 pb-16 max-w-[528px] w-full rounded-3xl signup-box"
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
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';
import SignupForm from './components/Signup/Form.vue';
import SignupBoxSVG from './components/Signup/CutoutSVG.vue';

export default {
  components: {
    SignupBoxSVG,
    SignupForm,
  },
  mixins: [globalConfigMixin],
  computed: {
    ...mapGetters({ globalConfig: 'globalConfig/get' }),
  },
};
</script>
<style scoped>
.signup-box::before {
  -webkit-mask-image: url('#cutoutMask');
  mask-image: url('#cutoutMask');
}
</style>
