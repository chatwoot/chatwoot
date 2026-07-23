<script setup>
import { reactive, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useBranding } from 'shared/composables/useBranding';
import { login } from '../../api/auth';
import FormInput from '../../components/Form/Input.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const { t } = useI18n();
const { replaceInstallationName } = useBranding();
const globalConfig = useMapGetter('globalConfig/get');

const credentials = reactive({
  name: '',
  pin: '',
});

const showLoading = ref(false);
const hasErrored = ref(false);

const submitDeskLogin = async () => {
  const name = credentials.name.trim();
  const pin = credentials.pin.trim();

  if (!name) {
    useAlert(t('LOGIN.DESK.NAME.ERROR'));
    return;
  }

  if (!/^\d{4,6}$/.test(pin)) {
    useAlert(t('LOGIN.DESK.PIN.ERROR'));
    return;
  }

  showLoading.value = true;
  hasErrored.value = false;

  try {
    await login({ name, pin });
    useAlert(t('LOGIN.API.SUCCESS_MESSAGE'));
  } catch (error) {
    hasErrored.value = true;
    showLoading.value = false;
    useAlert(error?.message || t('LOGIN.DESK.API.UNAUTH'));
  }
};
</script>

<template>
  <main
    class="flex flex-col w-full min-h-screen py-20 bg-n-brand/5 dark:bg-n-background sm:px-6 lg:px-8"
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
        {{ replaceInstallationName(t('LOGIN.DESK.TITLE')) }}
      </h2>
      <p class="mt-3 text-sm text-center text-n-slate-11">
        {{ t('LOGIN.DESK.SUBTITLE') }}
      </p>
    </section>

    <section
      class="bg-white shadow sm:mx-auto mt-11 sm:w-full sm:max-w-lg dark:bg-n-solid-2 p-11 sm:shadow-lg sm:rounded-lg"
      :class="{ 'animate-wiggle': hasErrored }"
    >
      <form class="space-y-5" @submit.prevent="submitDeskLogin">
        <FormInput
          v-model="credentials.name"
          name="desk_name"
          type="text"
          required
          autocomplete="username"
          :label="t('LOGIN.DESK.NAME.LABEL')"
          :placeholder="t('LOGIN.DESK.NAME.PLACEHOLDER')"
        />
        <FormInput
          v-model="credentials.pin"
          name="desk_pin"
          type="password"
          inputmode="numeric"
          pattern="[0-9]*"
          maxlength="6"
          required
          autocomplete="current-password"
          :label="t('LOGIN.DESK.PIN.LABEL')"
          :placeholder="t('LOGIN.DESK.PIN.PLACEHOLDER')"
        />
        <NextButton
          lg
          type="submit"
          class="w-full"
          :label="t('LOGIN.DESK.SUBMIT')"
          :disabled="showLoading"
          :is-loading="showLoading"
        />
      </form>
    </section>
  </main>
</template>
