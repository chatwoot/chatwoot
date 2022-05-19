<template>
  <div
    v-if="isEnabled"
    class="small-6 medium-4 large-3 columns channel"
    :class="{ inactive: !isActive }"
    @click="onItemClick"
  >
    <img
      v-if="channel.key === 'facebook'"
      src="~dashboard/assets/images/channels/messenger.png"
    />
    <img
      v-if="channel.key === 'twitter'"
      src="~dashboard/assets/images/channels/twitter.png"
    />
    <img
      v-if="channel.key === 'telegram'"
      src="~dashboard/assets/images/channels/telegram.png"
    />
    <img
      v-if="channel.key === 'api' && !channel.thumbnail"
      src="~dashboard/assets/images/channels/api.png"
    />
    <img
      v-if="channel.key === 'api' && channel.thumbnail"
      :src="channel.thumbnail"
    />
    <img
      v-if="channel.key === 'email'"
      src="~dashboard/assets/images/channels/email.png"
    />
    <img
      v-if="channel.key === 'line'"
      src="~dashboard/assets/images/channels/line.png"
    />
    <img
      v-if="channel.key === 'website'"
      src="~dashboard/assets/images/channels/website.png"
    />
    <img
      v-if="channel.key === 'sms'"
      src="~dashboard/assets/images/channels/sms.png"
    />
    <img
      v-if="channel.key === 'whatsapp'"
      src="~dashboard/assets/images/channels/whatsapp.png"
    />
    <h3 class="channel__title">
      {{ channel.name }}
    </h3>
  </div>
</template>
<script>
const FEATURE_FLAG_KEYS = {
  api: 'channel_api',
  email: 'channel_email',
  facebook: 'channel_facebook_page',
  line: 'channel_line',
  sms: 'channel_sms',
  telegram: 'channel_telegram',
  twilio: 'channel_twilio_sms',
  twitter: 'channel_twitter_profile',
  website: 'channel_web_widget',
  whatsapp: 'channel_whatsapp',
};

export default {
  props: {
    channel: {
      type: Object,
      required: true,
    },
    enabledFeatures: {
      type: Array,
      required: true,
    },
  },
  computed: {
    isEnabled() {
      return this.enabledFeatures.includes(FEATURE_FLAG_KEYS[this.channel.key]);
    },
    isActive() {
      const { key } = this.channel;
      // if (Object.keys(this.enabledFeatures).length === 0) {
      //   return false;
      // }
      // if (key === 'facebook') {
      //   return this.enabledFeatures.channel_facebook;
      // }
      // if (key === 'twitter') {
      //   return this.enabledFeatures.channel_twitter;
      // }
      // if (key === 'email') {
      //   return this.enabledFeatures.channel_email;
      // }

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
    onItemClick() {
      if (this.isActive) {
        this.$emit('channel-item-click', this.channel.key);
      }
    },
  },
};
</script>
