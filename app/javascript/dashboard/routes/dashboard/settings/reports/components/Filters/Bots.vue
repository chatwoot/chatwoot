<script>
export default {
  name: 'ReportsFiltersBots',
  emits: ['botFilterSelection'],
  data() {
    return {
      selectedOption: null,
      options: [
        { id: 'all', name: 'Pilih Bot' },
        { id: 1, name: 'Sales Assistant Bot' },
        { id: 2, name: 'Customer Service Bot' },
        { id: 3, name: 'Restaurant Bot' },
        { id: 4, name: 'Booking Bot' },
        { id: 5, name: 'Custom Workflow Bot' }
      ]
    };
  },
  mounted() {
    this.selectedOption = this.options[0];
    this.handleInput();
    
    // TODO: fetch bots from API
    // this.$store.dispatch('bots/get');
  },
  methods: {
    handleInput() {
      this.$emit('botFilterSelection', this.selectedOption);
    },
  },
};
</script>

<template>
  <div class="multiselect-wrap--small">
    <multiselect
      v-model="selectedOption"
      class="no-margin"
      label="name"
      track-by="id"
      :options="options"
      :option-height="24"
      :show-labels="false"
      @update:model-value="handleInput"
    />
  </div>
</template>