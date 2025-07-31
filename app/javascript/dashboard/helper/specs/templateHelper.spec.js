import {
  replaceTemplateVariables,
  buildTemplateParameters,
  processVariable,
  allKeysRequired,
} from '../templateHelper';
import { templates } from '../../store/modules/specs/inboxes/templateFixtures';

describe('templateHelper', () => {
  const technicianTemplate = templates.find(t => t.name === 'technician_visit');

  describe('processVariable', () => {
    it('should remove curly braces from variables', () => {
      expect(processVariable('{{name}}')).toBe('name');
      expect(processVariable('{{1}}')).toBe('1');
      expect(processVariable('{{customer_id}}')).toBe('customer_id');
    });
  });

  describe('allKeysRequired', () => {
    it('should return true when all keys have values', () => {
      const obj = { name: 'John', age: '30' };
      expect(allKeysRequired(obj)).toBe(true);
    });

    it('should return false when some keys are empty', () => {
      const obj = { name: 'John', age: '' };
      expect(allKeysRequired(obj)).toBe(false);
    });

    it('should return true for empty object', () => {
      expect(allKeysRequired({})).toBe(true);
    });
  });

  describe('replaceTemplateVariables', () => {
    const templateText =
      "Hi {{1}}, we're scheduling a technician visit to {{2}} on {{3}} between {{4}} and {{5}}. Please confirm if this time slot works for you.";

    it('should replace all variables with provided values', () => {
      const processedParams = {
        body: {
          1: 'John',
          2: '123 Main St',
          3: '2025-01-15',
          4: '10:00 AM',
          5: '2:00 PM',
        },
      };

      const result = replaceTemplateVariables(templateText, processedParams);
      expect(result).toBe(
        "Hi John, we're scheduling a technician visit to 123 Main St on 2025-01-15 between 10:00 AM and 2:00 PM. Please confirm if this time slot works for you."
      );
    });

    it('should keep original variable format when no replacement value provided', () => {
      const processedParams = {
        body: {
          1: 'John',
          3: '2025-01-15',
        },
      };

      const result = replaceTemplateVariables(templateText, processedParams);
      expect(result).toContain('John');
      expect(result).toContain('2025-01-15');
      expect(result).toContain('{{2}}');
      expect(result).toContain('{{4}}');
      expect(result).toContain('{{5}}');
    });

    it('should handle empty processedParams', () => {
      const result = replaceTemplateVariables(templateText, {});
      expect(result).toBe(templateText);
    });
  });

  describe('buildTemplateParameters', () => {
    it('should build parameters for template with body variables', () => {
      const result = buildTemplateParameters(technicianTemplate, false);

      expect(result.body).toEqual({
        1: '',
        2: '',
        3: '',
        4: '',
        5: '',
      });
    });

    it('should include header parameters when hasMediaHeader is true', () => {
      const imageTemplate = templates.find(
        t => t.name === 'order_confirmation'
      );
      const result = buildTemplateParameters(imageTemplate, true);

      expect(result.header).toEqual({
        media_url: '',
        media_type: 'image',
      });
    });

    it('should not include header parameters when hasMediaHeader is false', () => {
      const result = buildTemplateParameters(technicianTemplate, false);
      expect(result.header).toBeUndefined();
    });

    it('should handle template with no body component', () => {
      const templateWithoutBody = {
        components: [{ type: 'HEADER', format: 'TEXT' }],
      };

      const result = buildTemplateParameters(templateWithoutBody, false);
      expect(result).toEqual({});
    });

    it('should handle template with no variables', () => {
      const templateWithoutVars = templates.find(
        t => t.name === 'no_variable_template'
      );
      const result = buildTemplateParameters(templateWithoutVars, false);

      expect(result.body).toBeUndefined();
    });

    it('should handle URL buttons with variables for non-authentication templates', () => {
      const templateWithUrlButton = {
        category: 'MARKETING',
        components: [
          {
            type: 'BODY',
            text: 'Check out our website at {{site_url}}',
          },
          {
            type: 'BUTTONS',
            buttons: [
              {
                type: 'URL',
                url: 'https://example.com/{{campaign_id}}',
                text: 'Visit Site',
              },
            ],
          },
        ],
      };

      const result = buildTemplateParameters(templateWithUrlButton, false);
      expect(result.buttons).toEqual([
        {
          type: 'url',
          parameter: '',
          url: 'https://example.com/{{campaign_id}}',
          variables: ['campaign_id'],
        },
      ]);
    });
  });
});
