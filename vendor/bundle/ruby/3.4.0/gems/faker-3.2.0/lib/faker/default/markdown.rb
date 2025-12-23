# frozen_string_literal: true

module Faker
  class Markdown < Base
    class << self
      ##
      # Produces a random header format.
      #
      # @return [String]
      #
      # @example
      #   Faker::Markdown.headers #=> "##### Autem"
      #
      # @faker.version 1.8.0
      def headers
        "#{fetch('markdown.headers')} #{Lorem.word.capitalize}"
      end

      ##
      # Produces a random emphasis formatting on a random word in two sentences.
      #
      # @return [String]
      #
      # @example
      #   Faker::Markdown.emphasis #=> "_Incidunt atque quis repellat id impedit.  Quas numquam quod incidunt dicta non. Blanditiis delectus laudantium atque reiciendis qui._"
      #
      # @faker.version 1.8.0
      def emphasis
        paragraph = Faker::Lorem.paragraph(sentence_count: 3)
        words = paragraph.split
        position = rand(0..words.length - 1)
        formatting = fetch('markdown.emphasis')
        words[position] = "#{formatting}#{words[position]}#{formatting}"
        words.join(' ')
      end

      ##
      # Produces a random ordered list of items between 1 and 10 randomly.
      #
      # @return [String]
      #
      # @example
      #   Faker::Markdown.ordered_list #=> "1. Qui reiciendis non consequatur atque.\n2. Quo doloremque veritatis tempora aut.\n3. Aspernatur.\n4. Ea ab.\n5. Qui.\n6. Sit pariatur nemo eveniet.\n7. Molestiae aut.\n8. Nihil molestias iure placeat.\n9. Dolore autem quisquam."
      #
      # @faker.version 1.8.0
      def ordered_list
        number = rand(1..10)

        result = []
        number.times do |i|
          result << "#{i}. #{Faker::Lorem.sentence(word_count: 1)} \n"
        end
        result.join
      end

      ##
      # Produces a random unordered list of items between 1 and 10 randomly.
      #
      # @return [String]
      #
      # @example
      #   Faker::Markdown.unordered_list #=> "* Voluptatum aliquid tempora molestiae facilis non sed.\n* Nostrum omnis iste impedit voluptatum dolor.\n* Esse quidem et facere."
      #
      # @faker.version 1.8.0
      def unordered_list
        number = rand(1..10)

        result = []
        number.times do |_i|
          result << "* #{Faker::Lorem.sentence(word_count: 1)} \n"
        end
        result.join
      end

      ##
      # Produces a random inline code snippet between two sentences.
      #
      # @return [String]
      #
      # @example
      #   Faker::Markdown.inline_code #=> "Aut eos quis suscipit. `Dignissimos voluptatem expedita qui.` Quo doloremque veritatis tempora aut."
      #
      # @faker.version 1.8.0
      def inline_code
        "`#{Faker::Lorem.sentence(word_count: 1)}`"
      end

      ##
      # Produces a random code block formatted in Ruby.
      #
      # @return [String]
      #
      # @example
      #   Faker::Markdown.block_code #=> "```ruby\nEos quasi qui.\n```"
      #
      # @faker.version 1.8.0
      def block_code
        "```ruby\n#{Lorem.sentence(word_count: 1)}\n```"
      end

      ##
      # Produces a random 3x4 table with a row of headings, a row of hyphens and two rows of data
      #
      # @return [String]
      #
      # @example
      #   Faker::Markdown.table #=> "ad | similique | voluptatem\n---- | ---- | ----\ncorrupti | est | rerum\nmolestiae | quidem | et"
      #
      # @faker.version 1.8.0
      def table
        table = []
        3.times do
          table << "#{Lorem.word} | #{Lorem.word} | #{Lorem.word}"
        end
        table.insert(1, '---- | ---- | ----')
        table.join("\n")
      end

      ##
      # Produces a random method from the methods above, excluding the methods listed in the arguments.
      #
      # @overload random(methods)
      #   @param methods [Symbol] Specify which methods to exclude.
      #
      # @return [String, Array<String>]
      #
      # @example
      #   Faker::Markdown.random #=> returns output from a single method outlined above
      #   Faker::Markdown.random("table") #=> returns output from any single method outlined above except for "table"
      #   Faker::Markdown.random("ordered_list", "unordered_list") #=> returns output from any single method outlined above except for either ordered_list and unordered_list
      #
      # @faker.version 1.8.0
      def random(*args)
        method_list = available_methods
        args&.each { |ex| method_list.delete_if { |meth| meth == ex.to_sym } }
        send(method_list[Faker::Config.random.rand(0..method_list.length - 1)])
      end

      ##
      # Produces a simulated blog-esque text-heavy block in markdown
      #
      # Keyword arguments: sentences, repeat
      # @param sentences [Integer] Specifies how many sentences make a text block.
      # @param repeat [Integer] Specifies how many times the text block repeats.
      # @return [String]
      #
      # @example
      #   Faker::Markdown.sandwich #=> returns newline separated content of 1 header, 1 default lorem paragraph, and 1 random markdown element
      #   Faker::Markdown.sandwich(sentences: 5) #=> returns newline separated content of 1 header, 1 5-sentence lorem paragraph, and 1 random markdown element
      #   Faker::Markdown.sandwich(sentences: 6, repeat: 3) #=> returns newline separated content of 1 header, and then 3 sections consisting of, here, 1 6-sentence lorem paragraph and 1 random markdown element. The random markdown element is chosen at random in each iteration of the paragraph-markdown pairing.
      #
      # @faker.version 1.8.0
      def sandwich(sentences: 3, repeat: 1)
        text_block = []
        text_block << headers
        repeat.times do
          text_block << Faker::Lorem.paragraph(sentence_count: sentences)
          text_block << random
        end
        text_block.join("\n")
      end

      private

      def available_methods
        (Markdown.public_methods(false) - Base.methods).sort
      end
    end
  end
end
