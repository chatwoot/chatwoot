module Crack
  module Util
    def snake_case(str)
      return str.downcase if str =~ /^[A-Z]+$/
      str.gsub(/([A-Z]+)(?=[A-Z][a-z]?)|\B[A-Z]/, '_\&') =~ /_*(.*)/
      return $+.downcase
    end

    def to_xml_attributes(hash)
      hash.map do |k,v|
        %{#{Crack::Util.snake_case(k.to_s).sub(/^(.{1,1})/) { |m| m.downcase }}="#{v.to_s.gsub('"', '&quot;')}"}
      end.join(' ')
    end

    extend self
  end
end