const firstPresent = (...values) => values.find(value => value);

export const normalizeTemplateToInteractive = template => {
  if (!template) return {};

  const result = {
    type: 'button',
    body: {},
    header: {},
    footer: {},
    action: { buttons: [] },
  };

  const components = template.components || [];

  components.forEach(component => {
    const compType = (component.type || '').toUpperCase();

    switch (compType) {
      case 'HEADER':
        if (component.parameters?.[0]?.type === 'image') {
          result.header = {
            type: 'image',
            image: { link: component.parameters[0].image?.link || '' },
          };
        } else if (component.parameters?.[0]?.type === 'text') {
          result.header = {
            type: 'text',
            text: component.parameters[0].text || '',
          };
        }
        break;

      case 'BODY':
        if (component.parameters?.length > 0) {
          const bodyParts = component.parameters.map(p => p.text || '');
          result.body.text = bodyParts.join('\n\n');
        }
        break;

      case 'FOOTER':
        if (component.parameters?.[0]?.text) {
          result.footer.text = component.parameters[0].text;
        }
        break;

      case 'BUTTON':
        if (component.parameters?.[0]) {
          result.action.buttons.push({
            type: 'reply',
            reply: {
              title:
                component.parameters[0].text ||
                component.parameters[0].coupon_code ||
                'Button',
            },
          });
        }
        break;

      default:
        break;
    }
  });

  if (!result.body.text && template.name) {
    result.body.text = `Template: ${template.name}`;
  }

  return result;
};

export const extractWhatsAppInteractivePayload = contentAttributes => {
  const attributes = contentAttributes || {};
  const interactivePayload = firstPresent(
    attributes.whatsapp_interactive_payload,
    attributes.whatsappInteractivePayload,
    attributes.interactive
  );

  if (interactivePayload) return interactivePayload;

  const templatePayload = firstPresent(
    attributes.whatsapp_template_payload,
    attributes.whatsappTemplatePayload,
    attributes.template
  );

  return normalizeTemplateToInteractive(templatePayload);
};
