import CalendlyAPIClient from '../../integrations/calendly';
import ApiClient from '../../ApiClient';

describe('#calendlyAPI', () => {
  it('creates correct instance', () => {
    expect(CalendlyAPIClient).toBeInstanceOf(ApiClient);
    expect(CalendlyAPIClient).toHaveProperty('getEventTypes');
    expect(CalendlyAPIClient).toHaveProperty('createSchedulingLink');
    expect(CalendlyAPIClient).toHaveProperty('getScheduledEvents');
    expect(CalendlyAPIClient).toHaveProperty('cancelEvent');
    expect(CalendlyAPIClient).toHaveProperty('getAvailableTimes');
    expect(CalendlyAPIClient).toHaveProperty('updateSettings');
  });

  const originalAxios = window.axios;
  const axiosMock = {
    post: vi.fn(() => Promise.resolve()),
    get: vi.fn(() => Promise.resolve()),
    patch: vi.fn(() => Promise.resolve()),
    delete: vi.fn(() => Promise.resolve()),
  };

  beforeEach(() => {
    window.axios = axiosMock;
  });

  afterEach(() => {
    window.axios = originalAxios;
  });

  describe('getEventTypes', () => {
    it('creates a valid request', () => {
      CalendlyAPIClient.getEventTypes();
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/integrations/calendly/event_types'
      );
    });
  });

  describe('createSchedulingLink', () => {
    it('creates a valid request', () => {
      const eventTypeUri = 'https://api.calendly.com/event_types/ET123';
      CalendlyAPIClient.createSchedulingLink(eventTypeUri);
      expect(axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/integrations/calendly/scheduling_link',
        { event_type_uri: eventTypeUri }
      );
    });
  });

  describe('getScheduledEvents', () => {
    it('creates a valid request', () => {
      CalendlyAPIClient.getScheduledEvents();
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/integrations/calendly/scheduled_events'
      );
    });
  });

  describe('cancelEvent', () => {
    it('creates a valid request', () => {
      CalendlyAPIClient.cancelEvent('EV123', 'Changed plans');
      expect(axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/integrations/calendly/cancel_event',
        { event_uuid: 'EV123', reason: 'Changed plans' }
      );
    });

    it('sends empty reason by default', () => {
      CalendlyAPIClient.cancelEvent('EV123');
      expect(axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/integrations/calendly/cancel_event',
        { event_uuid: 'EV123', reason: '' }
      );
    });
  });

  describe('getAvailableTimes', () => {
    it('creates a valid request', () => {
      const eventTypeUri = 'https://api.calendly.com/event_types/ET123';
      CalendlyAPIClient.getAvailableTimes(
        eventTypeUri,
        '2025-06-15T00:00:00Z',
        '2025-06-16T00:00:00Z'
      );
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/integrations/calendly/available_times',
        {
          params: {
            event_type_uri: eventTypeUri,
            start_time: '2025-06-15T00:00:00Z',
            end_time: '2025-06-16T00:00:00Z',
          },
        }
      );
    });
  });

  describe('updateSettings', () => {
    it('creates a valid request', () => {
      const settings = {
        default_event_type_uri: 'https://api.calendly.com/event_types/ET123',
      };
      CalendlyAPIClient.updateSettings(settings);
      expect(axiosMock.patch).toHaveBeenCalledWith(
        '/api/v1/integrations/calendly/update_settings',
        settings
      );
    });
  });
});
