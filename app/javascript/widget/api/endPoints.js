import { buildSearchParamsWithLocale } from '../helpers/urlParamsHelper';
import { generateEventParams } from './events';

const createConversation = params => {
  const referrerURL = window.referrerURL || '';
  const search = buildSearchParamsWithLocale(window.location.search);
  return {
    url: `/api/v1/widget/conversations${search}`,
    params: {
      contact: {
        name: params.fullName,
        email: params.emailAddress,
      },
      message: {
        content: params.message,
        timestamp: new Date().toString(),
        referer_url: referrerURL,
      },
    },
  };
};

const sendMessage = content => {
  const referrerURL = window.referrerURL || '';
  const search = buildSearchParamsWithLocale(window.location.search);
  return {
    url: `/api/v1/widget/messages${search}`,
    params: {
      message: {
        content,
        timestamp: new Date().toString(),
        referer_url: referrerURL,
      },
    },
  };
};

const sendAttachment = ({ attachment }) => {
  const { referrerURL = '' } = window;
  const timestamp = new Date().toString();
  const { file } = attachment;

  const formData = new FormData();
  formData.append('message[attachments][]', file);
  formData.append('message[referer_url]', referrerURL);
  formData.append('message[timestamp]', timestamp);
  return {
    url: `/api/v1/widget/messages${window.location.search}`,
    params: formData,
  };
};

const getConversation = ({ before }) => ({
  url: `/api/v1/widget/messages${window.location.search}`,
  params: { before },
});

const updateMessage = id => ({
  url: `/api/v1/widget/messages/${id}${window.location.search}`,
});

const getAvailableAgents = token => ({
  url: '/api/v1/widget/inbox_members',
  params: {
    website_token: token,
  },
});
const getCampaigns = token => ({
  url: '/api/v1/widget/campaigns',
  params: {
    website_token: token,
  },
});
const triggerCampaign = ({ websiteToken, campaignId }) => ({
  url: '/api/v1/widget/events',
  data: {
    name: 'campaign.triggered',
    event_info: {
      campaign_id: campaignId,
      ...generateEventParams(),
    },
  },
  params: {
    website_token: websiteToken,
  },
});

export default {
  createConversation,
  sendMessage,
  sendAttachment,
  getConversation,
  updateMessage,
  getAvailableAgents,
  getCampaigns,
  triggerCampaign,
};
