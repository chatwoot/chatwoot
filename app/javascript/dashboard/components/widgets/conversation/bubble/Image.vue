<template>
  <div v-if="!imgError" class="image message-text__wrap">
    <img :src="url" @click="onClick" @error="onImgError()" />
    <woot-modal :full-width="true" :show.sync="show" :on-close="onClose">
      <img :src="url" class="modal-image" />
    </woot-modal>
  </div>
  <bubble-file v-else :url="url"/>
</template>

<script>
import BubbleFile from './File';

export default {
  components: {
    BubbleFile,
  },
  props: {
    url: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      show: false,
      imgError: false,
    };
  },
  methods: {
    onClose() {
      this.show = false;
    },
    onClick() {
      this.show = true;
    },
    onImgError() {
      this.imgError = true;
    },
  },
};
</script>
