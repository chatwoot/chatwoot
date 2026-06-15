import { ref } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import ChannelApi from 'dashboard/api/channels';
import { buildFacebookLoginScopes } from 'dashboard/helper/facebookScopes';
import { setupFacebookSdk } from 'dashboard/routes/dashboard/settings/inbox/channels/whatsapp/utils';

// Headless half of the Facebook Page connect flow: load the Meta SDK, run
// FB.login for page scopes, and fetch the user's pages. The caller owns the
// page-picker UI and the channel creation, because choosing a page is an
// interactive step (a user can manage several pages).
//
// Split into preloadSdk() + loginAndFetchPages() for popup safety: FB.login
// opens a popup and needs the click's transient activation. Preloading the SDK
// when the picker opens means the click-time `await` resolves within that
// activation window; a cold load resolves on the script's `load` task seconds
// later, after activation has expired, and the popup gets blocked.
export function useFacebookPageConnect() {
  const accountId = useMapGetter('getCurrentAccountId');
  const isAuthenticating = ref(false);

  let sdkSetupPromise = null;

  // Idempotent — call this when the picker UI opens. A failed load clears the
  // cache so a later attempt can retry instead of being stuck on a rejection.
  const preloadSdk = () => {
    if (!sdkSetupPromise) {
      sdkSetupPromise = setupFacebookSdk(
        window.chatwootConfig?.fbAppId,
        window.chatwootConfig?.fbApiVersion
      ).catch(error => {
        sdkSetupPromise = null;
        throw error;
      });
    }
    return sdkSetupPromise;
  };

  // FB.login never rejects; resolve the user access token on success and null
  // for any other status (closed popup, not_authorized, unknown).
  const login = () =>
    new Promise(resolve => {
      window.FB.login(
        response => {
          resolve(
            response.status === 'connected'
              ? response.authResponse?.accessToken || null
              : null
          );
        },
        { scope: buildFacebookLoginScopes() }
      );
    });

  // Resolves { userAccessToken, pages } on success, null when the user cancels,
  // and rejects on SDK-load or page-fetch failure (the caller maps it to UI).
  const loginAndFetchPages = async () => {
    if (isAuthenticating.value) return null;
    isAuthenticating.value = true;
    try {
      await preloadSdk();
      const token = await login();
      if (!token) return null;

      const response = await ChannelApi.fetchFacebookPages(
        token,
        accountId.value
      );
      const { page_details: pages, user_access_token: userAccessToken } =
        response.data.data;
      return { userAccessToken, pages };
    } finally {
      isAuthenticating.value = false;
    }
  };

  return { isAuthenticating, preloadSdk, loginAndFetchPages };
}
