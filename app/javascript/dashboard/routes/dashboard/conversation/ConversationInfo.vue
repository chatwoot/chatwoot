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

// DEBUG: Component is loading
console.log('ConversationInfo component is loading!');

// DEBUG: Props received
console.log('ConversationInfo props received:', {
  conversationAttributes: props.conversationAttributes,
  contactAttributes: props.contactAttributes,
});

const referer = computed(() => {
  const value = props.conversationAttributes.referer;
  return value ? { value } : null;
});

const initiatedAt = computed(() => {
  const value = props.conversationAttributes.initiated_at?.timestamp;
  return value ? { value } : null;
});

const browserInfo = computed(() => props.conversationAttributes.browser);

const browserName = computed(() => {
  if (!browserInfo.value) return null;
  const { browser_name: name = '', browser_version: version = '' } =
    browserInfo.value;
  const value = `${name} ${version}`.trim();
  return value ? { value } : null;
});

const browserLanguage = computed(() => {
  const value = getLanguageName(props.conversationAttributes.browser_language);
  return value ? { value } : null;
});

const platformName = computed(() => {
  if (!browserInfo.value) return null;
  const { platform_name: name = '', platform_version: version = '' } =
    browserInfo.value;
  const value = `${name} ${version}`.trim();
  return value ? { value } : null;
});

const createdAtIp = computed(() => {
  const value = props.contactAttributes.created_at_ip;
  return value ? { value } : null;
});

const appleMessagesCapabilities = computed(() => {
  // Debug logging
  console.log('ConversationInfo Debug:', {
    contactAttributes: props.contactAttributes,
    conversationAttributes: props.conversationAttributes,
    contactCapabilities: props.contactAttributes?.apple_messages_capabilities,
    conversationCapabilities:
      props.conversationAttributes?.apple_messages_capabilities,
  });

  const capabilities =
    props.contactAttributes?.apple_messages_capabilities ||
    props.conversationAttributes?.apple_messages_capabilities;

  console.log('Apple Messages Capabilities computed:', {
    capabilities,
    hasCapabilities: !!capabilities,
    returnValue: capabilities
      ? {
          value: capabilities,
          tokens: capabilities.split(',').map(cap => cap.trim()),
        }
      : null,
  });

  if (!capabilities) {
    console.log('No capabilities found, returning null');
    return null;
  }

  // Parse capabilities string into individual tokens
  const capabilityList = capabilities.split(',').map(cap => cap.trim());
  const result = { value: capabilities, tokens: capabilityList };

  console.log('Apple Messages Capabilities final result:', result);
  return result;
});

// Capability descriptions for better UX
const capabilityDescriptions = {
  AUTH: 'Authentication Messages',
  LIST: 'List Picker Messages',
  TIME: 'Time Picker Messages',
  QUICK: 'Quick Reply Messages',
  AUTH2: 'Enhanced Authentication',
};

const staticElements = computed(() => {
  // Access computed values explicitly to ensure reactivity
  const initiatedAtValue = initiatedAt.value;
  const browserLanguageValue = browserLanguage.value;
  const refererValue = referer.value;
  const browserNameValue = browserName.value;
  const platformNameValue = platformName.value;
  const createdAtIpValue = createdAtIp.value;
  const appleMessagesCapabilitiesValue = appleMessagesCapabilities.value;

  const elements = [
    {
      content: initiatedAtValue,
      title: 'CONTACT_PANEL.INITIATED_AT',
      key: 'static-initiated-at',
      type: 'static_attribute',
    },
    {
      content: browserLanguageValue,
      title: 'CONTACT_PANEL.BROWSER_LANGUAGE',
      key: 'static-browser-language',
      type: 'static_attribute',
    },
    {
      content: refererValue,
      title: 'CONTACT_PANEL.INITIATED_FROM',
      key: 'static-referer',
      type: 'static_attribute',
    },
    {
      content: browserNameValue,
      title: 'CONTACT_PANEL.BROWSER',
      key: 'static-browser',
      type: 'static_attribute',
    },
    {
      content: platformNameValue,
      title: 'CONTACT_PANEL.OS',
      key: 'static-platform',
      type: 'static_attribute',
    },
    {
      content: createdAtIpValue,
      title: 'CONTACT_PANEL.IP_ADDRESS',
      key: 'static-ip-address',
      type: 'static_attribute',
    },
    {
      content: appleMessagesCapabilitiesValue,
      title: 'CONTACT_PANEL.APPLE_MESSAGES_CAPABILITIES',
      key: 'static-apple-capabilities',
      type: 'static_attribute',
    },
  ];

  const filtered = elements.filter(attribute => {
    if (!attribute.content) {
      return false;
    }

    // For Apple Messages capabilities, check if tokens exist
    if (attribute.key === 'static-apple-capabilities') {
      const content = attribute.content;
      return (
        content && Array.isArray(content.tokens) && content.tokens.length > 0
      );
    }

    // For other attributes, check if value exists
    return attribute.content && attribute.content.value;
  });

  return filtered;
});
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
          <a
            v-if="element.key === 'static-referer'"
            :href="element.content.value"
            rel="noopener noreferrer nofollow"
            target="_blank"
            class="text-n-brand"
          >
            {{ element.content.value }}
          </a>

          <!-- Apple Messages Capabilities as tokens -->
          <div
            v-else-if="element.key === 'static-apple-capabilities'"
            class="flex flex-wrap gap-1 mt-1"
          >
            <span
              v-for="capability in element.content.tokens"
              :key="capability"
              :title="capabilityDescriptions[capability] || capability"
              class="inline-flex items-center px-2 py-1 text-xs font-medium bg-blue-100 text-blue-800 rounded-full border border-blue-200"
            >
              {{ capability }}
            </span>
          </div>
        </ContactDetailsItem>
      </template>
    </CustomAttributes>
  </div>
</template>
