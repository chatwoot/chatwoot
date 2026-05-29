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

// Regression coverage for the quote-toggle rewrite shipped on this branch.
// Parse cleaned HTML into a container so each test can assert against
// .textContent or query nested nodes.
const cleaned = html => {
  const c = document.createElement('div');
  c.innerHTML = EmailQuoteExtractor.extractQuotes(html);
  return c;
};

describe('EmailQuoteExtractor', () => {
  it('removes blockquote-based quotes from the email body', () => {
    const c = cleaned(SAMPLE_EMAIL_HTML);
    expect(c.querySelectorAll('blockquote').length).toBe(0);
    expect(c.textContent?.trim()).toBe('method');
    expect(c.textContent).not.toContain('On Mon, Sep 29, 2025 at 5:18 PM');
  });

  it('keeps blockquote fallback when it is not the last top-level element', () => {
    const c = cleaned(EMAIL_WITH_FOLLOW_UP_CONTENT);
    expect(c.querySelector('blockquote')).not.toBeNull();
    expect(c.lastElementChild?.tagName).toBe('P');
  });

  it('detects quote indicators in nested blockquotes', () => {
    expect(EmailQuoteExtractor.hasQuotes(SAMPLE_EMAIL_HTML)).toBe(true);
  });

  it('does not flag blockquotes that are followed by other elements', () => {
    expect(EmailQuoteExtractor.hasQuotes(EMAIL_WITH_FOLLOW_UP_CONTENT)).toBe(
      false
    );
  });

  it('returns false when no quote indicators are present', () => {
    expect(EmailQuoteExtractor.hasQuotes('<p>Plain content</p>')).toBe(false);
  });

  it('removes trailing blockquotes while preserving trailing signatures', () => {
    const c = cleaned(EMAIL_WITH_SIGNATURE);
    expect(c.querySelector('blockquote')).toBeNull();
    expect(c.textContent).toContain('Thanks,');
    expect(c.textContent).toContain('Jane Doe');
  });

  it('detects quotes for trailing blockquotes even when signatures follow text', () => {
    expect(EmailQuoteExtractor.hasQuotes(EMAIL_WITH_SIGNATURE)).toBe(true);
  });

  describe('HTML sanitization', () => {
    it('removes onerror handlers from img tags in extractQuotes', () => {
      const maliciousHtml = '<p>Hello</p><img src="x" onerror="alert(1)">';
      const cleanedHtml = EmailQuoteExtractor.extractQuotes(maliciousHtml);

      expect(cleanedHtml).not.toContain('onerror');
      expect(cleanedHtml).toContain('<p>Hello</p>');
    });

    it('removes onerror handlers from img tags in hasQuotes', () => {
      const maliciousHtml = '<p>Hello</p><img src="x" onerror="alert(1)">';
      // Should not throw and should safely check for quotes
      const result = EmailQuoteExtractor.hasQuotes(maliciousHtml);
      expect(result).toBe(false);
    });

    it('removes script tags in extractQuotes', () => {
      const maliciousHtml =
        '<p>Content</p><script>alert("xss")</script><p>More</p>';
      const cleanedHtml = EmailQuoteExtractor.extractQuotes(maliciousHtml);

      expect(cleanedHtml).not.toContain('<script');
      expect(cleanedHtml).not.toContain('alert');
      expect(cleanedHtml).toContain('<p>Content</p>');
      expect(cleanedHtml).toContain('<p>More</p>');
    });

    it('removes onclick handlers in extractQuotes', () => {
      const maliciousHtml = '<p onclick="alert(1)">Click me</p>';
      const cleanedHtml = EmailQuoteExtractor.extractQuotes(maliciousHtml);

      expect(cleanedHtml).not.toContain('onclick');
      expect(cleanedHtml).toContain('Click me');
    });

    it('removes javascript: URLs in extractQuotes', () => {
      const maliciousHtml = '<a href="javascript:alert(1)">Link</a>';
      const cleanedHtml = EmailQuoteExtractor.extractQuotes(maliciousHtml);

      // eslint-disable-next-line no-script-url
      expect(cleanedHtml).not.toContain('javascript:');
      expect(cleanedHtml).toContain('Link');
    });

    it('removes encoded payloads with event handlers in extractQuotes', () => {
      const maliciousHtml =
        '<img src="x" id="PHNjcmlwdD5hbGVydCgxKTwvc2NyaXB0Pg==" onerror="eval(atob(this.id))">';
      const cleanedHtml = EmailQuoteExtractor.extractQuotes(maliciousHtml);

      expect(cleanedHtml).not.toContain('onerror');
      expect(cleanedHtml).not.toContain('eval');
    });
  });

  describe('client wrappers', () => {
    it('Gmail — strips .gmail_quote_container with attribution + blockquote', () => {
      const html = `<div dir="ltr"><p>Dear Sam,</p><p>Thank you for the quotation.</p><p>Best,<br>Alex</p></div><br><div class="gmail_quote gmail_quote_container"><div class="gmail_attr">On Wed, 4 Dec 2024 at 17:15, Sam wrote:<br></div><blockquote class="gmail_quote"><p>Dear Alex,</p><p>Thank you for your inquiry.</p></blockquote></div>`;
      const c = cleaned(html);
      expect(c.textContent).toContain('Dear Sam');
      expect(c.textContent).not.toContain('Thank you for your inquiry');
      expect(c.querySelector('.gmail_quote')).toBeNull();
      expect(EmailQuoteExtractor.hasQuotes(html)).toBe(true);
    });

    it('Outlook — strips #divRplyFwdMsg header AND the trailing bare blockquote', () => {
      const html = `<p>Hi team,</p><p>Regards,<br>Pat</p><div id="divRplyFwdMsg"><b>From:</b> Sam<br><b>Sent:</b> Wed Dec 4, 2024<br><b>To:</b> Pat<br><b>Subject:</b> Quotation</div><blockquote><p>Hi Pat,</p><p>Quotation attached.</p></blockquote>`;
      const c = cleaned(html);
      expect(c.textContent).toContain('Hi team');
      expect(c.textContent).not.toContain('From: Sam');
      expect(c.textContent).not.toContain('Quotation attached');
      expect(c.querySelector('blockquote')).toBeNull();
      expect(c.querySelector('#divRplyFwdMsg')).toBeNull();
    });

    it('Yahoo — strips .yahoo_quoted wrapper', () => {
      const html = `<div>My reply text here.</div><div class="yahoo_quoted"><div>On Wed, Dec 4, 2024, Sam wrote:</div><div>Original Yahoo-quoted message body.</div></div>`;
      const c = cleaned(html);
      expect(c.textContent).toContain('My reply text here');
      expect(c.textContent).not.toContain('Original Yahoo-quoted message');
      expect(c.querySelector('.yahoo_quoted')).toBeNull();
    });

    it('Thunderbird — strips .moz-cite-prefix attribution AND <blockquote type="cite">', () => {
      const html = `<p>My reply.</p><p class="moz-cite-prefix">On 4/12/24 17:15, Sam wrote:</p><blockquote type="cite"><p>Original Thunderbird-quoted message body.</p></blockquote>`;
      const c = cleaned(html);
      expect(c.textContent).toContain('My reply');
      expect(c.textContent).not.toContain('On 4/12/24 17:15');
      expect(c.textContent).not.toContain(
        'Original Thunderbird-quoted message'
      );
      expect(c.querySelector('blockquote')).toBeNull();
      expect(c.querySelector('.moz-cite-prefix')).toBeNull();
    });
  });

  describe('hard markers', () => {
    it('Gmail "---------- Forwarded message ----------" block is stripped', () => {
      const html = `<div>FYI — see the original below.<div class="gmail_quote"><div>---------- Forwarded message ---------<br>From: Sam<br>Date: Wed, 4 Dec 2024<br>Subject: Quotation<br>To: Pat</div><div>Original forwarded body content.</div></div></div>`;
      const c = cleaned(html);
      expect(c.textContent).toContain('FYI — see the original below');
      expect(c.textContent).not.toContain('Forwarded message');
      expect(c.textContent).not.toContain('Original forwarded body content');
    });

    it('Outlook plain-style "-----Original Message-----" header is stripped', () => {
      const html = `<p>Quick reply.</p><p>-----Original Message-----<br>From: Sam<br>Sent: Wed Dec 4, 2024<br>To: Pat<br>Subject: Quotation</p><p>Original Outlook plain-style reply.</p>`;
      const c = cleaned(html);
      expect(c.textContent).toContain('Quick reply');
      expect(c.textContent).not.toContain('Original Message');
      expect(c.textContent).not.toContain('Original Outlook plain-style reply');
    });

    it('preserves reply text that sits before a hard marker in the SAME block', () => {
      const html =
        '<div>My reply<br><br>-----Original Message-----<br>From: Sam<br>Old body</div>';
      const c = cleaned(html);
      expect(c.textContent).toContain('My reply');
      expect(c.textContent).not.toContain('Original Message');
      expect(c.textContent).not.toContain('Old body');
    });

    it('does not strip when "Original Message" appears inside a sentence', () => {
      const html =
        '<p>The bug ticket says the markdown for `-----Original Message-----` should render.</p><p>Here is my fix.</p>';
      expect(cleaned(html).textContent).toContain('Here is my fix');
    });

    it('does not strip when "Original Message" sits inside <code> mid-paragraph', () => {
      const html =
        '<p>Hey Sam,</p><p>The markdown for <code>-----Original Message-----</code> should render.</p><p>Tested locally.</p><p>Pat</p>';
      const c = cleaned(html);
      expect(c.textContent).toContain('Hey Sam');
      expect(c.textContent).toContain('Tested locally');
      expect(c.textContent).toContain('Pat');
      expect(EmailQuoteExtractor.hasQuotes(html)).toBe(false);
    });

    it('cuts wrapper-level siblings when the marker is in a nested child', () => {
      // Outlook nested shape: marker sits in an inner block, but the actual
      // forwarded body lives in later siblings of the outer wrapper. Strategy
      // 2 selects the outer match so the wrapper's later siblings strip too.
      const html =
        '<div>' +
        '<p>My reply.</p>' +
        '<div class="OutlookHeader"><p>-----Original Message-----</p></div>' +
        '<p>From: Sam</p>' +
        '<p>Old body</p>' +
        '</div>';
      const c = cleaned(html);
      expect(c.textContent).toContain('My reply');
      expect(c.textContent).not.toContain('Original Message');
      expect(c.textContent).not.toContain('From: Sam');
      expect(c.textContent).not.toContain('Old body');
    });

    it('treats hard markers as absolute boundaries — sibling tail is always quoted body', () => {
      // Hard markers (`-----Original Message-----` etc.) are explicit,
      // anchored boundaries: by convention everything after is the original.
      // Strategy 4 (soft headers) preserves following siblings because
      // `From:` can appear in prose; strategy 2 deliberately does not. Locks
      // down the asymmetry against future "preserve bottom-post" rewrites.
      const html =
        '<p>-----Original Message-----</p>' +
        '<p>From: Sam</p>' +
        '<p>Old quoted body</p>' +
        '<p>Reply pretending to be bottom-posted</p>';
      const c = cleaned(html);
      expect(c.textContent).not.toContain('Original Message');
      expect(c.textContent).not.toContain('From: Sam');
      expect(c.textContent).not.toContain('Old quoted body');
      expect(c.textContent).not.toContain(
        'Reply pretending to be bottom-posted'
      );
    });
  });

  describe('multi-line attribution headers (From / Sent / To)', () => {
    it('detects header inside a single outer wrapper <div>', () => {
      const html =
        '<div><p>My reply.</p><p>-----Original Message-----<br>From: Sam<br>Sent: ...</p><p>Old body</p></div>';
      const c = cleaned(html);
      expect(c.textContent).toContain('My reply');
      expect(c.textContent).not.toContain('Original Message');
      expect(EmailQuoteExtractor.hasQuotes(html)).toBe(true);
    });

    it('detects "From:/Sent:" header even when followed by un-prefixed old lines', () => {
      const html =
        '<p>Reply text.</p><p>From: Sam<br>Sent: Wed Dec 4, 2024</p><p>Old line 1</p>';
      const c = cleaned(html);
      expect(c.textContent).toContain('Reply text');
      expect(c.textContent).not.toContain('From: Sam');
      expect(EmailQuoteExtractor.hasQuotes(html)).toBe(true);
    });

    it('detects minimal "From: name + Sent: weekday" header (no @, no year)', () => {
      const html =
        '<p>Reply text.</p><p>From: Sam<br>Sent: Wednesday<br>To: Pat<br>Subject: Re: foo</p><p>Old body</p>';
      const c = cleaned(html);
      expect(c.textContent).toContain('Reply text');
      expect(c.textContent).not.toContain('From: Sam');
      expect(EmailQuoteExtractor.hasQuotes(html)).toBe(true);
    });

    it('detects header buried in a deep wrapper (Outlook WordSection1)', () => {
      const html = `
        <div class="WordSection1">
          <p>Pat — please look into this.</p>
          <p>Thanks,<br>Sam</p>
          <div style="border-top:solid #E1E1E1 1.0pt">
            <p><b>From:</b> Maya<br><b>Sent:</b> Wed, 4 Dec<br><b>To:</b> Sam<br><b>Subject:</b> Customer escalation</p>
          </div>
          <p>Sam, Acme Corp is threatening to churn.</p>
        </div>
      `;
      const c = cleaned(html);
      expect(c.textContent).toContain('Pat — please look into this');
      expect(c.textContent).not.toContain('From: Maya');
      expect(c.textContent).not.toContain('Subject: Customer escalation');
    });

    it('strips a flat header at root but keeps the body visible (bottom-post safety)', () => {
      const html =
        '<p>Confirming I received this — will review tomorrow.</p>' +
        '<p>Thanks,<br>Pat</p>' +
        '<p>From: Sam<br>Sent: Wed Dec 4, 2024<br>To: Pat<br>Subject: Quotation</p>' +
        '<p>Hi Pat,<br>Quotation attached.<br>Sam</p>';
      const c = cleaned(html);
      expect(c.textContent).toContain('Confirming I received this');
      expect(c.textContent).toContain('Thanks,');
      expect(c.textContent).not.toContain('From: Sam');
    });

    it('preserves a bottom-posted reply that follows a flat header block at root', () => {
      const html =
        '<p>From: Sam<br>Sent: Wed Dec 4, 2024<br>To: Pat<br>Subject: foo</p>' +
        '<p>Hi Pat, original message body.</p>' +
        '<p>--- My reply below ---</p>' +
        '<p>Got it, thanks!</p>';
      const c = cleaned(html);
      expect(c.textContent).toContain('Got it, thanks');
      expect(c.textContent).toContain('My reply below');
      expect(c.textContent).not.toContain('From: Sam');
    });

    it('strips Apple-Mail blockquote (attribution + body inside one <blockquote type="cite">)', () => {
      const html =
        '<div>Sounds good, see you Friday.</div>' +
        '<div><blockquote type="cite">' +
        '<div>On Apr 6, 2026, at 11:26 AM, Sam wrote:</div>' +
        '<div><div>Hi Pat,</div><div>Locking the Friday slot.</div></div>' +
        '</blockquote></div>';
      const c = cleaned(html);
      expect(c.textContent).toContain('Sounds good');
      expect(c.textContent).not.toContain('On Apr 6, 2026');
      expect(c.textContent).not.toContain('Locking the Friday slot');
    });

    it('preserves user reply that follows a soft-header <blockquote>', () => {
      const html =
        '<blockquote>On Mon, Sep 22, Sam wrote:<br>Original quoted line.</blockquote><p>My actual reply.</p>';
      expect(cleaned(html).textContent).toContain('My actual reply');
    });

    it('preserves user reply that follows a wrapper containing a soft-header block', () => {
      const html =
        '<div><blockquote>On Mon, Sam wrote:</blockquote></div><p>My reply outside the wrapper.</p>';
      expect(cleaned(html).textContent).toContain(
        'My reply outside the wrapper'
      );
    });

    it('does not strip prose paragraphs that start with "From: " or "Sent: "', () => {
      const fromHtml =
        '<p>From: now on, please follow this checklist.</p><p>This is regular content.</p>';
      expect(cleaned(fromHtml).textContent).toContain('From: now on');
      expect(cleaned(fromHtml).textContent).toContain('regular content');

      const sentHtml =
        '<p>Sent: yesterday by the courier.</p><p>Tracking number to follow.</p>';
      expect(cleaned(sentHtml).textContent).toContain('Sent: yesterday');
      expect(cleaned(sentHtml).textContent).toContain('Tracking number');
    });
  });

  describe('single-line "On … wrote:" attribution', () => {
    it('detects header even when followed by un-prefixed old lines', () => {
      const html =
        '<p>On Wed, Sam wrote:</p><p>Old line 1</p><p>Old line 2</p>';
      const c = cleaned(html);
      expect(c.textContent).not.toContain('On Wed, Sam wrote');
      expect(EmailQuoteExtractor.hasQuotes(html)).toBe(true);
    });
  });

  describe('top-level RFC `>` and header tail (text + <br>)', () => {
    it('iPhone Mail — strips RFC `>` quoted lines from a plain-text only body', () => {
      const html = [
        'Test payments email<br><br>',
        'Thanks,<br>Shruthi<br><br>',
        'Sent from my iPhone<br><br>',
        '&gt; On Apr 6, 2026, at 11:26 PM, Shruthi wrote:<br>',
        '&gt; <br>&gt; Hi email<br>&gt; To Eli<br>',
        '&gt; Thanks,<br>&gt; Shruthi',
      ].join('');
      const c = cleaned(html);
      expect(c.textContent).toContain('Test payments email');
      expect(c.textContent).toContain('Sent from my iPhone'); // signature stays
      expect(c.textContent).not.toContain('On Apr 6, 2026');
      expect(c.textContent).not.toContain('Hi email');
      expect(EmailQuoteExtractor.hasQuotes(html)).toBe(true);
    });

    it('strips both plain-text `>` lines and HTML quote blocks in the same body', () => {
      const html = `<p>My HTML reply</p>
<p>Sivin</p>
<br>
&gt; On Mon, Apr 6, 2026, Shruthi wrote:<br>
&gt; Inline plain-text quote line<br>
<div class="gmail_quote">
  <p>The original HTML quoted email</p>
</div>`;
      const c = cleaned(html);
      expect(c.textContent).toContain('My HTML reply');
      expect(c.textContent).toContain('Sivin');
      expect(c.textContent).not.toContain('Inline plain-text quote line');
      expect(c.textContent).not.toContain('The original HTML quoted email');
      expect(c.querySelectorAll('.gmail_quote').length).toBe(0);
    });

    it('detects top-level "On … wrote:" header (no wrapper)', () => {
      const html =
        'Reply text<br><br>On Tue, Pat wrote:<br>Original line 1<br>Original line 2';
      const c = cleaned(html);
      expect(c.textContent).toContain('Reply text');
      expect(c.textContent).not.toContain('On Tue, Pat wrote');
      expect(c.textContent).not.toContain('Original line 1');
      expect(EmailQuoteExtractor.hasQuotes(html)).toBe(true);
    });

    it('detects top-level "From:/Sent:" header (no wrapper)', () => {
      const html =
        'Reply text<br>From: Sam<br>Sent: Wed Dec 4, 2024<br>Original body';
      const c = cleaned(html);
      expect(c.textContent).toContain('Reply text');
      expect(c.textContent).not.toContain('From: Sam');
      expect(EmailQuoteExtractor.hasQuotes(html)).toBe(true);
    });

    it('detects top-level "-----Original Message-----" (no wrapper)', () => {
      const html = 'Reply<br>-----Original Message-----<br>From: Sam<br>Body';
      const c = cleaned(html);
      expect(c.textContent).toContain('Reply');
      expect(c.textContent).not.toContain('Original Message');
      expect(EmailQuoteExtractor.hasQuotes(html)).toBe(true);
    });

    it('preserves user reply that is bottom-posted below `>`-quoted lines', () => {
      const html =
        '&gt; On Tue, Pat wrote:<br>&gt; Attached is the doc.<br>&gt; Pat<br><br>Got it, looks good.';
      expect(cleaned(html).textContent).toContain('Got it, looks good');
    });

    it('preserves user answers inline-posted between `>`-quoted lines', () => {
      const html =
        '&gt; Q1: pricing?<br>A1: USD 100<br>&gt; Q2: timeline?<br>A2: 2 weeks<br><br>Thanks!';
      const c = cleaned(html);
      expect(c.textContent).toContain('A1: USD 100');
      expect(c.textContent).toContain('A2: 2 weeks');
      expect(c.textContent).toContain('Thanks!');
    });
  });

  describe('inline / no-quote bodies', () => {
    it('inline reply — when content follows the quoted block, body is left intact', () => {
      const html =
        '<p>See my responses inline below.</p><blockquote><p>Q1: pricing?</p><p>A1: usd 100.</p></blockquote><p>Let me know if any of that needs clarification.</p><p>Pat</p>';
      const c = cleaned(html);
      expect(c.textContent).toContain('See my responses inline below');
      expect(c.textContent).toContain('Q1: pricing?');
      expect(c.textContent).toContain(
        'Let me know if any of that needs clarification'
      );
      expect(c.querySelector('blockquote')).not.toBeNull();
      expect(EmailQuoteExtractor.hasQuotes(html)).toBe(false);
    });

    it('plain body with no quotes — body unchanged, no toggle', () => {
      const html =
        '<p>Just checking in — any update on this?</p><p>Thanks,<br>Pat</p>';
      const c = cleaned(html);
      expect(c.textContent).toContain('Just checking in');
      expect(c.textContent).toContain('Thanks,');
      expect(EmailQuoteExtractor.hasQuotes(html)).toBe(false);
    });

    it('empty body — no error, no toggle', () => {
      expect(() => EmailQuoteExtractor.extractQuotes('')).not.toThrow();
      expect(EmailQuoteExtractor.hasQuotes('')).toBe(false);
    });
  });
});
