import messages from 'survey/i18n';
import { forkMessages } from 'survey/i18n/fazer-ai';
import upstreamEn from 'survey/i18n/locale/en.json';
import upstreamPtBr from 'survey/i18n/locale/pt_BR.json';

describe('fazer.ai survey translation overlay', () => {
  it('exposes a fork tree for every language we translate', () => {
    expect(Object.keys(forkMessages).sort()).toEqual(['en', 'es', 'pt_BR']);
  });

  it('adds the fork keys without touching upstream files', () => {
    expect(upstreamEn.SURVEY.RATING.CONFIRM_BUTTON).toBeUndefined();
    expect(messages.en.SURVEY.RATING.CONFIRM_BUTTON).toBe('Confirm rating');
  });

  it('keeps the upstream keys in the namespace it extends', () => {
    Object.keys(upstreamPtBr.SURVEY.RATING).forEach(key => {
      expect(messages.pt_BR.SURVEY.RATING[key]).toBe(
        upstreamPtBr.SURVEY.RATING[key]
      );
    });
  });

  it('translates rather than copying the en tree', () => {
    expect(messages.pt_BR.SURVEY.RATING.CONFIRM_BUTTON).toBe('Confirmar nota');
    expect(messages.es.SURVEY.RATING.CONFIRM_BUTTON).not.toBe(
      messages.en.SURVEY.RATING.CONFIRM_BUTTON
    );
  });

  it('leaves a language without a fork file untouched', () => {
    expect(messages.fr.SURVEY.RATING.CONFIRM_BUTTON).toBeUndefined();
    expect(messages.fr.SURVEY.RATING.LABEL).toBeDefined();
  });
});
