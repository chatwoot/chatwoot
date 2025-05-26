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
      isActive() {
        const availableChannels = (this.enabledFeatures?.available_channels || []).map(c => c.toLowerCase());
        return availableChannels.includes(this.channel.key.toLowerCase());
      }
  },
  methods: {
    getChannelThumbnail() {
      if (this.channel.key === 'api' && this.channel.thumbnail) {
        return this.channel.thumbnail;
      }
      if (this.channel.key === 'whatsapp_unofficial') {
        return `/assets/images/dashboard/channels/whatsapp.png`;
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
    @click="onItemClick"
  />
</template>
