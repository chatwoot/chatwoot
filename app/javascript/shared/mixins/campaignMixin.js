import { CAMPAIGN_TYPES } from '../constants/campaign';

export default {
  computed: {
    campaignType() {
      const campaignTypeMap = {
        ongoing_campaigns: CAMPAIGN_TYPES.ONGOING,
        one_off: CAMPAIGN_TYPES.ONE_OFF,
        flexible: CAMPAIGN_TYPES.FLEXIBLE,
      };
      return campaignTypeMap[this.$route.name];
    },
    isFlexibleType() {
      return this.campaignType === CAMPAIGN_TYPES.FLEXIBLE;
    },
    isOngoingType() {
      return this.campaignType === CAMPAIGN_TYPES.ONGOING;
    },
    isOneOffType() {
      return this.campaignType === CAMPAIGN_TYPES.ONE_OFF;
    },
    scheduledCalculations() {
      return [
        { key: 'equal', name: this.$t('CAMPAIGN.FLEXIBLE.CALCULATION.EQUAL') },
        { key: 'plus', name: this.$t('CAMPAIGN.FLEXIBLE.CALCULATION.PLUS') },
        { key: 'minus', name: this.$t('CAMPAIGN.FLEXIBLE.CALCULATION.MINUS') },
        {
          key: 'equalWithoutYear',
          name: this.$t('CAMPAIGN.FLEXIBLE.CALCULATION.EQUAL_WITHOUT_YEAR'),
        },
      ];
    },
    productAttributes() {
      return [
        {
          attributeKey: 'name',
          attributeI18nKey: 'NAME',
          inputType: 'plain_text',
        },
        {
          attributeKey: 'short_name',
          attributeI18nKey: 'SHORT_NAME',
          inputType: 'plain_text',
        },
        {
          attributeKey: 'price',
          attributeI18nKey: 'PRICE',
          inputType: 'number',
        },
      ];
    },
    dataAttributes() {
      const contactAts = this.contactFilterItems.map(item => ({
        key: item.attributeKey,
        name:
          this.$t(`CAMPAIGN.DATA_ATTRIBUTE.CONTACT`) +
          '.' +
          this.$t(`CONTACTS_FILTER.ATTRIBUTES.${item.attributeI18nKey}`),
        type: 'contact_attribute',
        model: 'contact',
        inputType: item.inputType,
      }));

      const allContactCustomAts =
        this.$store.getters['attributes/getAttributesByModel'](
          'contact_attribute'
        );
      const contactCustomAts = allContactCustomAts.map(attr => ({
        key: attr.attribute_key,
        name:
          this.$t(`CAMPAIGN.DATA_ATTRIBUTE.CONTACT`) +
          '.' +
          attr.attribute_display_name,
        type: 'contact_custom_attribute',
        model: 'contact',
        inputType: attr.attribute_display_type,
      }));

      const productAts = this.productAttributes.map(item => ({
        key: item.attributeKey,
        name:
          this.$t(`CAMPAIGN.DATA_ATTRIBUTE.PRODUCT`) +
          '.' +
          this.$t(
            `CAMPAIGN.DATA_ATTRIBUTE.PRODUCT_ATTRIBUTE.${item.attributeI18nKey}`
          ),
        type: 'product_attribute',
        model: 'product',
        inputType: item.inputType,
      }));

      const allProductCustomAts =
        this.$store.getters['attributes/getAttributesByModel'](
          'product_attribute'
        );
      const productCustomAts = allProductCustomAts.map(attr => ({
        key: attr.attribute_key,
        name:
          this.$t(`CAMPAIGN.DATA_ATTRIBUTE.PRODUCT`) +
          '.' +
          attr.attribute_display_name,
        type: 'product_custom_attribute',
        model: 'product',
        inputType: attr.attribute_display_type,
      }));

      const allAttributes = [
        ...contactAts,
        ...contactCustomAts,
        ...productAts,
        ...productCustomAts,
      ];
      return allAttributes.map(attr => ({
        id: `${attr.model}_${attr.key}`,
        ...attr,
      }));
    },
    dataDateAttributes() {
      return this.dataAttributes.filter(item => item.inputType === 'date');
    },
    audienceList() {
      const customViews =
        this.$store.getters['customViews/getCustomViewsByFilterType'](
          'contact'
        );
      const newCustomViews = customViews.map(item => ({
        id: item.id,
        title: item.name,
        type: 'custom_filter',
      }));

      const labels = this.$store.getters['labels/getLabels'];
      const newLabels = labels.map(item => ({
        id: item.id,
        title: `${this.$t('LABEL_MGMT.HEADER')}: ${
          item.description || item.title
        }`,
        type: 'label',
      }));

      return [...newCustomViews, ...newLabels];
    },
  },
};
