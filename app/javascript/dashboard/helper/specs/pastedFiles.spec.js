import {
  clipboardCarriesText,
  splitFilesBySize,
  usableFilesFromTransfer,
} from '../pastedFiles';

// The shapes below are not invented: they were measured on 10/09/2026, macOS, Chromium 153,
// by pasting each source into a probe page and reading `e.clipboardData`. The record lives in
// the round's holdout folder (clipboard-measurements.json). Two of them decide the whole
// question, and they are the two the issue said had to be measured before shipping:
//
//   * a Numbers copy really does carry an invalid attachment, and it is `image.png` of
//     `image/png`, never a spreadsheet file. It arrives WITH text/plain, text/html and text/rtf,
//     because the point of copying a cell is to paste its text somewhere. Its size is almost
//     always 0: nine direct pasteboard reads across three copies gave 0 bytes, and twice the
//     same gesture gave a real PNG that nobody could reproduce on command. Both shapes are
//     covered below, because the decision never looks at the size of that file: the empty one
//     must not warn, and the filled one is an ordinary attachment.
//   * a file copied in Finder arrives as `Files` alone. The macOS pasteboard does carry the
//     file name as text, and the browser drops it, so `types` has no text flavour at all.
//
// That asymmetry is the whole discriminator: warn when every pasted file is empty and nothing
// on the clipboard is text, stay quiet otherwise.
// A real DataTransfer answers for every type it announces, so the fixture answers too: whether
// the announced text has anything in it is the other candidate discriminator, and a fixture that
// cannot be asked would let it pass untested.
const transfer = (types, files, data = {}) => ({
  types,
  files: files.map(([name, type, size]) => ({ name, type, size })),
  getData: type => data[type] ?? '',
});

const NUMBERS_SINGLE_CELL = transfer(
  ['text/plain', 'text/html', 'text/rtf', 'Files'],
  [['image.png', 'image/png', 0]],
  { 'text/plain': 'planilha 2' }
);
const NUMBERS_RANGE = NUMBERS_SINGLE_CELL;
// The other shape the same gesture has produced, twice and not on demand: a real PNG.
const NUMBERS_SETTLED = transfer(
  ['text/plain', 'text/html', 'text/rtf', 'Files'],
  [['image.png', 'image/png', 10594]]
);
const FINDER_ZERO_BYTE_FILE = transfer(
  ['Files'],
  [['vazio.txt', 'text/plain', 0]]
);
const FINDER_VALID_FILE = transfer(
  ['Files'],
  [['valido.txt', 'text/plain', 4]]
);
const SCREENSHOT = transfer(['Files'], [['image.png', 'image/png', 40656]]);
// Copying an EMPTY cell in Numbers, measured on 10/09/2026 in the same probe as the shapes
// above, in Chromium 153.0.8010.12 and in WebKit 605.1.15 (Version/26.6 Safari): the text flavour
// is announced with nothing in it, beside the same artifact nobody chose. Four of five copies of
// an empty cell came out as `text/plain` of zero characters next to `Files`, and a pasteboard
// carrying an empty text flavour beside a zero-byte PNG reaches both engines exactly like this.
//
// This is the shape #567 proposed to treat as "no text", by reading the content instead of
// trusting the announced type. The measurement says the opposite: when the clipboard carries a
// file the person actually picked (`public.file-url`), NEITHER engine announces any text flavour
// at all, empty or filled, in one pasteboard item or in two. So a genuine empty file never
// arrives with text beside it, deciding on the content recovers no warning that is being missed,
// and it would turn this paste, an ordinary spreadsheet paste, into a false alarm about a file
// nobody chose. That is why the rule reads the announced type and not the content.
const NUMBERS_EMPTY_CELL = transfer(
  ['text/plain', 'Files'],
  [['image.png', 'image/png', 0]]
);
const PLAIN_TEXT = transfer(['text/plain'], [], { 'text/plain': 'texto' });

