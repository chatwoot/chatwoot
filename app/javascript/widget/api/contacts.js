import { API } from 'widget/helpers/axios';

const buildUrl = endPoint => `/api/v1/${endPoint}${window.location.search}`;

export default {
  get() {
    return API.get(buildUrl('widget/contact'));
  },
  update(userObject) {
    return API.patch(buildUrl('widget/contact'), userObject);
  },
  getWhatsappRedirectURL() {
    return API.get(buildUrl('widget/contact/get_whatsapp_redirect_url'));
  },
  getWhatsappWidgetUrl() {
    return API.get(buildUrl('widget/contact/get_url_for_whatsapp_widget'));
  },
  getCheckoutRedirectURL(shopUrl, lineItems) {
    return API.get(
      `/api/v1/widget/contact/get_checkout_url${
        window.location.search
      }&shop_url=${shopUrl}&line_items=${encodeURIComponent(
        JSON.stringify(lineItems)
      )}`
    );
  },
  setUser(identifier, userObject) {
    return API.patch(buildUrl('widget/contact/set_user'), {
      identifier,
      ...userObject,
    });
  },
  setCustomAttributes(customAttributes = {}) {
    return API.patch(buildUrl('widget/contact'), {
      custom_attributes: customAttributes,
    });
  },
  deleteCustomAttribute(customAttribute) {
    return API.post(buildUrl('widget/contact/destroy_custom_attributes'), {
      custom_attributes: [customAttribute],
    });
  },
  getBotConfig() {
    return API.get(buildUrl('widget/contact/bot_config'));
  },
  updateBotConfig(popupId) {
    return API.patch(
      `/api/v1/widget/contact/update_bot_config${window.location.search}`,
      {
        popup_id: popupId,
      }
    );
  },
  sendMainMenuMessage() {
    return API.post(buildUrl('widget/contact/send_main_menu_message'));
  },
};
