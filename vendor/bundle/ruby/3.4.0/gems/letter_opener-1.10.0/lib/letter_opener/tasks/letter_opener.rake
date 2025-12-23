namespace :tmp do
  task :letter_opener do
    rm_rf Dir["tmp/letter_opener/[^.]*"], verbose: false
  end

  task clear: :letter_opener
end
