<script setup>
import { computed } from 'vue';
import { useStore } from 'vuex';
import SignupForm from './components/Signup/Form.vue';

const store = useStore();
const globalConfig = computed(() => store.getters['globalConfig/get']);
</script>

<template>
  <main
    class="flex flex-col justify-center w-full min-h-screen py-12 bg-n-brand/5 dark:bg-n-background sm:px-6 lg:px-8"
  >
    <section class="max-w-5xl mx-auto">
      <img
        :src="globalConfig.logo || '/brand-assets/logo.svg'"
        :alt="globalConfig.installationName"
        class="block w-auto h-24 mx-auto rounded-2xl"
        :class="{
          'dark:hidden': !globalConfig.logo || !!globalConfig.logoDark,
        }"
      />
      <img
        v-if="!globalConfig.logo || globalConfig.logoDark"
        :src="globalConfig.logoDark || '/brand-assets/logo_dark.svg'"
        :alt="globalConfig.installationName"
        class="hidden w-auto h-24 mx-auto rounded-2xl dark:block"
      />
      <h2 class="mt-6 text-3xl font-medium text-center text-n-slate-12">
        {{ $t('REGISTER.TRY_WOOT') }}
      </h2>
      <p class="mt-3 text-sm font-medium text-center text-n-slate-12">
        {{ $t('REGISTER.HAVE_AN_ACCOUNT') }}
        <router-link
          to="/app/login"
          class="font-medium text-n-blue-10 hover:text-n-blue-15"
        >
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
