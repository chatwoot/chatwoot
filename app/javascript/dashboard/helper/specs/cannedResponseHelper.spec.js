import { CHANGE_TYPES, adaptCannedResponse } from '../cannedResponseHelper';

const IMAGE_URL =
  'http://localhost:3000/rails/active_storage/blobs/redirect/signed-image/dashboard.png';

const pdf = {
  signed_id: 'signed-pdf',
  filename: 'guide.pdf',
  content_type: 'application/pdf',
  byte_size: 1024,
  file_url: 'http://localhost:3000/guide.pdf',
};

const csv = {
  signed_id: 'signed-csv',
  filename: 'rates.csv',
  content_type: 'text/csv',
  byte_size: 1024,
  file_url: 'http://localhost:3000/rates.csv',
};

const WEB = { channelType: 'Channel::WebWidget' };
const EMAIL = { channelType: 'Channel::Email' };
const WHATSAPP = { channelType: 'Channel::Whatsapp' };
const SMS = { channelType: 'Channel::Sms' };

const changeTypes = preview => preview.changes.map(change => change.type);

describe('adaptCannedResponse', () => {
  const content = `Hi **there**, [watch the video](https://example.com/demo)\n\n- one\n- two\n\n![](${IMAGE_URL})`;

  it('changes nothing on live chat', () => {
    const preview = adaptCannedResponse({ content, files: [pdf] }, WEB);

    expect(preview.changes).toEqual([]);
    expect(preview.content).toBe(content);
    expect(preview.attachments).toEqual([pdf]);
  });

  it('reports only the formatting an email cannot carry', () => {
    const preview = adaptCannedResponse(
      { content: 'Use ~~old~~ **new** steps', files: [] },
      EMAIL
    );

    expect(changeTypes(preview)).toEqual([CHANGE_TYPES.STRIKETHROUGH]);
    expect(preview.content).toBe('Use old **new** steps');
  });

  it('moves images out of the text and flattens links on WhatsApp', () => {
    const preview = adaptCannedResponse({ content, files: [pdf] }, WHATSAPP);

    expect(changeTypes(preview)).toEqual([
      CHANGE_TYPES.LINK,
      CHANGE_TYPES.IMAGE_MOVED,
      CHANGE_TYPES.FILE_SEPARATE,
    ]);
    expect(preview.content).toContain(
      'watch the video: https://example.com/demo'
    );
    expect(preview.content).not.toContain(IMAGE_URL);
    expect(preview.attachments.map(file => file.signed_id)).toEqual([
      'signed-image',
      'signed-pdf',
    ]);
  });

  it('reads the blob of an image that was resized in the editor', () => {
    const preview = adaptCannedResponse(
      { content: `![](${IMAGE_URL}?cw_image_height=24px)`, files: [] },
      WHATSAPP
    );

    expect(preview.attachments).toEqual([
      {
        signed_id: 'signed-image',
        filename: 'dashboard.png',
        content_type: 'image/png',
        file_url: `${IMAGE_URL}?cw_image_height=24px`,
      },
    ]);
  });

  it('attaches nothing for a response cached before files existed', () => {
    const preview = adaptCannedResponse({ content: 'Hello' }, WHATSAPP);

    expect(preview.attachments).toEqual([]);
  });

  it('drops a list item that only held a moved image', () => {
    const preview = adaptCannedResponse(
      { content: `- one\n- ![](${IMAGE_URL})\n- two`, files: [] },
      WHATSAPP
    );

    expect(preview.content).toBe('- one\n- two');
  });

  it('keeps a line break inside a paragraph', () => {
    const preview = adaptCannedResponse(
      { content: 'one\\\ntwo', files: [] },
      SMS
    );

    expect(preview.content).toBe('one\\\ntwo');
  });

  it('does not read an image as a link', () => {
    const preview = adaptCannedResponse(
      { content: `Look\n\n![](${IMAGE_URL})`, files: [] },
      WHATSAPP
    );

    expect(changeTypes(preview)).toEqual([CHANGE_TYPES.IMAGE_MOVED]);
  });

  it('blocks a file type the channel does not accept', () => {
    const preview = adaptCannedResponse(
      { content: 'Rates attached', files: [pdf, csv] },
      WHATSAPP
    );

    expect(preview.changes).toEqual([
      { type: CHANGE_TYPES.FILE_SEPARATE },
      { type: CHANGE_TYPES.FILE_BLOCKED, name: 'rates.csv' },
    ]);
    expect(preview.attachments).toEqual([pdf]);
  });

  it('blocks a file larger than the channel limit', () => {
    const largeImage = {
      signed_id: 'signed-photo',
      filename: 'photo.png',
      content_type: 'image/png',
      byte_size: 6 * 1024 * 1024,
    };
    const preview = adaptCannedResponse(
      { content: 'Photo attached', files: [largeImage] },
      WHATSAPP
    );

    expect(changeTypes(preview)).toEqual([CHANGE_TYPES.FILE_BLOCKED]);
  });

  it('blocks an image that is not an uploaded file', () => {
    const preview = adaptCannedResponse(
      { content: '![logo](https://example.com/logo.png)', files: [] },
      WHATSAPP
    );

    expect(changeTypes(preview)).toEqual([CHANGE_TYPES.IMAGE_BLOCKED]);
    expect(preview.attachments).toEqual([]);
  });

  it('reports each kind of formatting once on SMS', () => {
    const preview = adaptCannedResponse(
      {
        content: '**Bold** and *italic*\n\n- one\n\n1. two\n\n`code`',
        files: [],
      },
      SMS
    );

    expect(changeTypes(preview)).toEqual([
      CHANGE_TYPES.BOLD,
      CHANGE_TYPES.ITALIC,
      CHANGE_TYPES.CODE,
      CHANGE_TYPES.LIST,
    ]);
    expect(preview.content).toBe('Bold and italic\n\none\n\ntwo\n\ncode');
  });

  it('uses the WhatsApp rules for a Twilio WhatsApp inbox', () => {
    const preview = adaptCannedResponse(
      { content: '**Bold** text', files: [] },
      { channelType: 'Channel::TwilioSms', medium: 'whatsapp' }
    );

    expect(preview.changes).toEqual([]);
  });
});
