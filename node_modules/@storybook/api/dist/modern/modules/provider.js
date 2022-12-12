export const init = ({
  provider,
  fullAPI
}) => {
  return {
    api: provider.renderPreview ? {
      renderPreview: provider.renderPreview
    } : {},
    init: () => {
      provider.handleAPI(fullAPI);
    }
  };
};