import endPoints from 'widget/api/endPoints';
import { API } from 'widget/helpers/axios';
import axios from 'axios'
import { ODOO_SERVICE_URL } from '../../dashboard/constants'

const createConversationAPI = async content => {
  const urlData = endPoints.createConversation(content);
  const result = await API.post(urlData.url, urlData.params);
  const contactData = result.data.contact
  let formData = {
    contact: {
      name: contactData.name,
      email: contactData.email,
      phone: contactData.phone_number ? contactData.phone_number : "",
    },
    lead: {
      name: contactData.name,
      note: `Web Live Chat`,
      utm_term: contactData.custom_attributes.utm_term ? contactData.custom_attributes.utm_term : "",
      utm_medium: contactData.custom_attributes.utm_medium ? contactData.custom_attributes.utm_medium : "",
      utm_source: contactData.custom_attributes.utm_source ? contactData.custom_attributes.utm_source : "",
      utm_campaign: contactData.custom_attributes.utm_campaign ? contactData.custom_attributes.utm_campaign : "",
      utm_content: urlData.params.message.referer_url ? urlData.params.message.referer_url : "",
      gclid: contactData.custom_attributes.gclid ? contactData.custom_attributes.gclid : ""
    },
  };
  if(contactData.custom_attributes.location){
    formData.lead["location"] = contactData.custom_attributes.location
  }
  const data = formData;
  
  try {
    let request = await axios.post(`https://odoo-connector.smsperkasa.com/form_webhook/`, data, {
      headers: {
        "Content-Type": "application/json",
      }
    });
  } catch (error) {
  }
  return result;
};

const sendMessageAPI = async content => {
  const urlData = endPoints.sendMessage(content);
  const result = await API.post(urlData.url, urlData.params);
  return result;
};

const sendAttachmentAPI = async attachment => {
  const urlData = endPoints.sendAttachment(attachment);
  const result = await API.post(urlData.url, urlData.params);
  return result;
};

const getMessagesAPI = async ({ before }) => {
  const urlData = endPoints.getConversation({ before });
  const result = await API.get(urlData.url, { params: urlData.params });
  return result;
};

const getConversationAPI = async () => {
  return API.get(`/api/v1/widget/conversations${window.location.search}`);
};

const toggleTyping = async ({ typingStatus }) => {
  return API.post(
    `/api/v1/widget/conversations/toggle_typing${window.location.search}`,
    { typing_status: typingStatus }
  );
};

const setUserLastSeenAt = async ({ lastSeen }) => {
  return API.post(
    `/api/v1/widget/conversations/update_last_seen${window.location.search}`,
    { contact_last_seen_at: lastSeen }
  );
};
const sendEmailTranscript = async ({ email }) => {
  return API.post(
    `/api/v1/widget/conversations/transcript${window.location.search}`,
    { email }
  );
};

export {
  createConversationAPI,
  sendMessageAPI,
  getConversationAPI,
  getMessagesAPI,
  sendAttachmentAPI,
  toggleTyping,
  setUserLastSeenAt,
  sendEmailTranscript,
};
