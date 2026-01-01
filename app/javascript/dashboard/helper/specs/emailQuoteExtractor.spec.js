import { describe, it, expect } from 'vitest';
import { EmailQuoteExtractor } from '../emailQuoteExtractor.js';

const SAMPLE_EMAIL_HTML = `
<p>method</p>
<blockquote>
<p>On Mon, Sep 29, 2025 at 5:18 PM John <a href="mailto:shivam@chatwoot.com">shivam@chatwoot.com</a> wrote:</p>
<p>Hi</p>
<blockquote>
<p>On Mon, Sep 29, 2025 at 5:17 PM Shivam Mishra <a href="mailto:shivam@chatwoot.com">shivam@chatwoot.com</a> wrote:</p>
<p>Yes, it is.</p>
<p>On Mon, Sep 29, 2025 at 5:16 PM John from Shaneforwoot &lt; shaneforwoot@gmail.com&gt; wrote:</p>
<blockquote>
<p>Hey</p>
<p>On Mon, Sep 29, 2025 at 4:59 PM John shivam@chatwoot.com wrote:</p>
<p>This is another quoted quoted text reply</p>
<p>This is nice</p>
<p>On Mon, Sep 29, 2025 at 4:21 PM John from Shaneforwoot &lt; &gt; shaneforwoot@gmail.com&gt; wrote:</p>
<p>Hey there, this is a reply from Chatwoot, notice the quoted text</p>
<p>Hey there</p>
<p>This is an email text, enjoy reading this</p>
<p>-- Shivam Mishra, Chatwoot</p>
</blockquote>
</blockquote>
</blockquote>
`;

const EMAIL_WITH_SIGNATURE = `
<p>Latest reply here.</p>
<p>Thanks,</p>
<p>Jane Doe</p>
<blockquote>
  <p>On Mon, Sep 22, Someone wrote:</p>
  <p>Previous reply content</p>
</blockquote>
`;

const EMAIL_WITH_FOLLOW_UP_CONTENT = `
<blockquote>
  <p>Inline quote that should stay</p>
</blockquote>
<p>Internal note follows</p>
<p>Regards,</p>
`;

describe('EmailQuoteExtractor', () => {
  it('removes blockquote-based quotes from the email body', () => {
    const cleanedHtml = EmailQuoteExtractor.extractQuotes(SAMPLE_EMAIL_HTML);

    const container = document.createElement('div');
    container.innerHTML = cleanedHtml;

    expect(container.querySelectorAll('blockquote').length).toBe(0);
    expect(container.textContent?.trim()).toBe('method');
    expect(container.textContent).not.toContain(
      'On Mon, Sep 29, 2025 at 5:18 PM'
    );
  });

  it('keeps blockquote fallback when it is not the last top-level element', () => {
    const cleanedHtml = EmailQuoteExtractor.extractQuotes(
      EMAIL_WITH_FOLLOW_UP_CONTENT
    );

    const container = document.createElement('div');
    container.innerHTML = cleanedHtml;

    expect(container.querySelector('blockquote')).not.toBeNull();
    expect(container.lastElementChild?.tagName).toBe('P');
  });

  it('detects quote indicators in nested blockquotes', () => {
    const result = EmailQuoteExtractor.hasQuotes(SAMPLE_EMAIL_HTML);
    expect(result).toBe(true);
  });

  it('does not flag blockquotes that are followed by other elements', () => {
    expect(EmailQuoteExtractor.hasQuotes(EMAIL_WITH_FOLLOW_UP_CONTENT)).toBe(
      false
    );
  });

  it('returns false when no quote indicators are present', () => {
    const html = '<p>Plain content</p>';
    expect(EmailQuoteExtractor.hasQuotes(html)).toBe(false);
  });

  it('removes trailing blockquotes while preserving trailing signatures', () => {
    const cleanedHtml = EmailQuoteExtractor.extractQuotes(EMAIL_WITH_SIGNATURE);

    expect(cleanedHtml).toContain('<p>Thanks,</p>');
    expect(cleanedHtml).toContain('<p>Jane Doe</p>');
    expect(cleanedHtml).not.toContain('<blockquote');
  });

  it('detects quotes for trailing blockquotes even when signatures follow text', () => {
    expect(EmailQuoteExtractor.hasQuotes(EMAIL_WITH_SIGNATURE)).toBe(true);
  });
});
