module Autonomia
  module Agents
    module Knowledge
      module Processors
        # pdf: extração de texto via gem `pdf-reader` (PDF::Reader). A gem é opcional neste fork —
        # se ausente, degrada p/ UnsupportedFormat (a fonte vira `failed` com mensagem clara) em vez
        # de quebrar o boot. Concatena o texto de cada página. Quando o PDF é escaneado (sem camada
        # de texto), a extração normal volta vazia; nesse caso cai p/ OCR (rtesseract + mini_magick).
        class Pdf < Base
          # Abaixo deste tamanho (após strip) a extração é "quase vazia" (PDF escaneado / só imagem):
          # vale tentar OCR em vez de marcar a fonte como falha por texto ausente.
          OCR_MIN_CHARS = 20
          OCR_LANGUAGE = 'por'.freeze

          def extract
            ensure_gem!
            text = +''
            with_tempfile do |path|
              reader = PDF::Reader.new(path)
              reader.pages.each { |page| text << page.text << "\n" }
            end
            text = text.force_encoding('UTF-8').scrub('')
            text.strip.length < OCR_MIN_CHARS ? ocr_fallback(text) : text
          rescue PDF::Reader::MalformedPDFError, PDF::Reader::UnsupportedFeatureError => e
            raise ExtractionError, "pdf_parse_failed: #{e.message}"
          end

          private

          # PDF escaneado: rasteriza cada página (mini_magick/imagemagick, que lê PDF via poppler)
          # e passa por OCR (rtesseract -> binário tesseract, idioma pt-BR). Guardado: se gem ou
          # binário faltarem em runtime, loga aviso e devolve o texto original (vazio) — nunca
          # levanta erro novo que quebre a ingestão. Deps de sistema instaladas na imagem prod
          # (docker/Dockerfile: tesseract-ocr tesseract-ocr-data-por poppler-utils).
          def ocr_fallback(text)
            require 'mini_magick'
            require 'rtesseract'
            ocr = +''
            with_tempfile { |path| ocr << ocr_pages(path) }
            ocr = ocr.force_encoding('UTF-8').scrub('').strip
            ocr.length >= OCR_MIN_CHARS ? ocr : text
          rescue LoadError, StandardError => e
            Rails.logger.warn("[autonomia] pdf_ocr_unavailable: #{e.class}: #{e.message}")
            text
          end

          # Rasteriza o PDF em uma imagem por página (300 DPI p/ OCR legível) e OCR-a cada uma,
          # juntando com quebra de linha entre páginas.
          def ocr_pages(pdf_path)
            image = MiniMagick::Image.open(pdf_path)
            out = +''
            image.pages.each_with_index do |page, index|
              page_image = MiniMagick::Image.open(page.path)
              page_image.density(300)
              out << RTesseract.new(page_image.path, lang: OCR_LANGUAGE).to_s.to_s
              out << "\n" if index < image.pages.size - 1
            end
            out
          end

          def ensure_gem!
            require 'pdf-reader'
          rescue LoadError
            raise UnsupportedFormat, 'pdf_support_unavailable'
          end
        end
      end
    end
  end
end
