import {
  detachPresetProvenance,
  hydrateInteractivePreset,
  serializeInteractiveDraft,
} from '../interactivePreset';

const record = (definition, attachments = []) => ({
  id: 42,
  name: 'Reusable',
  definition,
  attachments,
});

const image = (position, signedId = `signed-${position}`) => ({
  position,
  signed_id: signedId,
  filename: `${position}.png`,
  content_type: 'image/png',
  data_url: `https://example.test/${position}.png`,
});

describe('interactivePreset adapter', () => {
  it('hydrates and serializes reply buttons with durable media and trusted hints', () => {
    const preset = record(
      {
        schema_version: 1,
        type: 'button',
        header: { type: 'image' },
        body: { text: 'Choose' },
        footer: { text: 'Optional' },
        action: {
          buttons: [
            { title: 'One', preset_option_id: 'option-1' },
            { title: 'Two', preset_option_id: 'option-2' },
          ],
        },
      },
      [image(0)]
    );

    const { type, draft } = hydrateInteractivePreset(preset);
    draft.body = 'Edited surroundings';
    draft.buttons.reverse();
    const sent = serializeInteractiveDraft(type, draft);

    expect(draft.media).toMatchObject({
      file: 'signed-0',
      dataUrl: 'https://example.test/0.png',
    });
    expect(sent.attachments).toEqual(['signed-0']);
    expect(sent.definition).toMatchObject({
      source: { preset_id: 42 },
      action: {
        buttons: [
          { title: 'Two', preset_option_id: 'option-2' },
          { title: 'One', preset_option_id: 'option-1' },
        ],
      },
    });
    expect(JSON.stringify(sent)).not.toContain('clientKey');
  });

  it('maps list rows and preserves same-parent identity hints', () => {
    const { draft } = hydrateInteractivePreset(
      record({
        schema_version: 1,
        type: 'list',
        body: { text: 'Choose' },
        action: {
          button: 'Open',
          sections: [
            {
              title: 'First',
              rows: [
                {
                  title: 'Alpha',
                  description: 'A',
                  preset_option_id: 'row-1',
                },
              ],
            },
          ],
        },
      })
    );
    const serialized = serializeInteractiveDraft('list', draft, 'update');

    expect(serialized.definition.action.sections[0].rows[0]).toEqual({
      title: 'Alpha',
      preset_option_id: 'row-1',
      description: 'A',
    });
  });

  it('normalizes an omitted optional list-row description', () => {
    const { draft } = hydrateInteractivePreset(
      record({
        schema_version: 1,
        type: 'list',
        body: { text: 'Choose' },
        action: {
          button: 'Open',
          sections: [{ rows: [{ title: 'Alpha' }] }],
        },
      })
    );

    expect(draft.sections[0].rows[0].description).toBe('');
    expect(
      serializeInteractiveDraft('list', draft).definition.action.sections[0]
        .rows[0]
    ).toEqual({ title: 'Alpha' });
  });

  it('hydrates carousel media in position order and supports both action modes', () => {
    const { draft } = hydrateInteractivePreset(
      record(
        {
          schema_version: 1,
          type: 'carousel',
          body: { text: 'Choose' },
          action: {
            cards: [0, 1].map(index => ({
              card_index: index,
              type: 'button',
              header: { type: 'image' },
              action: {
                buttons: [
                  {
                    title: `Reply ${index}`,
                    preset_option_id: `reply-${index}`,
                  },
                ],
              },
            })),
          },
        },
        [image(1, 'second'), image(0, 'first')]
      )
    );

    expect(draft.actionMode).toBe('quick_reply');
    expect(draft.cards.map(card => card.media.file)).toEqual([
      'first',
      'second',
    ]);
    expect(
      serializeInteractiveDraft('carousel', draft).definition.action.cards[1]
        .action.buttons[0]
    ).toEqual({ title: 'Reply 1', preset_option_id: 'reply-1' });
  });

  it('hydrates CTA fields and strips identities and source for a new copy', () => {
    const { draft } = hydrateInteractivePreset(
      record({
        schema_version: 1,
        type: 'cta_url',
        body: { text: 'Visit' },
        action: { button: 'Open', url: 'https://example.test' },
      })
    );
    const withIdentity = {
      ...draft,
      hidden: { preset_option_id: 'must-not-leak' },
    };
    const created = serializeInteractiveDraft(
      'cta_url',
      withIdentity,
      'create'
    );

    expect(created.definition).toEqual({
      schema_version: 1,
      type: 'cta_url',
      body: { text: 'Visit' },
      action: { button: 'Open', url: 'https://example.test' },
    });
    expect(detachPresetProvenance(withIdentity)).not.toHaveProperty('source');
    expect(JSON.stringify(detachPresetProvenance(withIdentity))).not.toContain(
      'preset_option_id'
    );
  });

  it('removes option identities when saving a reply-capable copy as new', () => {
    const draft = {
      body: 'Choose',
      source: { preset_id: 42 },
      buttons: [
        { clientKey: 'client-only', title: 'One', preset_option_id: 'old-id' },
      ],
    };

    expect(
      serializeInteractiveDraft('button', draft, 'create').definition
    ).toEqual({
      schema_version: 1,
      type: 'button',
      body: { text: 'Choose' },
      action: { buttons: [{ title: 'One' }] },
    });
  });
});
