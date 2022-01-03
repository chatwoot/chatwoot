<template>
  <div class="conversation--details">
    <contact-details-item
      v-if="initiatedAt"
      :title="$t('CONTACT_PANEL.INITIATED_AT')"
      :value="initiatedAt.timestamp"
      class="conversation--attribute"
    />
    <contact-details-item
      v-if="referer"
      :title="$t('CONTACT_PANEL.INITIATED_FROM')"
      :value="referer"
      class="conversation--attribute"
    >
      <a :href="referer" rel="noopener noreferrer nofollow" target="_blank">
        {{ referer }}
      </a>
    </contact-details-item>
    <contact-details-item
      v-if="browserName"
      :title="$t('CONTACT_PANEL.BROWSER')"
      :value="browserName"
      class="conversation--attribute"
    />
    <contact-details-item
      v-if="platformName"
      :title="$t('CONTACT_PANEL.OS')"
      :value="platformName"
      class="conversation--attribute"
    />
    <contact-details-item
      v-if="ipAddress"
      :title="$t('CONTACT_PANEL.IP_ADDRESS')"
      :value="ipAddress"
      class="conversation--attribute"
    />
    <custom-attributes
      attribute-type="conversation_attribute"
      attribute-class="conversation--attribute"
      :class="customAttributeRowClass"
    />
    <custom-attribute-selector attribute-type="conversation_attribute" />
  </div>
</template>

<script>
import ContactDetailsItem from './ContactDetailsItem.vue';
import CustomAttributes from './customAttributes/CustomAttributes.vue';
import CustomAttributeSelector from './customAttributes/CustomAttributeSelector.vue';

export default {
  components: {
    ContactDetailsItem,
    CustomAttributes,
    CustomAttributeSelector,
  },
  props: {
    conversationAttributes: {
      type: Object,
      default: () => ({}),
    },
    contactAttributes: {
      type: Object,
      default: () => ({}),
    },
  },
  STATIC_ATTRIBUTES: [
    {
      name: 'initiated_at',
      label: 'CONTACT_PANEL.INITIATED_AT',
    },
    {
      name: 'referer',
      label: 'CONTACT_PANEL.BROWSER',
    },
    {
      name: 'browserName',
      label: 'CONTACT_PANEL.BROWSER',
    },
    {
      name: 'platformName',
      label: 'CONTACT_PANEL.OS',
    },
    {
      name: 'ipAddress',
      label: 'CONTACT_PANEL.IP_ADDRESS',
    },
  ],
  computed: {
    referer() {
      return this.conversationAttributes.referer;
    },
    initiatedAt() {
      return this.conversationAttributes.initiated_at;
    },
    browserName() {
      if (!this.conversationAttributes.browser) {
        return '';
      }
      const {
        browser_name: browserName = '',
        browser_version: browserVersion = '',
      } = this.conversationAttributes.browser;
      return `${browserName} ${browserVersion}`;
    },
    platformName() {
      if (!this.conversationAttributes.browser) {
        return '';
      }
      const {
        platform_name: platformName,
        platform_version: platformVersion,
      } = this.conversationAttributes.browser;
      return `${platformName || ''} ${platformVersion || ''}`;
    },
    ipAddress() {
      const { created_at_ip: createdAtIp } = this.contactAttributes;
      return createdAtIp;
    },
    customAttributeRowClass() {
      const attributes = [
        'initiatedAt',
        'referer',
        'browserName',
        'platformName',
        'ipAddress',
      ];
      const availableAttributes = attributes.filter(
        attribute => !!this[attribute]
      );
      return availableAttributes.length % 2 === 0 ? 'even' : 'odd';
    },
  },
};
</script>
<style scoped lang="scss">
.conversation--attribute {
  border-bottom: 1px solid var(--color-border-light);

  &:nth-child(2n) {
    background: var(--s-25);
  }
}
</style>
