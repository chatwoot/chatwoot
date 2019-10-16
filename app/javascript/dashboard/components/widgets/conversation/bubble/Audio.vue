<template>
  <div class="audio message-text__wrap">
    <a-player
      :music="playerOptions"
      mode="order"
    />
    <span class="time">{{readableTime}}</span>
  </div>
</template>

<script>
import APlayer from 'vue-aplayer';

export default {
  components: {
    APlayer,
  },
  props: [
    'url',
    'readableTime',
  ],
  data() {
    return {
      musicObj: {
        title: ' ',
        author: ' ',
        autoplay: false,
        narrow: true,
      },
    };
  },
  computed: {
    playerOptions() {
      return {
        ...this.musicObj,
        url: this.url,
      };
    },
  },
};
</script>
