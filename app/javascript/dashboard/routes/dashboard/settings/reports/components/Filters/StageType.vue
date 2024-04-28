<template>
  <div class="multiselect-wrap--small">
    <multiselect
      v-model="selectedOption"
      class="no-margin"
      track-by="name"
      label="name"
      :placeholder="$t('FORMS.MULTISELECT.SELECT_ONE')"
      selected-label
      select-label=""
      deselect-label=""
      :options="options"
      :searchable="false"
      :allow-empty="false"
      @select="updateStageType"
    />
  </div>
</template>

<script>
import { STAGE_TYPE_OPTIONS } from '../../constants';

const EVENT_NAME = 'on-stage-type-change';

export default {
  data() {
    const translatedOptions = Object.values(STAGE_TYPE_OPTIONS).map(option => ({
      ...option,
      name: this.$t(option.translationKey),
    }));
    // TO-DO: change to get from last user's selection
    const defaultOption = translatedOptions[0];
    this.$emit(EVENT_NAME, defaultOption);
    return {
      // relies on translations, need to move it to constants
      selectedOption: defaultOption,
      options: translatedOptions,
    };
  },
  methods: {
    updateStageType(selectedStageType) {
      this.selectedOption = selectedStageType;
      this.$emit(EVENT_NAME, selectedStageType);
    },
  },
};
</script>
