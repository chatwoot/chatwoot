import { addRequestDataToEvent } from '@sentry/utils';
import { defineIntegration } from '../integration.js';

const DEFAULT_OPTIONS = {
  include: {
    cookies: true,
    data: true,
    headers: true,
    ip: false,
    query_string: true,
    url: true,
    user: {
      id: true,
      username: true,
      email: true,
    },
  },
  transactionNamingScheme: 'methodPath' ,
};

const INTEGRATION_NAME = 'RequestData';

const _requestDataIntegration = ((options = {}) => {
  const _options = {
    ...DEFAULT_OPTIONS,
    ...options,
    include: {
      ...DEFAULT_OPTIONS.include,
      ...options.include,
      user:
        options.include && typeof options.include.user === 'boolean'
          ? options.include.user
          : {
              ...DEFAULT_OPTIONS.include.user,
              // Unclear why TS still thinks `options.include.user` could be a boolean at this point
              ...((options.include || {}).user ),
            },
    },
  };

  return {
    name: INTEGRATION_NAME,
    processEvent(event) {
      // Note: In the long run, most of the logic here should probably move into the request data utility functions. For
      // the moment it lives here, though, until https://github.com/getsentry/sentry-javascript/issues/5718 is addressed.
      // (TL;DR: Those functions touch many parts of the repo in many different ways, and need to be cleaned up. Once
      // that's happened, it will be easier to add this logic in without worrying about unexpected side effects.)

      const { sdkProcessingMetadata = {} } = event;
      const req = sdkProcessingMetadata.request;

      if (!req) {
        return event;
      }

      const addRequestDataOptions = convertReqDataIntegrationOptsToAddReqDataOpts(_options);

      return addRequestDataToEvent(event, req, addRequestDataOptions);
    },
  };
}) ;

/**
 * Add data about a request to an event. Primarily for use in Node-based SDKs, but included in `@sentry/core`
 * so it can be used in cross-platform SDKs like `@sentry/nextjs`.
 */
const requestDataIntegration = defineIntegration(_requestDataIntegration);

/** Convert this integration's options to match what `addRequestDataToEvent` expects */
/** TODO: Can possibly be deleted once https://github.com/getsentry/sentry-javascript/issues/5718 is fixed */
function convertReqDataIntegrationOptsToAddReqDataOpts(
  integrationOptions,
) {
  const {
    transactionNamingScheme,
    include: { ip, user, ...requestOptions },
  } = integrationOptions;

  const requestIncludeKeys = ['method'];
  for (const [key, value] of Object.entries(requestOptions)) {
    if (value) {
      requestIncludeKeys.push(key);
    }
  }

  let addReqDataUserOpt;
  if (user === undefined) {
    addReqDataUserOpt = true;
  } else if (typeof user === 'boolean') {
    addReqDataUserOpt = user;
  } else {
    const userIncludeKeys = [];
    for (const [key, value] of Object.entries(user)) {
      if (value) {
        userIncludeKeys.push(key);
      }
    }
    addReqDataUserOpt = userIncludeKeys;
  }

  return {
    include: {
      ip,
      user: addReqDataUserOpt,
      request: requestIncludeKeys.length !== 0 ? requestIncludeKeys : undefined,
      transaction: transactionNamingScheme,
    },
  };
}

export { requestDataIntegration };
//# sourceMappingURL=requestdata.js.map
