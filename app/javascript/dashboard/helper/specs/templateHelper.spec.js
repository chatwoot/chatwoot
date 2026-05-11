import {
  replaceTemplateVariables,
  replaceTemplateVariablesByExamples,
  buildTemplateParameters,
  processVariable,
  allKeysRequired,
  parseTemplateVariables,
  extractNamedVariables,
  buildExamplePropertyByParameterType,
  generateTemplateComponents,
  validateTemplateData,
  COMPONENT_TYPES,
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

  describe('extractNamedVariables', () => {
    it('should extract named variables', () => {
      expect(extractNamedVariables('Hi {{name}}, {{order_id}} ready')).toEqual([
        'name',
        'order_id',
      ]);
    });

    it('should return empty array for positional variables', () => {
      expect(extractNamedVariables('Hi {{1}}, {{2}} ready')).toEqual([]);
    });

    it('should handle valid variable names only', () => {
      expect(
        extractNamedVariables('{{valid}} {{1invalid}} {{also_valid}}')
      ).toEqual(['valid', 'also_valid']);
    });
  });

  describe('parseTemplateVariables', () => {
    describe('with positional parameter type', () => {
      it('should parse simple positional variables', () => {
        const text = 'Hi {{1}}, your order {{2}} is ready';
        const result = parseTemplateVariables(text, 'positional', 10, []);

        expect(result.processedText).toBe(
          'Hi {{1}}, your order {{2}} is ready'
        );
        expect(result.examples).toEqual(['', '']);
        expect(result.error).toEqual({});
      });

      it('should renumber non-sequential positional variables', () => {
        const text = 'Hi {{3}}, your order {{5}} is {{9}}';
        const result = parseTemplateVariables(text, 'positional', 10, []);

        expect(result.processedText).toBe(
          'Hi {{1}}, your order {{2}} is {{3}}'
        );
        expect(result.examples).toEqual(['', '', '']);
        expect(result.error).toEqual({});
      });

      it('should preserve existing examples that fit', () => {
        const text = 'Hi {{1}}, your order {{2}} is ready';
        const existingExamples = ['John', 'ORD-123', 'Extra'];
        const result = parseTemplateVariables(
          text,
          'positional',
          10,
          existingExamples
        );

        expect(result.processedText).toBe(
          'Hi {{1}}, your order {{2}} is ready'
        );
        expect(result.examples).toEqual(['John', 'ORD-123']);
        expect(result.error).toEqual({});
      });

      it('should add empty strings for new variables when existing examples are insufficient', () => {
        const text = 'Hi {{1}}, order {{2}} status {{3}}';
        const existingExamples = ['John'];
        const result = parseTemplateVariables(
          text,
          'positional',
          10,
          existingExamples
        );

        expect(result.processedText).toBe('Hi {{1}}, order {{2}} status {{3}}');
        expect(result.examples).toEqual(['John', '', '']);
        expect(result.error).toEqual({});
      });

      it('should respect maxVariables limit', () => {
        const text = 'Hi {{1}}, {{2}}, {{3}}, {{4}}, {{5}}Chat';
        const result = parseTemplateVariables(text, 'positional', 3, []);

        expect(result.processedText).toBe('Hi {{1}}, {{2}}, {{3}}, , Chat');
        expect(result.examples).toEqual(['', '', '']);
        expect(result.error).toEqual({});
      });

      it('should return error when named variables are mixed with positional', () => {
        const text = 'Hi {{1}}, your name is {{customer_name}}';
        const result = parseTemplateVariables(text, 'positional', 10, []);

        expect(result.processedText).toBe(
          'Hi {{1}}, your name is {{customer_name}}'
        );
        expect(result.examples).toEqual([]);
        expect(result.error).toEqual({ key: 'NAMED_IN_POSITIONAL' });
      });

      it('should handle text with no variables', () => {
        const text = 'Hi there, your order is ready';
        const result = parseTemplateVariables(text, 'positional', 10, []);

        expect(result.processedText).toBe('Hi there, your order is ready');
        expect(result.examples).toEqual([]);
        expect(result.error).toEqual({});
      });
    });

    describe('with named parameter type', () => {
      it('should parse simple named variables', () => {
        const text = 'Hi {{name}}, your order {{order_id}} is ready';
        const result = parseTemplateVariables(text, 'named', 10, []);

        expect(result.processedText).toBe(
          'Hi {{name}}, your order {{order_id}} is ready'
        );
        expect(result.examples).toEqual([
          { param_name: 'name', example: '' },
          { param_name: 'order_id', example: '' },
        ]);
        expect(result.error).toEqual({});
      });

      it('should preserve existing examples for matching variables', () => {
        const text = 'Hi {{name}}, your order {{order_id}} is ready';
        const existingExamples = [
          { param_name: 'name', example: 'John' },
          { param_name: 'old_var', example: 'OldValue' },
          { param_name: 'order_id', example: 'ORD-123' },
        ];
        const result = parseTemplateVariables(
          text,
          'named',
          10,
          existingExamples
        );

        expect(result.processedText).toBe(
          'Hi {{name}}, your order {{order_id}} is ready'
        );
        expect(result.examples).toEqual([
          { param_name: 'name', example: 'John' },
          { param_name: 'order_id', example: 'ORD-123' },
        ]);
        expect(result.error).toEqual({});
      });

      it('should return error when positional variables are mixed with named', () => {
        const text = 'Hi {{name}}, your order {{1}} is ready';
        const result = parseTemplateVariables(text, 'named', 10, []);

        expect(result.processedText).toBe(
          'Hi {{name}}, your order {{1}} is ready'
        );
        expect(result.examples).toEqual([]);
        expect(result.error).toEqual({ key: 'POSITIONAL_IN_NAMED' });
      });

      it('should detect duplicate variables', () => {
        const text = 'Hi {{name}}, {{name}} your order {{order_id}} is ready';
        const result = parseTemplateVariables(text, 'named', 10, []);

        expect(result.processedText).toBe(
          'Hi {{name}}, {{name}} your order {{order_id}} is ready'
        );
        expect(result.examples).toEqual([]);
        expect(result.error).toEqual({ key: 'DUPLICATE_VARIABLES' });
      });

      it('should return error when exceeding maxVariables', () => {
        const text = 'Variables: {{var1}} {{var2}} {{var3}} {{var4}} {{var5}}';
        const result = parseTemplateVariables(text, 'named', 3, []);

        expect(result.processedText).toBe(
          'Variables: {{var1}} {{var2}} {{var3}} {{var4}} {{var5}}'
        );
        expect(result.examples).toEqual([]);
        expect(result.error).toEqual({
          key: 'MAX_VARIABLES_EXCEEDED',
          data: { count: 3 },
        });
      });

      it('should handle variables with underscores', () => {
        const text = 'User {{user_name}} with ID {{customer_id_123}}';
        const result = parseTemplateVariables(text, 'named', 10, []);

        expect(result.processedText).toBe(
          'User {{user_name}} with ID {{customer_id_123}}'
        );
        expect(result.examples).toEqual([
          { param_name: 'user_name', example: '' },
          { param_name: 'customer_id_123', example: '' },
        ]);
        expect(result.error).toEqual({});
      });

      it('should handle text with no variables', () => {
        const text = 'Hi there, your order is ready';
        const result = parseTemplateVariables(text, 'named', 10, []);

        expect(result.processedText).toBe('Hi there, your order is ready');
        expect(result.examples).toEqual([]);
        expect(result.error).toEqual({});
      });

      it('should handle variables that start with valid characters', () => {
        const text = 'Variables: {{_invalid}} {{9invalid}} {{Valid_123}}';
        const result = parseTemplateVariables(text, 'named', 10, []);

        expect(result.processedText).toBe(
          'Variables: {{_invalid}} {{9invalid}} {{Valid_123}}'
        );
        expect(result.examples).toEqual([
          { param_name: 'Valid_123', example: '' },
        ]);
        expect(result.error).toEqual({});
      });
    });
  });

  describe('buildExamplePropertyByParameterType', () => {
    describe('with positional parameter type', () => {
      it('should return positional example data when positional examples exist', () => {
        const exampleData = {
          header_text: ['Example 1', 'Example 2'],
          header_text_named_params: [],
        };
        const result = buildExamplePropertyByParameterType(
          exampleData,
          'header',
          'positional'
        );

        expect(result).toEqual({
          header_text: ['Example 1', 'Example 2'],
        });
      });

      it('should return null when no positional examples exist', () => {
        const exampleData = {
          body_text: [],
          body_text_named_params: [{ param_name: 'name', example: 'John' }],
        };
        const result = buildExamplePropertyByParameterType(
          exampleData,
          'body',
          'positional'
        );

        expect(result).toBeNull();
      });

      it('should handle different component types', () => {
        const exampleData = {
          body_text: ['Order', '123'],
          body_text_named_params: [],
        };
        const result = buildExamplePropertyByParameterType(
          exampleData,
          'body',
          'positional'
        );

        expect(result).toEqual({
          body_text: ['Order', '123'],
        });
      });

      it('should return null when property is undefined', () => {
        const exampleData = {
          header_text_named_params: [],
        };
        const result = buildExamplePropertyByParameterType(
          exampleData,
          'header',
          'positional'
        );

        expect(result).toBeNull();
      });
    });

    describe('with named parameter type', () => {
      it('should return named example data when named examples exist', () => {
        const exampleData = {
          body_text: [],
          body_text_named_params: [
            { param_name: 'customer', example: 'Alice' },
            { param_name: 'order_id', example: 'ORD-456' },
          ],
        };
        const result = buildExamplePropertyByParameterType(
          exampleData,
          'body',
          'named'
        );

        expect(result).toEqual({
          body_text_named_params: [
            { param_name: 'customer', example: 'Alice' },
            { param_name: 'order_id', example: 'ORD-456' },
          ],
        });
      });

      it('should return null when no named examples exist', () => {
        const exampleData = {
          header_text: ['Example'],
          header_text_named_params: [],
        };
        const result = buildExamplePropertyByParameterType(
          exampleData,
          'header',
          'named'
        );

        expect(result).toBeNull();
      });

      it('should handle different component types', () => {
        const exampleData = {
          header_text: [],
          header_text_named_params: [
            { param_name: 'title', example: 'Welcome' },
          ],
        };
        const result = buildExamplePropertyByParameterType(
          exampleData,
          'header',
          'named'
        );

        expect(result).toEqual({
          header_text_named_params: [
            { param_name: 'title', example: 'Welcome' },
          ],
        });
      });

      it('should return null when property is undefined', () => {
        const exampleData = {
          body_text: [],
        };
        const result = buildExamplePropertyByParameterType(
          exampleData,
          'body',
          'named'
        );

        expect(result).toBeNull();
      });
    });
  });

  describe('generateTemplateComponents', () => {
    describe('basic component generation', () => {
      it('should generate body-only template', () => {
        const templateData = {
          header: { enabled: false },
          body: { type: 'BODY', text: 'Simple message', example: {} },
          footer: { enabled: false },
          buttons: [],
        };

        const result = generateTemplateComponents(templateData, 'positional');

        expect(result).toEqual([
          {
            type: 'BODY',
            text: 'Simple message',
          },
        ]);
      });

      it('should generate template with all components', () => {
        const templateData = {
          header: {
            enabled: true,
            type: 'HEADER',
            format: 'TEXT',
            text: 'Header Text',
            example: {},
          },
          body: {
            type: 'BODY',
            text: 'Body text',
            example: {},
          },
          footer: {
            enabled: true,
            type: 'FOOTER',
            text: 'Footer text',
          },
          buttons: [
            { type: 'QUICK_REPLY', text: 'Yes' },
            { type: 'QUICK_REPLY', text: 'No' },
          ],
        };

        const result = generateTemplateComponents(templateData, 'positional');

        expect(result).toEqual([
          {
            type: 'HEADER',
            format: 'TEXT',
            text: 'Header Text',
          },
          {
            type: 'BODY',
            text: 'Body text',
          },
          {
            type: 'FOOTER',
            text: 'Footer text',
          },
          {
            type: COMPONENT_TYPES.BUTTONS,
            buttons: [
              { type: 'QUICK_REPLY', text: 'Yes' },
              { type: 'QUICK_REPLY', text: 'No' },
            ],
          },
        ]);
      });
    });

    describe('header variations', () => {
      it('should handle TEXT header with positional examples', () => {
        const templateData = {
          header: {
            enabled: true,
            type: 'HEADER',
            format: 'TEXT',
            text: 'Welcome {{1}}',
            example: {
              header_text: ['Customer Name'],
              header_text_named_params: [],
            },
          },
          body: { type: 'BODY', text: 'Body', example: {} },
          footer: { enabled: false },
          buttons: [],
        };

        const result = generateTemplateComponents(templateData, 'positional');

        expect(result[0]).toEqual({
          type: 'HEADER',
          format: 'TEXT',
          text: 'Welcome {{1}}',
          example: {
            header_text: ['Customer Name'],
          },
        });
      });

      it('should handle TEXT header with named examples', () => {
        const templateData = {
          header: {
            enabled: true,
            type: 'HEADER',
            format: 'TEXT',
            text: 'Welcome {{name}}',
            example: {
              header_text: [],
              header_text_named_params: [
                { param_name: 'name', example: 'John' },
              ],
            },
          },
          body: { type: 'BODY', text: 'Body', example: {} },
          footer: { enabled: false },
          buttons: [],
        };

        const result = generateTemplateComponents(templateData, 'named');

        expect(result[0]).toEqual({
          type: 'HEADER',
          format: 'TEXT',
          text: 'Welcome {{name}}',
          example: {
            header_text_named_params: [{ param_name: 'name', example: 'John' }],
          },
        });
      });

      it('should handle media headers (IMAGE/VIDEO/DOCUMENT)', () => {
        const templateData = {
          header: {
            enabled: true,
            type: 'HEADER',
            format: 'IMAGE',
            media: { blobId: 'img123' },
          },
          body: { type: 'BODY', text: 'Body', example: {} },
          footer: { enabled: false },
          buttons: [],
        };

        const result = generateTemplateComponents(templateData, 'positional');

        expect(result[0]).toEqual({
          type: 'HEADER',
          format: 'IMAGE',
          media: {
            blob_id: 'img123',
          },
        });
      });

      it('should handle LOCATION header', () => {
        const templateData = {
          header: {
            enabled: true,
            type: 'HEADER',
            format: 'LOCATION',
          },
          body: { type: 'BODY', text: 'Body', example: {} },
          footer: { enabled: false },
          buttons: [],
        };

        const result = generateTemplateComponents(templateData, 'positional');

        expect(result[0]).toEqual({
          type: 'HEADER',
          format: 'LOCATION',
        });
      });
    });

    describe('body variations', () => {
      it('should add examples to body based on parameter type', () => {
        const templateData = {
          header: { enabled: false },
          body: {
            type: 'BODY',
            text: 'Order {{1}} status: {{2}}',
            example: {
              body_text: ['ORD-123', 'Delivered'],
              body_text_named_params: [],
            },
          },
          footer: { enabled: false },
          buttons: [],
        };

        const result = generateTemplateComponents(templateData, 'positional');

        expect(result[0]).toEqual({
          type: 'BODY',
          text: 'Order {{1}} status: {{2}}',
          example: {
            body_text: ['ORD-123', 'Delivered'],
          },
        });
      });

      it('should not add example property when no examples exist', () => {
        const templateData = {
          header: { enabled: false },
          body: {
            type: 'BODY',
            text: 'Static message with no variables',
            example: {
              body_text: [],
              body_text_named_params: [],
            },
          },
          footer: { enabled: false },
          buttons: [],
        };

        const result = generateTemplateComponents(templateData, 'positional');

        expect(result[0]).toEqual({
          type: 'BODY',
          text: 'Static message with no variables',
        });
      });
    });

    describe('footer and buttons', () => {
      it('should include footer when enabled', () => {
        const templateData = {
          header: { enabled: false },
          body: { type: 'BODY', text: 'Body', example: {} },
          footer: {
            enabled: true,
            type: 'FOOTER',
            text: 'Terms and conditions apply',
          },
          buttons: [],
        };

        const result = generateTemplateComponents(templateData, 'positional');

        expect(result).toContainEqual({
          type: 'FOOTER',
          text: 'Terms and conditions apply',
        });
      });

      it('should not include footer when disabled', () => {
        const templateData = {
          header: { enabled: false },
          body: { type: 'BODY', text: 'Body', example: {} },
          footer: {
            enabled: false,
            type: 'FOOTER',
            text: 'This should not appear',
          },
          buttons: [],
        };

        const result = generateTemplateComponents(templateData, 'positional');

        expect(result).not.toContainEqual(
          expect.objectContaining({ type: 'FOOTER' })
        );
      });

      it('should include buttons when present', () => {
        const templateData = {
          header: { enabled: false },
          body: { type: 'BODY', text: 'Body', example: {} },
          footer: { enabled: false },
          buttons: [
            { type: 'URL', text: 'Visit', url: 'https://example.com' },
            { type: 'PHONE_NUMBER', text: 'Call', phone_number: '+1234567890' },
            { type: 'QUICK_REPLY', text: 'Help' },
          ],
        };

        const result = generateTemplateComponents(templateData, 'positional');

        expect(result).toContainEqual({
          type: COMPONENT_TYPES.BUTTONS,
          buttons: [
            { type: 'URL', text: 'Visit', url: 'https://example.com' },
            { type: 'PHONE_NUMBER', text: 'Call', phone_number: '+1234567890' },
            { type: 'QUICK_REPLY', text: 'Help' },
          ],
        });
      });

      it('should not include buttons component when buttons array is empty', () => {
        const templateData = {
          header: { enabled: false },
          body: { type: 'BODY', text: 'Body', example: {} },
          footer: { enabled: false },
          buttons: [],
        };

        const result = generateTemplateComponents(templateData, 'positional');

        expect(result).not.toContainEqual(
          expect.objectContaining({ type: COMPONENT_TYPES.BUTTONS })
        );
      });

      it('should remove error property from buttons before including them', () => {
        const templateData = {
          header: { enabled: false },
          body: { type: 'BODY', text: 'Body', example: {} },
          footer: { enabled: false },
          buttons: [
            {
              type: 'URL',
              text: 'Visit',
              url: 'https://example.com',
              error: 'Named variable is not supported',
            },
            {
              type: 'QUICK_REPLY',
              text: 'Help',
            },
            {
              type: 'PHONE_NUMBER',
              text: 'Call',
              phone_number: '+1234567890',
              error: null,
            },
          ],
        };

        const result = generateTemplateComponents(templateData, 'positional');

        // Find the buttons component in the result
        const buttonsComponent = result.find(
          component => component.type === COMPONENT_TYPES.BUTTONS
        );

        expect(buttonsComponent).toBeDefined();
        expect(buttonsComponent.buttons).toHaveLength(3);

        // Verify that none of the buttons have the error property
        buttonsComponent.buttons.forEach(button => {
          expect(button).not.toHaveProperty('error');
        });

        // Verify the buttons still have their other properties
        expect(buttonsComponent.buttons[0]).toEqual({
          type: 'URL',
          text: 'Visit',
          url: 'https://example.com',
        });
        expect(buttonsComponent.buttons[1]).toEqual({
          type: 'QUICK_REPLY',
          text: 'Help',
        });
        expect(buttonsComponent.buttons[2]).toEqual({
          type: 'PHONE_NUMBER',
          text: 'Call',
          phone_number: '+1234567890',
        });
      });
    });
  });

  describe('validateTemplateData', () => {
    const validTemplateData = {
      header: { enabled: false },
      body: { type: 'BODY', text: 'Valid body text' },
      footer: { enabled: false },
      buttons: [],
    };

    it('should return true for valid template data', () => {
      expect(validateTemplateData(validTemplateData)).toBe(true);
    });

    it('should return false when body has error', () => {
      const templateData = {
        ...validTemplateData,
        body: { ...validTemplateData.body, error: 'Body error' },
      };
      expect(validateTemplateData(templateData)).toBe(false);
    });

    it('should return false when body has no text', () => {
      const templateData = {
        ...validTemplateData,
        body: { type: 'BODY', text: '' },
      };
      expect(validateTemplateData(templateData)).toBe(false);
    });

    it('should return false when TEXT header is enabled but has no text', () => {
      const templateData = {
        ...validTemplateData,
        header: { enabled: true, format: 'TEXT', text: '' },
      };
      expect(validateTemplateData(templateData)).toBe(false);
    });

    it('should return false when IMAGE header is enabled but has no blobId', () => {
      const templateData = {
        ...validTemplateData,
        header: { enabled: true, format: 'IMAGE', media: {} },
      };
      expect(validateTemplateData(templateData)).toBe(false);
    });

    it('should return true when IMAGE header has blobId', () => {
      const templateData = {
        ...validTemplateData,
        header: {
          enabled: true,
          format: 'IMAGE',
          media: { blobId: 'blob123' },
        },
      };
      expect(validateTemplateData(templateData)).toBe(true);
    });

    it('should return false when header has error', () => {
      const templateData = {
        ...validTemplateData,
        header: {
          enabled: true,
          format: 'TEXT',
          text: 'Header',
          error: 'Error',
        },
      };
      expect(validateTemplateData(templateData)).toBe(false);
    });

    it('should return false when footer is enabled but has no text', () => {
      const templateData = {
        ...validTemplateData,
        footer: { enabled: true, text: '' },
      };
      expect(validateTemplateData(templateData)).toBe(false);
    });

    it('should return false when buttons have errors', () => {
      const templateData = {
        ...validTemplateData,
        buttons: [
          {
            type: 'URL',
            text: 'Visit',
            url: 'https://example.com',
            error: 'Button error',
          },
        ],
      };
      expect(validateTemplateData(templateData)).toBe(false);
    });

    it('should return true when buttons have no errors', () => {
      const templateData = {
        ...validTemplateData,
        buttons: [{ type: 'URL', text: 'Visit', url: 'https://example.com' }],
      };
      expect(validateTemplateData(templateData)).toBe(true);
    });
  });

  describe('replaceTemplateVariablesByExamples', () => {
    it('should replace positional variables using provided examples', () => {
      const templateText = 'Hi {{1}}, your order {{2}} is ready';
      const examples = ['John', 'ORD-42'];

      const result = replaceTemplateVariablesByExamples({
        templateText,
        examples,
        parameterType: 'positional',
      });

      expect(result).toBe('Hi John, your order ORD-42 is ready');
    });

    it('should skip empty positional examples', () => {
      const templateText = 'Tracking: {{1}} - Status: {{2}}';
      const examples = ['TRK-1', ''];

      const result = replaceTemplateVariablesByExamples({
        templateText,
        examples,
        parameterType: 'positional',
      });

      expect(result).toBe('Tracking: TRK-1 - Status: {{2}}');
    });

    it('should replace named variables using provided examples', () => {
      const templateText = 'Hi {{name}}, your OTP is {{otp}}';
      const examples = [
        { param_name: 'name', example: 'Jane' },
        { param_name: 'otp', example: '987654' },
      ];

      const result = replaceTemplateVariablesByExamples({
        templateText,
        examples,
        parameterType: 'named',
      });

      expect(result).toBe('Hi Jane, your OTP is 987654');
    });

    it('should return empty string when template text is empty', () => {
      const result = replaceTemplateVariablesByExamples({
        templateText: '',
        examples: ['Example'],
        parameterType: 'positional',
      });

      expect(result).toBe('');
    });
  });
});