describe('pastedFiles', () => {
  describe('clipboardCarriesText', () => {
    it('is true for the shapes a rich copy produces', () => {
      expect(clipboardCarriesText(NUMBERS_SINGLE_CELL)).toBe(true);
      expect(clipboardCarriesText(PLAIN_TEXT)).toBe(true);
    });

    it('is false for a file copy, which the browser reports as Files alone', () => {
      expect(clipboardCarriesText(FINDER_ZERO_BYTE_FILE)).toBe(false);
      expect(clipboardCarriesText(SCREENSHOT)).toBe(false);
    });

    // Each flavour on its own, because a copy does not always bring all three: a web page gives
    // text/html, a rich text editor gives text/rtf, and treating any one of them as "no text"
    // would put the spurious alert back for that source alone.
    it.each(['text/plain', 'text/html', 'text/rtf'])(
      'counts %s on its own as text',
      type => {
        expect(
          clipboardCarriesText(
            transfer([type, 'Files'], [['image.png', 'image/png', 0]], {
              [type]: 'planilha 2',
            })
          )
        ).toBe(true);
      }
    );

    it('counts an announced text flavour with nothing in it, the empty spreadsheet cell', () => {
      expect(clipboardCarriesText(NUMBERS_EMPTY_CELL)).toBe(true);
      expect(NUMBERS_EMPTY_CELL.getData('text/plain')).toBe('');
    });

    it('survives a transfer with no types at all', () => {
      expect(clipboardCarriesText(undefined)).toBe(false);
      expect(clipboardCarriesText({})).toBe(false);
    });
  });

  describe('splitFilesBySize', () => {
    it('keeps the order and drops nothing on the floor', () => {
      const files = [
        { name: 'a.png', size: 0 },
        { name: 'b.png', size: 10 },
        { name: 'c.png', size: 0 },
      ];

      expect(splitFilesBySize(files)).toEqual({
        files: [{ name: 'b.png', size: 10 }],
        empty: [
          { name: 'a.png', size: 0 },
          { name: 'c.png', size: 0 },
        ],
      });
    });

    it('ignores holes rather than crashing on them', () => {
      expect(splitFilesBySize([null, undefined])).toEqual({
        files: [],
        empty: [],
      });
      expect(splitFilesBySize(null)).toEqual({ files: [], empty: [] });
    });
  });

  describe('usableFilesFromTransfer', () => {
    it('stays quiet for a Numbers paste, which is why the filter exists', () => {
      expect(usableFilesFromTransfer(NUMBERS_SINGLE_CELL)).toEqual({
        files: [],
        shouldAlertEmpty: false,
      });
      expect(usableFilesFromTransfer(NUMBERS_RANGE).shouldAlertEmpty).toBe(
        false
      );
    });

    it('stays quiet for an empty spreadsheet cell, whose text is announced empty', () => {
      expect(usableFilesFromTransfer(NUMBERS_EMPTY_CELL)).toEqual({
        files: [],
        shouldAlertEmpty: false,
      });
    });

    it('explains the refusal for a genuine empty file', () => {
      expect(usableFilesFromTransfer(FINDER_ZERO_BYTE_FILE)).toEqual({
        files: [],
        shouldAlertEmpty: true,
      });
    });

    it('attaches the spreadsheet image on the runs where it comes through filled', () => {
      expect(usableFilesFromTransfer(NUMBERS_SETTLED)).toEqual({
        files: [{ name: 'image.png', type: 'image/png', size: 10594 }],
        shouldAlertEmpty: false,
      });
    });

    it('says nothing when there was nothing to drop', () => {
      expect(usableFilesFromTransfer(FINDER_VALID_FILE)).toEqual({
        files: [{ name: 'valido.txt', type: 'text/plain', size: 4 }],
        shouldAlertEmpty: false,
      });
      expect(usableFilesFromTransfer(SCREENSHOT).shouldAlertEmpty).toBe(false);
      expect(usableFilesFromTransfer(PLAIN_TEXT).shouldAlertEmpty).toBe(false);
    });

    it('keeps the valid file and still explains the empty one beside it', () => {
      const mixed = transfer(
        ['Files'],
        [
          ['vazio.txt', 'text/plain', 0],
          ['valido.txt', 'text/plain', 4],
        ]
      );

      expect(usableFilesFromTransfer(mixed)).toEqual({
        files: [{ name: 'valido.txt', type: 'text/plain', size: 4 }],
        shouldAlertEmpty: true,
      });
    });
  });
});
