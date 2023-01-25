<template>
  <div class="image message-text__wrap">
    <img :src="url" @click="onClick" @error="onImgError()" :alt="Story no longer available" />
    <woot-modal :full-width="true" :show.sync="show" :on-close="onClose">
      <img :src="url" class="modal-image" />
    </woot-modal>
  </div>
</template>

<script>
export default {
  components: {},
  props: {
    url: {
      type: String,
      required: true,
    },
  },
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
    onImgError() {
      console.log('Image failed to load');
      this.props.url = "";
    },
  },
};
</script>
