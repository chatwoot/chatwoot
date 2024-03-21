<template>
  <channel-selector
    :class="{ inactive: !isActive }"
    :title="channel.name"
    :src="getChannelThumbnail()"
    @click="onItemClick"
  />
</template>
<script>
import ChannelSelector from '../ChannelSelector.vue';
export default {
  components: { ChannelSelector },
  props: {
    channel: {
      type: Object,
      required: true,
    },
    enabledFeatures: {
      type: Object,
      required: true,
    },
  },
  computed: {
    hasStringeeConfigured() {
      return window.chatwootConfig?.stringeeSID;
    },
    hasZaloConfigured() {
      return window.chatwootConfig?.zaloAppId;
    },
    hasFbConfigured() {
      return window.chatwootConfig?.fbAppId;
    },
    isActive() {
      const { key } = this.channel;
      if (Object.keys(this.enabledFeatures).length === 0) {
        return false;
      }
      if (key === 'website') {
        return this.enabledFeatures.channel_website;
      }
      if (key === 'facebook') {
        return this.enabledFeatures.channel_facebook && this.hasFbConfigured;
      }
      if (key === 'zalo') {
        return this.enabledFeatures.channel_zalo && this.hasZaloConfigured;
      }
      if (key === 'stringee') {
        return (
          this.enabledFeatures.channel_stringee && this.hasStringeeConfigured
        );
      }
      if (key === 'email') {
        return this.enabledFeatures.channel_email;
      }

      return [
        'website',
        'twilio',
        'api',
        'whatsapp',
        'sms',
        'telegram',
        'line',
      ].includes(key);
    },
  },
  methods: {
    getChannelThumbnail() {
      if (this.channel.key === 'api' && this.channel.thumbnail) {
        return this.channel.thumbnail;
      }
      return `/assets/images/dashboard/channels/${this.channel.key}.png`;
    },
    onItemClick() {
      if (this.isActive) {
        this.$emit('channel-item-click', this.channel.key);
      }
    },
  },
};
</script>
