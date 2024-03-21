import Facebook from './channels/Facebook';
import Zalo from './channels/Zalo';
import Stringee from './channels/Stringee';
import Website from './channels/Website';
import Twitter from './channels/Twitter';
import Api from './channels/Api';
import Email from './channels/Email';
import Sms from './channels/Sms';
import Whatsapp from './channels/Whatsapp';
import Line from './channels/Line';
import Telegram from './channels/Telegram';

const channelViewList = {
  facebook: Facebook,
  zalo: Zalo,
  stringee: Stringee,
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
