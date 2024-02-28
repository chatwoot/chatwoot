<template>
  <div class="flex-1 overflow-auto">
    <woot-button
      color-scheme="success"
      class-names="button--fixed-top"
      icon="add-circle"
      @click="openAddPopup()"
    >
      {{ $t('ATTRIBUTES_MGMT.HEADER_BTN_TXT') }}
    </woot-button>
    <custom-attribute />
    <woot-modal :show.sync="showAddPopup" :on-close="hideAddPopup">
      <add-attribute :on-close="hideAddPopup" />
    </woot-modal>
  </div>
</template>

<script>
import AddAttribute from './AddAttribute.vue';
import CustomAttribute from './CustomAttribute.vue';
export default {
  components: {
    AddAttribute,
    CustomAttribute,
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
  },
};
</script>

<style></style>
