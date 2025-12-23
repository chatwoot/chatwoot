# frozen_string_literal: true

Dir[File.join(__dir__, 'http/**/*.rb')].sort.each do |file|
  require file
end
