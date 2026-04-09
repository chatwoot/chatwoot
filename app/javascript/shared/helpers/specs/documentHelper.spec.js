import {
  isPdfDocument,
  formatDocumentLink,
} from 'shared/helpers/documentHelper';

describe('documentHelper', () => {
  describe('#isPdfDocument', () => {
    it('returns true for PDF documents', () => {
      expect(isPdfDocument('PDF:document.pdf')).toBe(true);
      expect(isPdfDocument('PDF:my-file_20241227123045.pdf')).toBe(true);
      expect(isPdfDocument('PDF:report with spaces_20241227123045.pdf')).toBe(
        true
      );
    });

    it('returns false for regular URLs', () => {
      expect(isPdfDocument('https://example.com')).toBe(false);
      expect(isPdfDocument('http://docs.example.com/file.pdf')).toBe(false);
      expect(isPdfDocument('ftp://files.example.com/document.pdf')).toBe(false);
    });

    it('returns false for empty or null values', () => {
      expect(isPdfDocument('')).toBe(false);
      expect(isPdfDocument(null)).toBe(false);
      expect(isPdfDocument(undefined)).toBe(false);
    });

    it('returns false for strings that contain PDF but do not start with PDF:', () => {
      expect(isPdfDocument('document PDF:file.pdf')).toBe(false);
      expect(isPdfDocument('My PDF:file.pdf')).toBe(false);
    });
  });

  describe('#formatDocumentLink', () => {
    describe('PDF documents', () => {
      it('removes PDF: prefix from PDF documents', () => {
        expect(formatDocumentLink('PDF:document.pdf')).toBe('document.pdf');
        expect(formatDocumentLink('PDF:my-file.pdf')).toBe('my-file.pdf');
      });

      it('removes timestamp suffix from PDF documents', () => {
        expect(formatDocumentLink('PDF:document_20241227123045.pdf')).toBe(
          'document.pdf'
        );
        expect(formatDocumentLink('PDF:report_20231215094530.pdf')).toBe(
          'report.pdf'
        );
      });

      it('handles PDF documents with spaces in filename', () => {
        expect(formatDocumentLink('PDF:my document_20241227123045.pdf')).toBe(
          'my document.pdf'
        );
        expect(
          formatDocumentLink('PDF:Annual Report 2024_20241227123045.pdf')
        ).toBe('Annual Report 2024.pdf');
      });

      it('handles PDF documents without timestamp suffix', () => {
        expect(formatDocumentLink('PDF:document.pdf')).toBe('document.pdf');
        expect(formatDocumentLink('PDF:simple-file.pdf')).toBe(
          'simple-file.pdf'
        );
      });

      it('handles PDF documents with partial timestamp patterns', () => {
        expect(formatDocumentLink('PDF:document_202412.pdf')).toBe(
          'document_202412.pdf'
        );
        expect(formatDocumentLink('PDF:file_123.pdf')).toBe('file_123.pdf');
      });

      it('handles edge cases with timestamp pattern', () => {
        expect(
          formatDocumentLink('PDF:doc_20241227123045_final_20241227123045.pdf')
        ).toBe('doc_20241227123045_final.pdf');
      });
    });

    describe('Regular URLs', () => {
      it('returns regular URLs unchanged', () => {
        expect(formatDocumentLink('https://example.com')).toBe(
          'https://example.com'
        );
        expect(formatDocumentLink('http://docs.example.com/api')).toBe(
          'http://docs.example.com/api'
        );
        expect(formatDocumentLink('https://github.com/user/repo')).toBe(
          'https://github.com/user/repo'
        );
      });

      it('handles URLs with query parameters', () => {
        expect(formatDocumentLink('https://example.com?param=value')).toBe(
          'https://example.com?param=value'
        );
        expect(
          formatDocumentLink(
            'https://api.example.com/docs?version=v1&format=json'
          )
        ).toBe('https://api.example.com/docs?version=v1&format=json');
      });

      it('handles URLs with fragments', () => {
        expect(formatDocumentLink('https://example.com/docs#section1')).toBe(
          'https://example.com/docs#section1'
        );
      });
    });
  });
});
