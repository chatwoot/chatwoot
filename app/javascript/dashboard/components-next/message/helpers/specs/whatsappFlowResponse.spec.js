import {
  buildFlowResponseEntries,
  formatFlowResponseLabel,
  formatFlowResponseValue,
} from '../whatsappFlowResponse';

describe('whatsappFlowResponse', () => {
  describe('formatFlowResponseLabel', () => {
    it('formats snake case and generated Flow field names', () => {
      expect(formatFlowResponseLabel('flow_token')).toBe('Flow Token');
      expect(formatFlowResponseLabel('screen_0_Rating_0')).toBe(
        'Screen 0 Rating 0'
      );
    });

    it('formats camel case labels', () => {
      expect(formatFlowResponseLabel('appointmentDate')).toBe(
        'Appointment Date'
      );
    });
  });

  describe('formatFlowResponseValue', () => {
    it('formats primitive values', () => {
      expect(formatFlowResponseValue('excellent')).toBe('excellent');
      expect(formatFlowResponseValue(false)).toBe('false');
      expect(formatFlowResponseValue(3)).toBe('3');
    });

    it('formats empty values', () => {
      expect(formatFlowResponseValue(null)).toBe('—');
      expect(formatFlowResponseValue('')).toBe('—');
    });

    it('formats structured values without losing data', () => {
      expect(formatFlowResponseValue({ day: 'Monday' })).toBe(
        '{\n  "day": "Monday"\n}'
      );
      expect(formatFlowResponseValue(['morning', 'afternoon'])).toBe(
        '[\n  "morning",\n  "afternoon"\n]'
      );
    });
  });

  describe('buildFlowResponseEntries', () => {
    it('builds readable answer entries while keeping the flow token as metadata', () => {
      expect(
        buildFlowResponseEntries({
          flow_token: 'correlation-token',
          rating: 'excellent',
          appointment: { day: 'Monday' },
        })
      ).toEqual([
        { key: 'rating', label: 'Rating', value: 'excellent' },
        {
          key: 'appointment',
          label: 'Appointment',
          value: '{\n  "day": "Monday"\n}',
        },
      ]);
    });

    it('displays a raw response as a single readable entry', () => {
      expect(buildFlowResponseEntries('{invalid-json')).toEqual([
        {
          key: 'response',
          label: 'Response',
          value: '{invalid-json',
        },
      ]);
    });
  });
});
