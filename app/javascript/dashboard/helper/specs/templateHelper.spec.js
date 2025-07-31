import {
  replaceTemplateVariables,
  buildTemplateParameters,
  processVariable,
  allKeysRequired,
  populateAuthenticationButtonParameters,
} from '../templateHelper';
import { templates } from '../../store/modules/specs/inboxes/templateFixtures';

describe('templateHelper', () => {
  const technicianTemplate = templates.find(t => t.name === 'technician_visit');
  const otpTemplate = templates.find(t => t.name === 'basic_otp');

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

    it('should handle AUTHENTICATION category templates with special OTP handling', () => {
      const result = buildTemplateParameters(otpTemplate, false);
      expect(result.body).toEqual({
        otp_code: '',
      });
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

    it('should skip button variables for AUTHENTICATION templates', () => {
      const result = buildTemplateParameters(otpTemplate, false);
      expect(result.buttons).toBeUndefined();
    });
  });

  describe('populateAuthenticationButtonParameters', () => {
    it('should auto-populate URL button parameters with OTP code for authentication templates', () => {
      const processedParams = {
        body: {
          otp_code: '123456',
        },
        buttons: [
          {
            type: 'url',
            parameter: '',
            url: 'https://www.whatsapp.com/otp/code/?code=otp{{1}}',
          },
        ],
      };

      const result = populateAuthenticationButtonParameters(
        otpTemplate,
        processedParams
      );

      expect(result.buttons[0].parameter).toBe('123456');
    });

    it('should use positional parameter "1" if available for authentication templates', () => {
      const processedParams = {
        body: {
          1: '654321',
          otp_code: '123456',
        },
        buttons: [
          {
            type: 'url',
            parameter: '',
            url: 'https://www.whatsapp.com/otp/code/?code=otp{{1}}',
          },
        ],
      };

      const result = populateAuthenticationButtonParameters(
        otpTemplate,
        processedParams
      );

      expect(result.buttons[0].parameter).toBe('654321');
    });

    it('should not modify non-authentication templates', () => {
      const processedParams = {
        body: {
          name: 'John',
        },
        buttons: [
          {
            type: 'url',
            parameter: '',
            url: 'https://example.com/{{name}}',
          },
        ],
      };

      const result = populateAuthenticationButtonParameters(
        technicianTemplate,
        processedParams
      );

      expect(result.buttons[0].parameter).toBe('');
    });

    it('should not modify non-URL buttons in authentication templates', () => {
      const authTemplateWithQuickReply = {
        category: 'AUTHENTICATION',
        components: [
          {
            type: 'BODY',
            text: 'Your code is {{1}}',
          },
        ],
      };

      const processedParams = {
        body: {
          otp_code: '123456',
        },
        buttons: [
          {
            type: 'quick_reply',
            parameter: 'original_value',
          },
        ],
      };

      const result = populateAuthenticationButtonParameters(
        authTemplateWithQuickReply,
        processedParams
      );

      expect(result.buttons[0].parameter).toBe('original_value');
    });

    it('should handle templates without buttons', () => {
      const processedParams = {
        body: {
          otp_code: '123456',
        },
      };

      const result = populateAuthenticationButtonParameters(
        otpTemplate,
        processedParams
      );

      expect(result).toEqual(processedParams);
    });

    it('should not mutate the original processedParams object', () => {
      const processedParams = {
        body: {
          otp_code: '123456',
        },
        buttons: [
          {
            type: 'url',
            parameter: '',
            url: 'https://www.whatsapp.com/otp/code/?code=otp{{1}}',
          },
        ],
      };

      const originalParams = JSON.parse(JSON.stringify(processedParams));
      populateAuthenticationButtonParameters(otpTemplate, processedParams);

      expect(processedParams).toEqual(originalParams);
    });
  });
});
