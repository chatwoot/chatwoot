import authEndPoint from 'widget/api/endPoints';
import { API } from 'widget/helpers/axios';

export default {
  update: ({
    messageId,
    email,
    values,
    phone,
    orderId,
    selectedReply,
    productId,
    previousSelectedReplies,
  }) => {
    const urlData = authEndPoint.updateMessage(messageId);
    return API.patch(urlData.url, {
      contact: { email },
      message: {
        submitted_values: values,
        user_phone_number: phone,
        selected_reply: selectedReply,
        previous_selected_replies: previousSelectedReplies,
        user_order_id: orderId,
        product_id: productId,
      },
    });
  },
  personaliseMessageVariables: (payload, accessToken) => {
    return API.post('/api/v1/personalise_variables', payload, {
      headers: {
        api_access_token: accessToken,
      },
    });
  },
};
