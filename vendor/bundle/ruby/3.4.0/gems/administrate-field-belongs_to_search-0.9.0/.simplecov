SimpleCov.start 'rails' do
  add_group 'app', 'app'
  add_group 'lib', 'lib'

  refuse_coverage_drop

  formatter SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
  ])
end
