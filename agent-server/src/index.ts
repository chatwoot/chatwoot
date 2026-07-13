import { loadConfig } from './config.js';
import { buildServer } from './server.js';

const config = loadConfig();
const server = buildServer(config);

const shutdown = async (signal: string): Promise<void> => {
  server.log.info({ event: 'server_shutdown', signal });
  await server.close();
  process.exit(0);
};

process.on('SIGINT', () => void shutdown('SIGINT'));
process.on('SIGTERM', () => void shutdown('SIGTERM'));

try {
  await server.listen({ host: config.HOST, port: config.PORT });
} catch (error) {
  server.log.error(error);
  process.exit(1);
}
