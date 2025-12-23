# require "sdoc"
require "rdoc/task"
require_relative "../lib/net/imap"
require 'rdoc/rdoc' unless defined?(RDoc::Markup::ToHtml)

module RDoc::Generator
  module NetIMAP

    module RemoveRedundantParens
      def param_seq
        super.sub(/^\(\)\s*/, "")
      end
    end

    # See https://github.com/ruby/rdoc/pull/936
    module FixSectionComments
      def markup(text)
        @store ||= @parent&.store
        super
      end
      def description; markup comment end
      def comment;     super || @comments&.first end
      def parse(_comment_location = nil) super() end
    end

    # render "[label] data" lists as tables.  adapted from "hanna-nouveau" gem.
    module LabelListTable
      def list_item_start(list_item, list_type)
        case list_type
        when :NOTE
          %(<tr><td class='label'>#{Array(list_item.label).map{|label| to_html(label)}.join("<br />")}</td><td>)
        else
          super
        end
      end

      def list_end_for(list_type)
        case list_type
        when :NOTE then
          "</td></tr>"
        else
          super
        end
      end
    end

  end
end

class RDoc::AnyMethod
  prepend RDoc::Generator::NetIMAP::RemoveRedundantParens
end

class RDoc::Context::Section
  prepend RDoc::Generator::NetIMAP::FixSectionComments
end

class RDoc::Markup::ToHtml
  LIST_TYPE_TO_HTML[:NOTE] = ['<table class="rdoc-list note-list"><tbody>', '</tbody></table>']
  prepend RDoc::Generator::NetIMAP::LabelListTable
end

RDoc::Task.new do |doc|
  doc.main       = "README.md"
  doc.title      = "net-imap #{Net::IMAP::VERSION}"
  doc.rdoc_dir   = "doc"
  doc.rdoc_files = FileList.new %w[lib/**/*.rb *.rdoc *.md]
  doc.options << "--template-stylesheets" << "docs/styles.css"
  # doc.generator  = "hanna"
end
