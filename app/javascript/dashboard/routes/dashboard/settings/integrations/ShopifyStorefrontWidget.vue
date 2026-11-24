<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import shopifyAPI from 'dashboard/api/integrations/shopify';
import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';

const props = defineProps({
  storeDomain: { type: String, required: true },
});

const { t } = useI18n();
const store = useStore();
const inboxes = useMapGetter('inboxes/getWebsiteInboxes');
const selectedInboxId = ref('');
const savedInboxId = ref(null);
const themeEditorUrl = ref('');
const isLoading = ref(true);
const loadFailed = ref(false);
const isSaving = ref(false);
const needsReauthorization = ref(false);
const isReconnecting = ref(false);
const inboxDialog = ref(null);
const inboxOptions = computed(() =>
  inboxes.value.map(({ id, name }) => ({ value: id, label: name }))
);
const savedInbox = computed(() =>
  inboxes.value.find(({ id }) => id === savedInboxId.value)
);
const inboxDialogTitle = computed(() =>
  savedInbox.value
    ? t('INTEGRATION_SETTINGS.SHOPIFY.STOREFRONT_WIDGET.CHANGE_INBOX')
    : t('INTEGRATION_SETTINGS.SHOPIFY.STOREFRONT_WIDGET.SELECT_INBOX')
);
const canSave = computed(
  () =>
    selectedInboxId.value !== savedInboxId.value &&
    inboxOptions.value.some(({ value }) => value === selectedInboxId.value)
);

const setWidget = ({ inbox_id: inboxId, theme_editor_url: url }) => {
  selectedInboxId.value = inboxId ?? '';
  savedInboxId.value = inboxId;
  themeEditorUrl.value = url;
};

const openInboxDialog = () => {
  selectedInboxId.value = savedInbox.value?.id ?? '';
  inboxDialog.value.open();
};

const handleReauthorizationError = error => {
  needsReauthorization.value =
    error.response?.data?.code === 'shopify_reauthorization_required';
  return needsReauthorization.value;
};

const reconnectStore = async () => {
  isReconnecting.value = true;
  try {
    const { data } = await shopifyAPI.connect(props.storeDomain);
    window.location.assign(data.redirect_url);
  } catch {
    useAlert(t('INTEGRATION_SETTINGS.SHOPIFY.ERROR'));
    isReconnecting.value = false;
  }
};

const loadWidget = async () => {
  isLoading.value = true;
  loadFailed.value = false;
  needsReauthorization.value = false;
  try {
    const [{ data }, inboxesLoaded] = await Promise.all([
      shopifyAPI.getStorefrontWidget(),
      store.dispatch('inboxes/get'),
    ]);
    if (!inboxesLoaded) {
      loadFailed.value = true;
      return;
    }
    setWidget(data);
  } catch (error) {
    loadFailed.value = !handleReauthorizationError(error);
  } finally {
    isLoading.value = false;
  }
};

const saveWidget = async () => {
  if (isSaving.value || !canSave.value) return;

  isSaving.value = true;
  try {
    const { data } = await shopifyAPI.saveStorefrontWidget(
      selectedInboxId.value
    );
    setWidget(data);
    inboxDialog.value.close();
  } catch (error) {
    if (handleReauthorizationError(error)) {
      inboxDialog.value.close();
    } else {
      useAlert(t('INTEGRATION_SETTINGS.SHOPIFY.STOREFRONT_WIDGET.SAVE_ERROR'));
    }
  } finally {
    isSaving.value = false;
  }
};

onMounted(loadWidget);
</script>

