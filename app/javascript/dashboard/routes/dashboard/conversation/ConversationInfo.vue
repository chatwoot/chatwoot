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

const staticElements = computed(() =>
  [
    {
      content: initiatedAt,
      title: 'CONTACT_PANEL.INITIATED_AT',
      key: 'static-initiated-at',
      type: 'static_attribute',
      icon: 'i-lucide-timer',
    },
    {
      content: browserLanguage,
      title: 'CONTACT_PANEL.BROWSER_LANGUAGE',
      key: 'static-browser-language',
      type: 'static_attribute',
      icon: 'i-lucide-languages',
    },
    {
      content: referer,
      title: 'CONTACT_PANEL.INITIATED_FROM',
      key: 'static-referer',
      type: 'static_attribute',
      icon: 'i-lucide-link',
    },
    {
      content: browserName,
      title: 'CONTACT_PANEL.BROWSER',
      key: 'static-browser',
      type: 'static_attribute',
      icon: 'i-woot-website',
    },
    {
      content: platformName,
      title: 'CONTACT_PANEL.OS',
      key: 'static-platform',
      type: 'static_attribute',
      icon: 'i-woot-monitor',
    },
    {
      content: createdAtIp,
      title: 'CONTACT_PANEL.IP_ADDRESS',
      key: 'static-ip-address',
      type: 'static_attribute',
      icon: 'i-woot-ip-address',
    },
  ].filter(attribute => !!attribute.content.value)
);
</script>

<template>
  <!-- Static Conversation Attributes -->
  <div v-if="staticElements.length > 0" class="mt-2">
    <div v-for="element in staticElements" :key="element.key">
      <ContactDetailsItem
        :title="$t(element.title)"
        :value="element.content.value"
        :icon="element.icon"
      >
        <a
          v-if="element.key === 'static-referer'"
          :href="element.content.value"
          rel="noopener noreferrer nofollow"
          target="_blank"
          class="text-n-brand"
        >
          {{ element.content.value }}
        </a>
      </ContactDetailsItem>
    </div>
  </div>

  <!-- Custom Attributes -->
  <CustomAttributes
    attribute-from="conversation_panel"
    attribute-type="conversation_attribute"
    :empty-state-message="$t('CONVERSATION_CUSTOM_ATTRIBUTES.NO_RECORDS_FOUND')"
    show-title
  />
</template>
