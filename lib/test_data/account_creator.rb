module TestData
  class AccountCreator
    DATA_FILE = 'tmp/test_data_account_ids.txt'.freeze

    def self.create!(id)
      company_name = generate_company_name
      domain       = generate_domain(company_name)
      account      = Account.create!(
        id:          id,
        name:        company_name,
        domain:      domain,
        created_at:  Faker::Time.between(from: 2.years.ago, to: 6.months.ago)
      )
      persist_account_id(account.id)
      account
    end

    private_class_method

    def self.generate_company_name
      "#{Faker::Company.name} #{Constants::COMPANY_TYPES.sample}"
    end

    def self.generate_domain(company_name)
      "#{company_name.parameterize}.#{Constants::DOMAIN_EXTENSIONS.sample}"
    end

    def self.persist_account_id(account_id)
      FileUtils.mkdir_p('tmp') unless Dir.exist?('tmp')
      File.open(DATA_FILE, 'a') do |file|
        file.write("#{account_id},")
      end
    end
  end
end
