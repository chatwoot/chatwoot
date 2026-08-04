<script setup>
import { computed, onActivated, onDeactivated, ref } from 'vue';
import { picoSearch } from '@scmmishra/pico-search';
import { useI18n } from 'vue-i18n';
import { vOnClickOutside } from '@vueuse/components';

import { useAlert } from 'dashboard/composables';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useAbortableRequest } from 'dashboard/composables/useAbortableRequest';
import { INBOX_TYPES, TWILIO_CHANNEL_MEDIUM } from 'dashboard/helper/inbox';
import InboxesAPI from 'dashboard/api/inboxes';
import Button from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import TemplateCard from './TemplateCard.vue';
import TemplatePreviewDrawer from './TemplatePreviewDrawer.vue';
import { formatTemplateLanguage, groupTemplates } from './templateUtils';

const FUZZY_SEARCH_KEYS = [
  { name: 'name', weight: 4 },
  'category',
  'language',
  'status',
  'inboxNames',
  'searchableContent',
];

const META_TEMPLATE_MANAGER_URL =
  'https://business.facebook.com/latest/whatsapp_manager/message_templates';
const TWILIO_TEMPLATE_MANAGER_URL =
  'https://console.twilio.com/us1/develop/sms/content-editor';
const TEMPLATE_LEARN_MORE_URL =
  'https://www.chatwoot.com/hc/user-guide/articles/1754940076-whatsapp-templates';

const store = useStore();
const { t } = useI18n();

const inboxes = useMapGetter('inboxes/getInboxes');
const templates = ref([]);
const searchQuery = ref('');
const selectedInboxId = ref('all');
const selectedLanguage = ref('all');
const selectedTemplate = ref(null);
const openFilterMenu = ref(null);
const previewPanelRef = ref(null);
const templateRecordsByInboxId = new Map();
const {
  run: runTemplateRequest,
  abort: abortTemplateRequest,
  isPending: isLoading,
} = useAbortableRequest();

const hasTemplates = computed(() => templates.value.length > 0);

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

const hasTwilioInboxes = computed(() =>
  whatsappInboxes.value.some(inbox => inbox.channel_type === INBOX_TYPES.TWILIO)
);

const hasUnsupportedWhatsappInboxes = computed(() =>
  whatsappInboxes.value.some(
    inbox =>
      inbox.channel_type === INBOX_TYPES.WHATSAPP &&
      inbox.provider !== 'whatsapp_cloud'
  )
);

const selectedInbox = computed(() =>
  whatsappInboxes.value.find(
    inbox => String(inbox.id) === selectedInboxId.value
  )
);

const newTemplateUrl = computed(() => {
  if (selectedInbox.value) {
    if (selectedInbox.value.channel_type === INBOX_TYPES.TWILIO) {
      return TWILIO_TEMPLATE_MANAGER_URL;
    }

    return selectedInbox.value.provider === 'whatsapp_cloud'
      ? META_TEMPLATE_MANAGER_URL
      : null;
  }

  if (
    canManageInMeta.value &&
    !hasTwilioInboxes.value &&
    !hasUnsupportedWhatsappInboxes.value
  ) {
    return META_TEMPLATE_MANAGER_URL;
  }

  return hasTwilioInboxes.value &&
    !canManageInMeta.value &&
    !hasUnsupportedWhatsappInboxes.value
    ? TWILIO_TEMPLATE_MANAGER_URL
    : null;
});

const inboxOptions = computed(() => [
  {
    value: 'all',
    label: t('WHATSAPP_TEMPLATE_MGMT.FILTERS.ALL_INBOXES'),
  },
  ...whatsappInboxes.value.map(inbox => ({
    value: String(inbox.id),
    label: inbox.name,
  })),
]);

const languageOptions = computed(() => [
  {
    value: 'all',
    label: t('WHATSAPP_TEMPLATE_MGMT.FILTERS.ALL_LANGUAGES'),
  },
  ...[...new Set(templates.value.map(template => template.language))]
    .filter(Boolean)
    .sort()
    .map(language => ({
      value: language,
      label: formatTemplateLanguage(language),
    })),
]);

const filterMenus = computed(() =>
  [
    {
      key: 'inbox',
      icon: 'i-lucide-inbox',
      options: inboxOptions.value,
      active: selectedInboxId.value,
    },
    {
      key: 'language',
      icon: 'i-lucide-languages',
      options: languageOptions.value,
      active: selectedLanguage.value,
    },
  ].map(menu => {
    const items = menu.options.map(option => ({
      ...option,
      action: menu.key,
      isSelected: option.value === menu.active,
    }));

    return {
      ...menu,
      items,
      selected: items.find(item => item.isSelected) || items[0],
    };
  })
);

const closeFilterMenu = () => {
  openFilterMenu.value = null;
};

const toggleFilterMenu = key => {
  openFilterMenu.value = openFilterMenu.value === key ? null : key;
};

const openPreview = template => {
  selectedTemplate.value = template;
  previewPanelRef.value?.open();
};

const handleFilterAction = ({ action, value }) => {
  closeFilterMenu();
  if (action === 'inbox') selectedInboxId.value = value;
  else selectedLanguage.value = value;
};

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

  return picoSearch(records, query, FUZZY_SEARCH_KEYS);
});

const showSearch = computed(() =>
  Boolean(filteredTemplates.value.length || searchQuery.value)
);

