<script setup>
import { computed, onActivated, ref, watch } from 'vue';
import { picoSearch } from '@scmmishra/pico-search';
import { useI18n } from 'vue-i18n';

import { useAlert } from 'dashboard/composables';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { INBOX_TYPES, TWILIO_CHANNEL_MEDIUM } from 'dashboard/helper/inbox';
import InboxesAPI from 'dashboard/api/inboxes';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import PaginationFooter from 'dashboard/components-next/pagination/PaginationFooter.vue';
import SelectMenu from 'dashboard/components-next/selectmenu/SelectMenu.vue';
import { PLATFORMS } from 'dashboard/services/TemplateConstants';
import SettingsLayout from '../SettingsLayout.vue';
import TemplateCard from './TemplateCard.vue';
import TemplatePreviewDrawer from './TemplatePreviewDrawer.vue';
import { formatTemplateLanguage } from './templateUtils';

const META_TEMPLATE_MANAGER_URL =
  'https://business.facebook.com/latest/whatsapp_manager/message_templates';
const TWILIO_TEMPLATE_MANAGER_URL =
  'https://console.twilio.com/us1/develop/sms/content-editor';
const META_TEMPLATE_LEARN_MORE_URL =
  'https://developers.facebook.com/documentation/business-messaging/whatsapp/templates/overview/';
const ITEMS_PER_PAGE = 5;

const store = useStore();
const { t } = useI18n();

const inboxes = useMapGetter('inboxes/getInboxes');
const templates = ref([]);
const isLoading = ref(false);
const searchQuery = ref('');
const selectedInboxId = ref('all');
const selectedLanguage = ref('all');
const currentPage = ref(1);
const selectedTemplate = ref(null);

const whatsappInboxes = computed(() =>
  inboxes.value.filter(
    inbox =>
      inbox.channel_type === INBOX_TYPES.WHATSAPP ||
      (inbox.channel_type === INBOX_TYPES.TWILIO &&
        inbox.medium === TWILIO_CHANNEL_MEDIUM.WHATSAPP)
  )
);

const canManageInMeta = computed(() =>
  whatsappInboxes.value.some(inbox => inbox.provider === 'whatsapp_cloud')
);

const selectedInbox = computed(() =>
  whatsappInboxes.value.find(
    inbox => String(inbox.id) === selectedInboxId.value
  )
);

const newTemplateUrl = computed(() => {
  if (selectedInbox.value?.channel_type === INBOX_TYPES.TWILIO) {
    return TWILIO_TEMPLATE_MANAGER_URL;
  }

  if (canManageInMeta.value) return META_TEMPLATE_MANAGER_URL;

  return whatsappInboxes.value.some(
    inbox => inbox.channel_type === INBOX_TYPES.TWILIO
  )
    ? TWILIO_TEMPLATE_MANAGER_URL
    : null;
});

const inboxOptions = computed(() => [
  {
    value: 'all',
    label: t('WHATSAPP_TEMPLATE_MGMT.FILTERS.CHANNEL'),
  },
  ...whatsappInboxes.value.map(inbox => ({
    value: String(inbox.id),
    label: inbox.name,
  })),
]);

const languageOptions = computed(() => [
  {
    value: 'all',
    label: t('WHATSAPP_TEMPLATE_MGMT.FILTERS.LANGUAGE'),
  },
  ...[...new Set(templates.value.map(template => template.language))]
    .filter(Boolean)
    .sort()
    .map(language => ({
      value: language,
      label: formatTemplateLanguage(language),
    })),
]);

const selectedInboxLabel = computed(
  () =>
    inboxOptions.value.find(option => option.value === selectedInboxId.value)
      ?.label || t('WHATSAPP_TEMPLATE_MGMT.FILTERS.CHANNEL')
);

const selectedLanguageLabel = computed(
  () =>
    languageOptions.value.find(
      option => option.value === selectedLanguage.value
    )?.label || t('WHATSAPP_TEMPLATE_MGMT.FILTERS.LANGUAGE')
);

