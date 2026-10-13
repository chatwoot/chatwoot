let clientKeySequence = 0;

const nextClientKey = prefix => {
  clientKeySequence += 1;
  return `${prefix}-${clientKeySequence}`;
};

const compact = object =>
  Object.fromEntries(
    Object.entries(object).filter(([, value]) => value !== undefined)
  );

const optionFromDefinition = (option, prefix) => ({
  clientKey: nextClientKey(prefix),
  title: option.title ?? '',
  ...(option.description !== undefined && {
    description: option.description,
  }),
  ...(option.preset_option_id && {
    preset_option_id: option.preset_option_id,
  }),
});

const mediaFromAttachment = attachment =>
  attachment
    ? {
        name: attachment.filename,
        type: attachment.content_type,
        dataUrl: attachment.data_url,
        file: attachment.signed_id,
      }
    : null;

const orderedAttachments = preset =>
  [...(preset.attachments ?? [])].sort((a, b) => a.position - b.position);

export const hydrateInteractivePreset = preset => {
  const definition = preset.definition;
  const type = definition.type;
  const attachments = orderedAttachments(preset);
  const common = {
    body: definition.body?.text ?? '',
    source: { preset_id: preset.id },
  };
  let draft;

  if (type === 'list') {
    draft = {
      ...common,
      header: definition.header?.text ?? '',
      footer: definition.footer?.text ?? '',
      button: definition.action?.button ?? '',
      sections: (definition.action?.sections ?? []).map(section => ({
        clientKey: nextClientKey('list-section'),
        title: section.title ?? '',
        rows: (section.rows ?? []).map(row => ({
          ...optionFromDefinition(row, 'list-row'),
          description: row.description ?? '',
        })),
      })),
    };
  } else if (type === 'carousel') {
    const cards = definition.action?.cards ?? [];
    const actionMode = cards[0]?.type === 'button' ? 'quick_reply' : 'url';
    draft = {
      ...common,
      actionMode,
      cards: cards.map((card, index) => ({
        clientKey: nextClientKey('carousel-card'),
        body: card.body?.text ?? '',
        media: mediaFromAttachment(attachments[index]),
        action:
          actionMode === 'url'
            ? {
                button: card.action?.button ?? '',
                url: card.action?.url ?? '',
              }
            : {
                buttons: (card.action?.buttons ?? []).map(button =>
                  optionFromDefinition(button, 'carousel-reply')
                ),
              },
      })),
    };
  } else if (type === 'cta_url') {
    draft = {
      ...common,
      headerType: definition.header?.type ?? '',
      headerText: definition.header?.text ?? '',
      footer: definition.footer?.text ?? '',
      button: definition.action?.button ?? '',
      url: definition.action?.url ?? '',
      media: mediaFromAttachment(attachments[0]),
    };
  } else {
    draft = {
      ...common,
      headerType: definition.header?.type ?? '',
      headerText: definition.header?.text ?? '',
      footer: definition.footer?.text ?? '',
      media: mediaFromAttachment(attachments[0]),
      buttons: (definition.action?.buttons ?? []).map(button =>
        optionFromDefinition(button, 'reply-button')
      ),
    };
  }

  return { type, draft };
};

const optionTitle = option =>
  typeof option === 'string' ? option.trim() : option.title.trim();

const serializeOption = (option, preserveIdentity) =>
  compact({
    title: optionTitle(option),
    preset_option_id:
      preserveIdentity && typeof option !== 'string'
        ? option.preset_option_id
        : undefined,
  });

export const serializeInteractiveDraft = (type, draft, mode = 'send') => {
  const preserveIdentity = mode !== 'create';
  const body = draft.body.trim();
  let definition;
  let attachments;

  if (type === 'list') {
    definition = compact({
      schema_version: 1,
      type,
      body: { text: body },
      header: draft.header.trim()
        ? { type: 'text', text: draft.header.trim() }
        : undefined,
      footer: draft.footer.trim() ? { text: draft.footer.trim() } : undefined,
      action: {
        button: draft.button.trim(),
        sections: draft.sections.map(section =>
          compact({
            title: section.title.trim() || undefined,
            rows: section.rows.map(row =>
              compact({
                ...serializeOption(row, preserveIdentity),
                description: row.description?.trim() || undefined,
              })
            ),
          })
        ),
      },
    });
  } else if (type === 'carousel') {
    definition = {
      schema_version: 1,
      type,
      body: { text: body },
      action: {
        cards: draft.cards.map((card, cardIndex) =>
          compact({
            card_index: cardIndex,
            type: draft.actionMode === 'url' ? 'cta_url' : 'button',
            header: { type: 'image' },
            body: card.body.trim() ? { text: card.body.trim() } : undefined,
            action:
              draft.actionMode === 'url'
                ? {
                    button: card.action.button.trim(),
                    url: card.action.url.trim(),
                  }
                : {
                    buttons: card.action.buttons.map(option =>
                      serializeOption(option, preserveIdentity)
                    ),
                  },
          })
        ),
      },
    };
    attachments = draft.cards.map(card => card.media.file);
  } else {
    const headerType = draft.headerType;
    definition = compact({
      schema_version: 1,
      type,
      body: { text: body },
      header: headerType
        ? compact({
            type: headerType,
            text: headerType === 'text' ? draft.headerText.trim() : undefined,
          })
        : undefined,
      footer: draft.footer?.trim() ? { text: draft.footer.trim() } : undefined,
      action:
        type === 'cta_url'
          ? { button: draft.button.trim(), url: draft.url.trim() }
          : {
              buttons: draft.buttons.map(option =>
                serializeOption(option, preserveIdentity)
              ),
            },
    });
    attachments = draft.media ? [draft.media.file] : undefined;
  }

  if (mode === 'send' && draft.source?.preset_id) {
    definition.source = { preset_id: draft.source.preset_id };
  }

  return compact({ definition, attachments });
};

export const detachPresetProvenance = draft => {
  const strip = value => {
    if (Array.isArray(value)) return value.map(strip);
    if (!value || typeof value !== 'object') return value;
    return Object.fromEntries(
      Object.entries(value)
        .filter(([key]) => !['source', 'preset_option_id'].includes(key))
        .map(([key, child]) => [key, strip(child)])
    );
  };
  return strip(draft);
};
