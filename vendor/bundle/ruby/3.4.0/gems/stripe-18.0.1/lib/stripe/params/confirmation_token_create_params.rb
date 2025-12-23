# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class ConfirmationTokenCreateParams < ::Stripe::RequestParams
    class PaymentMethodData < ::Stripe::RequestParams
      class AcssDebit < ::Stripe::RequestParams
        # Customer's bank account number.
        attr_accessor :account_number
        # Institution number of the customer's bank.
        attr_accessor :institution_number
        # Transit number of the customer's bank.
        attr_accessor :transit_number

        def initialize(account_number: nil, institution_number: nil, transit_number: nil)
          @account_number = account_number
          @institution_number = institution_number
          @transit_number = transit_number
        end
      end

      class Affirm < ::Stripe::RequestParams; end
      class AfterpayClearpay < ::Stripe::RequestParams; end
      class Alipay < ::Stripe::RequestParams; end
      class Alma < ::Stripe::RequestParams; end
      class AmazonPay < ::Stripe::RequestParams; end

      class AuBecsDebit < ::Stripe::RequestParams
        # The account number for the bank account.
        attr_accessor :account_number
        # Bank-State-Branch number of the bank account.
        attr_accessor :bsb_number

        def initialize(account_number: nil, bsb_number: nil)
          @account_number = account_number
          @bsb_number = bsb_number
        end
      end

      class BacsDebit < ::Stripe::RequestParams
        # Account number of the bank account that the funds will be debited from.
        attr_accessor :account_number
        # Sort code of the bank account. (e.g., `10-20-30`)
        attr_accessor :sort_code

        def initialize(account_number: nil, sort_code: nil)
          @account_number = account_number
          @sort_code = sort_code
        end
      end

      class Bancontact < ::Stripe::RequestParams; end
      class Billie < ::Stripe::RequestParams; end

      class BillingDetails < ::Stripe::RequestParams
        class Address < ::Stripe::RequestParams
          # City, district, suburb, town, or village.
          attr_accessor :city
          # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
          attr_accessor :country
          # Address line 1, such as the street, PO Box, or company name.
          attr_accessor :line1
          # Address line 2, such as the apartment, suite, unit, or building.
          attr_accessor :line2
          # ZIP or postal code.
          attr_accessor :postal_code
          # State, county, province, or region.
          attr_accessor :state

          def initialize(
            city: nil,
            country: nil,
            line1: nil,
            line2: nil,
            postal_code: nil,
            state: nil
          )
            @city = city
            @country = country
            @line1 = line1
            @line2 = line2
            @postal_code = postal_code
            @state = state
          end
        end
        # Billing address.
        attr_accessor :address
        # Email address.
        attr_accessor :email
        # Full name.
        attr_accessor :name
        # Billing phone number (including extension).
        attr_accessor :phone
        # Taxpayer identification number. Used only for transactions between LATAM buyers and non-LATAM sellers.
        attr_accessor :tax_id

        def initialize(address: nil, email: nil, name: nil, phone: nil, tax_id: nil)
          @address = address
          @email = email
          @name = name
          @phone = phone
          @tax_id = tax_id
        end
      end

      class Blik < ::Stripe::RequestParams; end

      class Boleto < ::Stripe::RequestParams
        # The tax ID of the customer (CPF for individual consumers or CNPJ for businesses consumers)
        attr_accessor :tax_id

        def initialize(tax_id: nil)
          @tax_id = tax_id
        end
      end

      class Cashapp < ::Stripe::RequestParams; end
      class Crypto < ::Stripe::RequestParams; end
      class CustomerBalance < ::Stripe::RequestParams; end

      class Eps < ::Stripe::RequestParams
        # The customer's bank.
        attr_accessor :bank

        def initialize(bank: nil)
          @bank = bank
        end
      end

      class Fpx < ::Stripe::RequestParams
        # Account holder type for FPX transaction
        attr_accessor :account_holder_type
        # The customer's bank.
        attr_accessor :bank

        def initialize(account_holder_type: nil, bank: nil)
          @account_holder_type = account_holder_type
          @bank = bank
        end
      end

      class Giropay < ::Stripe::RequestParams; end
      class Grabpay < ::Stripe::RequestParams; end

      class Ideal < ::Stripe::RequestParams
        # The customer's bank. Only use this parameter for existing customers. Don't use it for new customers.
        attr_accessor :bank

        def initialize(bank: nil)
          @bank = bank
        end
      end

      class InteracPresent < ::Stripe::RequestParams; end
      class KakaoPay < ::Stripe::RequestParams; end

      class Klarna < ::Stripe::RequestParams
        class Dob < ::Stripe::RequestParams
          # The day of birth, between 1 and 31.
          attr_accessor :day
          # The month of birth, between 1 and 12.
          attr_accessor :month
          # The four-digit year of birth.
          attr_accessor :year

          def initialize(day: nil, month: nil, year: nil)
            @day = day
            @month = month
            @year = year
          end
        end
        # Customer's date of birth
        attr_accessor :dob

        def initialize(dob: nil)
          @dob = dob
        end
      end

      class Konbini < ::Stripe::RequestParams; end
      class KrCard < ::Stripe::RequestParams; end
      class Link < ::Stripe::RequestParams; end
      class MbWay < ::Stripe::RequestParams; end
      class Mobilepay < ::Stripe::RequestParams; end
      class Multibanco < ::Stripe::RequestParams; end

      class NaverPay < ::Stripe::RequestParams
        # Whether to use Naver Pay points or a card to fund this transaction. If not provided, this defaults to `card`.
        attr_accessor :funding

        def initialize(funding: nil)
          @funding = funding
        end
      end

      class NzBankAccount < ::Stripe::RequestParams
        # The name on the bank account. Only required if the account holder name is different from the name of the authorized signatory collected in the PaymentMethod’s billing details.
        attr_accessor :account_holder_name
        # The account number for the bank account.
        attr_accessor :account_number
        # The numeric code for the bank account's bank.
        attr_accessor :bank_code
        # The numeric code for the bank account's bank branch.
        attr_accessor :branch_code
        # Attribute for param field reference
        attr_accessor :reference
        # The suffix of the bank account number.
        attr_accessor :suffix

        def initialize(
          account_holder_name: nil,
          account_number: nil,
          bank_code: nil,
          branch_code: nil,
          reference: nil,
          suffix: nil
        )
          @account_holder_name = account_holder_name
          @account_number = account_number
          @bank_code = bank_code
          @branch_code = branch_code
          @reference = reference
          @suffix = suffix
        end
      end

      class Oxxo < ::Stripe::RequestParams; end

      class P24 < ::Stripe::RequestParams
        # The customer's bank.
        attr_accessor :bank

        def initialize(bank: nil)
          @bank = bank
        end
      end

      class PayByBank < ::Stripe::RequestParams; end
      class Payco < ::Stripe::RequestParams; end
      class Paynow < ::Stripe::RequestParams; end
      class Paypal < ::Stripe::RequestParams; end
      class Pix < ::Stripe::RequestParams; end
      class Promptpay < ::Stripe::RequestParams; end

      class RadarOptions < ::Stripe::RequestParams
        # A [Radar Session](https://stripe.com/docs/radar/radar-session) is a snapshot of the browser metadata and device details that help Radar make more accurate predictions on your payments.
        attr_accessor :session

        def initialize(session: nil)
          @session = session
        end
      end

      class RevolutPay < ::Stripe::RequestParams; end
      class SamsungPay < ::Stripe::RequestParams; end
      class Satispay < ::Stripe::RequestParams; end

      class SepaDebit < ::Stripe::RequestParams
        # IBAN of the bank account.
        attr_accessor :iban

        def initialize(iban: nil)
          @iban = iban
        end
      end

      class Sofort < ::Stripe::RequestParams
        # Two-letter ISO code representing the country the bank account is located in.
        attr_accessor :country

        def initialize(country: nil)
          @country = country
        end
      end

      class Swish < ::Stripe::RequestParams; end
      class Twint < ::Stripe::RequestParams; end

      class UsBankAccount < ::Stripe::RequestParams
        # Account holder type: individual or company.
        attr_accessor :account_holder_type
        # Account number of the bank account.
        attr_accessor :account_number
        # Account type: checkings or savings. Defaults to checking if omitted.
        attr_accessor :account_type
        # The ID of a Financial Connections Account to use as a payment method.
        attr_accessor :financial_connections_account
        # Routing number of the bank account.
        attr_accessor :routing_number

        def initialize(
          account_holder_type: nil,
          account_number: nil,
          account_type: nil,
          financial_connections_account: nil,
          routing_number: nil
        )
          @account_holder_type = account_holder_type
          @account_number = account_number
          @account_type = account_type
          @financial_connections_account = financial_connections_account
          @routing_number = routing_number
        end
      end

      class WechatPay < ::Stripe::RequestParams; end
      class Zip < ::Stripe::RequestParams; end
      # If this is an `acss_debit` PaymentMethod, this hash contains details about the ACSS Debit payment method.
      attr_accessor :acss_debit
      # If this is an `affirm` PaymentMethod, this hash contains details about the Affirm payment method.
      attr_accessor :affirm
      # If this is an `AfterpayClearpay` PaymentMethod, this hash contains details about the AfterpayClearpay payment method.
      attr_accessor :afterpay_clearpay
      # If this is an `Alipay` PaymentMethod, this hash contains details about the Alipay payment method.
      attr_accessor :alipay
      # This field indicates whether this payment method can be shown again to its customer in a checkout flow. Stripe products such as Checkout and Elements use this field to determine whether a payment method can be shown as a saved payment method in a checkout flow. The field defaults to `unspecified`.
      attr_accessor :allow_redisplay
      # If this is a Alma PaymentMethod, this hash contains details about the Alma payment method.
      attr_accessor :alma
      # If this is a AmazonPay PaymentMethod, this hash contains details about the AmazonPay payment method.
      attr_accessor :amazon_pay
      # If this is an `au_becs_debit` PaymentMethod, this hash contains details about the bank account.
      attr_accessor :au_becs_debit
      # If this is a `bacs_debit` PaymentMethod, this hash contains details about the Bacs Direct Debit bank account.
      attr_accessor :bacs_debit
      # If this is a `bancontact` PaymentMethod, this hash contains details about the Bancontact payment method.
      attr_accessor :bancontact
      # If this is a `billie` PaymentMethod, this hash contains details about the Billie payment method.
      attr_accessor :billie
      # Billing information associated with the PaymentMethod that may be used or required by particular types of payment methods.
      attr_accessor :billing_details
      # If this is a `blik` PaymentMethod, this hash contains details about the BLIK payment method.
      attr_accessor :blik
      # If this is a `boleto` PaymentMethod, this hash contains details about the Boleto payment method.
      attr_accessor :boleto
      # If this is a `cashapp` PaymentMethod, this hash contains details about the Cash App Pay payment method.
      attr_accessor :cashapp
      # If this is a Crypto PaymentMethod, this hash contains details about the Crypto payment method.
      attr_accessor :crypto
      # If this is a `customer_balance` PaymentMethod, this hash contains details about the CustomerBalance payment method.
      attr_accessor :customer_balance
      # If this is an `eps` PaymentMethod, this hash contains details about the EPS payment method.
      attr_accessor :eps
      # If this is an `fpx` PaymentMethod, this hash contains details about the FPX payment method.
      attr_accessor :fpx
      # If this is a `giropay` PaymentMethod, this hash contains details about the Giropay payment method.
      attr_accessor :giropay
      # If this is a `grabpay` PaymentMethod, this hash contains details about the GrabPay payment method.
      attr_accessor :grabpay
      # If this is an `ideal` PaymentMethod, this hash contains details about the iDEAL payment method.
      attr_accessor :ideal
      # If this is an `interac_present` PaymentMethod, this hash contains details about the Interac Present payment method.
      attr_accessor :interac_present
      # If this is a `kakao_pay` PaymentMethod, this hash contains details about the Kakao Pay payment method.
      attr_accessor :kakao_pay
      # If this is a `klarna` PaymentMethod, this hash contains details about the Klarna payment method.
      attr_accessor :klarna
      # If this is a `konbini` PaymentMethod, this hash contains details about the Konbini payment method.
      attr_accessor :konbini
      # If this is a `kr_card` PaymentMethod, this hash contains details about the Korean Card payment method.
      attr_accessor :kr_card
      # If this is an `Link` PaymentMethod, this hash contains details about the Link payment method.
      attr_accessor :link
      # If this is a MB WAY PaymentMethod, this hash contains details about the MB WAY payment method.
      attr_accessor :mb_way
      # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
      attr_accessor :metadata
      # If this is a `mobilepay` PaymentMethod, this hash contains details about the MobilePay payment method.
      attr_accessor :mobilepay
      # If this is a `multibanco` PaymentMethod, this hash contains details about the Multibanco payment method.
      attr_accessor :multibanco
      # If this is a `naver_pay` PaymentMethod, this hash contains details about the Naver Pay payment method.
      attr_accessor :naver_pay
      # If this is an nz_bank_account PaymentMethod, this hash contains details about the nz_bank_account payment method.
      attr_accessor :nz_bank_account
      # If this is an `oxxo` PaymentMethod, this hash contains details about the OXXO payment method.
      attr_accessor :oxxo
      # If this is a `p24` PaymentMethod, this hash contains details about the P24 payment method.
      attr_accessor :p24
      # If this is a `pay_by_bank` PaymentMethod, this hash contains details about the PayByBank payment method.
      attr_accessor :pay_by_bank
      # If this is a `payco` PaymentMethod, this hash contains details about the PAYCO payment method.
      attr_accessor :payco
      # If this is a `paynow` PaymentMethod, this hash contains details about the PayNow payment method.
      attr_accessor :paynow
      # If this is a `paypal` PaymentMethod, this hash contains details about the PayPal payment method.
      attr_accessor :paypal
      # If this is a `pix` PaymentMethod, this hash contains details about the Pix payment method.
      attr_accessor :pix
      # If this is a `promptpay` PaymentMethod, this hash contains details about the PromptPay payment method.
      attr_accessor :promptpay
      # Options to configure Radar. See [Radar Session](https://stripe.com/docs/radar/radar-session) for more information.
      attr_accessor :radar_options
      # If this is a `revolut_pay` PaymentMethod, this hash contains details about the Revolut Pay payment method.
      attr_accessor :revolut_pay
      # If this is a `samsung_pay` PaymentMethod, this hash contains details about the SamsungPay payment method.
      attr_accessor :samsung_pay
      # If this is a `satispay` PaymentMethod, this hash contains details about the Satispay payment method.
      attr_accessor :satispay
      # If this is a `sepa_debit` PaymentMethod, this hash contains details about the SEPA debit bank account.
      attr_accessor :sepa_debit
      # If this is a `sofort` PaymentMethod, this hash contains details about the SOFORT payment method.
      attr_accessor :sofort
      # If this is a `swish` PaymentMethod, this hash contains details about the Swish payment method.
      attr_accessor :swish
      # If this is a TWINT PaymentMethod, this hash contains details about the TWINT payment method.
      attr_accessor :twint
      # The type of the PaymentMethod. An additional hash is included on the PaymentMethod with a name matching this value. It contains additional information specific to the PaymentMethod type.
      attr_accessor :type
      # If this is an `us_bank_account` PaymentMethod, this hash contains details about the US bank account payment method.
      attr_accessor :us_bank_account
      # If this is an `wechat_pay` PaymentMethod, this hash contains details about the wechat_pay payment method.
      attr_accessor :wechat_pay
      # If this is a `zip` PaymentMethod, this hash contains details about the Zip payment method.
      attr_accessor :zip

      def initialize(
        acss_debit: nil,
        affirm: nil,
        afterpay_clearpay: nil,
        alipay: nil,
        allow_redisplay: nil,
        alma: nil,
        amazon_pay: nil,
        au_becs_debit: nil,
        bacs_debit: nil,
        bancontact: nil,
        billie: nil,
        billing_details: nil,
        blik: nil,
        boleto: nil,
        cashapp: nil,
        crypto: nil,
        customer_balance: nil,
        eps: nil,
        fpx: nil,
        giropay: nil,
        grabpay: nil,
        ideal: nil,
        interac_present: nil,
        kakao_pay: nil,
        klarna: nil,
        konbini: nil,
        kr_card: nil,
        link: nil,
        mb_way: nil,
        metadata: nil,
        mobilepay: nil,
        multibanco: nil,
        naver_pay: nil,
        nz_bank_account: nil,
        oxxo: nil,
        p24: nil,
        pay_by_bank: nil,
        payco: nil,
        paynow: nil,
        paypal: nil,
        pix: nil,
        promptpay: nil,
        radar_options: nil,
        revolut_pay: nil,
        samsung_pay: nil,
        satispay: nil,
        sepa_debit: nil,
        sofort: nil,
        swish: nil,
        twint: nil,
        type: nil,
        us_bank_account: nil,
        wechat_pay: nil,
        zip: nil
      )
        @acss_debit = acss_debit
        @affirm = affirm
        @afterpay_clearpay = afterpay_clearpay
        @alipay = alipay
        @allow_redisplay = allow_redisplay
        @alma = alma
        @amazon_pay = amazon_pay
        @au_becs_debit = au_becs_debit
        @bacs_debit = bacs_debit
        @bancontact = bancontact
        @billie = billie
        @billing_details = billing_details
        @blik = blik
        @boleto = boleto
        @cashapp = cashapp
        @crypto = crypto
        @customer_balance = customer_balance
        @eps = eps
        @fpx = fpx
        @giropay = giropay
        @grabpay = grabpay
        @ideal = ideal
        @interac_present = interac_present
        @kakao_pay = kakao_pay
        @klarna = klarna
        @konbini = konbini
        @kr_card = kr_card
        @link = link
        @mb_way = mb_way
        @metadata = metadata
        @mobilepay = mobilepay
        @multibanco = multibanco
        @naver_pay = naver_pay
        @nz_bank_account = nz_bank_account
        @oxxo = oxxo
        @p24 = p24
        @pay_by_bank = pay_by_bank
        @payco = payco
        @paynow = paynow
        @paypal = paypal
        @pix = pix
        @promptpay = promptpay
        @radar_options = radar_options
        @revolut_pay = revolut_pay
        @samsung_pay = samsung_pay
        @satispay = satispay
        @sepa_debit = sepa_debit
        @sofort = sofort
        @swish = swish
        @twint = twint
        @type = type
        @us_bank_account = us_bank_account
        @wechat_pay = wechat_pay
        @zip = zip
      end
    end

    class PaymentMethodOptions < ::Stripe::RequestParams
      class Card < ::Stripe::RequestParams
        class Installments < ::Stripe::RequestParams
          class Plan < ::Stripe::RequestParams
            # For `fixed_count` installment plans, this is required. It represents the number of installment payments your customer will make to their credit card.
            attr_accessor :count
            # For `fixed_count` installment plans, this is required. It represents the interval between installment payments your customer will make to their credit card.
            # One of `month`.
            attr_accessor :interval
            # Type of installment plan, one of `fixed_count`, `bonus`, or `revolving`.
            attr_accessor :type

            def initialize(count: nil, interval: nil, type: nil)
              @count = count
              @interval = interval
              @type = type
            end
          end
          # The selected installment plan to use for this payment attempt.
          # This parameter can only be provided during confirmation.
          attr_accessor :plan

          def initialize(plan: nil)
            @plan = plan
          end
        end
        # Installment configuration for payments confirmed using this ConfirmationToken.
        attr_accessor :installments

        def initialize(installments: nil)
          @installments = installments
        end
      end
      # Configuration for any card payments confirmed using this ConfirmationToken.
      attr_accessor :card

      def initialize(card: nil)
        @card = card
      end
    end

    class Shipping < ::Stripe::RequestParams
      class Address < ::Stripe::RequestParams
        # City, district, suburb, town, or village.
        attr_accessor :city
        # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
        attr_accessor :country
        # Address line 1, such as the street, PO Box, or company name.
        attr_accessor :line1
        # Address line 2, such as the apartment, suite, unit, or building.
        attr_accessor :line2
        # ZIP or postal code.
        attr_accessor :postal_code
        # State, county, province, or region.
        attr_accessor :state

        def initialize(
          city: nil,
          country: nil,
          line1: nil,
          line2: nil,
          postal_code: nil,
          state: nil
        )
          @city = city
          @country = country
          @line1 = line1
          @line2 = line2
          @postal_code = postal_code
          @state = state
        end
      end
      # Shipping address
      attr_accessor :address
      # Recipient name.
      attr_accessor :name
      # Recipient phone (including extension)
      attr_accessor :phone

      def initialize(address: nil, name: nil, phone: nil)
        @address = address
        @name = name
        @phone = phone
      end
    end
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # ID of an existing PaymentMethod.
    attr_accessor :payment_method
    # If provided, this hash will be used to create a PaymentMethod.
    attr_accessor :payment_method_data
    # Payment-method-specific configuration for this ConfirmationToken.
    attr_accessor :payment_method_options
    # Return URL used to confirm the Intent.
    attr_accessor :return_url
    # Indicates that you intend to make future payments with this ConfirmationToken's payment method.
    #
    # The presence of this property will [attach the payment method](https://stripe.com/docs/payments/save-during-payment) to the PaymentIntent's Customer, if present, after the PaymentIntent is confirmed and any required actions from the user are complete.
    attr_accessor :setup_future_usage
    # Shipping information for this ConfirmationToken.
    attr_accessor :shipping

    def initialize(
      expand: nil,
      payment_method: nil,
      payment_method_data: nil,
      payment_method_options: nil,
      return_url: nil,
      setup_future_usage: nil,
      shipping: nil
    )
      @expand = expand
      @payment_method = payment_method
      @payment_method_data = payment_method_data
      @payment_method_options = payment_method_options
      @return_url = return_url
      @setup_future_usage = setup_future_usage
      @shipping = shipping
    end
  end
end