const filteredTemplates = computed(() => {
  let records = templates.value;

  if (selectedInboxId.value !== 'all') {
    records = records.filter(template =>
      template.inboxes.some(inbox => String(inbox.id) === selectedInboxId.value)
    );
  }

  if (selectedLanguage.value !== 'all') {
    records = records.filter(
      template => template.language === selectedLanguage.value
    );
  }

  const query = searchQuery.value.trim();
  if (!query) return records;

  const normalizedQuery = query.toLowerCase();
  const contentMatches = records.filter(template =>
    [template.name, template.searchableContent].some(value =>
      value?.toLowerCase().includes(normalizedQuery)
    )
  );
  if (contentMatches.length) return contentMatches;

  return picoSearch(records, query, [
    { name: 'name', weight: 4 },
    'category',
    'language',
    'status',
    'inboxNames',
    'searchableContent',
  ]);
});

const paginatedTemplates = computed(() => {
  const start = (currentPage.value - 1) * ITEMS_PER_PAGE;
  return filteredTemplates.value.slice(start, start + ITEMS_PER_PAGE);
});

const groupTemplates = templateRecords => {
  const groupedTemplates = new Map();

  templateRecords.forEach(({ template, inbox, lastUpdatedAt }) => {
    const platform =
      inbox.channel_type === INBOX_TYPES.TWILIO
        ? PLATFORMS.TWILIO
        : PLATFORMS.WHATSAPP;
    const businessAccountId = inbox.provider_config?.business_account_id;
    const name = template.name || template.friendly_name;
    const templateIdentifier = template.id || template.content_sid || name;
    const key = [
      platform,
      businessAccountId || inbox.id,
      templateIdentifier,
      template.language,
    ].join(':');
    const existingTemplate = groupedTemplates.get(key);

    if (existingTemplate) {
      existingTemplate.inboxes.push(inbox);
      existingTemplate.inboxNames = existingTemplate.inboxes
        .map(item => item.name)
        .join(', ');
      if (
        lastUpdatedAt &&
        (!existingTemplate.lastUpdatedAt ||
          new Date(lastUpdatedAt) > new Date(existingTemplate.lastUpdatedAt))
      ) {
        existingTemplate.lastUpdatedAt = lastUpdatedAt;
      }
      return;
    }

    const searchableContent = JSON.stringify(
      template.components || template.types || template.body || []
    );

    groupedTemplates.set(key, {
      ...template,
      id: templateIdentifier,
      name,
      platform,
      key,
      inboxes: [inbox],
      inboxNames: inbox.name,
      lastUpdatedAt,
      searchableContent,
    });
  });

  return [...groupedTemplates.values()].sort((first, second) =>
    first.name.localeCompare(second.name)
  );
};

const fetchTemplates = async () => {
  isLoading.value = true;

  try {
    await store.dispatch('inboxes/get');
    const responses = await Promise.all(
      whatsappInboxes.value.map(async inbox => {
        const { data } = await InboxesAPI.getMessageTemplates(inbox.id);
        return data.payload.map(template => ({
          template,
          inbox,
          lastUpdatedAt: data.meta?.last_updated_at,
        }));
      })
    );

    templates.value = groupTemplates(responses.flat());
  } catch {
    useAlert(t('WHATSAPP_TEMPLATE_MGMT.FETCH_ERROR'));
  } finally {
    isLoading.value = false;
  }
};

watch([searchQuery, selectedInboxId, selectedLanguage], () => {
  currentPage.value = 1;
});

onActivated(fetchTemplates);
</script>

