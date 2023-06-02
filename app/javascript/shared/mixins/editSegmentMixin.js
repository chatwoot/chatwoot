import {
  getInputType,
  getAttributeInputType,
} from 'dashboard/helper/customViewsHelper';
import contactFilterItems from 'dashboard/routes/dashboard/contacts/contactFilterItems';
import countries from 'shared/constants/countries.js';

export default {
  data() {
    return {
      filterTypes: contactFilterItems,
    };
  },
  methods: {
    initializeSegmentToFilterModal(activeSegment) {
      const query = activeSegment?.query?.payload;
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
    generateValueObjectForFilter(filter) {
      const { attribute_key, filter_operator, values } = filter;
      const inboxType = getInputType(
        attribute_key,
        filter_operator,
        this.filterTypes
      );

      if (inboxType === undefined) {
        const allCustomAttributes = this.$store.getters[
          'attributes/getAttributesByModel'
        ]('contact_attribute');

        const filterInputTypes = getAttributeInputType(
          attribute_key,
          allCustomAttributes
        );
        return filterInputTypes === 'string'
          ? values[0].toString()
          : { id: values[0], name: values[0] };
      }

      return inboxType === 'search_select'
        ? this.getValuesForFilter(filter)
        : values[0].toString();
    },
    getValuesForFilter(filter) {
      const { attribute_key, values } = filter;
      switch (attribute_key) {
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
  },
};
