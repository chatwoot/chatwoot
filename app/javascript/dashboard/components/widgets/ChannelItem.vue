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
  emits: ['channelItemClick'],
  computed: {
    hasFbConfigured() {
      return window.chatwootConfig?.fbAppId;
    },
    hasInstagramConfigured() {
      return window.chatwootConfig?.instagramAppId;
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
      if (key === 'email') {
        return this.enabledFeatures.channel_email;
      }

      if (key === 'instagram') {
        return (
          this.enabledFeatures.channel_instagram && this.hasInstagramConfigured
        );
      }

      if (key === 'voice') {
        return this.enabledFeatures.channel_voice;
      }

      return [
        'website',
        'twilio',
        'api',
        'whatsapp',
        'sms',
        'telegram',
        'line',
        'instagram',
        'voice',
      ].includes(key);
    },
    isComingSoon() {
      const { key } = this.channel;
      // Show "Coming Soon" only if the channel is marked as coming soon
      // and the corresponding feature flag is not enabled yet.
      return ['voice'].includes(key) && !this.isActive;
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
        this.$emit('channelItemClick', this.channel.key);
      }
    },
  },
};
</script>

<template>
  <ChannelSelector
    :class="{ inactive: !isActive }"
    :title="channel.name"
    :src="getChannelThumbnail()"
    :is-coming-soon="isComingSoon"
    @click="onItemClick"
  />
</template>
