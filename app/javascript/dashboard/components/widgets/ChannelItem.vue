<template>
  <div
    class="small-3 columns channel"
    :class="{ inactive: !isActive(channel) }"
    @click="onItemClick"
  >
    <img
      v-if="channel === 'facebook'"
      src="~dashboard/assets/images/channels/facebook.png"
    />
    <img
      v-if="channel === 'twitter'"
      src="~dashboard/assets/images/channels/twitter.png"
    />
    <img
      v-if="channel === 'telegram'"
      src="~dashboard/assets/images/channels/telegram.png"
    />
    <img
      v-if="channel === 'line'"
      src="~dashboard/assets/images/channels/line.png"
    />
    <img
      v-if="channel === 'website'"
      src="~dashboard/assets/images/channels/website.png"
    />
    <img
      v-if="channel === 'twilio'"
      src="~dashboard/assets/images/channels/twilio.png"
    />
    <h3 class="channel__title">
      {{ channel }}
    </h3>
  </div>
</template>
<script>
export default {
  props: {
    channel: {
      type: String,
      required: true,
    },
    enabledFeatures: {
      type: Object,
      required: true,
    },
  },
  methods: {
    isActive(channel) {
      if (Object.keys(this.enabledFeatures) === 0) {
        return false;
      }
      if (channel === 'facebook') {
        return this.enabledFeatures.channel_facebook;
      }
      if (channel === 'twitter') {
        return this.enabledFeatures.channel_facebook;
      }
      return ['website', 'twilio'].includes(channel);
    },
    onItemClick() {
      if (this.isActive(this.channel)) {
        this.$emit('channel-item-click', this.channel);
      }
    },
  },
};
</script>
