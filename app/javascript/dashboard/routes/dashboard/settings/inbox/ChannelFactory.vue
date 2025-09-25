<script>
import { defineComponent, h } from 'vue';
import Facebook from './channels/Facebook.vue';
import Website from './channels/Website.vue';
import Twitter from './channels/Twitter.vue';
import Api from './channels/Api.vue';
import Email from './channels/Email.vue';
import Sms from './channels/Sms.vue';
import Whatsapp from './channels/Whatsapp.vue';
import Line from './channels/Line.vue';
import Telegram from './channels/Telegram.vue';
import Instagram from './channels/Instagram.vue';
import Voice from './channels/Voice.vue';
import AppleMessagesForBusiness from './channels/AppleMessagesForBusiness.vue';

const channelViewList = {
  facebook: Facebook,
  website: Website,
  twitter: Twitter,
  api: Api,
  email: Email,
  sms: Sms,
  whatsapp: Whatsapp,
  line: Line,
  telegram: Telegram,
  instagram: Instagram,
  voice: Voice,
  apple_messages_for_business: AppleMessagesForBusiness,
};

export default defineComponent({
  name: 'NewChannelView',
  props: {
    channelName: {
      type: String,
      required: true,
    },
  },
  render() {
    const ChannelComponent = channelViewList[this.channelName];
    return ChannelComponent ? h(ChannelComponent) : null;
  },
});
</script>
