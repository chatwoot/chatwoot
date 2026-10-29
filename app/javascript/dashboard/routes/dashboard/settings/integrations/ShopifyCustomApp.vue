<script setup>
import { computed, onMounted, reactive, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import shopifyAPI from 'dashboard/api/integrations/shopify';
import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const { t } = useI18n();
const SHOPIFY_LOGO = '/dashboard/images/integrations/shopify.png';
const SHOPIFY_DARK_LOGO = '/dashboard/images/integrations/shopify-dark.png';
const configuration = ref(null);
const expanded = ref(false);
const editing = ref(false);
const loading = ref(true);
const saving = ref(false);
const error = ref('');
const form = reactive({
  shop_domain: '',
  client_id: '',
  client_secret: '',
  install_url: '',
});
const canSave = computed(
  () =>
    form.install_url.trim() &&
    (configuration.value ||
      (form.shop_domain.trim() &&
        form.client_id.trim() &&
        form.client_secret.trim()))
);

onMounted(async () => {
  try {
    const { data } = await shopifyAPI.getCustomApp();
    configuration.value = data.custom_app;
    expanded.value = Boolean(configuration.value);
  } catch {
    error.value = t('INTEGRATION_SETTINGS.SHOPIFY.CUSTOM_APP.LOAD_ERROR');
  } finally {
    loading.value = false;
  }
});

const save = async () => {
  saving.value = true;
  error.value = '';
  try {
    const attributes = configuration.value
      ? {
          client_secret: form.client_secret,
          install_url: form.install_url.trim(),
        }
      : {
          ...form,
          shop_domain: form.shop_domain.trim(),
          client_id: form.client_id.trim(),
          install_url: form.install_url.trim(),
        };
    const { data } = await shopifyAPI.saveCustomApp(
      attributes,
      Boolean(configuration.value)
    );
    configuration.value = data.custom_app;
    form.client_secret = '';
    form.install_url = '';
    editing.value = false;
  } catch {
    error.value = t('INTEGRATION_SETTINGS.SHOPIFY.CUSTOM_APP.SAVE_ERROR');
  } finally {
    saving.value = false;
  }
};

const reset = async () => {
  saving.value = true;
  error.value = '';
  try {
    await shopifyAPI.deleteCustomApp();
    configuration.value = null;
    editing.value = false;
    Object.keys(form).forEach(key => {
      form[key] = '';
    });
  } catch {
    error.value = t('INTEGRATION_SETTINGS.SHOPIFY.CUSTOM_APP.RESET_ERROR');
  } finally {
    saving.value = false;
  }
};

const connect = async () => {
  saving.value = true;
  error.value = '';
  try {
    await shopifyAPI.saveCustomApp({ enabled: true }, true);
    const { data } = await shopifyAPI.connect(configuration.value.shop_domain);
    window.location.assign(data.redirect_url);
  } catch {
    error.value = t('INTEGRATION_SETTINGS.SHOPIFY.CUSTOM_APP.CONNECT_ERROR');
  } finally {
    saving.value = false;
  }
};
</script>

<template>
  <section
    class="[&_p]:whitespace-normal [&_p]:overflow-visible rounded-xl border border-n-weak bg-n-solid-1 p-6"
  >
    <div class="flex flex-col gap-6 lg:flex-row lg:items-center">
      <div class="flex h-16 w-16 shrink-0 items-center justify-center">
        <img
          :src="SHOPIFY_LOGO"
          alt=""
          class="block max-w-full rounded-md border border-n-weak bg-n-alpha-3 shadow-sm dark:hidden"
        />
        <img
          :src="SHOPIFY_DARK_LOGO"
          alt=""
          class="hidden max-w-full rounded-md border border-n-weak bg-n-alpha-2 shadow-sm dark:block"
        />
      </div>
      <div class="min-w-0 flex-1">
        <button
          type="button"
          class="flex w-full items-center justify-between gap-3 border-0 bg-transparent p-0 text-start"
          :aria-expanded="expanded"
          @click="expanded = !expanded"
        >
          <span class="text-base font-medium text-n-slate-12">{{
            t('INTEGRATION_SETTINGS.SHOPIFY.CUSTOM_APP.TITLE')
          }}</span>
          <span class="text-sm text-n-blue-11">{{
            t('INTEGRATION_SETTINGS.SHOPIFY.CUSTOM_APP.ADVANCED')
          }}</span>
        </button>
        <p class="mb-0 mt-2 text-sm text-n-slate-11">
          {{ t('INTEGRATION_SETTINGS.SHOPIFY.CUSTOM_APP.DESCRIPTION') }}
        </p>
      </div>
    </div>
    <div v-if="expanded" class="mt-6 flex flex-col gap-6">
      <div class="rounded-lg bg-n-alpha-2 p-4 text-sm text-n-slate-11">
        {{ t('INTEGRATION_SETTINGS.SHOPIFY.CUSTOM_APP.BEFORE_START') }}
      </div>
      <div class="flex flex-col gap-3">
        <h3 class="m-0 text-base font-medium text-n-slate-12">
          {{ t('INTEGRATION_SETTINGS.SHOPIFY.CUSTOM_APP.CREATE_TITLE') }}
        </h3>
        <p class="m-0 text-sm text-n-slate-11">
          {{ t('INTEGRATION_SETTINGS.SHOPIFY.CUSTOM_APP.CREATE_HELP') }}
        </p>
        <a
          href="https://dev.shopify.com/dashboard"
          target="_blank"
          rel="noopener noreferrer"
          class="text-sm text-n-blue-11"
        >
          {{ t('INTEGRATION_SETTINGS.SHOPIFY.CUSTOM_APP.OPEN_SHOPIFY') }}
        </a>
        <p class="m-0 text-sm text-n-slate-11">
          {{ t('INTEGRATION_SETTINGS.SHOPIFY.CUSTOM_APP.DISTRIBUTION_HELP') }}
        </p>
      </div>
      <div
        v-if="configuration && !editing"
        class="flex items-center justify-between gap-4 rounded-lg bg-n-alpha-2 p-4"
      >
        <div class="text-sm text-n-slate-11">
          <p class="m-0 font-medium text-n-slate-12">
            {{ configuration.shop_domain }}
          </p>
          <p class="m-0">
            {{ t('INTEGRATION_SETTINGS.SHOPIFY.CUSTOM_APP.DETAILS_SAVED') }}
          </p>
        </div>
        <div class="flex gap-2">
          <Button
            faded
            slate
            :label="t('INTEGRATION_SETTINGS.SHOPIFY.CUSTOM_APP.EDIT')"
            :disabled="saving"
            @click="editing = true"
          />
          <Button
            faded
            ruby
            :label="t('INTEGRATION_SETTINGS.SHOPIFY.CUSTOM_APP.RESET')"
            :disabled="saving"
            @click="reset"
          />
        </div>
      </div>
      <form v-else class="flex flex-col gap-4" @submit.prevent="save">
        <h3 class="m-0 text-base font-medium text-n-slate-12">
          {{ t('INTEGRATION_SETTINGS.SHOPIFY.CUSTOM_APP.DETAILS_TITLE') }}
        </h3>
        <template v-if="!configuration">
          <Input
            v-model="form.shop_domain"
            :label="t('INTEGRATION_SETTINGS.SHOPIFY.CUSTOM_APP.STORE')"
            :message="t('INTEGRATION_SETTINGS.SHOPIFY.CUSTOM_APP.STORE_HELP')"
            placeholder="your-store.myshopify.com"
          />
          <Input
            v-model="form.client_id"
            :label="t('INTEGRATION_SETTINGS.SHOPIFY.CUSTOM_APP.CLIENT_ID')"
            :message="
              t('INTEGRATION_SETTINGS.SHOPIFY.CUSTOM_APP.CREDENTIALS_HELP')
            "
          />
        </template>
        <p v-else class="m-0 text-sm text-n-slate-11">
          {{ configuration.shop_domain }}
        </p>
        <Input
          v-model="form.client_secret"
          type="password"
          :label="t('INTEGRATION_SETTINGS.SHOPIFY.CUSTOM_APP.SECRET')"
          :message="
            configuration
              ? t('INTEGRATION_SETTINGS.SHOPIFY.CUSTOM_APP.SECRET_SAVED')
              : t('INTEGRATION_SETTINGS.SHOPIFY.CUSTOM_APP.SECRET_HELP')
          "
        />
        <Input
          v-model="form.install_url"
          type="password"
          :label="t('INTEGRATION_SETTINGS.SHOPIFY.CUSTOM_APP.INSTALL_URL')"
          :message="t('INTEGRATION_SETTINGS.SHOPIFY.CUSTOM_APP.INSTALL_HELP')"
        />
        <div>
          <Button
            type="submit"
            :label="
              configuration
                ? t('INTEGRATION_SETTINGS.SHOPIFY.CUSTOM_APP.UPDATE')
                : t('INTEGRATION_SETTINGS.SHOPIFY.CUSTOM_APP.SAVE')
            "
            :disabled="loading || saving || !canSave"
            :is-loading="saving"
          />
        </div>
      </form>
      <div
        v-if="configuration"
        class="flex flex-col gap-4 border-t border-n-weak pt-6"
      >
        <h3 class="m-0 text-base font-medium text-n-slate-12">
          {{ t('INTEGRATION_SETTINGS.SHOPIFY.CUSTOM_APP.CONFIGURE_TITLE') }}
        </h3>
        <p class="m-0 text-sm text-n-slate-11">
          {{ t('INTEGRATION_SETTINGS.SHOPIFY.CUSTOM_APP.URL_HELP') }}
        </p>
        <woot-code :script="configuration.callback_url" />
        <p class="m-0 text-sm text-n-slate-11">
          {{ t('INTEGRATION_SETTINGS.SHOPIFY.CUSTOM_APP.SCOPES_HELP') }}
        </p>
        <woot-code script="read_customers,read_orders,read_fulfillments" />
        <p class="m-0 text-sm text-n-slate-11">
          {{ t('INTEGRATION_SETTINGS.SHOPIFY.CUSTOM_APP.WEBHOOK_HELP') }}
        </p>
        <woot-code :script="configuration.webhook_url" />
        <p class="m-0 text-sm text-n-slate-11">
          {{ t('INTEGRATION_SETTINGS.SHOPIFY.CUSTOM_APP.RELEASE_HELP') }}
        </p>
        <div>
          <Button
            :label="t('INTEGRATION_SETTINGS.SHOPIFY.CUSTOM_APP.CONNECT')"
            :is-loading="saving"
            :disabled="saving"
            @click="connect"
          />
        </div>
        <p class="m-0 text-sm text-n-slate-11">
          {{ t('INTEGRATION_SETTINGS.SHOPIFY.CUSTOM_APP.VERIFY_HELP') }}
        </p>
      </div>
      <p v-if="error" role="alert" class="m-0 text-sm text-n-ruby-11">
        {{ error }}
      </p>
      <a
        href="https://shopify.dev/docs/apps/build/dev-dashboard/create-apps-using-dev-dashboard"
        target="_blank"
        rel="noopener noreferrer"
        class="text-sm text-n-blue-11"
      >
        <span>{{
          t('INTEGRATION_SETTINGS.SHOPIFY.CUSTOM_APP.DOCUMENTATION')
        }}</span>
      </a>
    </div>
  </section>
</template>
