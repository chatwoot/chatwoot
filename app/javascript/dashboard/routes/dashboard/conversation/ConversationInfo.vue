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
  ].filter(attribute => !!attribute.content.value)
);

const evenClass = [
  '[&>*:nth-child(odd)]:!bg-white [&>*:nth-child(even)]:!bg-slate-25',
  'dark:[&>*:nth-child(odd)]:!bg-slate-900 dark:[&>*:nth-child(even)]:!bg-slate-800/50',
];
</script>

<template>
  <div class="conversation--details">
    <div :class="evenClass">
      <ContactDetailsItem
        v-for="element in staticElements"
        :key="element.title"
        :title="$t(element.title)"
        :value="element.content.value"
        class="border-b border-solid border-slate-50 dark:border-slate-700/50"
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
    </div>
    <CustomAttributes
      :start-at="staticElements.length % 2 === 0 ? 'even' : 'odd'"
      attribute-class="conversation--attribute"
      attribute-from="conversation_panel"
      attribute-type="conversation_attribute"
    />
  </div>
</template>
