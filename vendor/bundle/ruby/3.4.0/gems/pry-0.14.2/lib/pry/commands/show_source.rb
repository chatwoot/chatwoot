# frozen_string_literal: true

class Pry
  class Command
    class ShowSource < Command::ShowInfo
      include Pry::Helpers::DocumentationHelpers

      match 'show-source'
      group 'Introspection'
      description 'Show the source for a method or class.'

      banner <<-'BANNER'
        Usage:   show-source [OPTIONS] [METH|CLASS]
        Aliases: $, show-method

        Show the source for a method or class. Tries instance methods first and then
        methods by default.

        show-source hi_method
        show-source hi_method
        show-source Pry#rep     # source for Pry#rep method
        show-source Pry         # for Pry class
        show-source Pry -a      # for all Pry class definitions (all monkey patches)
        show-source Pry.foo -e  # for class of the return value of expression `Pry.foo`
        show-source Pry --super # for superclass of Pry (Object class)
        show-source Pry -d      # include documentation

        https://github.com/pry/pry/wiki/Source-browsing#wiki-Show_method
      BANNER

      def options(opt)
        opt.on :e, :eval, "evaluate the command's argument as a ruby " \
                          "expression and show the class its return value"
        opt.on :d, :doc, 'include documentation in the output'
        super(opt)
      end

      def process
        if opts.present?(:e)
          obj = target.eval(args.first)
          self.args = Array.new(1) { obj.is_a?(Module) ? obj.name : obj.class.name }
        end

        super
      end

      # The source for code_object prepared for display.
      def content_for(code_object)
        content = ''
        if opts.present?(:d)
          code = Code.new(
            render_doc_markup_for(code_object), start_line_for(code_object), :text
          )
          content += code.with_line_numbers(use_line_numbers?).to_s
          content += "\n"
        end

        code = Code.new(
          code_object.source || [], start_line_for(code_object)
        )
        content += code.with_line_numbers(use_line_numbers?).highlighted
        content
      end

      # process the markup (if necessary) and apply colors
      def render_doc_markup_for(code_object)
        docs = docs_for(code_object)

        if code_object.command?
          # command '--help' shouldn't use markup highlighting
          docs
        else
          if docs.empty?
            raise CommandError, "No docs found for: #{obj_name || 'current context'}"
          end

          process_comment_markup(docs)
        end
      end

      # Return docs for the code_object, adjusting for whether the code_object
      # has yard docs available, in which case it returns those.
      # (note we only have to check yard docs for modules since they can
      # have multiple docs, but methods can only be doc'd once so we
      # dont need to check them)
      def docs_for(code_object)
        if code_object.module_with_yard_docs?
          # yard docs
          code_object.yard_doc
        else
          # normal docs (i.e comments above method/module/command)
          code_object.doc
        end
      end

      # Which sections to include in the 'header', can toggle: :owner,
      # :signature and visibility.
      def header_options
        super.merge signature: true
      end

      # figure out start line of docs by back-calculating based on
      # number of lines in the comment and the start line of the code_object
      # @return [Fixnum] start line of docs
      def start_line_for(code_object)
        return 1 if code_object.command? || opts.present?(:'base-one')
        return 1 unless code_object.source_line

        code_object.source_line - code_object.doc.lines.count
      end
    end

    Pry::Commands.add_command(Pry::Command::ShowSource)
    Pry::Commands.alias_command 'show-method', 'show-source'
    Pry::Commands.alias_command '$', 'show-source'
    Pry::Commands.alias_command '?', 'show-source -d'
  end
end
