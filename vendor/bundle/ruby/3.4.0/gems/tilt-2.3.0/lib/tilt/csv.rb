# frozen_string_literal: true
require_relative 'template'
require 'csv'

module Tilt

  # CSV Template implementation. See:
  # http://ruby-doc.org/stdlib/libdoc/csv/rdoc/CSV.html
  #
  # == Example
  #
  #    # Example of csv template
  #    tpl = <<-EOS
  #      # header
  #      csv << ['NAME', 'ID']
  #
  #      # data rows
  #      @people.each do |person|
  #        csv << [person[:name], person[:id]]
  #      end
  #    EOS
  #
  #    @people = [
  #      {:name => "Joshua Peek", :id => 1},
  #      {:name => "Ryan Tomayko", :id => 2},
  #      {:name => "Simone Carletti", :id => 3}
  #    ]
  #
  #    template = Tilt::CSVTemplate.new { tpl }
  #    template.render(self)
  #
  class CSVTemplate < Template
    self.default_mime_type = 'text/csv'

    def prepare
      @outvar = @options.delete(:outvar) || '_csvout'
    end

    def precompiled_template(locals)
      <<-RUBY
        #{@outvar} = CSV.generate(**#{@options}) do |csv|
          #{@data}
        end
      RUBY
    end

    def precompiled(locals)
      source, offset = super
      [source, offset + 1]
    end

  end
end
