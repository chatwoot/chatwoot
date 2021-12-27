<template>
  <div class="column content-box">
    <woot-button
      color-scheme="success"
      class-names="button--fixed-right-top"
      icon="add-circle"
      @click="openAddPopup()"
    >
      {{ $t('AUTOMATION.HEADER_BTN_TXT') }}
    </woot-button>
    <woot-modal
      :show.sync="showAddPopup"
      size="medium"
      :on-close="hideAddPopup"
    >
      <add-automation-rule
        v-if="showAddPopup"
        :on-close="hideAddPopup"
        @applyFilter="onCreateAutomation"
      />
    </woot-modal>
  </div>
</template>
<script>
import AddAutomationRule from './AddAutomationRule.vue';

export default {
  components: {
    AddAutomationRule,
  },
  data() {
    return {
      showAddPopup: false,
    };
  },
  methods: {
    openAddPopup() {
      this.showAddPopup = true;
    },
    hideAddPopup() {
      this.showAddPopup = false;
    },
    async onCreateAutomation(payload) {
      // This is a test action to send the automation data to the server
      // this.$store.dispatch('automations/create', payload);
      const requestOptions = {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      };
      await fetch('https://reqres.in/api/automations', requestOptions);
    },
  },
};
</script>
