/**
 * Build Meta WhatsApp Business API template components from form data
 */

import type { HeaderFormat, ButtonType } from '../validators/metaTemplateRules';

export interface MetaTemplatePayload {
  name: string;
  category: string;
  language: string;
  allow_category_change: boolean;
  components: Array<{
    type: string;
    format?: string;
    text?: string;
    example?: {
      header_text?: string[];
      header_url?: string[];
      header_handle?: string[];
      body_text?: string[][];
    };
    buttons?: Array<{
      type: string;
      text?: string;
      url?: string;
      phone_number?: string;
      example?: string[];
    }>;
  }>;
}

export interface TemplateFormData {
  name: string;
  category: string;
  language: string;
  allowCategoryChange: boolean;
  headerFormat: HeaderFormat | null;
  headerText: string;
  headerTextExample: string;
  headerMediaUrl: string; // preview only
  headerMediaHandle: string; // required for IMAGE/VIDEO/DOCUMENT template creation
  bodyText: string;
  bodyExamples: string[];
  footerText: string;
  buttons: Array<{
    type: ButtonType;
    text?: string;
    url?: string;
    urlExample?: string;
    phoneNumber?: string;
  }>;
}

/**
 * Build the complete Meta template payload from form data
 */
export function buildTemplatePayload(formData: TemplateFormData): MetaTemplatePayload {
  const components: MetaTemplatePayload['components'] = [];

  // 1. HEADER component (optional)
  if (formData.headerFormat) {
    const headerComponent: any = {
      type: 'HEADER',
      format: formData.headerFormat,
    };

    if (formData.headerFormat === 'TEXT') {
      headerComponent.text = formData.headerText;
      
      // Add example if there's a placeholder
      if (formData.headerText.includes('{{1}}') && formData.headerTextExample) {
        headerComponent.example = {
          header_text: [formData.headerTextExample],
        };
      }
    }

    // For IMAGE/VIDEO/DOCUMENT headers, we need to provide an example with the media URL
    // Meta requires header_handle with a handle obtained via Meta upload API (h)
    if ((formData.headerFormat === 'IMAGE' || 
         formData.headerFormat === 'VIDEO' || 
         formData.headerFormat === 'DOCUMENT') && formData.headerMediaHandle) {
      headerComponent.example = {
        header_handle: [formData.headerMediaHandle],
      };
    }

    components.push(headerComponent);
  }

  // 2. BODY component (required)
  const bodyComponent: any = {
    type: 'BODY',
    text: formData.bodyText,
  };

  // Add examples if there are placeholders
  if (formData.bodyExamples && formData.bodyExamples.length > 0) {
    bodyComponent.example = {
      body_text: [formData.bodyExamples],
    };
  }

  components.push(bodyComponent);

  // 3. FOOTER component (optional)
  if (formData.footerText && formData.footerText.trim().length > 0) {
    components.push({
      type: 'FOOTER',
      text: formData.footerText.trim(),
    });
  }

  // 4. BUTTONS component (optional)
  if (formData.buttons && formData.buttons.length > 0) {
    const buttonsComponent: any = {
      type: 'BUTTONS',
      buttons: formData.buttons.map(button => {
        const btn: any = {
          type: button.type,
        };

        if (button.type === 'QUICK_REPLY' || button.type === 'URL' || button.type === 'PHONE_NUMBER') {
          btn.text = button.text;
        }

        if (button.type === 'URL') {
          btn.url = button.url;
          
          // Add example if URL has placeholder
          if (button.url && button.url.includes('{{1}}') && button.urlExample) {
            btn.example = [button.urlExample];
          }
        }

        if (button.type === 'PHONE_NUMBER') {
          btn.phone_number = button.phoneNumber;
        }

        if (button.type === 'COPY_CODE') {
          // COPY_CODE doesn't need text - Meta auto-generates "Copy code" label
          btn.example = formData.bodyExamples.length > 0 ? [formData.bodyExamples[0]] : [];
        }

        return btn;
      }),
    };

    components.push(buttonsComponent);
  }

  // Build final payload
  return {
    name: formData.name.toLowerCase().replace(/\s+/g, '_'),
    category: formData.category,
    language: formData.language,
    allow_category_change: formData.allowCategoryChange,
    components,
  };
}
