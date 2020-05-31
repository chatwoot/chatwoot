<template>
  <div>
    <i class="ion ion-earth"></i>
    <select :value="selectedLocale" @change="onLocaleChange">
      <option
        v-for="lang in enabledLanguages"
        :key="lang.iso_639_1_code"
        :value="lang.iso_639_1_code"
      >
        {{ lang.name }}
      </option>
    </select>
  </div>
</template>

<script>
import Vue from 'vue';
import configMixin from 'shared/mixins/configMixin';

export default {
  mixins: [configMixin],
  data() {
    return {
      selectedLocale: 'en',
    };
  },
  methods: {
    onLocaleChange(selectedLocale) {
      Vue.config.lang = selectedLocale;
      this.selectedLocale = selectedLocale;
    },
  },
};
</script>
