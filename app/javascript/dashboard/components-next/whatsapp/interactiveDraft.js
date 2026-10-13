import { isValidHttpUrl } from './urlValidation';

const SUPPORTED_TYPES = ['button', 'list', 'carousel', 'cta_url'];

export const getImplementedInteractiveCapabilities = (capabilities = {}) =>
  Object.fromEntries(
    SUPPORTED_TYPES.filter(type => capabilities[type]?.implemented).map(
      type => [type, capabilities[type]]
    )
  );

export const getInteractiveDraftLimits = (type, capability) => {
  const limits = capability?.limits ?? {};

  if (type === 'list') {
    return {
      bodyMaxLength: limits.body_max_length ?? 4096,
      headerMaxLength: limits.header_max_length ?? 60,
      footerMaxLength: limits.footer_max_length ?? 60,
      buttonMaxLength: limits.button_max_length ?? 20,
      sectionMinCount: limits.section_min_count ?? 1,
      sectionMaxCount: limits.section_max_count ?? 10,
      rowMinCount: limits.row_min_count ?? 1,
      rowMaxCount: limits.row_max_count ?? 10,
      sectionTitleMaxLength: limits.section_title_max_length ?? 24,
      rowTitleMaxLength: limits.row_title_max_length ?? 24,
      rowDescriptionMaxLength: limits.row_description_max_length ?? 72,
    };
  }

  if (type === 'cta_url') {
    return {
      bodyMaxLength: limits.body_max_length ?? 1024,
      headerMaxLength: limits.header_max_length ?? 60,
      footerMaxLength: limits.footer_max_length ?? 60,
      headerTypes: limits.header_types ?? [
        'text',
        'image',
        'video',
        'document',
      ],
      buttonMaxLength: limits.button_max_length ?? 20,
      urlSchemes: limits.url_schemes ?? ['http', 'https'],
    };
  }

  if (type === 'carousel') {
    return {
      bodyMaxLength: limits.body_max_length ?? 1024,
      cardMinCount: limits.card_min_count ?? 2,
      cardMaxCount: limits.card_max_count ?? 10,
      cardBodyMaxLength: limits.card_body_max_length ?? 160,
      cardBodyMaxLineBreaks: limits.card_body_max_line_breaks ?? 2,
      media: limits.media ?? ['image'],
      actionModes: limits.action_modes ?? ['quick_reply', 'url'],
      buttonMaxLength: limits.button_max_length ?? 20,
      urlSchemes: limits.url_schemes ?? ['http', 'https'],
    };
  }

  return {
    bodyMaxLength: limits.body_max_length ?? 1024,
    headerMaxLength: limits.header_max_length ?? 60,
    footerMaxLength: limits.footer_max_length ?? 60,
    headerTypes: limits.header_types ?? ['text', 'image', 'video', 'document'],
    buttonTitleMaxLength: limits.button_title_max_length ?? 20,
    buttonMinCount: limits.button_min_count ?? 1,
    buttonMaxCount: limits.button_max_count ?? 3,
  };
};

const isListDraftValid = (draft, limits) => {
  const { body, header, footer, button, sections } = draft;
  const totalRows = sections.reduce(
    (count, section) => count + section.rows.length,
    0
  );

  return (
    body.trim().length >= 1 &&
    body.trim().length <= limits.bodyMaxLength &&
    header.trim().length <= limits.headerMaxLength &&
    footer.trim().length <= limits.footerMaxLength &&
    button.trim().length >= 1 &&
    button.trim().length <= limits.buttonMaxLength &&
    sections.length >= limits.sectionMinCount &&
    sections.length <= limits.sectionMaxCount &&
    totalRows >= limits.rowMinCount &&
    totalRows <= limits.rowMaxCount &&
    sections.every(
      section =>
        section.title.trim().length <= limits.sectionTitleMaxLength &&
        section.rows.length >= 1 &&
        section.rows.every(
          row =>
            row.title.trim().length >= 1 &&
            row.title.trim().length <= limits.rowTitleMaxLength &&
            row.description.trim().length <= limits.rowDescriptionMaxLength
        )
    )
  );
};

