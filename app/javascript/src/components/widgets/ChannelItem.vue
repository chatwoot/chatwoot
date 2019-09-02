<template>
  <div
    class="small-3 channel"
    :class="{ inactive: !['facebook', 'email'].includes(channel) }"
    @click.capture="itemClick"
  >
    <img v-if="channel === 'email'" src="~assets/images/channels/email.png" />
    <img
      v-if="channel === 'facebook'"
      src="~assets/images/channels/facebook.png"
    />
    <img
      v-if="channel === 'twitter'"
      src="~assets/images/channels/twitter.png"
    />
    <img
      v-if="channel === 'telegram'"
      src="~assets/images/channels/telegram.png"
    />
    <img v-if="channel === 'line'" src="~assets/images/channels/line.png" />
    <h3 class="channel__title">
      {{ channel }}
    </h3>
  </div>
</template>
<script>
/* global bus */
export default {
  props: {
    channel: {
      type: String,
      default: '',
    },
  },
  methods: {
    itemClick() {
      bus.$emit('channelItemClick', this.channel);
    },
  },
};
</script>
