import authEndPoint from 'widget/api/endPoints';
import { API } from 'widget/helpers/axios';

export default {
  update: ({ messageId, email, values, phone, orderId, selectedReply }) => {
    const urlData = authEndPoint.updateMessage(messageId);
    return API.patch(urlData.url, {
      contact: { email },
      message: {
        submitted_values: values,
        user_phone_number: phone,
        selected_reply: selectedReply,
        user_order_id: orderId,
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
