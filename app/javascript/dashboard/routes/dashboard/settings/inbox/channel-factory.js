import Facebook from './channels/Facebook.vue';
import Website from './channels/Website.vue';
import Twitter from './channels/Twitter.vue';
import Api from './channels/Api.vue';
import Email from './channels/Email.vue';
import Sms from './channels/Sms.vue';
import Whatsapp from './channels/Whatsapp.vue';
import Line from './channels/Line.vue';
import Telegram from './channels/Telegram.vue';

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
};

export default {
  create() {
    return {
      props: {
        channel_name: {
          type: String,
          required: true,
        },
      },
      name: 'new-channel-view',
      render(h) {
        return h(channelViewList[this.channel_name] || null);
      },
    };
  },
};