<template>
  <section class="rounded-xl outline outline-1 outline-n-container bg-n-card">
    <h2 class="px-6 py-4 text-heading-2 text-n-slate-12">
      {{ t('INTEGRATION_SETTINGS.SHOPIFY.STOREFRONT_WIDGET.TITLE') }}
    </h2>

    <woot-loading-state v-if="isLoading" />
    <div
      v-else-if="needsReauthorization"
      class="flex flex-wrap items-center justify-between gap-3 border-t border-n-weak px-6 py-4"
    >
      <p role="alert" class="mb-0 text-body-main text-n-ruby-9">
        {{ t('INTEGRATION_SETTINGS.SHOPIFY.STOREFRONT_WIDGET.RECONNECT_HELP') }}
      </p>
      <Button
        faded
        slate
        sm
        :label="t('INTEGRATION_SETTINGS.SHOPIFY.STOREFRONT_WIDGET.RECONNECT')"
        :is-loading="isReconnecting"
        :disabled="isReconnecting"
        @click="reconnectStore"
      />
    </div>
    <div
      v-else-if="loadFailed"
      class="flex flex-wrap items-center justify-between gap-3 border-t border-n-weak px-6 py-4"
    >
      <p role="alert" class="mb-0 text-body-main text-n-ruby-9">
        {{ t('INTEGRATION_SETTINGS.SHOPIFY.STOREFRONT_WIDGET.LOAD_ERROR') }}
      </p>
      <Button
        faded
        slate
        sm
        :label="t('INTEGRATION_SETTINGS.SHOPIFY.STOREFRONT_WIDGET.RETRY')"
        @click="loadWidget"
      />
    </div>

    <template v-else>
      <div
        class="flex flex-wrap items-center justify-between gap-3 border-t border-n-weak px-6 py-4"
      >
        <div class="min-w-0">
          <h3 class="text-heading-3 text-n-slate-12">
            {{
              t('INTEGRATION_SETTINGS.SHOPIFY.STOREFRONT_WIDGET.INBOX_LABEL')
            }}
          </h3>
          <p
            v-if="savedInbox"
            class="mb-0 break-words text-body-main text-n-slate-11"
          >
            {{ savedInbox.name }}
          </p>
          <p
            v-else-if="!inboxOptions.length"
            class="mb-0 text-body-main text-n-slate-11"
          >
            {{ t('INTEGRATION_SETTINGS.SHOPIFY.STOREFRONT_WIDGET.NO_INBOXES') }}
          </p>
        </div>
        <Button
          v-if="inboxOptions.length"
          type="button"
          faded
          slate
          sm
          :label="inboxDialogTitle"
          @click="openInboxDialog"
        />
      </div>

      <div
        v-if="savedInbox && themeEditorUrl"
        class="flex flex-wrap items-center justify-between gap-x-5 gap-y-3 border-t border-n-weak px-6 py-4"
      >
        <div class="min-w-0 flex-1 basis-60">
          <h3 class="text-heading-3 text-n-slate-12">
            {{
              t(
                'INTEGRATION_SETTINGS.SHOPIFY.STOREFRONT_WIDGET.STOREFRONT_LABEL'
              )
            }}
          </h3>
          <p class="mb-0 text-body-main text-n-slate-11">
            {{
              t(
                'INTEGRATION_SETTINGS.SHOPIFY.STOREFRONT_WIDGET.ENABLE_IN_SHOPIFY'
              )
            }}
          </p>
        </div>
        <a
          :href="themeEditorUrl"
          target="_blank"
          rel="noopener noreferrer"
          class="inline-flex min-h-8 items-center gap-2 rounded-lg bg-n-brand px-3 py-1.5 text-sm font-medium text-white hover:brightness-110 hover:text-white hover:no-underline focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-n-brand"
        >
          {{
            t(
              'INTEGRATION_SETTINGS.SHOPIFY.STOREFRONT_WIDGET.OPEN_THEME_EDITOR'
            )
          }}
          <Icon icon="i-lucide-external-link" class="size-3.5 shrink-0" />
        </a>
      </div>
    </template>

    <Dialog
      ref="inboxDialog"
      :title="inboxDialogTitle"
      :description="
        t('INTEGRATION_SETTINGS.SHOPIFY.STOREFRONT_WIDGET.DESCRIPTION')
      "
      :confirm-button-label="
        t('INTEGRATION_SETTINGS.SHOPIFY.STOREFRONT_WIDGET.SAVE')
      "
      :disable-confirm-button="!canSave"
      :disable-close="isSaving"
      :is-loading="isSaving"
      @confirm="saveWidget"
    >
      <div class="flex flex-col gap-1">
        <span class="text-sm font-medium text-n-slate-12">
          {{ t('INTEGRATION_SETTINGS.SHOPIFY.STOREFRONT_WIDGET.INBOX_LABEL') }}
        </span>
        <ComboBox
          v-model="selectedInboxId"
          :options="inboxOptions"
          :placeholder="
            t('INTEGRATION_SETTINGS.SHOPIFY.STOREFRONT_WIDGET.SELECT_INBOX')
          "
          :disabled="isSaving"
          class="[&>div>button]:bg-n-alpha-black2 [&>div>button:not(.focused)]:dark:outline-n-weak [&>div>button:not(.focused)]:hover:!outline-n-slate-6"
        />
      </div>
    </Dialog>
  </section>
</template>
