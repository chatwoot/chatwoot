# frozen_string_literal: true

require "spec_helper"
require "fileutils"

class TestUser < TestModel
  validates :email, 'valid_email_2/email': true
end

class TestUserDotted < TestModel
  validates :email, 'valid_email_2/email': { disallow_dotted: true }
end

class TestUserSubaddressing < TestModel
  validates :email, 'valid_email_2/email': { disallow_subaddressing: true }
end

class TestUserMX < TestModel
  validates :email, 'valid_email_2/email': { mx: true }
end

class TestUserStrictMX < TestModel
  validates :email, 'valid_email_2/email': { strict_mx: true }
end

class TestUserMXDnsTimeout < TestModel
  validates :email, 'valid_email_2/email': { mx: true, dns_timeout: 10 }
end

class TestUserMXDnsFailingTimeout < TestModel
  validates :email, 'valid_email_2/email': { mx: true, dns_timeout: Float::MIN }
end

class TestUserMXDnsNameserver < TestModel
  validates :email, 'valid_email_2/email': { mx: true, dns_nameserver: ['8.8.8.8', '8.8.4.4'] }
end

class TestUserMXDnsFailingNameserver < TestModel
  validates :email, 'valid_email_2/email': { mx: true, dns_timeout: 0.1, dns_nameserver: '1.0.0.0' }
end

class TestUserDisallowDisposable < TestModel
  validates :email, 'valid_email_2/email': { disposable: true }
end

class TestUserDisallowDisposableDomain < TestModel
  validates :email, 'valid_email_2/email': { disposable_domain: true }
end

class TestUserDisallowDisposableWithWhitelist < TestModel
  validates :email, 'valid_email_2/email': { disposable_with_whitelist: true }
end

class TestUserDisallowDisposableDomainWithWhitelist < TestModel
  validates :email, 'valid_email_2/email': { disposable_domain_with_whitelist: true }
end

class TestUserDisallowBlacklisted < TestModel
  validates :email, 'valid_email_2/email': { blacklist: true }
end

class TestUserMessage < TestModel
  validates :email, 'valid_email_2/email': { message: "custom message" }
end

class TestUserMessageWithLambda < TestModel
  validates :email, 'valid_email_2/email': { message: -> { "custom message lambda" } }
end

class TestUserMessageWithProc < TestModel
  validates :email, 'valid_email_2/email': { message: Proc.new { "custom message proc" } }
end

class TestUserMultiple < TestModel
  validates :email, 'valid_email_2/email': { multiple: true }
end

