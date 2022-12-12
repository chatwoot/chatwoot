import "core-js/modules/es.promise.js";
import { logger } from '@storybook/node-logger';
import { readFile } from 'fs-extra';
import http from 'http';
import https from 'https';
export async function getServer(app, options) {
  if (!options.https) {
    return http.createServer(app);
  }

  if (!options.sslCert) {
    logger.error('Error: --ssl-cert is required with --https');
    process.exit(-1);
  }

  if (!options.sslKey) {
    logger.error('Error: --ssl-key is required with --https');
    process.exit(-1);
  }

  var sslOptions = {
    ca: await Promise.all((options.sslCa || []).map(function (ca) {
      return readFile(ca, 'utf-8');
    })),
    cert: await readFile(options.sslCert, 'utf-8'),
    key: await readFile(options.sslKey, 'utf-8')
  };
  return https.createServer(sslOptions, app);
}