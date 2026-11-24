<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import shopifyAPI from 'dashboard/api/integrations/shopify';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  storeDomain: { type: String, required: true },
});

const { t } = useI18n();
const store = useStore();
const inboxes = useMapGetter('inboxes/getWebsiteInboxes');
const selectedInboxId = ref(null);
const savedInboxId = ref(null);
const themeEditorUrl = ref('');
const isLoading = ref(true);
const loadFailed = ref(false);
const isSaving = ref(false);
const needsReauthorization = ref(false);
const isReconnecting = ref(false);
const canSave = computed(
  () => selectedInboxId.value && selectedInboxId.value !== savedInboxId.value
);

const setWidget = ({ inbox_id: inboxId, theme_editor_url: url }) => {
  selectedInboxId.value = inboxId;
  savedInboxId.value = inboxId;
  themeEditorUrl.value = url;
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
  isSaving.value = true;
  try {
    const { data } = await shopifyAPI.saveStorefrontWidget(
      selectedInboxId.value
    );
    setWidget(data);
  } catch (error) {
    if (!handleReauthorizationError(error)) {
      useAlert(t('INTEGRATION_SETTINGS.SHOPIFY.STOREFRONT_WIDGET.SAVE_ERROR'));
    }
  } finally {
    isSaving.value = false;
  }
};

onMounted(loadWidget);
</script>

<template>
  <section
    class="flex flex-col gap-4 rounded-md bg-n-alpha-3 px-6 py-5 outline outline-1 outline-n-container"
  >
    <div>
      <h5 class="tracking-tight text-n-slate-12">
        {{ t('INTEGRATION_SETTINGS.SHOPIFY.STOREFRONT_WIDGET.TITLE') }}
      </h5>
      <p class="text-sm text-n-slate-11">
        {{ t('INTEGRATION_SETTINGS.SHOPIFY.STOREFRONT_WIDGET.DESCRIPTION') }}
      </p>
    </div>

    <woot-loading-state v-if="isLoading" />
    <div v-else-if="needsReauthorization" class="flex items-center gap-3">
      <p role="alert" class="text-sm text-n-ruby-9">
        {{ t('INTEGRATION_SETTINGS.SHOPIFY.STOREFRONT_WIDGET.RECONNECT_HELP') }}
      </p>
      <Button
        faded
        slate
        :label="t('INTEGRATION_SETTINGS.SHOPIFY.STOREFRONT_WIDGET.RECONNECT')"
        :is-loading="isReconnecting"
        :disabled="isReconnecting"
        @click="reconnectStore"
      />
    </div>
    <div v-else-if="loadFailed" class="flex items-center gap-3">
      <p role="alert" class="text-sm text-n-ruby-9">
        {{ t('INTEGRATION_SETTINGS.SHOPIFY.STOREFRONT_WIDGET.LOAD_ERROR') }}
      </p>
      <Button
        faded
        slate
        :label="t('INTEGRATION_SETTINGS.SHOPIFY.STOREFRONT_WIDGET.RETRY')"
        @click="loadWidget"
      />
    </div>

    <template v-else>
      <form
        v-if="inboxes.length"
        class="flex flex-wrap items-end gap-3"
        @submit.prevent="saveWidget"
      >
        <label class="m-0 min-w-52 text-sm text-n-slate-12">
          {{ t('INTEGRATION_SETTINGS.SHOPIFY.STOREFRONT_WIDGET.INBOX_LABEL') }}
          <select
            v-model="selectedInboxId"
            class="m-0 mt-1"
            :disabled="isSaving"
          >
            <option :value="null" disabled>
              {{
                t('INTEGRATION_SETTINGS.SHOPIFY.STOREFRONT_WIDGET.SELECT_INBOX')
              }}
            </option>
            <option v-for="inbox in inboxes" :key="inbox.id" :value="inbox.id">
              {{ inbox.name }}
            </option>
          </select>
        </label>
        <Button
          type="submit"
          solid
          blue
          :is-loading="isSaving"
          :disabled="!canSave || isSaving"
          :label="t('INTEGRATION_SETTINGS.SHOPIFY.STOREFRONT_WIDGET.SAVE')"
        />
      </form>
      <router-link
        class="text-sm text-n-brand underline"
        :to="{
          name: 'settings_inboxes_page_channel',
          params: { sub_page: 'website' },
          query: { from: 'shopify' },
        }"
      >
        {{ t('INTEGRATION_SETTINGS.SHOPIFY.STOREFRONT_WIDGET.CREATE_INBOX') }}
      </router-link>

      <div
        v-if="themeEditorUrl && !canSave"
        class="flex flex-col items-start gap-1"
      >
        <a
          :href="themeEditorUrl"
          target="_blank"
          rel="noopener noreferrer"
          class="text-sm text-n-brand underline"
        >
          {{
            t(
              'INTEGRATION_SETTINGS.SHOPIFY.STOREFRONT_WIDGET.OPEN_THEME_EDITOR'
            )
          }}
        </a>
        <p class="text-sm text-n-slate-11">
          {{
            t(
              'INTEGRATION_SETTINGS.SHOPIFY.STOREFRONT_WIDGET.ENABLE_IN_SHOPIFY'
            )
          }}
        </p>
      </div>
    </template>
  </section>
</template>