describe ValidEmail2 do

  let(:disposable_domain) { ValidEmail2.disposable_emails.first }

  describe "basic validation" do
    subject(:user) { TestUser.new(email: "") }

    it "is valid" do
      user = TestUser.new(email: "foo@bar123.com")
      expect(user.valid?).to be_truthy
    end

    it "is invalid if email is empty" do
      expect(user.valid?).to be_truthy
    end

    it "is invalid if domain is missing" do
      user = TestUser.new(email: "foo@.com")
      expect(user.valid?).to be_falsey
    end

    %w[+ _ ! / \  ' `].each do |invalid_character|
      it "is invalid if email contains a \"#{invalid_character}\" character" do
        user = TestUser.new(email: "foo@google#{invalid_character}yahoo.com")
        expect(user.valid?).to be_falsey
      end
    end

    it "is invalid if address is malformed" do
      user = TestUser.new(email: "foo@bar")
      expect(user.valid?).to be_falsey
    end

    it "is invalid if Mail::AddressListsParser raises exception" do
      user = TestUser.new(email: "foo@gmail.com")
      expect(Mail::Address).to receive(:new).and_raise(Mail::Field::ParseError.new(nil, nil, nil))
      expect(user.valid?).to be_falsey
    end

    it "is invalid if the domain contains consecutive dots" do
      user = TestUser.new(email: "foo@bar..com")
      expect(user.valid?).to be_falsey
    end

    it "is invalid if the address contains consecutive dots" do
      user = TestUser.new(email: "foo..bar@gmail.com")
      expect(user.valid?).to be_falsey
    end

    it "is invalid if the address starts with a dot" do
      user = TestUser.new(email: ".foo@bar.com")
      expect(user.valid?).to be_falsey
    end

    it "is invalid if the local part of the address ends with a dot" do
      user = TestUser.new(email: "foo.@bar.com")
      expect(user.valid?).to be_falsey
    end

    it "is invalid if the email contains emoticons" do
      user = TestUser.new(email: "foo🙈@gmail.com")
      expect(user.valid?).to be_falsy
    end

    it "is invalid if the domain contains spaces" do
      user = TestUser.new(email: "user@gmail .com")
      expect(user.valid?).to be_falsy
    end

    it "is invalid if the domain contains a forward slash" do
      user = TestUser.new(email: "user@gm/ail.com")
      expect(user.valid?).to be_falsy
    end

    it "is invalid if the domain begins with a dash" do
      user = TestUser.new(email: "foo@-gmail.com")
      expect(user.valid?).to be_falsy
    end

    it "is invalid if the domain name ends with a dash" do
      user = TestUser.new(email: "foo@gmail-.com")
      expect(user.valid?).to be_falsy
    end
  end

  describe "with disposable validation" do
    it "is valid if it's not a disposable email" do
      user = TestUserDisallowDisposable.new(email: "foo@gmail.com")
      expect(user.valid?).to be_truthy
    end

    it "is valid if it just ends with a disposable domain" do
      user = TestUserDisallowDisposable.new(email: "foo@nondisposable-0-mail.com")
      expect(user.valid?).to be_truthy
    end

    context "with disposable domain" do
      it "is invalid with disposable domain" do
        user = TestUserDisallowDisposable.new(email: "foo@#{disposable_domain}")
        expect(user.valid?).to be_falsey
      end

      it "is invalid with disposable domain even without mx server check" do
        user = TestUserDisallowDisposableDomain.new(email: "foo@#{disposable_domain}")
        expect(user.valid?).to be_falsey
      end

      it "is invalid if the domain is a subdomain of a disposable domain" do
        user = TestUserDisallowDisposable.new(email: "foo@bar.#{disposable_domain}")
        expect(user.valid?).to be_falsey
      end

      it "allows example.com" do
        user = TestUserDisallowDisposable.new(email: "foo@example.com")
        expect(user.valid?).to be_truthy
      end
    end

    context "with domain that is not disposable but it's mx server is disposable" do
      let(:domain) { "sogetthis.com" }

      around do |example|
        ValidEmail2.disposable_emails.delete(domain)
        example.run
        ValidEmail2.disposable_emails << domain
      end

      it "is invalid" do
        user = TestUserDisallowDisposable.new(email: "foo@sogetthis.com")
        expect(user.valid?).to be_falsey
      end
    end

    describe "with whitelisted emails" do
      let(:whitelist_domain) { disposable_domain }
      let(:whitelist_file_path) { "config/whitelisted_email_domains.yml" }

      # Some of the specs below need to explictly set the whitelist var or it
      # may be cached to an empty set
      def set_whitelist
        ValidEmail2.instance_variable_set(
          :@whitelist,
          ValidEmail2.send(:load_if_exists, ValidEmail2::WHITELIST_FILE)
        )
      end

      after do
        FileUtils.rm(whitelist_file_path, force: true)
        set_whitelist
      end

      it "is invalid if the domain is disposable and not in the whitelist" do
        user = TestUserDisallowDisposableWithWhitelist.new(email: "foo@#{whitelist_domain}")
        expect(user.valid?).to be_falsey
      end

      it "is valid if the domain is disposable but in the whitelist" do
        File.open(whitelist_file_path, "w") { |f| f.write [whitelist_domain].to_yaml }
        set_whitelist
        user = TestUserDisallowDisposableWithWhitelist.new(email: "foo@#{whitelist_domain}")
        expect(user.valid?).to be_truthy
      end

      it "is invalid if the domain is a disposable_domain and not in the whitelist" do
        user = TestUserDisallowDisposableDomainWithWhitelist.new(email: "foo@#{whitelist_domain}")
        expect(user.valid?).to be_falsey
      end

      it "is valid if the domain is a disposable_domain but in the whitelist" do
        File.open(whitelist_file_path, "w") { |f| f.write [whitelist_domain].to_yaml }
        set_whitelist
        user = TestUserDisallowDisposableDomainWithWhitelist.new(email: "foo@#{whitelist_domain}")
        expect(user.valid?).to be_truthy
      end
    end
  end

  describe "with blacklist validation" do
    it "is valid if the domain is not blacklisted" do
      user = TestUserDisallowBlacklisted.new(email: "foo@gmail.com")
      expect(user.valid?).to be_truthy
    end

    it "is invalid if the domain is blacklisted" do
      user = TestUserDisallowBlacklisted.new(email: "foo@blacklisted-test.com")
      expect(user.valid?).to be_falsey
    end
  end

  describe "with mx validation" do
    it "is valid if mx records are found" do
      user = TestUserMX.new(email: "foo@gmail.com")
      expect(user.valid?).to be_truthy
    end

    it "is valid if A records are found" do
      user = TestUserMX.new(email: "foo@ghs.google.com")
      expect(user.valid?).to be_truthy
    end

    it "is invalid if no mx records are found" do
      user = TestUserMX.new(email: "foo@subdomain.gmail.com")
      expect(user.valid?).to be_falsey
    end

    it "is invalid if a null mx is found" do
      user = TestUserMX.new(email: "foo@gmail.de")
      expect(user.valid?).to be_falsey
    end
  end

  describe "with strict mx validation" do
    it "is valid if mx records are found" do
      user = TestUserStrictMX.new(email: "foo@gmail.com")
      expect(user.valid?).to be_truthy
    end

    it "is invalid if A records are found but no mx records are found" do
      user = TestUserStrictMX.new(email: "foo@ghs.google.com")
      expect(user.valid?).to be_falsey
    end

    it "is invalid if no mx records are found" do
      user = TestUserStrictMX.new(email: "foo@subdomain.gmail.com")
      expect(user.valid?).to be_falsey
    end

    it "is invalid if a null mx is found" do
      user = TestUserStrictMX.new(email: "foo@gmail.de")
      expect(user.valid?).to be_falsey
    end
  end

  describe "with mx validation and dns not hitting timeout" do
    it "is valid if mx records are found" do
      user = TestUserMXDnsTimeout.new(email: "foo@gmail.com")
      expect(user.valid?).to be_truthy
    end

    it "is valid if A records are found" do
      user = TestUserMXDnsTimeout.new(email: "foo@ghs.google.com")
      expect(user.valid?).to be_truthy
    end

    it "is invalid if no mx records are found" do
      user = TestUserMXDnsTimeout.new(email: "foo@subdomain.gmail.com")
      expect(user.valid?).to be_falsey
    end

    it "is invalid if a null mx is found" do
      user = TestUserMXDnsTimeout.new(email: "foo@gmail.de")
      expect(user.valid?).to be_falsey
    end
  end

  describe "with mx validation and dns hitting timeout" do
    it "is never valid even if mx records exist" do
      user = TestUserMXDnsFailingTimeout.new(email: "foo@gmail.com")
      expect(user.valid?).to be_falsey
    end

    it "is never valid even A records exist" do
      user = TestUserMXDnsFailingTimeout.new(email: "foo@ghs.google.com")
      expect(user.valid?).to be_falsey
    end

    it "is invalid if no mx records exist" do
      user = TestUserMXDnsFailingTimeout.new(email: "foo@subdomain.gmail.com")
      expect(user.valid?).to be_falsey
    end

    it "is invalid if a null mx exists" do
      user = TestUserMXDnsFailingTimeout.new(email: "foo@gmail.de")
      expect(user.valid?).to be_falsey
    end
  end

  describe "with mx validation and dns nameserver" do
    it "is valid if mx records are found" do
      user = TestUserMXDnsNameserver.new(email: "foo@gmail.com")
      expect(user.valid?).to be_truthy
    end

    it "is valid if A records are found" do
      user = TestUserMXDnsNameserver.new(email: "foo@ghs.google.com")
      expect(user.valid?).to be_truthy
    end

    it "is invalid if no mx records are found" do
      user = TestUserMXDnsNameserver.new(email: "foo@subdomain.gmail.com")
      expect(user.valid?).to be_falsey
    end

    it "is invalid if a null mx is found" do
      user = TestUserMXDnsNameserver.new(email: "foo@gmail.de")
      expect(user.valid?).to be_falsey
    end
  end

  describe "with mx validation and failing dns nameserver" do
    it "is never valid even if mx records exist" do
      user = TestUserMXDnsFailingNameserver.new(email: "foo@gmail.com")
      expect(user.valid?).to be_falsey
    end

    it "is never valid even A records exist" do
      user = TestUserMXDnsFailingNameserver.new(email: "foo@ghs.google.com")
      expect(user.valid?).to be_falsey
    end

    it "is invalid if no mx records exist" do
      user = TestUserMXDnsFailingNameserver.new(email: "foo@subdomain.gmail.com")
      expect(user.valid?).to be_falsey
    end

    it "is invalid if a null mx exists" do
      user = TestUserMXDnsFailingNameserver.new(email: "foo@gmail.de")
      expect(user.valid?).to be_falsey
    end
  end

  describe "with dotted validation" do
    it "is valid when address does not contain dots" do
      user = TestUserDotted.new(email: "johndoe@gmail.com")
      expect(user.valid?).to be_truthy
    end

    it "is invalid when address cotains dots" do
      user = TestUserDotted.new(email: "john.doe@gmail.com")
      expect(user.valid?).to be_falsey
    end
  end

  describe "with subaddress validation" do
    it "is valid when address does not contain subaddress" do
      user = TestUserSubaddressing.new(email: "foo@gmail.com")
      expect(user.valid?).to be_truthy
    end

    it "is invalid when address cotains subaddress" do
      user = TestUserSubaddressing.new(email: "foo+1@gmail.com")
      expect(user.valid?).to be_falsey
    end
  end

  context "when message is present" do
    describe "with custom error message" do
      it "supports settings a custom error message" do
        user = TestUserMessage.new(email: "fakeemail")
        user.valid?
        expect(user.errors.full_messages).to include("Email custom message")
      end
    end

    describe "with custom error message lambda" do
      it "supports settings a custom error message lambda" do
        user = TestUserMessageWithLambda.new(email: "fakeemail")
        user.valid?
        expect(user.errors.full_messages).to include("Email custom message lambda")
      end
    end

    describe "with custom error message proc" do
      it "supports settings a custom error message proc" do
        user = TestUserMessageWithProc.new(email: "fakeemail")
        user.valid?
        expect(user.errors.full_messages).to include("Email custom message proc")
      end
    end
  end

  describe "with multiple addresses" do
    it "tests each address for it's own" do
      user = TestUserMultiple.new(email: "foo@gmail.com, bar@gmail.com")
      expect(user.valid?).to be_truthy
    end

    it "tests each address from an array" do
      user = TestUserMultiple.new(email: %w[foo@gmail.com bar@gmail.com])
      expect(user.valid?).to be_truthy
    end

    context 'when one address is invalid' do
      it "fails for all" do
        user = TestUserMultiple.new(email: "foo@gmail.com, bar@123")
        expect(user.valid?).to be_falsey
      end
    end
  end

  describe "#dotted?" do
    it "is true when address local part contains a dot delimiter ('.')" do
      email = ValidEmail2::Address.new("john.doe@gmail.com")
      expect(email.dotted?).to be_truthy
    end

    it "is false when address local part contains a dot delimiter ('.')" do
      email = ValidEmail2::Address.new("johndoe@gmail.com")
      expect(email.dotted?).to be_falsey
    end
  end

  describe "#subaddressed?" do
    it "is true when address local part contains a recipient delimiter ('+')" do
      email = ValidEmail2::Address.new("foo+1@gmail.com")
      expect(email.subaddressed?).to be_truthy
    end

    it "is false when address local part contains a recipient delimiter ('+')" do
      email = ValidEmail2::Address.new("foo@gmail.com")
      expect(email.subaddressed?).to be_falsey
    end
  end
end
