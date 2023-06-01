import { mapGetters } from 'vuex';
import advancedFilterTypes from 'components/widgets/conversation/advancedFilterItems';
import languages from 'components/widgets/conversation/advancedFilterItems/languages';
import countries from 'shared/constants/countries.js';

export default {
  data() {
    return {
      filterTypes: advancedFilterTypes,
    };
  },
  computed: {
    ...mapGetters({
      agentList: 'agents/getAgents',
      teamsList: 'teams/getTeams',
      inboxesList: 'inboxes/getInboxes',
      campaigns: 'campaigns/getAllCampaigns',
      labels: 'labels/getLabels',
    }),
  },
  mounted() {
    this.$store.dispatch('campaigns/get');
  },
  methods: {
    initializeCustomViewFilterToModal(activeFolder) {
      const query = activeFolder?.query?.payload;
      if (!Array.isArray(query)) return;

      this.appliedFilter.push(
        ...query.map(filter => ({
          attribute_key: filter.attribute_key,
          attribute_model: filter.attribute_model,
          filter_operator: filter.filter_operator,
          values: Array.isArray(filter.values)
            ? this.generateValueObjectForFilter(filter)
            : [],
          query_operator: filter.query_operator,
          custom_attribute_type: filter.custom_attribute_type,
        }))
      );
    },
    getInputType(key, operator) {
      if (key === 'created_at' || key === 'last_activity_at')
        if (operator === 'days_before') return 'plain_text';
      const type = this.filterTypes.find(filter => filter.attributeKey === key);
      return type?.inputType;
    },
    generateValueObjectForFilter(filter) {
      const { attribute_key, filter_operator, values } = filter;
      const inboxType = this.getInputType(attribute_key, filter_operator);
      const allCustomAttributes = this.$store.getters[
        'attributes/getAttributesByModel'
      ]('conversation_attribute');

      if (inboxType === undefined) {
        const customAttribute = allCustomAttributes.find(
          attr => attr.attribute_key === attribute_key
        );
        const { attribute_display_type } = customAttribute;
        const filterInputTypes = this.generateCustomAttributesInputType(
          attribute_display_type
        );

        return filterInputTypes === 'string'
          ? values[0].toString()
          : { id: values[0], name: values[0] };
      }

      return inboxType === 'multi_select' || inboxType === 'search_select'
        ? this.getValuesForFilter(filter)
        : values[0].toString();
    },
    getValuesForFilter(filter) {
      const { attribute_key, values } = filter;
      switch (attribute_key) {
        case 'assignee_id':
          return this.getValuesName(values, this.agentList, 'id', 'name');
        case 'inbox_id':
          return this.getValuesName(values, this.inboxesList, 'id', 'name');
        case 'team_id':
          return this.getValuesName(values, this.teamsList, 'id', 'name');
        case 'campaign_id':
          return this.getValuesName(values, this.campaigns, 'id', 'title');
        case 'labels': {
          const selectedLabels = this.labels.filter(label =>
            values.includes(label.title)
          );
          return selectedLabels.map(({ title }) => ({
            id: title,
            name: title,
          }));
        }
        case 'browser_language': {
          const selectedLanguages = languages.filter(language =>
            values.includes(language.id)
          );
          return selectedLanguages.map(({ id, name }) => ({
            id: id.toLowerCase(),
            name: name,
          }));
        }
        case 'country_code': {
          const selectedCountries = countries.filter(country =>
            values.includes(country.id)
          );
          return selectedCountries.map(({ id, name }) => ({
            id: id,
            name: name,
          }));
        }
        default:
          return { id: values[0], name: values[0] };
      }
    },
    getValuesName(values, list, idKey, nameKey) {
      const item = list.find(v => v[idKey] === values[0]);
      return {
        id: values[0],
        name: item ? item[nameKey] : values[0],
      };
    },
    generateCustomAttributesInputType(type) {
      const filterInputTypes = {
        text: 'string',
        number: 'string',
        date: 'string',
        checkbox: 'multi_select',
        list: 'multi_select',
        link: 'string',
      };
      return filterInputTypes[type];
    },
  },
};
