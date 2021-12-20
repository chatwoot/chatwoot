<template>
  <div class="column content-box">
    <woot-button
      color-scheme="success"
      class-names="button--fixed-right-top"
      @click="openAddPopup()"
      icon="add-circle"
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
        @applyFilter="onApplyFilter"
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
    onApplyFilter() {},
  },
};
</script>
