import MessageFormatter from '../MessageFormatter';

describe('#MessageFormatter', () => {
  describe('content with links', () => {
    it('should format correctly', () => {
      const message =
        'Chatwoot is an opensource tool. [Chatwoot](https://www.chatwoot.com)';
      expect(new MessageFormatter(message).formattedMessage).toMatch(
        '<p>Chatwoot is an opensource tool. <a href="https://www.chatwoot.com" class="link" rel="noreferrer noopener nofollow" target="_blank">Chatwoot</a></p>'
      );
    });
    it('should format correctly', () => {
      const message =
        'Chatwoot is an opensource tool. https://www.chatwoot.com';
      expect(new MessageFormatter(message).formattedMessage).toMatch(
        '<p>Chatwoot is an opensource tool. <a href="https://www.chatwoot.com" class="link" rel="noreferrer noopener nofollow" target="_blank">https://www.chatwoot.com</a></p>'
      );
    });
    it('should not convert template variables to links when linkify is disabled', () => {
      const message = 'Hey {{customer.name}}, check https://chatwoot.com';
      const formatter = new MessageFormatter(message, false, false, false);
      expect(formatter.formattedMessage).toMatch(
        '<p>Hey {{customer.name}}, check https://chatwoot.com</p>'
      );
    });
  });

  describe('parses heading to strong', () => {
    it('should format correctly', () => {
      const message = '### opensource \n ## tool';
      expect(new MessageFormatter(message).formattedMessage).toMatch(
        `<h3>opensource</h3>
<h2>tool</h2>`
      );
    });

    it('should not render a setext heading when text is followed by "--"', () => {
      const message = 'hy\n\n\\\n\\-\\-\n\nHello there';
      const result = new MessageFormatter(message).formattedMessage;
      expect(result).not.toMatch('<h2>');
      expect(result).not.toMatch('<h1>');
    });
  });

  describe('content with image and has "cw_image_height" query at the end of URL', () => {
    it('should set image height correctly', () => {
      const message =
        'Chatwoot is an opensource tool. ![](http://chatwoot.com/chatwoot.png?cw_image_height=24px)';
      expect(new MessageFormatter(message).formattedMessage).toMatch(
        '<p>Chatwoot is an opensource tool. <img src="http://chatwoot.com/chatwoot.png?cw_image_height=24px" alt="" style="height: 24px;" /></p>'
      );
    });

    it('should set image height correctly if its original size', () => {
      const message =
        'Chatwoot is an opensource tool. ![](http://chatwoot.com/chatwoot.png?cw_image_height=auto)';
      expect(new MessageFormatter(message).formattedMessage).toMatch(
        '<p>Chatwoot is an opensource tool. <img src="http://chatwoot.com/chatwoot.png?cw_image_height=auto" alt="" style="height: auto;" /></p>'
      );
    });

    it('should not set height', () => {
      const message =
        'Chatwoot is an opensource tool. ![](http://chatwoot.com/chatwoot.png)';
      expect(new MessageFormatter(message).formattedMessage).toMatch(
        '<p>Chatwoot is an opensource tool. <img src="http://chatwoot.com/chatwoot.png" alt="" /></p>'
      );
    });
  });

  describe('#disableImageRendering', () => {
    it('omits nested and reference images with relative URLs', () => {
      const message = `Before ![nested [alt]](/relative.png)

![reference][logo]

[logo]: /logo.png

After`;
      const formatter = new MessageFormatter(message);

      formatter.disableImageRendering();

      expect(formatter.formattedMessage).not.toContain('<img');
      expect(formatter.formattedMessage).toContain('Before');
      expect(formatter.formattedMessage).toContain('After');
    });
  });

  describe('tweets', () => {
    it('should return the same string if not tags or @mentions', () => {
      const message = 'Chatwoot is an opensource tool';
      expect(new MessageFormatter(message).formattedMessage).toMatch(message);
    });

    it('should add links to @mentions', () => {
      const message =
        '@chatwootapp is an opensource tool thanks @longnonexistenttwitterusername';
      expect(
        new MessageFormatter(message, true, false).formattedMessage
      ).toMatch(
        '<p><a href="http://twitter.com/chatwootapp" class="link" rel="noreferrer noopener nofollow" target="_blank">@chatwootapp</a> is an opensource tool thanks @longnonexistenttwitterusername</p>'
      );
    });

    it('should add links to #tags', () => {
      const message = '#chatwootapp is an opensource tool';
      expect(
        new MessageFormatter(message, true, false).formattedMessage
      ).toMatch(
        '<p><a href="https://twitter.com/hashtag/chatwootapp" class="link" rel="noreferrer noopener nofollow" target="_blank">#chatwootapp</a> is an opensource tool</p>'
      );
    });
  });

  describe('private notes', () => {
    it('should return the same string if not tags or @mentions', () => {
      const message = 'Chatwoot is an opensource tool';
      expect(new MessageFormatter(message).formattedMessage).toMatch(message);
    });

    it('should add links to @mentions', () => {
      const message =
        '@chatwootapp is an opensource tool thanks @longnonexistenttwitterusername';
      expect(
        new MessageFormatter(message, false, true).formattedMessage
      ).toMatch(message);
    });

    it('should add links to #tags', () => {
      const message = '#chatwootapp is an opensource tool';
      expect(
        new MessageFormatter(message, false, true).formattedMessage
      ).toMatch(message);
    });
  });

  describe('plain text content', () => {
    it('returns the plain text without HTML', () => {
      const message =
        '<b>Chatwoot is an opensource tool. https://www.chatwoot.com</b>';
      expect(new MessageFormatter(message).plainText).toMatch(
        'Chatwoot is an opensource tool. https://www.chatwoot.com'
      );
    });
  });

  describe('help center table colwidth marker', () => {
    it('strips the internal colwidths marker from rendered output', () => {
      const message =
        '<!--cw-colwidths:120,200-->\n| A | B |\n| --- | --- |\n| 1 | 2 |';
      const formatter = new MessageFormatter(message);
      expect(formatter.formattedMessage).not.toContain('cw-colwidths');
      expect(formatter.plainText).not.toContain('cw-colwidths');
    });

    it('strips a blockquote-prefixed marker so the quoted table still renders', () => {
      const message =
        '> <!--cw-colwidths:120,200-->\n> | A | B |\n> | --- | --- |\n> | 1 | 2 |';
      const { formattedMessage } = new MessageFormatter(message);
      expect(formattedMessage).not.toContain('cw-colwidths');
      expect(formattedMessage).toContain('<blockquote>');
      expect(formattedMessage).toContain('<table>');
    });
  });

  describe('#sanitize', () => {
    it('sanitizes markup and removes all unnecessary elements', () => {
      const message =
        '[xssLink](javascript:alert(document.cookie))\n[normalLink](https://google.com)**I am a bold text paragraph**';
      expect(new MessageFormatter(message).formattedMessage).toMatch(
        `<p>[xssLink](javascript:alert(document.cookie))<br />
<a href="https://google.com" class="link" rel="noreferrer noopener nofollow" target="_blank">normalLink</a><strong>I am a bold text paragraph</strong></p>`
      );
    });
  });

  // Byte-exact editor serializer output for Enter / Shift+Enter combinations.
  // An empty line is stored as a `\` hard-break chain and an underline below
  // it is escaped (`\--`, `\-`, `\==`); the bubble must render no backslash
  // and keep every composed line.
  describe('editor break and empty-line encoding', () => {
    const signatureTail =
      '\n\nThanks \\\nSivin | Chatwoot\n\n![](https://example.com/logo.png)';
    const cases = [
      ['enter above signature', `hey\n\n\\\n\\--${signatureTail}`, 2],
      ['shift+enter then -- on the same line', 'hey\\\n\\--', 1],
      ['two breaks above signature', `hey\n\n\\\n\\\n\\--${signatureTail}`, 3],
      [
        'three enters and four breaks above signature',
        `sd\n\n\\\n\\\n\\\n\\\n\\\n\\\n\\--${signatureTail}`,
        7,
      ],
      ['equals underline below an empty line', 'a\n\n\\\n\\==', 1],
      ['lone dash after a break', 'a\\\n\\-', 1],
      ['lone dash below an empty line', 'x\n\n\\\n\\-', 1],
      ['bold dashes after a break', 'a\\\n**--**', 1],
      ['dashes led by a bold space below an empty line', 'a\n\n\n --', 0],
      ['dashes trailed by a bold space', 'a\n\n\\\n\\-- ', 1],
      ['empty line between paragraphs', 'a\n\n\\\nb', 1],
      ['double break inside a paragraph', 'a\\\n\\\nb', 2],
      ['plain hard break', 'line one\\\nline two', 1],
    ];

    it.each(cases)(
      'renders %s without backslash artifacts and keeps every line',
      (_name, message, breakCount) => {
        const { formattedMessage } = new MessageFormatter(message);
        expect(formattedMessage).not.toContain('\\');
        expect(formattedMessage).not.toMatch(/<h[12]/);
        expect(formattedMessage.match(/<br/g) || []).toHaveLength(breakCount);
      }
    );

    it('keeps the signature delimiter as literal text below the empty line', () => {
      const { formattedMessage } = new MessageFormatter(
        `hey\n\n\\\n\\--${signatureTail}`
      );
      expect(formattedMessage).toContain('--</p>');
    });
  });
});
