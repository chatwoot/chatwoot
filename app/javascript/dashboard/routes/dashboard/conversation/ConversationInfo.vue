<script setup>
import { computed } from 'vue';
import { getLanguageName } from 'dashboard/components/widgets/conversation/advancedFilterItems/languages';
import ContactDetailsItem from './ContactDetailsItem.vue';
import CustomAttributes from './customAttributes/CustomAttributes.vue';

const props = defineProps({
  conversationAttributes: {
    type: Object,
    default: () => ({}),
  },
  contactAttributes: {
    type: Object,
    default: () => ({}),
  },
});

const CURRENT_PAGE_STALE_AFTER_MS = 5 * 60 * 1000;

const referer = computed(() => props.conversationAttributes.referer);
const initiatedAt = computed(
  () => props.conversationAttributes.initiated_at?.timestamp
);

const browserInfo = computed(() => props.conversationAttributes.browser);

const browserName = computed(() => {
  if (!browserInfo.value) return '';
  const { browser_name: name = '', browser_version: version = '' } =
    browserInfo.value;
  return `${name} ${version}`;
});

const browserLanguage = computed(() =>
  getLanguageName(props.conversationAttributes.browser_language)
);

const platformName = computed(() => {
  if (!browserInfo.value) return '';
  const { platform_name: name = '', platform_version: version = '' } =
    browserInfo.value;
  return `${name} ${version}`;
});

const createdAtIp = computed(() => props.contactAttributes.created_at_ip);

const currentPage = computed(
  () => props.conversationAttributes.current_page || {}
);
const currentPageUrl = computed(() => {
  const value = currentPage.value.url;
  if (!value) return '';

  try {
    const url = new URL(value);
    if (!['http:', 'https:'].includes(url.protocol)) return '';
    url.username = '';
    url.password = '';
    url.search = '';
    url.hash = '';
    return url.toString();
  } catch {
    return '';
  }
});
const currentPageTitle = computed(() => {
  if (!currentPageUrl.value) return '';
  return currentPage.value.title || currentPageUrl.value;
});
const currentPageUpdatedAt = computed(() => {
  if (!currentPage.value.updated_at) return '';

  const updatedAt = new Date(currentPage.value.updated_at);
  return Number.isNaN(updatedAt.getTime()) ? '' : updatedAt.toLocaleString();
});
const currentPageIsStale = computed(() => {
  if (!currentPage.value.updated_at) return true;

  const updatedAt = Date.parse(currentPage.value.updated_at);
  return (
    Number.isNaN(updatedAt) ||
    Date.now() - updatedAt > CURRENT_PAGE_STALE_AFTER_MS
  );
});

const staticElements = computed(() =>
  [
    {
      content: currentPageTitle,
      href: currentPageUrl,
      updatedAt: currentPageUpdatedAt,
      isStale: currentPageIsStale,
      title: 'CONTACT_PANEL.CURRENT_PAGE',
      key: 'static-current-page',
      type: 'static_attribute',
    },
    {
      content: initiatedAt,
      title: 'CONTACT_PANEL.INITIATED_AT',
      key: 'static-initiated-at',
      type: 'static_attribute',
    },
    {
      content: browserLanguage,
      title: 'CONTACT_PANEL.BROWSER_LANGUAGE',
      key: 'static-browser-language',
      type: 'static_attribute',
    },
    {
      content: referer,
      title: 'CONTACT_PANEL.INITIATED_FROM',
      key: 'static-referer',
      type: 'static_attribute',
    },
    {
      content: browserName,
      title: 'CONTACT_PANEL.BROWSER',
      key: 'static-browser',
      type: 'static_attribute',
    },
    {
      content: platformName,
      title: 'CONTACT_PANEL.OS',
      key: 'static-platform',
      type: 'static_attribute',
    },
    {
      content: createdAtIp,
      title: 'CONTACT_PANEL.IP_ADDRESS',
      key: 'static-ip-address',
      type: 'static_attribute',
    },
  ].filter(attribute => !!attribute.content.value)
);
</script>

<template>
  <div class="conversation--details">
    <CustomAttributes
      :static-elements="staticElements"
      attribute-class="conversation--attribute"
      attribute-from="conversation_panel"
      attribute-type="conversation_attribute"
    >
      <template #staticItem="{ element }">
        <ContactDetailsItem
          :key="element.title"
          :title="$t(element.title)"
          :value="element.content.value"
        >
          <template
            v-if="
              ['static-referer', 'static-current-page'].includes(element.key)
            "
          >
            <a
              v-if="element.key === 'static-referer' || element.href?.value"
              :href="element.href?.value || element.content.value"
              rel="noopener noreferrer nofollow"
              target="_blank"
              class="text-n-brand"
            >
              {{ element.content.value }}
            </a>
            <span v-else>{{ element.content.value }}</span>
            <p
              v-if="element.key === 'static-current-page' && element.href.value"
              class="mt-1 break-all text-xs text-n-slate-11"
            >
              {{ element.href.value }}
            </p>
            <p
              v-if="
                element.key === 'static-current-page' && element.updatedAt.value
              "
              class="mt-1 text-xs text-n-slate-11"
            >
              {{
                $t('CONTACT_PANEL.CURRENT_PAGE_LAST_UPDATED', {
                  time: element.updatedAt.value,
                })
              }}
              <span v-if="element.isStale.value">
                {{ `· ${$t('CONTACT_PANEL.CURRENT_PAGE_STALE')}` }}
              </span>
            </p>
          </template>
        </ContactDetailsItem>
      </template>
    </CustomAttributes>
  </div>
</template>
