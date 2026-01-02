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

    it('should handle templates with no variables', () => {
      const emptyTemplate = templates.find(
        t => t.name === 'no_variable_template'
      );
      const result = buildTemplateParameters(emptyTemplate, false);
      expect(result).toEqual({});
    });

    it('should build parameters for templates with multiple component types', () => {
      const complexTemplate = {
        components: [
          { type: 'HEADER', format: 'IMAGE' },
          { type: 'BODY', text: 'Hi {{1}}, your order {{2}} is ready!' },
          { type: 'FOOTER', text: 'Thank you for your business' },
          {
            type: 'BUTTONS',
            buttons: [{ type: 'URL', url: 'https://example.com/{{3}}' }],
          },
        ],
      };

      const result = buildTemplateParameters(complexTemplate, true);

      expect(result.header).toEqual({
        media_url: '',
        media_type: 'image',
      });
      expect(result.body).toEqual({ 1: '', 2: '' });
      expect(result.buttons).toEqual([
        {
          type: 'url',
          parameter: '',
          url: 'https://example.com/{{3}}',
          variables: ['3'],
        },
      ]);
    });

    it('should handle copy code buttons correctly', () => {
      const copyCodeTemplate = templates.find(
        t => t.name === 'discount_coupon'
      );
      const result = buildTemplateParameters(copyCodeTemplate, false);

      expect(result.body).toBeDefined();
      expect(result.buttons).toEqual([
        {
          type: 'copy_code',
          parameter: '',
        },
      ]);
    });

    it('should handle templates with document headers', () => {
      const documentTemplate = templates.find(
        t => t.name === 'purchase_receipt'
      );
      const result = buildTemplateParameters(documentTemplate, true);

      expect(result.header).toEqual({
        media_url: '',
        media_type: 'document',
        media_name: '',
      });
      expect(result.body).toEqual({
        1: '',
        2: '',
        3: '',
      });
    });

    it('should handle video header templates', () => {
      const videoTemplate = templates.find(t => t.name === 'training_video');
      const result = buildTemplateParameters(videoTemplate, true);

      expect(result.header).toEqual({
        media_url: '',
        media_type: 'video',
      });
      expect(result.body).toEqual({
        name: '',
        date: '',
      });
    });
  });

  describe('enhanced format validation', () => {
    it('should validate enhanced format structure', () => {
      const processedParams = {
        body: { 1: 'John', 2: 'Order123' },
        header: {
          media_url: 'https://example.com/image.jpg',
          media_type: 'image',
        },
        buttons: [{ type: 'copy_code', parameter: 'SAVE20' }],
      };

      // Test that structure is properly formed
      expect(processedParams.body).toBeDefined();
      expect(typeof processedParams.body).toBe('object');
      expect(processedParams.header).toBeDefined();
      expect(Array.isArray(processedParams.buttons)).toBe(true);
    });

    it('should handle empty component sections', () => {
      const processedParams = {
        body: {},
        header: {},
        buttons: [],
      };

      expect(allKeysRequired(processedParams.body)).toBe(true);
      expect(allKeysRequired(processedParams.header)).toBe(true);
      expect(processedParams.buttons.length).toBe(0);
    });

    it('should validate parameter completeness', () => {
      const incompleteParams = {
        body: { 1: 'John', 2: '' },
      };

      expect(allKeysRequired(incompleteParams.body)).toBe(false);
    });

    it('should handle edge cases in processVariable', () => {
      expect(processVariable('{{')).toBe('');
      expect(processVariable('}}')).toBe('');
      expect(processVariable('')).toBe('');
      expect(processVariable('{{nested{{variable}}}}')).toBe('nestedvariable');
    });

    it('should handle special characters in template variables', () => {
      /* eslint-disable no-template-curly-in-string */
      const templateText =
        'Welcome {{user_name}}, your order #{{order_id}} costs ${{amount}}';
      /* eslint-enable no-template-curly-in-string */
      const processedParams = {
        body: {
          user_name: 'John & Jane',
          order_id: '12345',
          amount: '99.99',
        },
      };

      const result = replaceTemplateVariables(templateText, processedParams);
      expect(result).toBe(
        'Welcome John & Jane, your order #12345 costs $99.99'
      );
    });

    it('should handle templates with mixed parameter types', () => {
      const mixedTemplate = {
        components: [
          { type: 'HEADER', format: 'VIDEO' },
          { type: 'BODY', text: 'Order {{order_id}} status: {{status}}' },
          { type: 'FOOTER', text: 'Thank you' },
          {
            type: 'BUTTONS',
            buttons: [
              { type: 'URL', url: 'https://track.com/{{order_id}}' },
              { type: 'COPY_CODE' },
              { type: 'PHONE_NUMBER', phone_number: '+1234567890' },
            ],
          },
        ],
      };

      const result = buildTemplateParameters(mixedTemplate, true);

      expect(result.header).toEqual({
        media_url: '',
        media_type: 'video',
      });
      expect(result.body).toEqual({
        order_id: '',
        status: '',
      });
      expect(result.buttons).toHaveLength(2); // URL and COPY_CODE (PHONE_NUMBER doesn't need parameters)
      expect(result.buttons[0].type).toBe('url');
      expect(result.buttons[1].type).toBe('copy_code');
    });

    it('should handle templates with no processable components', () => {
      const emptyTemplate = {
        components: [
          { type: 'HEADER', format: 'TEXT', text: 'Static Header' },
          { type: 'BODY', text: 'Static body with no variables' },
          { type: 'FOOTER', text: 'Static footer' },
        ],
      };

      const result = buildTemplateParameters(emptyTemplate, false);
      expect(result).toEqual({});
    });

    it('should validate that replaceTemplateVariables preserves unreplaced variables', () => {
      const templateText = 'Hi {{name}}, order {{order_id}} is {{status}}';
      const partialParams = {
        body: {
          name: 'John',
          // order_id missing
          status: 'ready',
        },
      };

      const result = replaceTemplateVariables(templateText, partialParams);
      expect(result).toBe('Hi John, order {{order_id}} is ready');
      expect(result).toContain('{{order_id}}'); // Unreplaced variable preserved
    });
  });
});
