export default {
  methods: {
    setFilterAttributes() {
      const allCustomAttributes = this.$store.getters[
        'attributes/getAttributesByModel'
      ](this.attributeModel);
      const customAttributesFormatted = {
        name: this.$t(`${this.filtersFori18n}.GROUPS.CUSTOM_ATTRIBUTES`),
        attributes: allCustomAttributes.map(attr => {
          return {
            key: attr.attribute_key,
            name: attr.attribute_display_name,
          };
        }),
      };
      const allFilterGroups = this.filterAttributeGroups.map(group => {
        return {
          name: this.$t(`${this.filtersFori18n}.GROUPS.${group.i18nGroup}`),
          attributes: group.attributes.map(attribute => {
            return {
              key: attribute.key,
              name: this.$t(
                `${this.filtersFori18n}.ATTRIBUTES.${attribute.i18nKey}`
              ),
            };
          }),
        };
      });
      const customAttributeTypes = allCustomAttributes.map(attr => {
        return {
          attributeKey: attr.attribute_key,
          attributeI18nKey: `CUSTOM_ATTRIBUTE_${attr.attribute_display_type.toUpperCase()}`,
          inputType: this.customAttributeInputType(attr.attribute_display_type),
          filterOperators: this.getOperatorTypes(attr.attribute_display_type),
          attributeModel: 'custom_attributes',
        };
      });
      this.filterTypes = [...this.filterTypes, ...customAttributeTypes];
      this.filterGroups = [...allFilterGroups, customAttributesFormatted];
    },
  },
};
