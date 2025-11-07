const createPromise = () => {
  let p = {};
  return {
    promise: new Promise((resolve, reject) => {
      p.resolve = resolve;
      p.reject = reject;
    }),
    setSuccess: result => {
      p.resolve(result);
    },
    setError: reason => {
      p.reject(reason);
    },
  };
};

class TokenHelper {
  tenant = '';

  playerEnv = '';

  accessToken = '';

  refreshToken = '';

  tokenParsed = {};

  timeSkew = 0;

  refreshQueue = [];
  serverUrl = '';
  baseUrl = '';
  isEhrLaunch;
  space = 'jeeves-epic';

  isTokenExpired(minValidity) {
    if (!this.tokenParsed || !this.refreshToken || !this.tokenParsed.exp) {
      // console.log('Not authenticated');
      return true;
    }

    let expiresIn =
      this.tokenParsed.exp -
      Math.ceil(new Date().getTime() / 1000) +
      this.timeSkew;
    if (minValidity) {
      if (Number.isNaN(minValidity)) {
        // console.log('Invalid minValidity');
        return true;
      }
      expiresIn -= minValidity;
    }
    return expiresIn < 0;
  }

  // eslint-disable-next-line class-methods-use-this
  updateToken(minValidity) {
    const promise = createPromise();

    if (!this.refreshToken) {
      promise.setError('Refresh token not found');
      return promise.promise;
    }

    const exec = () => {
      let refresh = false;
      if (minValidity === -1) {
        refresh = true;
      } else if (!this.tokenParsed || this.isTokenExpired(minValidity)) {
        refresh = true;
      }

      if (!refresh) {
        promise.setSuccess(false);
      } else {
        const url = `https://auth.314ecorp.${this.playerEnv}/auth/realms/${this.tenant}/protocol/openid-connect/token`;
        const params = `grant_type=refresh_token&refresh_token=${this.refreshToken}&client_id=jeeves`;

        this.refreshQueue.push(promise);

        if (this.refreshQueue.length === 1) {
          const req = new XMLHttpRequest();
          req.open('POST', url, true);
          req.setRequestHeader(
            'Content-Type',
            'application/x-www-form-urlencoded'
          );
          req.withCredentials = true;

          let timeLocal = new Date().getTime();

          req.onreadystatechange = () => {
            if (req.readyState === 4) {
              if (req.status === 200) {
                timeLocal = (timeLocal + new Date().getTime()) / 2;
                const tokenResponse = JSON.parse(req.responseText);
                // eslint-disable-next-line no-console
                console.log('Refresh token success', tokenResponse);

                this.accessToken = tokenResponse.access_token;

                this.refreshQueue.forEach(queue => {
                  if (queue) {
                    queue.setSuccess(true);
                  }
                });
                this.refreshQueue = [];
              } else {
                this.refreshQueue.forEach(queue => {
                  if (queue) {
                    queue.setError(true);
                  }
                });
                this.refreshQueue = [];
              }
            }
          };

          req.send(params);
        }
      }
    };

    exec();
    return promise.promise;
  }

  init(message) {
    const {
      accessToken,
      refreshToken,
      idToken,
      localTime,
      tenant,
      playerEnv,
      hasLiveAgentEnabled,
      isEhrLaunch,
      serverUrl,
      baseUrl,
      space
    } = message;
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
    this.idToken = idToken;
    this.tenant = tenant;
    this.playerEnv = playerEnv;
    this.baseUrl = baseUrl;
    this.space = space;
    if (serverUrl) {
      this.serverUrl = serverUrl;
    } else {
      this.serverUrl = `https://${tenant}.jeeves.314ecorp.${playerEnv}`; // this is fallback to old server url
    }
    this.hasLiveAgentEnabled = hasLiveAgentEnabled;
    this.isEhrLaunch = isEhrLaunch;

    // ignore
    // eslint-disable-next-line no-console
    console.log({ hasLiveAgentEnabled });
    try {
      const parsed = JSON.parse(window.atob(accessToken.split('.')[1]));
      this.tokenParsed = parsed;
    } catch (e) {
      // ignore
      // eslint-disable-next-line no-console
      console.log(e);
    }

    if (localTime && this.tokenParsed.iat) {
      this.timeSkew = Math.floor(localTime / 1000) - this.tokenParsed.iat;
    }
  }

  async getToken() {
    await this.updateToken(60);
    return this.accessToken;
  }
}

const tokenHelperInstance = new TokenHelper();

export { tokenHelperInstance };
