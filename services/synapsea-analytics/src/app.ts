import { env } from './config/env.js';
import { createServer } from './shared/http/createServer.js';

const bootstrap = async () => {
  const app = createServer();
  await app.listen({ port: env.PORT, host: '0.0.0.0' });
};

bootstrap();
