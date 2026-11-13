import {
  buildForwardedEmailHtml,
  textToHtml,
} from 'dashboard/helper/forwardEmailHelper';

const labels = {
  title: '---------- Forwarded message ---------',
  from: 'From',
  date: 'Date',
  subject: 'Subject',
  to: 'To',
};

describe('forwardEmailHelper', () => {
  describe('textToHtml', () => {
    it('escapes html and converts line breaks', () => {
      expect(textToHtml('Hi <b>there</b>\nBye & thanks')).toBe(
        'Hi &lt;b&gt;there&lt;/b&gt;<br>Bye &amp; thanks'
      );
    });
  });

  describe('buildForwardedEmailHtml', () => {
    const build = overrides =>
      buildForwardedEmailHtml({
        labels,
        sender: { name: 'Jane Doe', email: 'jane@example.com' },
        date: 'Thu, Sep 17, 2026 at 9:39 AM',
        subject: 'Order #42',
        recipients: ['support@example.com'],
        bodyHtml: '<p>Original body</p>',
        ...overrides,
      });

    it('renders the gmail style header followed by the body', () => {
      expect(build()).toBe(
        [
          '<div class="chatwoot_forward_header">',
          '---------- Forwarded message ---------<br>',
          'From: <b>Jane Doe</b> &lt;<a href="mailto:jane@example.com">jane@example.com</a>&gt;<br>',
          'Date: Thu, Sep 17, 2026 at 9:39 AM<br>',
          'Subject: Order #42<br>',
          'To: &lt;<a href="mailto:support@example.com">support@example.com</a>&gt;',
          '</div><br><p>Original body</p>',
        ].join('')
      );
    });

    it('omits the bold name when the sender has none', () => {
      expect(build({ sender: { email: 'jane@example.com' } })).toContain(
        'From: &lt;<a href="mailto:jane@example.com">jane@example.com</a>&gt;<br>'
      );
    });

    it('lists every recipient', () => {
      expect(
        build({ recipients: ['a@example.com', 'b@example.com'] })
      ).toContain(
        'To: &lt;<a href="mailto:a@example.com">a@example.com</a>&gt;, &lt;<a href="mailto:b@example.com">b@example.com</a>&gt;'
      );
    });

    it('escapes header values but keeps the body html intact', () => {
      const html = build({
        sender: { name: '<script>x</script>', email: 'a"b@example.com' },
        subject: 'Re: <img src=x onerror=alert(1)>',
        bodyHtml: '<p>Keep <b>this</b></p>',
      });

      expect(html).toContain('<b>&lt;script&gt;x&lt;/script&gt;</b>');
      expect(html).toContain('mailto:a&quot;b@example.com');
      expect(html).toContain('Subject: Re: &lt;img src=x onerror=alert(1)&gt;');
      expect(html).toContain('<p>Keep <b>this</b></p>');
      expect(html).not.toContain('<script>');
    });
  });
});
