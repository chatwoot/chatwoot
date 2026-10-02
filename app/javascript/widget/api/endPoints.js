import { buildSearchParamsWithLocale } from '../helpers/urlParamsHelper';
import { generateEventParams } from './events';

const PAGE_TITLE_MAX_LENGTH = 256;
const TAB_ID_MAX_LENGTH = 64;

const serializeCurrentPage = currentPage => {
  if (!currentPage || typeof currentPage !== 'object') return null;

  let url;
  try {
    const pageURL = new URL(currentPage.url);
    if (!['http:', 'https:'].includes(pageURL.protocol)) return null;
    if (pageURL.username || pageURL.password) return null;
    pageURL.search = '';
    pageURL.hash = '';
    url = pageURL.toString();
  } catch (error) {
    return null;
  }

  const rawTabId = currentPage.tabId ?? currentPage.tab_id;
  const tabId =
    typeof rawTabId === 'string' ? rawTabId.slice(0, TAB_ID_MAX_LENGTH) : '';
  const title = String(currentPage.title || '').slice(0, PAGE_TITLE_MAX_LENGTH);
  const sequence =
    Number.isSafeInteger(currentPage.sequence) && currentPage.sequence >= 0
      ? currentPage.sequence
      : 0;

  return {
    url,
    title,
    tab_id: tabId,
    sequence,
  };
};

const createConversation = (params, pageContext) => {
  const referrerURL = window.referrerURL || '';
  const search = buildSearchParamsWithLocale(window.location.search);
  const currentPage = serializeCurrentPage(
    pageContext || params.currentPage || params.current_page
  );
  const conversationParams = {
    contact: {
      name: params.fullName,
      email: params.emailAddress,
      phone_number: params.phoneNumber,
      custom_attributes: params.contactCustomAttributes,
    },
    message: {
      content: params.message,
      timestamp: new Date().toString(),
      referer_url: referrerURL,
    },
    custom_attributes: params.customAttributes,
  };
  if (currentPage) conversationParams.current_page = currentPage;

  return {
    url: `/api/v1/widget/conversations${search}`,
    params: conversationParams,
  };
};

const updateCurrentPage = pageContext => ({
  url: `/api/v1/widget/conversations/update_current_page${window.location.search}`,
  params: {
    current_page: serializeCurrentPage(pageContext),
  },
});

const sendMessage = (content, replyTo, { customAttributes, labels } = {}) => {
  const referrerURL = window.referrerURL || '';
  const search = buildSearchParamsWithLocale(window.location.search);
  const params = {
    message: {
      content,
      reply_to: replyTo,
      timestamp: new Date().toString(),
      referer_url: referrerURL,
    },
  };
  if (customAttributes && Object.keys(customAttributes).length > 0) {
    params.custom_attributes = customAttributes;
  }
  if (labels && labels.length > 0) {
    params.labels = labels;
  }
  return { url: `/api/v1/widget/messages${search}`, params };
};

const sendAttachment = (
  { attachment, replyTo = null },
  { customAttributes, labels } = {}
) => {
  const { referrerURL = '' } = window;
  const timestamp = new Date().toString();
  const { file } = attachment;

  const formData = new FormData();
  if (typeof file === 'string') {
    formData.append('message[attachments][]', file);
  } else {
    formData.append('message[attachments][]', file, file.name);
  }

  formData.append('message[referer_url]', referrerURL);
  formData.append('message[timestamp]', timestamp);
  if (replyTo !== null) {
    formData.append('message[reply_to]', replyTo);
  }
  if (customAttributes && Object.keys(customAttributes).length > 0) {
    Object.entries(customAttributes).forEach(([key, value]) => {
      formData.append(`custom_attributes[${key}]`, value);
    });
  }
  if (labels && labels.length > 0) {
    labels.forEach(label => {
      formData.append('labels[]', label);
    });
  }
  return {
    url: `/api/v1/widget/messages${window.location.search}`,
    params: formData,
  };
};

const getConversation = ({ before, after }) => ({
  url: `/api/v1/widget/messages${window.location.search}`,
  params: { before, after },
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
const triggerCampaign = ({ websiteToken, campaignId, customAttributes }) => ({
  url: '/api/v1/widget/events',
  data: {
    name: 'campaign.triggered',
    event_info: {
      campaign_id: campaignId,
      custom_attributes: customAttributes,
      ...generateEventParams(),
    },
  },
  params: {
    website_token: websiteToken,
  },
});

const getMostReadArticles = (slug, locale) => ({
  url: `/hc/${slug}/${locale}/articles.json`,
  params: {
    page: 1,
    sort: 'views',
    status: 1,
    per_page: 6,
  },
});

export default {
  createConversation,
  updateCurrentPage,
  sendMessage,
  sendAttachment,
  getConversation,
  updateMessage,
  getAvailableAgents,
  getCampaigns,
  triggerCampaign,
  getMostReadArticles,
};
