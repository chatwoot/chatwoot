module LetterOpener
  class Railtie < Rails::Railtie
    initializer "letter_opener.add_delivery_method" do
      ActiveSupport.on_load :action_mailer do
        ActionMailer::Base.add_delivery_method(
          :letter_opener,
          LetterOpener::DeliveryMethod
        )
      end
    end

    rake_tasks do
      load 'letter_opener/tasks/letter_opener.rake'
    end
  end
end
