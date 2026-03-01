<script setup>
import { computed } from 'vue';
import { useStore } from 'vuex';
import { useBranding } from 'shared/composables/useBranding';
import SignupForm from './components/Signup/Form.vue';

const store = useStore();
const { replaceInstallationName } = useBranding();
const globalConfig = computed(() => store.getters['globalConfig/get']);
</script>

<template>
  <main
    class="flex flex-col justify-center w-full min-h-screen py-12 bg-n-brand/5 dark:bg-n-background sm:px-6 lg:px-8"
  >
    <section class="max-w-5xl mx-auto">
      <img
        :src="globalConfig.logo"
        :alt="globalConfig.installationName"
        class="block w-auto h-8 mx-auto dark:hidden"
      />
      <img
        v-if="globalConfig.logoDark"
        :src="globalConfig.logoDark"
        :alt="globalConfig.installationName"
        class="hidden w-auto h-8 mx-auto dark:block"
      />
      <h2 class="mt-6 text-3xl font-medium text-center text-n-slate-12">
        {{ replaceInstallationName($t('REGISTER.GET_STARTED')) }}
      </h2>
      <p class="mt-3 text-sm text-center text-n-slate-11">
        {{ $t('REGISTER.HAVE_AN_ACCOUNT') }}
        <router-link to="/app/login" class="text-link text-n-brand">
          {{ $t('LOGIN.SUBMIT') }}
        </router-link>
      </p>
    </section>

    <section
      class="bg-white shadow sm:mx-auto mt-11 sm:w-full sm:max-w-lg dark:bg-n-solid-2 p-11 sm:shadow-lg sm:rounded-lg"
    >
      <SignupForm />
    </section>
  </main>
</template>
