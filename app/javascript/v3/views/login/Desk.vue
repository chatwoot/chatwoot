<script setup>
import { onMounted, reactive, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useBranding } from 'shared/composables/useBranding';
import { login } from '../../api/auth';
import wootAPI from '../../api/apiClient';
import FormInput from '../../components/Form/Input.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const { t } = useI18n();
const { replaceInstallationName } = useBranding();
const globalConfig = useMapGetter('globalConfig/get');

const credentials = reactive({
  userId: '',
  pin: '',
});

const deskUsers = ref([]);
const loadingUsers = ref(true);
const showLoading = ref(false);
const hasErrored = ref(false);

const loadDeskUsers = async () => {
  loadingUsers.value = true;
  try {
    const { data } = await wootAPI.get('desk_users');
    deskUsers.value = data?.payload || [];
    if (deskUsers.value.length === 1) {
      credentials.userId = String(deskUsers.value[0].id);
    }
  } catch {
    deskUsers.value = [];
    useAlert(t('LOGIN.DESK.NAME.LOAD_ERROR'));
  } finally {
    loadingUsers.value = false;
  }
};

onMounted(loadDeskUsers);

const submitDeskLogin = async () => {
  const userId = String(credentials.userId || '').trim();
  const pin = credentials.pin.trim();

  if (!userId) {
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
    await login({ user_id: Number(userId), pin });
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
        <label class="block">
          <span class="mb-2 text-sm font-medium text-n-slate-12">
            {{ t('LOGIN.DESK.NAME.LABEL') }}
          </span>
          <select
            v-model="credentials.userId"
            name="desk_user_id"
            required
            class="w-full px-3 py-2 mt-2 text-base bg-white border rounded-lg outline-none border-n-weak text-n-slate-12 focus:border-n-brand dark:bg-n-solid-1"
            :disabled="loadingUsers || !deskUsers.length"
          >
            <option disabled value="">
              {{
                loadingUsers
                  ? t('LOGIN.DESK.NAME.LOADING')
                  : t('LOGIN.DESK.NAME.PLACEHOLDER')
              }}
            </option>
            <option
              v-for="user in deskUsers"
              :key="user.id"
              :value="String(user.id)"
            >
              {{ user.name }}
            </option>
          </select>
        </label>
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
          :disabled="showLoading || loadingUsers || !credentials.userId"
          :is-loading="showLoading"
        />
      </form>
    </section>
  </main>
</template>
