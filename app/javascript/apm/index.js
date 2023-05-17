import { init as initApm } from '@elastic/apm-rum';

if (process.env.NODE_ENV !== 'development') {
  initApm({
    // Set required service name (allowed characters: a-z, A-Z, 0-9, -, _, and space)
    serviceName: 'birdwoot',

    // Set custom APM Server URL (default: http://localhost:8200)
    serverUrl: process.env.VUE_APP_APM_RUM_SERVER_URL,

    // Set the service version (required for source map feature)
    serviceVersion: process.env.VUE_APP_VERSION,

    // Set the service environment
    environment: process.env.NODE_ENV,
  });
}
