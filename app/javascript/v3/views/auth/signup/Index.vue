<script setup>
import { computed } from 'vue';
import { useStore } from 'vuex';
import SignupForm from './components/Signup/Form.vue';

const store = useStore();
const globalConfig = computed(() => store.getters['globalConfig/get']);
const showDefaultSignupChrome = computed(() =>
  ['Converso', 'Chatwoot'].includes(globalConfig.value.installationName)
);
</script>

<template>
  <main
    class="flex min-h-screen w-full flex-col bg-n-brand/5 py-16 dark:bg-background sm:px-6 sm:py-20 md:py-24 lg:px-8"
  >
    <section class="mx-auto w-full max-w-5xl px-4 sm:px-0">
      <div class="flex flex-col items-center justify-center">
        <img
          :src="globalConfig.logoThumbnail"
          :alt="globalConfig.installationName"
          class="block h-24 w-auto shrink-0 sm:h-28 md:h-32"
        />
        <div
          class="flex flex-col items-center gap-0.5 text-center sm:items-start sm:text-left"
        >
          <span
            class="font-inter text-4xl font-bold uppercase leading-none tracking-tight text-transparent bg-gradient-to-r from-woot-500 via-secondary to-green-200 bg-clip-text sm:text-5xl"
          >
            {{ globalConfig.installationName }}
          </span>
        </div>
      </div>
    </section>

    <section
      class="mt-12 mb-10 overflow-hidden rounded-xl bg-white px-8 pb-0 pt-8 shadow-sm ring-1 ring-n-container dark:bg-surface-container dark:ring-0 dark:shadow-xl sm:mx-auto sm:mt-14 sm:mb-12 sm:w-full sm:max-w-lg sm:px-10 sm:pt-10"
    >
      <div>
        <h1
          class="mb-2 text-[2rem] font-bold leading-[1.15] tracking-tight text-balance text-n-slate-12 dark:text-on-surface sm:text-[2.125rem]"
        >
          {{
            showDefaultSignupChrome
              ? $t('REGISTER.GET_STARTED')
              : $t('REGISTER.TRY_WOOT')
          }}
        </h1>
        <p
          class="mb-6 max-w-md text-sm leading-relaxed text-n-slate-11 dark:text-on-surface-variant sm:mb-8"
        >
          {{
            $t('REGISTER.SIGNUP_SUBTITLE', {
              productName: globalConfig.installationName,
            })
          }}
        </p>
        <SignupForm />
      </div>
      <div
        class="mt-8 pb-8 pt-1 text-center text-xs leading-relaxed text-n-slate-11 dark:text-on-surface-variant sm:mt-10 sm:pb-10 sm:pt-2 sm:text-sm"
      >
        <div
          aria-hidden="true"
          class="mx-auto mb-5 h-px w-[min(10rem,62%)] max-w-full bg-gradient-to-r from-transparent via-n-container to-transparent opacity-80 dark:via-outline-variant sm:mb-6 sm:w-[min(12rem,58%)]"
        />
        <span class="text-n-slate-11 dark:text-on-surface-variant">
          {{ $t('REGISTER.HAVE_AN_ACCOUNT') }}
        </span>
        {{ ' ' }}
        <router-link
          to="/app/login"
          class="font-semibold text-n-brand underline-offset-4 transition-opacity hover:opacity-90 hover:underline dark:text-secondary"
        >
          {{ $t('LOGIN.SUBMIT') }}
        </router-link>
      </div>
    </section>
  </main>
</template>
