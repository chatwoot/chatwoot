<template>
  <div class="small-3 columns channel" :class="{ inactive: channel !== 'facebook' }" @click.capture="itemClick">
    <img src="~assets/images/channels/facebook.png" v-if="channel === 'facebook'">
    <img src="~assets/images/channels/twitter.png" v-if="channel === 'twitter'">
    <img src="~assets/images/channels/telegram.png" v-if="channel === 'telegram'">
    <img src="~assets/images/channels/line.png" v-if="channel === 'line'">
    <h3 class="channel__title">{{channel}}</h3>
    <!-- <p>This is the most sexiest integration to begin </p> -->
  </div>
</template>
<script>
/* global bus */
export default {
  props: ['channel'],
  created() {
  },
  methods: {
    itemClick() {
      bus.$emit('channelItemClick', this.channel);
    },
  },
};
</script>