const hasValidHeader = (draft, limits) =>
  (!draft.headerType || limits.headerTypes.includes(draft.headerType)) &&
  (draft.headerType !== 'text' ||
    (draft.headerText?.trim().length >= 1 &&
      draft.headerText.trim().length <= limits.headerMaxLength)) &&
  (!draft.headerType || draft.headerType === 'text' || !!draft.media);

const isCtaUrlDraftValid = (draft, limits) =>
  draft.body.trim().length >= 1 &&
  draft.body.trim().length <= limits.bodyMaxLength &&
  hasValidHeader(draft, limits) &&
  draft.footer.trim().length <= limits.footerMaxLength &&
  draft.button.trim().length >= 1 &&
  draft.button.trim().length <= limits.buttonMaxLength &&
  isValidHttpUrl(draft.url.trim(), limits.urlSchemes);

const isCarouselDraftValid = (draft, limits) => {
  const { body, actionMode, cards } = draft;
  const validCardBodies = cards.every(card => {
    const cardBody = card.body?.trim() ?? '';
    const lineBreaks = cardBody.match(/\r\n|\r|\n/g)?.length ?? 0;
    return (
      cardBody.length <= limits.cardBodyMaxLength &&
      lineBreaks <= limits.cardBodyMaxLineBreaks
    );
  });
  const validMedia = cards.every(
    card => card.media && card.media.type?.startsWith('image/')
  );
  const validActions = cards.every(card => {
    if (actionMode === 'url') {
      const label = card.action.button?.trim() ?? '';
      return (
        label.length >= 1 &&
        label.length <= limits.buttonMaxLength &&
        isValidHttpUrl(card.action.url?.trim(), limits.urlSchemes)
      );
    }
    const buttons = card.action.buttons ?? [];
    const titles = buttons.map(button => button.title?.trim() ?? '');
    return (
      buttons.length >= 1 &&
      titles.every(
        title => title.length >= 1 && title.length <= limits.buttonMaxLength
      ) &&
      new Set(titles).size === titles.length
    );
  });
  const replyCounts = cards.map(card => card.action.buttons?.length ?? 0);

  return (
    body.trim().length >= 1 &&
    body.trim().length <= limits.bodyMaxLength &&
    limits.actionModes.includes(actionMode) &&
    cards.length >= limits.cardMinCount &&
    cards.length <= limits.cardMaxCount &&
    validCardBodies &&
    validMedia &&
    validActions &&
    (actionMode !== 'quick_reply' ||
      (replyCounts[0] > 0 &&
        replyCounts.every(count => count === replyCounts[0])))
  );
};

const isButtonDraftValid = (draft, limits) => {
  const { body, footer, buttons } = draft;
  const titles = buttons.map(button =>
    (typeof button === 'string' ? button : button.title).trim()
  );

  return (
    body.trim().length >= 1 &&
    body.trim().length <= limits.bodyMaxLength &&
    hasValidHeader(draft, limits) &&
    (!footer ||
      (footer.trim().length >= 1 &&
        footer.trim().length <= limits.footerMaxLength)) &&
    buttons.length >= limits.buttonMinCount &&
    buttons.length <= limits.buttonMaxCount &&
    titles.every(
      title => title.length >= 1 && title.length <= limits.buttonTitleMaxLength
    ) &&
    new Set(titles).size === titles.length
  );
};

export const isInteractiveDraftValid = (type, draft, limits) => {
  if (type === 'list') return isListDraftValid(draft, limits);
  if (type === 'cta_url') return isCtaUrlDraftValid(draft, limits);
  if (type === 'carousel') return isCarouselDraftValid(draft, limits);
  return isButtonDraftValid(draft, limits);
};
