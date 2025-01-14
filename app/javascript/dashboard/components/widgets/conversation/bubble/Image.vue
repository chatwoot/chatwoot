<script>
export default {
  components: {},
  props: {
    url: {
      type: String,
      required: true,
    },
  },
  emits: ['error'],
  data() {
    return {
      show: false,
    };
  },
  methods: {
    onClose() {
      this.show = false;
    },
    onClick() {
      this.show = true;
    },
  },
};
</script>

<template>
  <div class="image message-text__wrap">
    <img :src="url" @click="onClick" @error="$emit('error')" />
    <woot-modal v-model:show="show" full-width :on-close="onClose">
      <img :src="url" class="modal-image skip-context-menu" />
    </woot-modal>
  </div>
</template>
