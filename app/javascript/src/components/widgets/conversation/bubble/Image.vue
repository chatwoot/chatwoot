<template>
  <div class="image message-text__wrap">
    <img
      :src="url"
      v-on:click="onClick"
    />
    <span class="time">{{readableTime}}</span>
    <woot-modal :show.sync="show" :on-close="onClose">
      <img
        :src="url"
        class="modal-image"
      />
    </woot-modal>
  </div>
</template>

<script>
export default {
  props: [
    'url',
    'readableTime',
  ],
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
