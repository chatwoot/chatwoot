<template>
  <div class="flex-1 overflow-auto">
    <stage />
  </div>
</template>

<script>
import Stage from './Stage.vue';
export default {
  components: {
    Stage,
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
