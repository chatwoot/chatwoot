class App
command :third do |c| c.action { |g,o,a| puts "third: #{a.join(',')}" } end
end
