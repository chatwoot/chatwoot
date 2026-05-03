import { describe, expect, it } from 'vitest';
import { extractWhatsAppInteractivePayload } from '../whatsappInteractivePayload';

const templatePayload = {
  name: 'alerta_movimentacao_processual_v2',
  language: { code: 'pt_BR' },
  components: [
    {
      type: 'header',
      parameters: [
        {
          type: 'image',
          image: {
            link: 'https://jusmonitoria.witdev.com.br/jusmonitorialogo.png',
          },
        },
      ],
    },
    {
      type: 'body',
      parameters: [
        {
          type: 'text',
          parameter_name: 'lista_processos',
          text: 'Processo 9541385-01.2026.4.01.3315 com novas movimentacoes',
        },
      ],
    },
  ],
};

describe('extractWhatsAppInteractivePayload', () => {
  it('normalizes camelCase WhatsApp template attributes from the dashboard store', () => {
    const payload = extractWhatsAppInteractivePayload({
      whatsappTemplatePayload: templatePayload,
    });

    expect(payload.type).toBe('button');
    expect(payload.header.image.link).toBe(
      'https://jusmonitoria.witdev.com.br/jusmonitorialogo.png'
    );
    expect(payload.body.text).toBe(
      'Processo 9541385-01.2026.4.01.3315 com novas movimentacoes'
    );
  });

  it('normalizes snake_case WhatsApp template attributes from Rails payloads', () => {
    const payload = extractWhatsAppInteractivePayload({
      whatsapp_template_payload: templatePayload,
    });

    expect(payload.body.text).toContain('9541385-01.2026.4.01.3315');
  });

  it('uses the template alias when the canonical payload key was transformed away', () => {
    const payload = extractWhatsAppInteractivePayload({
      template: templatePayload,
    });

    expect(payload.body.text).toContain('novas movimentacoes');
  });
});
