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
const browserName = computed(() => {
  if (!props.conversationAttributes.browser) {
    return '';
  }
  const { browser_name: browser = '', browser_version: browserVersion = '' } =
    props.conversationAttributes.browser;
  return `${browser} ${browserVersion}`;
});
const browserLanguage = computed(() =>
  getLanguageName(props.conversationAttributes.browser_language)
);
const platformName = computed(() => {
  const { browser } = props.conversationAttributes;
  if (!browser) {
    return '';
  }
  const { platform_name: platform, platform_version: platformVersion } =
    browser;
  return `${platform || ''} ${platformVersion || ''}`;
});

const createdAtIp = computed(() => props.contactAttributes.created_at_ip);

const staticElements = computed(() => {
  const conversationAttributes = [
    {
      content: initiatedAt,
      title: 'CONTACT_PANEL.INITIATED_AT',
    },
    {
      content: browserLanguage,
      title: 'CONTACT_PANEL.BROWSER_LANGUAGE',
    },
    {
      content: referer,
      title: 'CONTACT_PANEL.INITIATED_FROM',
      type: 'link',
    },
    {
      content: browserName,
      title: 'CONTACT_PANEL.BROWSER',
    },
    {
      content: platformName,
      title: 'CONTACT_PANEL.OS',
    },
    {
      content: createdAtIp,
      title: 'CONTACT_PANEL.IP_ADDRESS',
    },
  ];
  return conversationAttributes.filter(attribute => !!attribute.content.value);
});
</script>

<template>
  <div
    class="[&>*:nth-child(even)]:bg-slate-25 [&>*:nth-child(even)]:dark:bg-slate-800"
  >
    <ContactDetailsItem
      v-for="element in staticElements"
      :key="element.title"
      :title="$t(element.title)"
      :value="element.content.value"
    >
      <a
        v-if="element.type === 'link'"
        :href="referer"
        rel="noopener noreferrer nofollow"
        target="_blank"
        class="text-woot-400 dark:text-woot-600"
      >
        {{ referer }}
      </a>
    </ContactDetailsItem>
    <CustomAttributes
      :class="staticElements.length % 2 == 0 ? 'even' : 'odd'"
      attribute-class="conversation--attribute"
      attribute-from="conversation_panel"
      attribute-type="conversation_attribute"
    />
  </div>
</template>