const fetchTemplates = async () => {
  try {
    await runTemplateRequest(async signal => {
      const didFetchInboxes = await store.dispatch('inboxes/get');
      if (!didFetchInboxes) throw new Error();
      if (signal.aborted) return;

      const inboxesToFetch = [...whatsappInboxes.value];
      const responses = await Promise.allSettled(
        inboxesToFetch.map(async inbox => {
          const { data } = await InboxesAPI.getMessageTemplates(
            inbox.id,
            {},
            { signal }
          );

          if (!Array.isArray(data.payload)) {
            throw new TypeError();
          }

          return {
            inboxId: inbox.id,
            records: data.payload.map(template => ({
              template,
              inbox,
              lastUpdatedAt: data.meta?.last_sync_attempt_at,
            })),
          };
        })
      );

      if (signal.aborted) return;

      const successfulResponses = responses.filter(
        response => response.status === 'fulfilled'
      );
      const activeInboxIds = new Set(inboxesToFetch.map(inbox => inbox.id));

      templateRecordsByInboxId.forEach((_, inboxId) => {
        if (!activeInboxIds.has(inboxId))
          templateRecordsByInboxId.delete(inboxId);
      });
      successfulResponses.forEach(({ value }) => {
        templateRecordsByInboxId.set(value.inboxId, value.records);
      });
      templates.value = groupTemplates(
        [...templateRecordsByInboxId.values()].flat()
      );

      if (
        !inboxOptions.value.some(({ value }) => value === selectedInboxId.value)
      )
        selectedInboxId.value = 'all';
      if (
        !languageOptions.value.some(
          ({ value }) => value === selectedLanguage.value
        )
      )
        selectedLanguage.value = 'all';

      if (responses.some(response => response.status === 'rejected')) {
        const errorMessage = successfulResponses.length
          ? t('WHATSAPP_TEMPLATE_MGMT.PARTIAL_FETCH_ERROR')
          : t('WHATSAPP_TEMPLATE_MGMT.FETCH_ERROR');
        useAlert(errorMessage);
      }
    });
  } catch {
    useAlert(t('WHATSAPP_TEMPLATE_MGMT.FETCH_ERROR'));
  }
};

onActivated(fetchTemplates);
onDeactivated(abortTemplateRequest);
</script>

<template>
  <SettingsLayout
    :is-loading="isLoading"
    :loading-message="$t('WHATSAPP_TEMPLATE_MGMT.LOADING')"
    :no-records-found="!templates.length"
    :no-records-message="$t('WHATSAPP_TEMPLATE_MGMT.EMPTY')"
  >
    <template #header>
      <BaseSettingsHeader
        v-model:search-query="searchQuery"
        :title="$t('WHATSAPP_TEMPLATE_MGMT.TITLE')"
        :search-placeholder="
          showSearch ? $t('WHATSAPP_TEMPLATE_MGMT.SEARCH_PLACEHOLDER') : ''
        "
      >
        <template #description>
          {{ $t('WHATSAPP_TEMPLATE_MGMT.DESCRIPTION') }}
          <a
            :href="TEMPLATE_LEARN_MORE_URL"
            class="text-sm font-medium text-n-blue-11 hover:underline"
            target="_blank"
            rel="noopener noreferrer"
          >
            {{ $t('WHATSAPP_TEMPLATE_MGMT.KNOW_MORE') }}
          </a>
        </template>
        <template #tabs>
          <div
            v-if="hasTemplates"
            v-on-click-outside="closeFilterMenu"
            class="flex items-center gap-2"
          >
            <div v-for="menu in filterMenus" :key="menu.key" class="relative">
              <Button
                :icon="menu.icon"
                color="slate"
                size="sm"
                :class="{ 'bg-n-slate-9/10': openFilterMenu === menu.key }"
                @click="toggleFilterMenu(menu.key)"
              >
                <span class="min-w-0 truncate">{{ menu.selected.label }}</span>
                <Icon icon="i-lucide-chevron-down" class="shrink-0 size-4" />
              </Button>
              <DropdownMenu
                v-if="openFilterMenu === menu.key"
                :menu-items="menu.items"
                class="mt-2 min-w-52 top-full ltr:left-0 rtl:right-0"
                @action="handleFilterAction"
              />
            </div>
          </div>
        </template>
        <template v-if="filteredTemplates.length" #count>
          <span class="text-body-main text-n-slate-11">
            {{
              $t('WHATSAPP_TEMPLATE_MGMT.COUNT', {
                n: filteredTemplates.length,
              })
            }}
          </span>
        </template>
        <template v-if="newTemplateUrl" #actions>
          <a :href="newTemplateUrl" target="_blank" rel="noopener noreferrer">
            <Button
              :label="$t('WHATSAPP_TEMPLATE_MGMT.NEW_TEMPLATE')"
              icon="i-lucide-plus"
              size="sm"
            />
          </a>
        </template>
      </BaseSettingsHeader>
    </template>

    <template #body>
      <div
        v-if="!filteredTemplates.length"
        class="flex items-center justify-center p-8"
      >
        <span class="text-base text-n-slate-11">
          {{ $t('WHATSAPP_TEMPLATE_MGMT.NO_RESULTS') }}
        </span>
      </div>

      <div v-else class="border-t divide-y divide-n-weak border-n-weak">
        <TemplateCard
          v-for="template in filteredTemplates"
          :key="template.key"
          :template="template"
          @preview="openPreview(template)"
        />
      </div>
    </template>

    <TemplatePreviewDrawer ref="previewPanelRef" :template="selectedTemplate" />
  </SettingsLayout>
</template>
