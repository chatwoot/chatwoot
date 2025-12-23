module GLI
  module Commands
    module HelpModules
      # Handles wrapping text
      class TextWrapper
        # Create a text_wrapper wrapping at the given width,
        # and indent.
        def initialize(width,indent)
          @width = width
          @indent = indent
        end

        # Return a wrapped version of text, assuming that the first line has already been
        # indented by @indent characters.  Resulting text does NOT have a newline in it.
        def wrap(text)
          return text if text.nil?
          wrapped_text = ''
          current_graf = ''

          paragraphs = text.split(/\n\n+/)
          paragraphs.each do |graf|
            current_line = ''
            current_line_length = @indent

            words = graf.split(/\s+/)
            current_line = words.shift || ''
            current_line_length += current_line.length

            words.each do |word|
              if current_line_length + word.length + 1 > @width
                current_graf << current_line << "\n"
                current_line = ''
                current_line << ' ' * @indent << word
                current_line_length = @indent + word.length
              else
                if current_line == ''
                  current_line << word
                else
                  current_line << ' ' << word
                end
                current_line_length += (word.length + 1)
              end
            end
            current_graf << current_line
            wrapped_text << current_graf  << "\n\n" << ' ' * @indent
            current_graf = ''
          end
          wrapped_text.gsub(/[\n\s]*\Z/,'')
        end
      end
    end
  end
end
