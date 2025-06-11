export function useWhatsappApiRequest() {
  const createSignupPayload = (authCode, store, businessDataParam) => {
    const accountId = store.getters.getCurrentAccountId;
    return {
      account_id: accountId,
      code: authCode.value,
      business_id: businessDataParam.business_id,
      waba_id: businessDataParam.waba_id,
      phone_number_id: businessDataParam.phone_number_id,
    };
  };

  const createFetchOptions = (payload, authHeaders) => {
    return {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document
          .querySelector('meta[name="csrf-token"]')
          ?.getAttribute('content'),
        ...authHeaders.value,
      },
      body: JSON.stringify(payload),
    };
  };

  const makeSignupRequest = async (payload, authHeaders) => {
    const options = createFetchOptions(payload, authHeaders);
    return fetch('/whatsapp/embedded_signup', options);
  };

  const processApiResponse = async (
    response,
    authCode,
    handleSignupSuccess
  ) => {
    const responseData = await response.json();

    if (response.ok) {
      authCode.value = null;
      handleSignupSuccess(responseData);
    } else {
      throw new Error(responseData.message || responseData.error);
    }
  };

  return {
    createSignupPayload,
    makeSignupRequest,
    processApiResponse,
  };
}
