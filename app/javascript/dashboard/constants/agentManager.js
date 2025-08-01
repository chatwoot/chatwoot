/**
 * Agent Manager API constants and utilities
 * Used for making requests to the agent-manager service
 */

// Base URL for the agent-manager service
const AGENT_MANAGER_BASE_URL = 'https://api.dev.omnifylabs.com';
const AGENT_MANAGER_BASE_URL_PROD = 'https://api.app.dashassist.ai';

/**
 * Get the agent manager base URL based on environment
 * @returns {string} The base URL for the agent manager service
 */
export const getAgentManagerBaseUrl = () => {
  return window.chatwootConfig.hostEnv === 'production' ? AGENT_MANAGER_BASE_URL_PROD : AGENT_MANAGER_BASE_URL;
};