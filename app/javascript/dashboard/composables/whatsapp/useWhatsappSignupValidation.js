export function useWhatsappSignupValidation() {
  const isValidBusinessData = businessData => {
    return (
      businessData &&
      (businessData.business_id || businessData.businessId) &&
      (businessData.waba_id || businessData.wabaId)
    );
  };

  const normalizeBusinessData = businessData => {
    return {
      business_id: businessData.business_id || businessData.businessId,
      waba_id: businessData.waba_id || businessData.wabaId,
      phone_number_id:
        businessData.phone_number_id ||
        businessData.phoneNumberId ||
        businessData.phone_id,
    };
  };

  return {
    isValidBusinessData,
    normalizeBusinessData,
  };
}