<template>
  <SettingsLayout
    :is-loading="isLoading"
    :loading-message="$t('WHATSAPP_TEMPLATE_MGMT.LOADING')"
    :no-records-found="!templates.length"
    :no-records-message="$t('WHATSAPP_TEMPLATE_MGMT.EMPTY')"
    class="mx-auto max-w-[56.25rem] !gap-14 pt-2"
  >
    <template #header>
      <div class="flex h-10 w-full items-center justify-between gap-8">
        <div class="flex min-w-0 items-center gap-4">
          <h1 class="text-xl font-medium leading-7 text-n-slate-12">
            {{ $t('WHATSAPP_TEMPLATE_MGMT.TITLE') }}
          </h1>
          <span class="h-4 w-0.5 shrink-0 rounded-full bg-n-weak" />
          <a
            :href="META_TEMPLATE_LEARN_MORE_URL"
            class="text-sm font-medium text-n-slate-11 hover:text-n-slate-12"
            target="_blank"
            rel="noopener noreferrer"
          >
            {{ $t('WHATSAPP_TEMPLATE_MGMT.KNOW_MORE') }}
          </a>
        </div>

        <a
          v-if="newTemplateUrl"
          :href="newTemplateUrl"
          target="_blank"
          rel="noopener noreferrer"
        >
          <Button
            class="!rounded-[0.625rem]"
            :label="$t('WHATSAPP_TEMPLATE_MGMT.NEW_TEMPLATE')"
            icon="i-lucide-plus"
          />
        </a>
      </div>
    </template>

    <template #body>
      <div class="flex min-h-[calc(100vh-7.5rem)] flex-col">
        <div
          class="mb-4 flex flex-wrap items-center justify-between gap-4 lg:flex-nowrap"
        >
          <div class="flex flex-wrap items-center gap-3">
            <SelectMenu
              v-model="selectedInboxId"
              :options="inboxOptions"
              :label="selectedInboxLabel"
              sub-menu-position="bottom"
            />
            <SelectMenu
              v-model="selectedLanguage"
              :options="languageOptions"
              :label="selectedLanguageLabel"
              sub-menu-position="bottom"
            />
          </div>
          <Input
            v-model="searchQuery"
            type="search"
            class="group w-full sm:w-[18.75rem] [&>input]:!rounded-[0.625rem] [&>input]:!bg-n-alpha-2 [&>input]:!outline-0 [&>input]:ltr:!pl-9 [&>input]:rtl:!pr-9 dark:[&>input]:!bg-n-solid-2"
            :placeholder="$t('WHATSAPP_TEMPLATE_MGMT.SEARCH_PLACEHOLDER')"
          >
            <template #prefix>
              <Icon
                icon="i-lucide-search"
                class="absolute top-1/2 size-4 -translate-y-1/2 text-n-slate-11 ltr:left-3 rtl:right-3"
              />
            </template>
          </Input>
        </div>

        <div
          v-if="!filteredTemplates.length"
          class="flex min-h-48 items-center justify-center rounded-2xl bg-n-alpha-2 text-sm text-n-slate-11 dark:bg-n-solid-2"
        >
          {{ $t('WHATSAPP_TEMPLATE_MGMT.NO_RESULTS') }}
        </div>

        <div v-else class="flex flex-col gap-4">
          <TemplateCard
            v-for="template in paginatedTemplates"
            :key="template.key"
            :template="template"
            @preview="selectedTemplate = template"
          />
        </div>

        <div
          v-if="filteredTemplates.length"
          class="mt-auto flex h-20 items-center"
        >
          <PaginationFooter
            class="!h-12 !rounded-xl !border-0 !bg-n-alpha-2 !px-5 !py-2 before:hidden dark:!bg-n-solid-2"
            :current-page="currentPage"
            :total-items="filteredTemplates.length"
            :items-per-page="ITEMS_PER_PAGE"
            @update:current-page="currentPage = $event"
          />
        </div>
      </div>
    </template>

    <TemplatePreviewDrawer
      :template="selectedTemplate"
      @close="selectedTemplate = null"
    />
  </SettingsLayout>
</template>
