import { describe, it, expect, vi } from 'vitest';
import {
  getEvolutionErrorKey,
  isEvolutionAPIError,
  formatEvolutionError,
} from '../evolutionErrorHandler';

describe('evolutionErrorHandler', () => {
  describe('getEvolutionErrorKey', () => {
    it('should return connection failed for network errors', () => {
      const error = {
        code: 'ECONNREFUSED',
      };

      const result = getEvolutionErrorKey(error);
      expect(result).toBe(
        'INBOX_MGMT.ADD.WHATSAPP.API.EVOLUTION_CONNECTION_FAILED'
      );
    });

    it('should return api unavailable for ENOTFOUND errors', () => {
      const error = {
        code: 'ENOTFOUND',
      };

      const result = getEvolutionErrorKey(error);
      expect(result).toBe(
        'INBOX_MGMT.ADD.WHATSAPP.API.EVOLUTION_API_UNAVAILABLE'
      );
    });

    it('should map 401 status to authentication failed', () => {
      const error = {
        response: {
          status: 401,
          data: { message: 'Unauthorized' },
        },
      };

      const result = getEvolutionErrorKey(error);
      expect(result).toBe(
        'INBOX_MGMT.ADD.WHATSAPP.API.EVOLUTION_AUTHENTICATION_FAILED'
      );
    });

    it('should map 422 status to instance creation failed', () => {
      const error = {
        response: {
          status: 422,
          data: { message: 'Validation error' },
        },
      };

      const result = getEvolutionErrorKey(error);
      expect(result).toBe(
        'INBOX_MGMT.ADD.WHATSAPP.API.EVOLUTION_INSTANCE_CREATION_FAILED'
      );
    });

    it('should map 503 status to api unavailable', () => {
      const error = {
        response: {
          status: 503,
          data: { message: 'Service unavailable' },
        },
      };

      const result = getEvolutionErrorKey(error);
      expect(result).toBe(
        'INBOX_MGMT.ADD.WHATSAPP.API.EVOLUTION_API_UNAVAILABLE'
      );
    });

    it('should detect phone already exists from error message', () => {
      const error = {
        response: {
          status: 400,
          data: { message: 'Phone number already exists in another instance' },
        },
      };

      const result = getEvolutionErrorKey(error);
      expect(result).toBe(
        'INBOX_MGMT.ADD.WHATSAPP.API.EVOLUTION_PHONE_ALREADY_EXISTS'
      );
    });

    it('should detect authentication failed from error message', () => {
      const error = {
        response: {
          status: 400,
          data: { message: 'Invalid API key provided' },
        },
      };

      const result = getEvolutionErrorKey(error);
      expect(result).toBe(
        'INBOX_MGMT.ADD.WHATSAPP.API.EVOLUTION_AUTHENTICATION_FAILED'
      );
    });

    it('should default to instance creation failed for unknown errors', () => {
      const error = {
        response: {
          status: 999,
          data: { message: 'Unknown error' },
        },
      };

      const result = getEvolutionErrorKey(error);
      expect(result).toBe(
        'INBOX_MGMT.ADD.WHATSAPP.API.EVOLUTION_INSTANCE_CREATION_FAILED'
      );
    });
  });

  describe('isEvolutionAPIError', () => {
    it('should return true for evolution channel URLs', () => {
      const error = {
        config: {
          url: '/api/v1/accounts/123/channels/evolution_channel',
        },
      };

      const result = isEvolutionAPIError(error);
      expect(result).toBe(true);
    });

    it('should return true for evolution-related error messages', () => {
      const error = {
        response: {
          data: { message: 'Evolution API connection failed' },
        },
      };

      const result = isEvolutionAPIError(error);
      expect(result).toBe(true);
    });

    it('should return false for non-evolution errors', () => {
      const error = {
        config: {
          url: '/api/v1/accounts/123/channels/website_channel',
        },
        response: {
          data: { message: 'Website channel error' },
        },
      };

      const result = isEvolutionAPIError(error);
      expect(result).toBe(false);
    });
  });

  describe('formatEvolutionError', () => {
    const mockT = vi.fn(key => {
      const translations = {
        'INBOX_MGMT.ADD.WHATSAPP.API.EVOLUTION_CONNECTION_FAILED':
          'Connection failed',
        'INBOX_MGMT.ADD.WHATSAPP.API.EVOLUTION_RETRY_MESSAGE':
          'You can try again',
        'INBOX_MGMT.ADD.WHATSAPP.API.EVOLUTION_TROUBLESHOOTING.CHECK_URL':
          'Check URL',
        'INBOX_MGMT.ADD.WHATSAPP.API.EVOLUTION_TROUBLESHOOTING.CHECK_NETWORK':
          'Check network',
        'INBOX_MGMT.ADD.WHATSAPP.API.EVOLUTION_TROUBLESHOOTING.CONTACT_SUPPORT':
          'Contact support',
      };
      return translations[key] || key;
    });

    beforeEach(() => {
      mockT.mockClear();
    });

    it('should format error with retry message', () => {
      const error = {
        response: {
          status: 503,
          data: { message: 'Service unavailable' },
        },
      };

      const result = formatEvolutionError(error, mockT);

      expect(result.message).toContain('You can try again');
      expect(result.canRetry).toBe(true);
      expect(result.originalError).toBe(error);
    });

    it('should include troubleshooting tips for connection errors', () => {
      const error = {
        response: {
          status: 502,
          data: { message: 'Bad gateway' },
        },
      };

      const result = formatEvolutionError(error, mockT);

      expect(result.troubleshooting).toContain('Check URL');
      expect(result.troubleshooting).toContain('Check network');
      expect(result.troubleshooting).toContain('Contact support');
    });

    it('should mark authentication errors as non-retryable', () => {
      const error = {
        response: {
          status: 401,
          data: { message: 'Unauthorized' },
        },
      };

      const result = formatEvolutionError(error, mockT);

      expect(result.canRetry).toBe(false);
    });

    it('should mark network errors as retryable', () => {
      const error = {
        code: 'ECONNREFUSED',
      };

      const result = formatEvolutionError(error, mockT);

      expect(result.canRetry).toBe(true);
    });
  });
});
