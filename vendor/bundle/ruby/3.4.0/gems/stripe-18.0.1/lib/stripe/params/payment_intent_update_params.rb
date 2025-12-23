# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class PaymentIntentUpdateParams < ::Stripe::RequestParams
    class AmountDetails < ::Stripe::RequestParams
      class LineItem < ::Stripe::RequestParams
        class PaymentMethodOptions < ::Stripe::RequestParams
          class Card < ::Stripe::RequestParams
            # Identifier that categorizes the items being purchased using a standardized commodity scheme such as (but not limited to) UNSPSC, NAICS, NAPCS, etc.
            attr_accessor :commodity_code

            def initialize(commodity_code: nil)
              @commodity_code = commodity_code
            end
          end

          class CardPresent < ::Stripe::RequestParams
            # Identifier that categorizes the items being purchased using a standardized commodity scheme such as (but not limited to) UNSPSC, NAICS, NAPCS, etc.
            attr_accessor :commodity_code

            def initialize(commodity_code: nil)
              @commodity_code = commodity_code
            end
          end

          class Klarna < ::Stripe::RequestParams
            # URL to an image for the product. Max length, 4096 characters.
            attr_accessor :image_url
            # URL to the product page. Max length, 4096 characters.
            attr_accessor :product_url
            # Unique reference for this line item to correlate it with your system’s internal records. The field is displayed in the Klarna Consumer App if passed.
            attr_accessor :reference
            # Reference for the subscription this line item is for.
            attr_accessor :subscription_reference

            def initialize(
              image_url: nil,
              product_url: nil,
              reference: nil,
              subscription_reference: nil
            )
              @image_url = image_url
              @product_url = product_url
              @reference = reference
              @subscription_reference = subscription_reference
            end
          end

          class Paypal < ::Stripe::RequestParams
            # Type of the line item.
            attr_accessor :category
            # Description of the line item.
            attr_accessor :description
            # The Stripe account ID of the connected account that sells the item.
            attr_accessor :sold_by

            def initialize(category: nil, description: nil, sold_by: nil)
              @category = category
              @description = description
              @sold_by = sold_by
            end
          end
          # This sub-hash contains line item details that are specific to `card` payment method."
          attr_accessor :card
          # This sub-hash contains line item details that are specific to `card_present` payment method."
          attr_accessor :card_present
          # This sub-hash contains line item details that are specific to `klarna` payment method."
          attr_accessor :klarna
          # This sub-hash contains line item details that are specific to `paypal` payment method."
          attr_accessor :paypal

          def initialize(card: nil, card_present: nil, klarna: nil, paypal: nil)
            @card = card
            @card_present = card_present
            @klarna = klarna
            @paypal = paypal
          end
        end

        class Tax < ::Stripe::RequestParams
          # The total amount of tax on a single line item represented in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal). Required for L3 rates. An integer greater than or equal to 0.
          #
          # This field is mutually exclusive with the `amount_details[tax][total_tax_amount]` field.
          attr_accessor :total_tax_amount

          def initialize(total_tax_amount: nil)
            @total_tax_amount = total_tax_amount
          end
        end
        # The discount applied on this line item represented in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal). An integer greater than 0.
        #
        # This field is mutually exclusive with the `amount_details[discount_amount]` field.
        attr_accessor :discount_amount
        # Payment method-specific information for line items.
        attr_accessor :payment_method_options
        # The product code of the line item, such as an SKU. Required for L3 rates. At most 12 characters long.
        attr_accessor :product_code
        # The product name of the line item. Required for L3 rates. At most 1024 characters long.
        #
        # For Cards, this field is truncated to 26 alphanumeric characters before being sent to the card networks. For Paypal, this field is truncated to 127 characters.
        attr_accessor :product_name
        # The quantity of items. Required for L3 rates. An integer greater than 0.
        attr_accessor :quantity
        # Contains information about the tax on the item.
        attr_accessor :tax
        # The unit cost of the line item represented in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal). Required for L3 rates. An integer greater than or equal to 0.
        attr_accessor :unit_cost
        # A unit of measure for the line item, such as gallons, feet, meters, etc.
        attr_accessor :unit_of_measure

        def initialize(
          discount_amount: nil,
          payment_method_options: nil,
          product_code: nil,
          product_name: nil,
          quantity: nil,
          tax: nil,
          unit_cost: nil,
          unit_of_measure: nil
        )
          @discount_amount = discount_amount
          @payment_method_options = payment_method_options
          @product_code = product_code
          @product_name = product_name
          @quantity = quantity
          @tax = tax
          @unit_cost = unit_cost
          @unit_of_measure = unit_of_measure
        end
      end

      class Shipping < ::Stripe::RequestParams
        # If a physical good is being shipped, the cost of shipping represented in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal). An integer greater than or equal to 0.
        attr_accessor :amount
        # If a physical good is being shipped, the postal code of where it is being shipped from. At most 10 alphanumeric characters long, hyphens are allowed.
        attr_accessor :from_postal_code
        # If a physical good is being shipped, the postal code of where it is being shipped to. At most 10 alphanumeric characters long, hyphens are allowed.
        attr_accessor :to_postal_code

        def initialize(amount: nil, from_postal_code: nil, to_postal_code: nil)
          @amount = amount
          @from_postal_code = from_postal_code
          @to_postal_code = to_postal_code
        end
      end

      class Tax < ::Stripe::RequestParams
        # The total amount of tax on the transaction represented in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal). Required for L2 rates. An integer greater than or equal to 0.
        #
        # This field is mutually exclusive with the `amount_details[line_items][#][tax][total_tax_amount]` field.
        attr_accessor :total_tax_amount

        def initialize(total_tax_amount: nil)
          @total_tax_amount = total_tax_amount
        end
      end
      # The total discount applied on the transaction represented in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal). An integer greater than 0.
      #
      # This field is mutually exclusive with the `amount_details[line_items][#][discount_amount]` field.
      attr_accessor :discount_amount
      # A list of line items, each containing information about a product in the PaymentIntent. There is a maximum of 100 line items.
      attr_accessor :line_items
      # Contains information about the shipping portion of the amount.
      attr_accessor :shipping
      # Contains information about the tax portion of the amount.
      attr_accessor :tax

      def initialize(discount_amount: nil, line_items: nil, shipping: nil, tax: nil)
        @discount_amount = discount_amount
        @line_items = line_items
        @shipping = shipping
        @tax = tax
      end
    end

    class Hooks < ::Stripe::RequestParams
      class Inputs < ::Stripe::RequestParams
        class Tax < ::Stripe::RequestParams
          # The [TaxCalculation](https://stripe.com/docs/api/tax/calculations) id
          attr_accessor :calculation

          def initialize(calculation: nil)
            @calculation = calculation
          end
        end
        # Tax arguments for automations
        attr_accessor :tax

        def initialize(tax: nil)
          @tax = tax
        end
      end
      # Arguments passed in automations
      attr_accessor :inputs

      def initialize(inputs: nil)
        @inputs = inputs
      end
    end

    class PaymentDetails < ::Stripe::RequestParams
      # A unique value to identify the customer. This field is available only for card payments.
      #
      # This field is truncated to 25 alphanumeric characters, excluding spaces, before being sent to card networks.
      attr_accessor :customer_reference
      # A unique value assigned by the business to identify the transaction. Required for L2 and L3 rates.
      #
      # Required when the Payment Method Types array contains `card`, including when [automatic_payment_methods.enabled](/api/payment_intents/create#create_payment_intent-automatic_payment_methods-enabled) is set to `true`.
      #
      # For Cards, this field is truncated to 25 alphanumeric characters, excluding spaces, before being sent to card networks. For Klarna, this field is truncated to 255 characters and is visible to customers when they view the order in the Klarna app.
      attr_accessor :order_reference

      def initialize(customer_reference: nil, order_reference: nil)
        @customer_reference = customer_reference
        @order_reference = order_reference
      end
    end

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
      class AcssDebit < ::Stripe::RequestParams
        class MandateOptions < ::Stripe::RequestParams
          # A URL for custom mandate text to render during confirmation step.
          # The URL will be rendered with additional GET parameters `payment_intent` and `payment_intent_client_secret` when confirming a Payment Intent,
          # or `setup_intent` and `setup_intent_client_secret` when confirming a Setup Intent.
          attr_accessor :custom_mandate_url
          # Description of the mandate interval. Only required if 'payment_schedule' parameter is 'interval' or 'combined'.
          attr_accessor :interval_description
          # Payment schedule for the mandate.
          attr_accessor :payment_schedule
          # Transaction type of the mandate.
          attr_accessor :transaction_type

          def initialize(
            custom_mandate_url: nil,
            interval_description: nil,
            payment_schedule: nil,
            transaction_type: nil
          )
            @custom_mandate_url = custom_mandate_url
            @interval_description = interval_description
            @payment_schedule = payment_schedule
            @transaction_type = transaction_type
          end
        end
        # Additional fields for Mandate creation
        attr_accessor :mandate_options
        # Indicates that you intend to make future payments with this PaymentIntent's payment method.
        #
        # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
        #
        # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
        #
        # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
        #
        # If you've already set `setup_future_usage` and you're performing a request using a publishable key, you can only update the value from `on_session` to `off_session`.
        attr_accessor :setup_future_usage
        # Controls when Stripe will attempt to debit the funds from the customer's account. The date must be a string in YYYY-MM-DD format. The date must be in the future and between 3 and 15 calendar days from now.
        attr_accessor :target_date
        # Bank account verification method.
        attr_accessor :verification_method

        def initialize(
          mandate_options: nil,
          setup_future_usage: nil,
          target_date: nil,
          verification_method: nil
        )
          @mandate_options = mandate_options
          @setup_future_usage = setup_future_usage
          @target_date = target_date
          @verification_method = verification_method
        end
      end

      class Affirm < ::Stripe::RequestParams
        # Controls when the funds are captured from the customer's account.
        #
        # If provided, this parameter overrides the behavior of the top-level [capture_method](/api/payment_intents/update#update_payment_intent-capture_method) for this payment method type when finalizing the payment with this payment method type.
        #
        # If `capture_method` is already set on the PaymentIntent, providing an empty value for this parameter unsets the stored value for this payment method type.
        attr_accessor :capture_method
        # Preferred language of the Affirm authorization page that the customer is redirected to.
        attr_accessor :preferred_locale
        # Indicates that you intend to make future payments with this PaymentIntent's payment method.
        #
        # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
        #
        # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
        #
        # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
        #
        # If you've already set `setup_future_usage` and you're performing a request using a publishable key, you can only update the value from `on_session` to `off_session`.
        attr_accessor :setup_future_usage

        def initialize(capture_method: nil, preferred_locale: nil, setup_future_usage: nil)
          @capture_method = capture_method
          @preferred_locale = preferred_locale
          @setup_future_usage = setup_future_usage
        end
      end

      class AfterpayClearpay < ::Stripe::RequestParams
        # Controls when the funds are captured from the customer's account.
        #
        # If provided, this parameter overrides the behavior of the top-level [capture_method](/api/payment_intents/update#update_payment_intent-capture_method) for this payment method type when finalizing the payment with this payment method type.
        #
        # If `capture_method` is already set on the PaymentIntent, providing an empty value for this parameter unsets the stored value for this payment method type.
        attr_accessor :capture_method
        # An internal identifier or reference that this payment corresponds to. You must limit the identifier to 128 characters, and it can only contain letters, numbers, underscores, backslashes, and dashes.
        # This field differs from the statement descriptor and item name.
        attr_accessor :reference
        # Indicates that you intend to make future payments with this PaymentIntent's payment method.
        #
        # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
        #
        # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
        #
        # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
        #
        # If you've already set `setup_future_usage` and you're performing a request using a publishable key, you can only update the value from `on_session` to `off_session`.
        attr_accessor :setup_future_usage

        def initialize(capture_method: nil, reference: nil, setup_future_usage: nil)
          @capture_method = capture_method
          @reference = reference
          @setup_future_usage = setup_future_usage
        end
      end

      class Alipay < ::Stripe::RequestParams
        # Indicates that you intend to make future payments with this PaymentIntent's payment method.
        #
        # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
        #
        # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
        #
        # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
        #
        # If you've already set `setup_future_usage` and you're performing a request using a publishable key, you can only update the value from `on_session` to `off_session`.
        attr_accessor :setup_future_usage

        def initialize(setup_future_usage: nil)
          @setup_future_usage = setup_future_usage
        end
      end

      class Alma < ::Stripe::RequestParams
        # Controls when the funds are captured from the customer's account.
        #
        # If provided, this parameter overrides the behavior of the top-level [capture_method](/api/payment_intents/update#update_payment_intent-capture_method) for this payment method type when finalizing the payment with this payment method type.
        #
        # If `capture_method` is already set on the PaymentIntent, providing an empty value for this parameter unsets the stored value for this payment method type.
        attr_accessor :capture_method

        def initialize(capture_method: nil)
          @capture_method = capture_method
        end
      end

      class AmazonPay < ::Stripe::RequestParams
        # Controls when the funds are captured from the customer's account.
        #
        # If provided, this parameter overrides the behavior of the top-level [capture_method](/api/payment_intents/update#update_payment_intent-capture_method) for this payment method type when finalizing the payment with this payment method type.
        #
        # If `capture_method` is already set on the PaymentIntent, providing an empty value for this parameter unsets the stored value for this payment method type.
        attr_accessor :capture_method
        # Indicates that you intend to make future payments with this PaymentIntent's payment method.
        #
        # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
        #
        # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
        #
        # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
        attr_accessor :setup_future_usage

        def initialize(capture_method: nil, setup_future_usage: nil)
          @capture_method = capture_method
          @setup_future_usage = setup_future_usage
        end
      end

      class AuBecsDebit < ::Stripe::RequestParams
        # Indicates that you intend to make future payments with this PaymentIntent's payment method.
        #
        # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
        #
        # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
        #
        # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
        #
        # If you've already set `setup_future_usage` and you're performing a request using a publishable key, you can only update the value from `on_session` to `off_session`.
        attr_accessor :setup_future_usage
        # Controls when Stripe will attempt to debit the funds from the customer's account. The date must be a string in YYYY-MM-DD format. The date must be in the future and between 3 and 15 calendar days from now.
        attr_accessor :target_date

        def initialize(setup_future_usage: nil, target_date: nil)
          @setup_future_usage = setup_future_usage
          @target_date = target_date
        end
      end

      class BacsDebit < ::Stripe::RequestParams
        class MandateOptions < ::Stripe::RequestParams
          # Prefix used to generate the Mandate reference. Must be at most 12 characters long. Must consist of only uppercase letters, numbers, spaces, or the following special characters: '/', '_', '-', '&', '.'. Cannot begin with 'DDIC' or 'STRIPE'.
          attr_accessor :reference_prefix

          def initialize(reference_prefix: nil)
            @reference_prefix = reference_prefix
          end
        end
        # Additional fields for Mandate creation
        attr_accessor :mandate_options
        # Indicates that you intend to make future payments with this PaymentIntent's payment method.
        #
        # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
        #
        # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
        #
        # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
        #
        # If you've already set `setup_future_usage` and you're performing a request using a publishable key, you can only update the value from `on_session` to `off_session`.
        attr_accessor :setup_future_usage
        # Controls when Stripe will attempt to debit the funds from the customer's account. The date must be a string in YYYY-MM-DD format. The date must be in the future and between 3 and 15 calendar days from now.
        attr_accessor :target_date

        def initialize(mandate_options: nil, setup_future_usage: nil, target_date: nil)
          @mandate_options = mandate_options
          @setup_future_usage = setup_future_usage
          @target_date = target_date
        end
      end

      class Bancontact < ::Stripe::RequestParams
        # Preferred language of the Bancontact authorization page that the customer is redirected to.
        attr_accessor :preferred_language
        # Indicates that you intend to make future payments with this PaymentIntent's payment method.
        #
        # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
        #
        # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
        #
        # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
        #
        # If you've already set `setup_future_usage` and you're performing a request using a publishable key, you can only update the value from `on_session` to `off_session`.
        attr_accessor :setup_future_usage

        def initialize(preferred_language: nil, setup_future_usage: nil)
          @preferred_language = preferred_language
          @setup_future_usage = setup_future_usage
        end
      end

      class Billie < ::Stripe::RequestParams
        # Controls when the funds are captured from the customer's account.
        #
        # If provided, this parameter overrides the behavior of the top-level [capture_method](/api/payment_intents/update#update_payment_intent-capture_method) for this payment method type when finalizing the payment with this payment method type.
        #
        # If `capture_method` is already set on the PaymentIntent, providing an empty value for this parameter unsets the stored value for this payment method type.
        attr_accessor :capture_method

        def initialize(capture_method: nil)
          @capture_method = capture_method
        end
      end

      class Blik < ::Stripe::RequestParams
        # The 6-digit BLIK code that a customer has generated using their banking application. Can only be set on confirmation.
        attr_accessor :code
        # Indicates that you intend to make future payments with this PaymentIntent's payment method.
        #
        # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
        #
        # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
        #
        # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
        #
        # If you've already set `setup_future_usage` and you're performing a request using a publishable key, you can only update the value from `on_session` to `off_session`.
        attr_accessor :setup_future_usage

        def initialize(code: nil, setup_future_usage: nil)
          @code = code
          @setup_future_usage = setup_future_usage
        end
      end

      class Boleto < ::Stripe::RequestParams
        # The number of calendar days before a Boleto voucher expires. For example, if you create a Boleto voucher on Monday and you set expires_after_days to 2, the Boleto invoice will expire on Wednesday at 23:59 America/Sao_Paulo time.
        attr_accessor :expires_after_days
        # Indicates that you intend to make future payments with this PaymentIntent's payment method.
        #
        # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
        #
        # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
        #
        # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
        #
        # If you've already set `setup_future_usage` and you're performing a request using a publishable key, you can only update the value from `on_session` to `off_session`.
        attr_accessor :setup_future_usage

        def initialize(expires_after_days: nil, setup_future_usage: nil)
          @expires_after_days = expires_after_days
          @setup_future_usage = setup_future_usage
        end
      end

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
          # Setting to true enables installments for this PaymentIntent.
          # This will cause the response to contain a list of available installment plans.
          # Setting to false will prevent any selected plan from applying to a charge.
          attr_accessor :enabled
          # The selected installment plan to use for this payment attempt.
          # This parameter can only be provided during confirmation.
          attr_accessor :plan

          def initialize(enabled: nil, plan: nil)
            @enabled = enabled
            @plan = plan
          end
        end

        class MandateOptions < ::Stripe::RequestParams
          # Amount to be charged for future payments.
          attr_accessor :amount
          # One of `fixed` or `maximum`. If `fixed`, the `amount` param refers to the exact amount to be charged in future payments. If `maximum`, the amount charged can be up to the value passed for the `amount` param.
          attr_accessor :amount_type
          # A description of the mandate or subscription that is meant to be displayed to the customer.
          attr_accessor :description
          # End date of the mandate or subscription. If not provided, the mandate will be active until canceled. If provided, end date should be after start date.
          attr_accessor :end_date
          # Specifies payment frequency. One of `day`, `week`, `month`, `year`, or `sporadic`.
          attr_accessor :interval
          # The number of intervals between payments. For example, `interval=month` and `interval_count=3` indicates one payment every three months. Maximum of one year interval allowed (1 year, 12 months, or 52 weeks). This parameter is optional when `interval=sporadic`.
          attr_accessor :interval_count
          # Unique identifier for the mandate or subscription.
          attr_accessor :reference
          # Start date of the mandate or subscription. Start date should not be lesser than yesterday.
          attr_accessor :start_date
          # Specifies the type of mandates supported. Possible values are `india`.
          attr_accessor :supported_types

          def initialize(
            amount: nil,
            amount_type: nil,
            description: nil,
            end_date: nil,
            interval: nil,
            interval_count: nil,
            reference: nil,
            start_date: nil,
            supported_types: nil
          )
            @amount = amount
            @amount_type = amount_type
            @description = description
            @end_date = end_date
            @interval = interval
            @interval_count = interval_count
            @reference = reference
            @start_date = start_date
            @supported_types = supported_types
          end
        end

        class ThreeDSecure < ::Stripe::RequestParams
          class NetworkOptions < ::Stripe::RequestParams
            class CartesBancaires < ::Stripe::RequestParams
              # The cryptogram calculation algorithm used by the card Issuer's ACS
              # to calculate the Authentication cryptogram. Also known as `cavvAlgorithm`.
              # messageExtension: CB-AVALGO
              attr_accessor :cb_avalgo
              # The exemption indicator returned from Cartes Bancaires in the ARes.
              # message extension: CB-EXEMPTION; string (4 characters)
              # This is a 3 byte bitmap (low significant byte first and most significant
              # bit first) that has been Base64 encoded
              attr_accessor :cb_exemption
              # The risk score returned from Cartes Bancaires in the ARes.
              # message extension: CB-SCORE; numeric value 0-99
              attr_accessor :cb_score

              def initialize(cb_avalgo: nil, cb_exemption: nil, cb_score: nil)
                @cb_avalgo = cb_avalgo
                @cb_exemption = cb_exemption
                @cb_score = cb_score
              end
            end
            # Cartes Bancaires-specific 3DS fields.
            attr_accessor :cartes_bancaires

            def initialize(cartes_bancaires: nil)
              @cartes_bancaires = cartes_bancaires
            end
          end
          # The `transStatus` returned from the card Issuer’s ACS in the ARes.
          attr_accessor :ares_trans_status
          # The cryptogram, also known as the "authentication value" (AAV, CAVV or
          # AEVV). This value is 20 bytes, base64-encoded into a 28-character string.
          # (Most 3D Secure providers will return the base64-encoded version, which
          # is what you should specify here.)
          attr_accessor :cryptogram
          # The Electronic Commerce Indicator (ECI) is returned by your 3D Secure
          # provider and indicates what degree of authentication was performed.
          attr_accessor :electronic_commerce_indicator
          # The exemption requested via 3DS and accepted by the issuer at authentication time.
          attr_accessor :exemption_indicator
          # Network specific 3DS fields. Network specific arguments require an
          # explicit card brand choice. The parameter `payment_method_options.card.network``
          # must be populated accordingly
          attr_accessor :network_options
          # The challenge indicator (`threeDSRequestorChallengeInd`) which was requested in the
          # AReq sent to the card Issuer's ACS. A string containing 2 digits from 01-99.
          attr_accessor :requestor_challenge_indicator
          # For 3D Secure 1, the XID. For 3D Secure 2, the Directory Server
          # Transaction ID (dsTransID).
          attr_accessor :transaction_id
          # The version of 3D Secure that was performed.
          attr_accessor :version

          def initialize(
            ares_trans_status: nil,
            cryptogram: nil,
            electronic_commerce_indicator: nil,
            exemption_indicator: nil,
            network_options: nil,
            requestor_challenge_indicator: nil,
            transaction_id: nil,
            version: nil
          )
            @ares_trans_status = ares_trans_status
            @cryptogram = cryptogram
            @electronic_commerce_indicator = electronic_commerce_indicator
            @exemption_indicator = exemption_indicator
            @network_options = network_options
            @requestor_challenge_indicator = requestor_challenge_indicator
            @transaction_id = transaction_id
            @version = version
          end
        end
        # Controls when the funds are captured from the customer's account.
        #
        # If provided, this parameter overrides the behavior of the top-level [capture_method](/api/payment_intents/update#update_payment_intent-capture_method) for this payment method type when finalizing the payment with this payment method type.
        #
        # If `capture_method` is already set on the PaymentIntent, providing an empty value for this parameter unsets the stored value for this payment method type.
        attr_accessor :capture_method
        # A single-use `cvc_update` Token that represents a card CVC value. When provided, the CVC value will be verified during the card payment attempt. This parameter can only be provided during confirmation.
        attr_accessor :cvc_token
        # Installment configuration for payments attempted on this PaymentIntent.
        #
        # For more information, see the [installments integration guide](https://stripe.com/docs/payments/installments).
        attr_accessor :installments
        # Configuration options for setting up an eMandate for cards issued in India.
        attr_accessor :mandate_options
        # When specified, this parameter indicates that a transaction will be marked
        # as MOTO (Mail Order Telephone Order) and thus out of scope for SCA. This
        # parameter can only be provided during confirmation.
        attr_accessor :moto
        # Selected network to process this PaymentIntent on. Depends on the available networks of the card attached to the PaymentIntent. Can be only set confirm-time.
        attr_accessor :network
        # Request ability to [capture beyond the standard authorization validity window](https://stripe.com/docs/payments/extended-authorization) for this PaymentIntent.
        attr_accessor :request_extended_authorization
        # Request ability to [increment the authorization](https://stripe.com/docs/payments/incremental-authorization) for this PaymentIntent.
        attr_accessor :request_incremental_authorization
        # Request ability to make [multiple captures](https://stripe.com/docs/payments/multicapture) for this PaymentIntent.
        attr_accessor :request_multicapture
        # Request ability to [overcapture](https://stripe.com/docs/payments/overcapture) for this PaymentIntent.
        attr_accessor :request_overcapture
        # We strongly recommend that you rely on our SCA Engine to automatically prompt your customers for authentication based on risk level and [other requirements](https://stripe.com/docs/strong-customer-authentication). However, if you wish to request 3D Secure based on logic from your own fraud engine, provide this option. If not provided, this value defaults to `automatic`. Read our guide on [manually requesting 3D Secure](https://stripe.com/docs/payments/3d-secure/authentication-flow#manual-three-ds) for more information on how this configuration interacts with Radar and our SCA Engine.
        attr_accessor :request_three_d_secure
        # When enabled, using a card that is attached to a customer will require the CVC to be provided again (i.e. using the cvc_token parameter).
        attr_accessor :require_cvc_recollection
        # Indicates that you intend to make future payments with this PaymentIntent's payment method.
        #
        # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
        #
        # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
        #
        # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
        #
        # If you've already set `setup_future_usage` and you're performing a request using a publishable key, you can only update the value from `on_session` to `off_session`.
        attr_accessor :setup_future_usage
        # Provides information about a card payment that customers see on their statements. Concatenated with the Kana prefix (shortened Kana descriptor) or Kana statement descriptor that’s set on the account to form the complete statement descriptor. Maximum 22 characters. On card statements, the *concatenation* of both prefix and suffix (including separators) will appear truncated to 22 characters.
        attr_accessor :statement_descriptor_suffix_kana
        # Provides information about a card payment that customers see on their statements. Concatenated with the Kanji prefix (shortened Kanji descriptor) or Kanji statement descriptor that’s set on the account to form the complete statement descriptor. Maximum 17 characters. On card statements, the *concatenation* of both prefix and suffix (including separators) will appear truncated to 17 characters.
        attr_accessor :statement_descriptor_suffix_kanji
        # If 3D Secure authentication was performed with a third-party provider,
        # the authentication details to use for this payment.
        attr_accessor :three_d_secure

        def initialize(
          capture_method: nil,
          cvc_token: nil,
          installments: nil,
          mandate_options: nil,
          moto: nil,
          network: nil,
          request_extended_authorization: nil,
          request_incremental_authorization: nil,
          request_multicapture: nil,
          request_overcapture: nil,
          request_three_d_secure: nil,
          require_cvc_recollection: nil,
          setup_future_usage: nil,
          statement_descriptor_suffix_kana: nil,
          statement_descriptor_suffix_kanji: nil,
          three_d_secure: nil
        )
          @capture_method = capture_method
          @cvc_token = cvc_token
          @installments = installments
          @mandate_options = mandate_options
          @moto = moto
          @network = network
          @request_extended_authorization = request_extended_authorization
          @request_incremental_authorization = request_incremental_authorization
          @request_multicapture = request_multicapture
          @request_overcapture = request_overcapture
          @request_three_d_secure = request_three_d_secure
          @require_cvc_recollection = require_cvc_recollection
          @setup_future_usage = setup_future_usage
          @statement_descriptor_suffix_kana = statement_descriptor_suffix_kana
          @statement_descriptor_suffix_kanji = statement_descriptor_suffix_kanji
          @three_d_secure = three_d_secure
        end
      end

      class CardPresent < ::Stripe::RequestParams
        class Routing < ::Stripe::RequestParams
          # Routing requested priority
          attr_accessor :requested_priority

          def initialize(requested_priority: nil)
            @requested_priority = requested_priority
          end
        end
        # Controls when the funds are captured from the customer's account.
        #
        # If provided, this parameter overrides the behavior of the top-level [capture_method](/api/payment_intents/update#update_payment_intent-capture_method) for this payment method type when finalizing the payment with this payment method type.
        #
        # If `capture_method` is already set on the PaymentIntent, providing an empty value for this parameter unsets the stored value for this payment method type.
        attr_accessor :capture_method
        # Request ability to capture this payment beyond the standard [authorization validity window](https://stripe.com/docs/terminal/features/extended-authorizations#authorization-validity)
        attr_accessor :request_extended_authorization
        # Request ability to [increment](https://stripe.com/docs/terminal/features/incremental-authorizations) this PaymentIntent if the combination of MCC and card brand is eligible. Check [incremental_authorization_supported](https://stripe.com/docs/api/charges/object#charge_object-payment_method_details-card_present-incremental_authorization_supported) in the [Confirm](https://stripe.com/docs/api/payment_intents/confirm) response to verify support.
        attr_accessor :request_incremental_authorization_support
        # Network routing priority on co-branded EMV cards supporting domestic debit and international card schemes.
        attr_accessor :routing

        def initialize(
          capture_method: nil,
          request_extended_authorization: nil,
          request_incremental_authorization_support: nil,
          routing: nil
        )
          @capture_method = capture_method
          @request_extended_authorization = request_extended_authorization
          @request_incremental_authorization_support = request_incremental_authorization_support
          @routing = routing
        end
      end

      class Cashapp < ::Stripe::RequestParams
        # Controls when the funds are captured from the customer's account.
        #
        # If provided, this parameter overrides the behavior of the top-level [capture_method](/api/payment_intents/update#update_payment_intent-capture_method) for this payment method type when finalizing the payment with this payment method type.
        #
        # If `capture_method` is already set on the PaymentIntent, providing an empty value for this parameter unsets the stored value for this payment method type.
        attr_accessor :capture_method
        # Indicates that you intend to make future payments with this PaymentIntent's payment method.
        #
        # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
        #
        # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
        #
        # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
        #
        # If you've already set `setup_future_usage` and you're performing a request using a publishable key, you can only update the value from `on_session` to `off_session`.
        attr_accessor :setup_future_usage

        def initialize(capture_method: nil, setup_future_usage: nil)
          @capture_method = capture_method
          @setup_future_usage = setup_future_usage
        end
      end

      class Crypto < ::Stripe::RequestParams
        # Indicates that you intend to make future payments with this PaymentIntent's payment method.
        #
        # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
        #
        # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
        #
        # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
        #
        # If you've already set `setup_future_usage` and you're performing a request using a publishable key, you can only update the value from `on_session` to `off_session`.
        attr_accessor :setup_future_usage

        def initialize(setup_future_usage: nil)
          @setup_future_usage = setup_future_usage
        end
      end

      class CustomerBalance < ::Stripe::RequestParams
        class BankTransfer < ::Stripe::RequestParams
          class EuBankTransfer < ::Stripe::RequestParams
            # The desired country code of the bank account information. Permitted values include: `BE`, `DE`, `ES`, `FR`, `IE`, or `NL`.
            attr_accessor :country

            def initialize(country: nil)
              @country = country
            end
          end
          # Configuration for the eu_bank_transfer funding type.
          attr_accessor :eu_bank_transfer
          # List of address types that should be returned in the financial_addresses response. If not specified, all valid types will be returned.
          #
          # Permitted values include: `sort_code`, `zengin`, `iban`, or `spei`.
          attr_accessor :requested_address_types
          # The list of bank transfer types that this PaymentIntent is allowed to use for funding Permitted values include: `eu_bank_transfer`, `gb_bank_transfer`, `jp_bank_transfer`, `mx_bank_transfer`, or `us_bank_transfer`.
          attr_accessor :type

          def initialize(eu_bank_transfer: nil, requested_address_types: nil, type: nil)
            @eu_bank_transfer = eu_bank_transfer
            @requested_address_types = requested_address_types
            @type = type
          end
        end
        # Configuration for the bank transfer funding type, if the `funding_type` is set to `bank_transfer`.
        attr_accessor :bank_transfer
        # The funding method type to be used when there are not enough funds in the customer balance. Permitted values include: `bank_transfer`.
        attr_accessor :funding_type
        # Indicates that you intend to make future payments with this PaymentIntent's payment method.
        #
        # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
        #
        # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
        #
        # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
        #
        # If you've already set `setup_future_usage` and you're performing a request using a publishable key, you can only update the value from `on_session` to `off_session`.
        attr_accessor :setup_future_usage

        def initialize(bank_transfer: nil, funding_type: nil, setup_future_usage: nil)
          @bank_transfer = bank_transfer
          @funding_type = funding_type
          @setup_future_usage = setup_future_usage
        end
      end

      class Eps < ::Stripe::RequestParams
        # Indicates that you intend to make future payments with this PaymentIntent's payment method.
        #
        # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
        #
        # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
        #
        # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
        #
        # If you've already set `setup_future_usage` and you're performing a request using a publishable key, you can only update the value from `on_session` to `off_session`.
        attr_accessor :setup_future_usage

        def initialize(setup_future_usage: nil)
          @setup_future_usage = setup_future_usage
        end
      end

      class Fpx < ::Stripe::RequestParams
        # Indicates that you intend to make future payments with this PaymentIntent's payment method.
        #
        # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
        #
        # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
        #
        # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
        #
        # If you've already set `setup_future_usage` and you're performing a request using a publishable key, you can only update the value from `on_session` to `off_session`.
        attr_accessor :setup_future_usage

        def initialize(setup_future_usage: nil)
          @setup_future_usage = setup_future_usage
        end
      end

      class Giropay < ::Stripe::RequestParams
        # Indicates that you intend to make future payments with this PaymentIntent's payment method.
        #
        # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
        #
        # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
        #
        # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
        #
        # If you've already set `setup_future_usage` and you're performing a request using a publishable key, you can only update the value from `on_session` to `off_session`.
        attr_accessor :setup_future_usage

        def initialize(setup_future_usage: nil)
          @setup_future_usage = setup_future_usage
        end
      end

      class Grabpay < ::Stripe::RequestParams
        # Indicates that you intend to make future payments with this PaymentIntent's payment method.
        #
        # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
        #
        # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
        #
        # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
        #
        # If you've already set `setup_future_usage` and you're performing a request using a publishable key, you can only update the value from `on_session` to `off_session`.
        attr_accessor :setup_future_usage

        def initialize(setup_future_usage: nil)
          @setup_future_usage = setup_future_usage
        end
      end

      class Ideal < ::Stripe::RequestParams
        # Indicates that you intend to make future payments with this PaymentIntent's payment method.
        #
        # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
        #
        # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
        #
        # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
        #
        # If you've already set `setup_future_usage` and you're performing a request using a publishable key, you can only update the value from `on_session` to `off_session`.
        attr_accessor :setup_future_usage

        def initialize(setup_future_usage: nil)
          @setup_future_usage = setup_future_usage
        end
      end

      class InteracPresent < ::Stripe::RequestParams; end

      class KakaoPay < ::Stripe::RequestParams
        # Controls when the funds are captured from the customer's account.
        #
        # If provided, this parameter overrides the behavior of the top-level [capture_method](/api/payment_intents/update#update_payment_intent-capture_method) for this payment method type when finalizing the payment with this payment method type.
        #
        # If `capture_method` is already set on the PaymentIntent, providing an empty value for this parameter unsets the stored value for this payment method type.
        attr_accessor :capture_method
        # Indicates that you intend to make future payments with this PaymentIntent's payment method.
        #
        # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
        #
        # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
        #
        # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
        attr_accessor :setup_future_usage

        def initialize(capture_method: nil, setup_future_usage: nil)
          @capture_method = capture_method
          @setup_future_usage = setup_future_usage
        end
      end

      class Klarna < ::Stripe::RequestParams
        class OnDemand < ::Stripe::RequestParams
          # Your average amount value. You can use a value across your customer base, or segment based on customer type, country, etc.
          attr_accessor :average_amount
          # The maximum value you may charge a customer per purchase. You can use a value across your customer base, or segment based on customer type, country, etc.
          attr_accessor :maximum_amount
          # The lowest or minimum value you may charge a customer per purchase. You can use a value across your customer base, or segment based on customer type, country, etc.
          attr_accessor :minimum_amount
          # Interval at which the customer is making purchases
          attr_accessor :purchase_interval
          # The number of `purchase_interval` between charges
          attr_accessor :purchase_interval_count

          def initialize(
            average_amount: nil,
            maximum_amount: nil,
            minimum_amount: nil,
            purchase_interval: nil,
            purchase_interval_count: nil
          )
            @average_amount = average_amount
            @maximum_amount = maximum_amount
            @minimum_amount = minimum_amount
            @purchase_interval = purchase_interval
            @purchase_interval_count = purchase_interval_count
          end
        end

        class Subscription < ::Stripe::RequestParams
          class NextBilling < ::Stripe::RequestParams
            # The amount of the next charge for the subscription.
            attr_accessor :amount
            # The date of the next charge for the subscription in YYYY-MM-DD format.
            attr_accessor :date

            def initialize(amount: nil, date: nil)
              @amount = amount
              @date = date
            end
          end
          # Unit of time between subscription charges.
          attr_accessor :interval
          # The number of intervals (specified in the `interval` attribute) between subscription charges. For example, `interval=month` and `interval_count=3` charges every 3 months.
          attr_accessor :interval_count
          # Name for subscription.
          attr_accessor :name
          # Describes the upcoming charge for this subscription.
          attr_accessor :next_billing
          # A non-customer-facing reference to correlate subscription charges in the Klarna app. Use a value that persists across subscription charges.
          attr_accessor :reference

          def initialize(
            interval: nil,
            interval_count: nil,
            name: nil,
            next_billing: nil,
            reference: nil
          )
            @interval = interval
            @interval_count = interval_count
            @name = name
            @next_billing = next_billing
            @reference = reference
          end
        end
        # Controls when the funds are captured from the customer's account.
        #
        # If provided, this parameter overrides the behavior of the top-level [capture_method](/api/payment_intents/update#update_payment_intent-capture_method) for this payment method type when finalizing the payment with this payment method type.
        #
        # If `capture_method` is already set on the PaymentIntent, providing an empty value for this parameter unsets the stored value for this payment method type.
        attr_accessor :capture_method
        # On-demand details if setting up or charging an on-demand payment.
        attr_accessor :on_demand
        # Preferred language of the Klarna authorization page that the customer is redirected to
        attr_accessor :preferred_locale
        # Indicates that you intend to make future payments with this PaymentIntent's payment method.
        #
        # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
        #
        # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
        #
        # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
        #
        # If you've already set `setup_future_usage` and you're performing a request using a publishable key, you can only update the value from `on_session` to `off_session`.
        attr_accessor :setup_future_usage
        # Subscription details if setting up or charging a subscription.
        attr_accessor :subscriptions

        def initialize(
          capture_method: nil,
          on_demand: nil,
          preferred_locale: nil,
          setup_future_usage: nil,
          subscriptions: nil
        )
          @capture_method = capture_method
          @on_demand = on_demand
          @preferred_locale = preferred_locale
          @setup_future_usage = setup_future_usage
          @subscriptions = subscriptions
        end
      end

      class Konbini < ::Stripe::RequestParams
        # An optional 10 to 11 digit numeric-only string determining the confirmation code at applicable convenience stores. Must not consist of only zeroes and could be rejected in case of insufficient uniqueness. We recommend to use the customer's phone number.
        attr_accessor :confirmation_number
        # The number of calendar days (between 1 and 60) after which Konbini payment instructions will expire. For example, if a PaymentIntent is confirmed with Konbini and `expires_after_days` set to 2 on Monday JST, the instructions will expire on Wednesday 23:59:59 JST. Defaults to 3 days.
        attr_accessor :expires_after_days
        # The timestamp at which the Konbini payment instructions will expire. Only one of `expires_after_days` or `expires_at` may be set.
        attr_accessor :expires_at
        # A product descriptor of up to 22 characters, which will appear to customers at the convenience store.
        attr_accessor :product_description
        # Indicates that you intend to make future payments with this PaymentIntent's payment method.
        #
        # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
        #
        # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
        #
        # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
        #
        # If you've already set `setup_future_usage` and you're performing a request using a publishable key, you can only update the value from `on_session` to `off_session`.
        attr_accessor :setup_future_usage

        def initialize(
          confirmation_number: nil,
          expires_after_days: nil,
          expires_at: nil,
          product_description: nil,
          setup_future_usage: nil
        )
          @confirmation_number = confirmation_number
          @expires_after_days = expires_after_days
          @expires_at = expires_at
          @product_description = product_description
          @setup_future_usage = setup_future_usage
        end
      end

      class KrCard < ::Stripe::RequestParams
        # Controls when the funds are captured from the customer's account.
        #
        # If provided, this parameter overrides the behavior of the top-level [capture_method](/api/payment_intents/update#update_payment_intent-capture_method) for this payment method type when finalizing the payment with this payment method type.
        #
        # If `capture_method` is already set on the PaymentIntent, providing an empty value for this parameter unsets the stored value for this payment method type.
        attr_accessor :capture_method
        # Indicates that you intend to make future payments with this PaymentIntent's payment method.
        #
        # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
        #
        # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
        #
        # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
        attr_accessor :setup_future_usage

        def initialize(capture_method: nil, setup_future_usage: nil)
          @capture_method = capture_method
          @setup_future_usage = setup_future_usage
        end
      end

      class Link < ::Stripe::RequestParams
        # Controls when the funds are captured from the customer's account.
        #
        # If provided, this parameter overrides the behavior of the top-level [capture_method](/api/payment_intents/update#update_payment_intent-capture_method) for this payment method type when finalizing the payment with this payment method type.
        #
        # If `capture_method` is already set on the PaymentIntent, providing an empty value for this parameter unsets the stored value for this payment method type.
        attr_accessor :capture_method
        # [Deprecated] This is a legacy parameter that no longer has any function.
        attr_accessor :persistent_token
        # Indicates that you intend to make future payments with this PaymentIntent's payment method.
        #
        # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
        #
        # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
        #
        # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
        #
        # If you've already set `setup_future_usage` and you're performing a request using a publishable key, you can only update the value from `on_session` to `off_session`.
        attr_accessor :setup_future_usage

        def initialize(capture_method: nil, persistent_token: nil, setup_future_usage: nil)
          @capture_method = capture_method
          @persistent_token = persistent_token
          @setup_future_usage = setup_future_usage
        end
      end

      class MbWay < ::Stripe::RequestParams
        # Indicates that you intend to make future payments with this PaymentIntent's payment method.
        #
        # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
        #
        # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
        #
        # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
        #
        # If you've already set `setup_future_usage` and you're performing a request using a publishable key, you can only update the value from `on_session` to `off_session`.
        attr_accessor :setup_future_usage

        def initialize(setup_future_usage: nil)
          @setup_future_usage = setup_future_usage
        end
      end

      class Mobilepay < ::Stripe::RequestParams
        # Controls when the funds are captured from the customer's account.
        #
        # If provided, this parameter overrides the behavior of the top-level [capture_method](/api/payment_intents/update#update_payment_intent-capture_method) for this payment method type when finalizing the payment with this payment method type.
        #
        # If `capture_method` is already set on the PaymentIntent, providing an empty value for this parameter unsets the stored value for this payment method type.
        attr_accessor :capture_method
        # Indicates that you intend to make future payments with this PaymentIntent's payment method.
        #
        # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
        #
        # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
        #
        # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
        #
        # If you've already set `setup_future_usage` and you're performing a request using a publishable key, you can only update the value from `on_session` to `off_session`.
        attr_accessor :setup_future_usage

        def initialize(capture_method: nil, setup_future_usage: nil)
          @capture_method = capture_method
          @setup_future_usage = setup_future_usage
        end
      end

      class Multibanco < ::Stripe::RequestParams
        # Indicates that you intend to make future payments with this PaymentIntent's payment method.
        #
        # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
        #
        # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
        #
        # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
        #
        # If you've already set `setup_future_usage` and you're performing a request using a publishable key, you can only update the value from `on_session` to `off_session`.
        attr_accessor :setup_future_usage

        def initialize(setup_future_usage: nil)
          @setup_future_usage = setup_future_usage
        end
      end

      class NaverPay < ::Stripe::RequestParams
        # Controls when the funds are captured from the customer's account.
        #
        # If provided, this parameter overrides the behavior of the top-level [capture_method](/api/payment_intents/update#update_payment_intent-capture_method) for this payment method type when finalizing the payment with this payment method type.
        #
        # If `capture_method` is already set on the PaymentIntent, providing an empty value for this parameter unsets the stored value for this payment method type.
        attr_accessor :capture_method
        # Indicates that you intend to make future payments with this PaymentIntent's payment method.
        #
        # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
        #
        # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
        #
        # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
        attr_accessor :setup_future_usage

        def initialize(capture_method: nil, setup_future_usage: nil)
          @capture_method = capture_method
          @setup_future_usage = setup_future_usage
        end
      end

      class NzBankAccount < ::Stripe::RequestParams
        # Indicates that you intend to make future payments with this PaymentIntent's payment method.
        #
        # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
        #
        # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
        #
        # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
        #
        # If you've already set `setup_future_usage` and you're performing a request using a publishable key, you can only update the value from `on_session` to `off_session`.
        attr_accessor :setup_future_usage
        # Controls when Stripe will attempt to debit the funds from the customer's account. The date must be a string in YYYY-MM-DD format. The date must be in the future and between 3 and 15 calendar days from now.
        attr_accessor :target_date

        def initialize(setup_future_usage: nil, target_date: nil)
          @setup_future_usage = setup_future_usage
          @target_date = target_date
        end
      end

      class Oxxo < ::Stripe::RequestParams
        # The number of calendar days before an OXXO voucher expires. For example, if you create an OXXO voucher on Monday and you set expires_after_days to 2, the OXXO invoice will expire on Wednesday at 23:59 America/Mexico_City time.
        attr_accessor :expires_after_days
        # Indicates that you intend to make future payments with this PaymentIntent's payment method.
        #
        # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
        #
        # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
        #
        # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
        #
        # If you've already set `setup_future_usage` and you're performing a request using a publishable key, you can only update the value from `on_session` to `off_session`.
        attr_accessor :setup_future_usage

        def initialize(expires_after_days: nil, setup_future_usage: nil)
          @expires_after_days = expires_after_days
          @setup_future_usage = setup_future_usage
        end
      end

      class P24 < ::Stripe::RequestParams
        # Indicates that you intend to make future payments with this PaymentIntent's payment method.
        #
        # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
        #
        # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
        #
        # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
        #
        # If you've already set `setup_future_usage` and you're performing a request using a publishable key, you can only update the value from `on_session` to `off_session`.
        attr_accessor :setup_future_usage
        # Confirm that the payer has accepted the P24 terms and conditions.
        attr_accessor :tos_shown_and_accepted

        def initialize(setup_future_usage: nil, tos_shown_and_accepted: nil)
          @setup_future_usage = setup_future_usage
          @tos_shown_and_accepted = tos_shown_and_accepted
        end
      end

      class PayByBank < ::Stripe::RequestParams; end

      class Payco < ::Stripe::RequestParams
        # Controls when the funds are captured from the customer's account.
        #
        # If provided, this parameter overrides the behavior of the top-level [capture_method](/api/payment_intents/update#update_payment_intent-capture_method) for this payment method type when finalizing the payment with this payment method type.
        #
        # If `capture_method` is already set on the PaymentIntent, providing an empty value for this parameter unsets the stored value for this payment method type.
        attr_accessor :capture_method

        def initialize(capture_method: nil)
          @capture_method = capture_method
        end
      end

      class Paynow < ::Stripe::RequestParams
        # Indicates that you intend to make future payments with this PaymentIntent's payment method.
        #
        # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
        #
        # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
        #
        # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
        #
        # If you've already set `setup_future_usage` and you're performing a request using a publishable key, you can only update the value from `on_session` to `off_session`.
        attr_accessor :setup_future_usage

        def initialize(setup_future_usage: nil)
          @setup_future_usage = setup_future_usage
        end
      end

      class Paypal < ::Stripe::RequestParams
        # Controls when the funds will be captured from the customer's account.
        attr_accessor :capture_method
        # [Preferred locale](https://stripe.com/docs/payments/paypal/supported-locales) of the PayPal checkout page that the customer is redirected to.
        attr_accessor :preferred_locale
        # A reference of the PayPal transaction visible to customer which is mapped to PayPal's invoice ID. This must be a globally unique ID if you have configured in your PayPal settings to block multiple payments per invoice ID.
        attr_accessor :reference
        # The risk correlation ID for an on-session payment using a saved PayPal payment method.
        attr_accessor :risk_correlation_id
        # Indicates that you intend to make future payments with this PaymentIntent's payment method.
        #
        # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
        #
        # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
        #
        # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
        #
        # If you've already set `setup_future_usage` and you're performing a request using a publishable key, you can only update the value from `on_session` to `off_session`.
        attr_accessor :setup_future_usage

        def initialize(
          capture_method: nil,
          preferred_locale: nil,
          reference: nil,
          risk_correlation_id: nil,
          setup_future_usage: nil
        )
          @capture_method = capture_method
          @preferred_locale = preferred_locale
          @reference = reference
          @risk_correlation_id = risk_correlation_id
          @setup_future_usage = setup_future_usage
        end
      end

      class Pix < ::Stripe::RequestParams
        # Determines if the amount includes the IOF tax. Defaults to `never`.
        attr_accessor :amount_includes_iof
        # The number of seconds (between 10 and 1209600) after which Pix payment will expire. Defaults to 86400 seconds.
        attr_accessor :expires_after_seconds
        # The timestamp at which the Pix expires (between 10 and 1209600 seconds in the future). Defaults to 1 day in the future.
        attr_accessor :expires_at
        # Indicates that you intend to make future payments with this PaymentIntent's payment method.
        #
        # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
        #
        # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
        #
        # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
        #
        # If you've already set `setup_future_usage` and you're performing a request using a publishable key, you can only update the value from `on_session` to `off_session`.
        attr_accessor :setup_future_usage

        def initialize(
          amount_includes_iof: nil,
          expires_after_seconds: nil,
          expires_at: nil,
          setup_future_usage: nil
        )
          @amount_includes_iof = amount_includes_iof
          @expires_after_seconds = expires_after_seconds
          @expires_at = expires_at
          @setup_future_usage = setup_future_usage
        end
      end

      class Promptpay < ::Stripe::RequestParams
        # Indicates that you intend to make future payments with this PaymentIntent's payment method.
        #
        # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
        #
        # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
        #
        # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
        #
        # If you've already set `setup_future_usage` and you're performing a request using a publishable key, you can only update the value from `on_session` to `off_session`.
        attr_accessor :setup_future_usage

        def initialize(setup_future_usage: nil)
          @setup_future_usage = setup_future_usage
        end
      end

      class RevolutPay < ::Stripe::RequestParams
        # Controls when the funds are captured from the customer's account.
        #
        # If provided, this parameter overrides the behavior of the top-level [capture_method](/api/payment_intents/update#update_payment_intent-capture_method) for this payment method type when finalizing the payment with this payment method type.
        #
        # If `capture_method` is already set on the PaymentIntent, providing an empty value for this parameter unsets the stored value for this payment method type.
        attr_accessor :capture_method
        # Indicates that you intend to make future payments with this PaymentIntent's payment method.
        #
        # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
        #
        # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
        #
        # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
        attr_accessor :setup_future_usage

        def initialize(capture_method: nil, setup_future_usage: nil)
          @capture_method = capture_method
          @setup_future_usage = setup_future_usage
        end
      end

      class SamsungPay < ::Stripe::RequestParams
        # Controls when the funds are captured from the customer's account.
        #
        # If provided, this parameter overrides the behavior of the top-level [capture_method](/api/payment_intents/update#update_payment_intent-capture_method) for this payment method type when finalizing the payment with this payment method type.
        #
        # If `capture_method` is already set on the PaymentIntent, providing an empty value for this parameter unsets the stored value for this payment method type.
        attr_accessor :capture_method

        def initialize(capture_method: nil)
          @capture_method = capture_method
        end
      end

      class Satispay < ::Stripe::RequestParams
        # Controls when the funds are captured from the customer's account.
        #
        # If provided, this parameter overrides the behavior of the top-level [capture_method](/api/payment_intents/update#update_payment_intent-capture_method) for this payment method type when finalizing the payment with this payment method type.
        #
        # If `capture_method` is already set on the PaymentIntent, providing an empty value for this parameter unsets the stored value for this payment method type.
        attr_accessor :capture_method

        def initialize(capture_method: nil)
          @capture_method = capture_method
        end
      end

      class SepaDebit < ::Stripe::RequestParams
        class MandateOptions < ::Stripe::RequestParams
          # Prefix used to generate the Mandate reference. Must be at most 12 characters long. Must consist of only uppercase letters, numbers, spaces, or the following special characters: '/', '_', '-', '&', '.'. Cannot begin with 'STRIPE'.
          attr_accessor :reference_prefix

          def initialize(reference_prefix: nil)
            @reference_prefix = reference_prefix
          end
        end
        # Additional fields for Mandate creation
        attr_accessor :mandate_options
        # Indicates that you intend to make future payments with this PaymentIntent's payment method.
        #
        # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
        #
        # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
        #
        # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
        #
        # If you've already set `setup_future_usage` and you're performing a request using a publishable key, you can only update the value from `on_session` to `off_session`.
        attr_accessor :setup_future_usage
        # Controls when Stripe will attempt to debit the funds from the customer's account. The date must be a string in YYYY-MM-DD format. The date must be in the future and between 3 and 15 calendar days from now.
        attr_accessor :target_date

        def initialize(mandate_options: nil, setup_future_usage: nil, target_date: nil)
          @mandate_options = mandate_options
          @setup_future_usage = setup_future_usage
          @target_date = target_date
        end
      end

      class Sofort < ::Stripe::RequestParams
        # Language shown to the payer on redirect.
        attr_accessor :preferred_language
        # Indicates that you intend to make future payments with this PaymentIntent's payment method.
        #
        # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
        #
        # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
        #
        # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
        #
        # If you've already set `setup_future_usage` and you're performing a request using a publishable key, you can only update the value from `on_session` to `off_session`.
        attr_accessor :setup_future_usage

        def initialize(preferred_language: nil, setup_future_usage: nil)
          @preferred_language = preferred_language
          @setup_future_usage = setup_future_usage
        end
      end

      class Swish < ::Stripe::RequestParams
        # A reference for this payment to be displayed in the Swish app.
        attr_accessor :reference
        # Indicates that you intend to make future payments with this PaymentIntent's payment method.
        #
        # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
        #
        # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
        #
        # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
        #
        # If you've already set `setup_future_usage` and you're performing a request using a publishable key, you can only update the value from `on_session` to `off_session`.
        attr_accessor :setup_future_usage

        def initialize(reference: nil, setup_future_usage: nil)
          @reference = reference
          @setup_future_usage = setup_future_usage
        end
      end

      class Twint < ::Stripe::RequestParams
        # Indicates that you intend to make future payments with this PaymentIntent's payment method.
        #
        # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
        #
        # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
        #
        # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
        #
        # If you've already set `setup_future_usage` and you're performing a request using a publishable key, you can only update the value from `on_session` to `off_session`.
        attr_accessor :setup_future_usage

        def initialize(setup_future_usage: nil)
          @setup_future_usage = setup_future_usage
        end
      end

      class UsBankAccount < ::Stripe::RequestParams
        class FinancialConnections < ::Stripe::RequestParams
          class Filters < ::Stripe::RequestParams
            # The account subcategories to use to filter for selectable accounts. Valid subcategories are `checking` and `savings`.
            attr_accessor :account_subcategories

            def initialize(account_subcategories: nil)
              @account_subcategories = account_subcategories
            end
          end
          # Provide filters for the linked accounts that the customer can select for the payment method.
          attr_accessor :filters
          # The list of permissions to request. If this parameter is passed, the `payment_method` permission must be included. Valid permissions include: `balances`, `ownership`, `payment_method`, and `transactions`.
          attr_accessor :permissions
          # List of data features that you would like to retrieve upon account creation.
          attr_accessor :prefetch
          # For webview integrations only. Upon completing OAuth login in the native browser, the user will be redirected to this URL to return to your app.
          attr_accessor :return_url

          def initialize(filters: nil, permissions: nil, prefetch: nil, return_url: nil)
            @filters = filters
            @permissions = permissions
            @prefetch = prefetch
            @return_url = return_url
          end
        end

        class MandateOptions < ::Stripe::RequestParams
          # The method used to collect offline mandate customer acceptance.
          attr_accessor :collection_method

          def initialize(collection_method: nil)
            @collection_method = collection_method
          end
        end

        class Networks < ::Stripe::RequestParams
          # Triggers validations to run across the selected networks
          attr_accessor :requested

          def initialize(requested: nil)
            @requested = requested
          end
        end
        # Additional fields for Financial Connections Session creation
        attr_accessor :financial_connections
        # Additional fields for Mandate creation
        attr_accessor :mandate_options
        # Additional fields for network related functions
        attr_accessor :networks
        # Preferred transaction settlement speed
        attr_accessor :preferred_settlement_speed
        # Indicates that you intend to make future payments with this PaymentIntent's payment method.
        #
        # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
        #
        # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
        #
        # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
        #
        # If you've already set `setup_future_usage` and you're performing a request using a publishable key, you can only update the value from `on_session` to `off_session`.
        attr_accessor :setup_future_usage
        # Controls when Stripe will attempt to debit the funds from the customer's account. The date must be a string in YYYY-MM-DD format. The date must be in the future and between 3 and 15 calendar days from now.
        attr_accessor :target_date
        # Bank account verification method.
        attr_accessor :verification_method

        def initialize(
          financial_connections: nil,
          mandate_options: nil,
          networks: nil,
          preferred_settlement_speed: nil,
          setup_future_usage: nil,
          target_date: nil,
          verification_method: nil
        )
          @financial_connections = financial_connections
          @mandate_options = mandate_options
          @networks = networks
          @preferred_settlement_speed = preferred_settlement_speed
          @setup_future_usage = setup_future_usage
          @target_date = target_date
          @verification_method = verification_method
        end
      end

      class WechatPay < ::Stripe::RequestParams
        # The app ID registered with WeChat Pay. Only required when client is ios or android.
        attr_accessor :app_id
        # The client type that the end customer will pay from
        attr_accessor :client
        # Indicates that you intend to make future payments with this PaymentIntent's payment method.
        #
        # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
        #
        # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
        #
        # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
        #
        # If you've already set `setup_future_usage` and you're performing a request using a publishable key, you can only update the value from `on_session` to `off_session`.
        attr_accessor :setup_future_usage

        def initialize(app_id: nil, client: nil, setup_future_usage: nil)
          @app_id = app_id
          @client = client
          @setup_future_usage = setup_future_usage
        end
      end

      class Zip < ::Stripe::RequestParams
        # Indicates that you intend to make future payments with this PaymentIntent's payment method.
        #
        # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
        #
        # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
        #
        # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
        #
        # If you've already set `setup_future_usage` and you're performing a request using a publishable key, you can only update the value from `on_session` to `off_session`.
        attr_accessor :setup_future_usage

        def initialize(setup_future_usage: nil)
          @setup_future_usage = setup_future_usage
        end
      end
      # If this is a `acss_debit` PaymentMethod, this sub-hash contains details about the ACSS Debit payment method options.
      attr_accessor :acss_debit
      # If this is an `affirm` PaymentMethod, this sub-hash contains details about the Affirm payment method options.
      attr_accessor :affirm
      # If this is a `afterpay_clearpay` PaymentMethod, this sub-hash contains details about the Afterpay Clearpay payment method options.
      attr_accessor :afterpay_clearpay
      # If this is a `alipay` PaymentMethod, this sub-hash contains details about the Alipay payment method options.
      attr_accessor :alipay
      # If this is a `alma` PaymentMethod, this sub-hash contains details about the Alma payment method options.
      attr_accessor :alma
      # If this is a `amazon_pay` PaymentMethod, this sub-hash contains details about the Amazon Pay payment method options.
      attr_accessor :amazon_pay
      # If this is a `au_becs_debit` PaymentMethod, this sub-hash contains details about the AU BECS Direct Debit payment method options.
      attr_accessor :au_becs_debit
      # If this is a `bacs_debit` PaymentMethod, this sub-hash contains details about the BACS Debit payment method options.
      attr_accessor :bacs_debit
      # If this is a `bancontact` PaymentMethod, this sub-hash contains details about the Bancontact payment method options.
      attr_accessor :bancontact
      # If this is a `billie` PaymentMethod, this sub-hash contains details about the Billie payment method options.
      attr_accessor :billie
      # If this is a `blik` PaymentMethod, this sub-hash contains details about the BLIK payment method options.
      attr_accessor :blik
      # If this is a `boleto` PaymentMethod, this sub-hash contains details about the Boleto payment method options.
      attr_accessor :boleto
      # Configuration for any card payments attempted on this PaymentIntent.
      attr_accessor :card
      # If this is a `card_present` PaymentMethod, this sub-hash contains details about the Card Present payment method options.
      attr_accessor :card_present
      # If this is a `cashapp` PaymentMethod, this sub-hash contains details about the Cash App Pay payment method options.
      attr_accessor :cashapp
      # If this is a `crypto` PaymentMethod, this sub-hash contains details about the Crypto payment method options.
      attr_accessor :crypto
      # If this is a `customer balance` PaymentMethod, this sub-hash contains details about the customer balance payment method options.
      attr_accessor :customer_balance
      # If this is a `eps` PaymentMethod, this sub-hash contains details about the EPS payment method options.
      attr_accessor :eps
      # If this is a `fpx` PaymentMethod, this sub-hash contains details about the FPX payment method options.
      attr_accessor :fpx
      # If this is a `giropay` PaymentMethod, this sub-hash contains details about the Giropay payment method options.
      attr_accessor :giropay
      # If this is a `grabpay` PaymentMethod, this sub-hash contains details about the Grabpay payment method options.
      attr_accessor :grabpay
      # If this is a `ideal` PaymentMethod, this sub-hash contains details about the Ideal payment method options.
      attr_accessor :ideal
      # If this is a `interac_present` PaymentMethod, this sub-hash contains details about the Card Present payment method options.
      attr_accessor :interac_present
      # If this is a `kakao_pay` PaymentMethod, this sub-hash contains details about the Kakao Pay payment method options.
      attr_accessor :kakao_pay
      # If this is a `klarna` PaymentMethod, this sub-hash contains details about the Klarna payment method options.
      attr_accessor :klarna
      # If this is a `konbini` PaymentMethod, this sub-hash contains details about the Konbini payment method options.
      attr_accessor :konbini
      # If this is a `kr_card` PaymentMethod, this sub-hash contains details about the KR Card payment method options.
      attr_accessor :kr_card
      # If this is a `link` PaymentMethod, this sub-hash contains details about the Link payment method options.
      attr_accessor :link
      # If this is a `mb_way` PaymentMethod, this sub-hash contains details about the MB WAY payment method options.
      attr_accessor :mb_way
      # If this is a `MobilePay` PaymentMethod, this sub-hash contains details about the MobilePay payment method options.
      attr_accessor :mobilepay
      # If this is a `multibanco` PaymentMethod, this sub-hash contains details about the Multibanco payment method options.
      attr_accessor :multibanco
      # If this is a `naver_pay` PaymentMethod, this sub-hash contains details about the Naver Pay payment method options.
      attr_accessor :naver_pay
      # If this is a `nz_bank_account` PaymentMethod, this sub-hash contains details about the NZ BECS Direct Debit payment method options.
      attr_accessor :nz_bank_account
      # If this is a `oxxo` PaymentMethod, this sub-hash contains details about the OXXO payment method options.
      attr_accessor :oxxo
      # If this is a `p24` PaymentMethod, this sub-hash contains details about the Przelewy24 payment method options.
      attr_accessor :p24
      # If this is a `pay_by_bank` PaymentMethod, this sub-hash contains details about the PayByBank payment method options.
      attr_accessor :pay_by_bank
      # If this is a `payco` PaymentMethod, this sub-hash contains details about the PAYCO payment method options.
      attr_accessor :payco
      # If this is a `paynow` PaymentMethod, this sub-hash contains details about the PayNow payment method options.
      attr_accessor :paynow
      # If this is a `paypal` PaymentMethod, this sub-hash contains details about the PayPal payment method options.
      attr_accessor :paypal
      # If this is a `pix` PaymentMethod, this sub-hash contains details about the Pix payment method options.
      attr_accessor :pix
      # If this is a `promptpay` PaymentMethod, this sub-hash contains details about the PromptPay payment method options.
      attr_accessor :promptpay
      # If this is a `revolut_pay` PaymentMethod, this sub-hash contains details about the Revolut Pay payment method options.
      attr_accessor :revolut_pay
      # If this is a `samsung_pay` PaymentMethod, this sub-hash contains details about the Samsung Pay payment method options.
      attr_accessor :samsung_pay
      # If this is a `satispay` PaymentMethod, this sub-hash contains details about the Satispay payment method options.
      attr_accessor :satispay
      # If this is a `sepa_debit` PaymentIntent, this sub-hash contains details about the SEPA Debit payment method options.
      attr_accessor :sepa_debit
      # If this is a `sofort` PaymentMethod, this sub-hash contains details about the SOFORT payment method options.
      attr_accessor :sofort
      # If this is a `Swish` PaymentMethod, this sub-hash contains details about the Swish payment method options.
      attr_accessor :swish
      # If this is a `twint` PaymentMethod, this sub-hash contains details about the TWINT payment method options.
      attr_accessor :twint
      # If this is a `us_bank_account` PaymentMethod, this sub-hash contains details about the US bank account payment method options.
      attr_accessor :us_bank_account
      # If this is a `wechat_pay` PaymentMethod, this sub-hash contains details about the WeChat Pay payment method options.
      attr_accessor :wechat_pay
      # If this is a `zip` PaymentMethod, this sub-hash contains details about the Zip payment method options.
      attr_accessor :zip

      def initialize(
        acss_debit: nil,
        affirm: nil,
        afterpay_clearpay: nil,
        alipay: nil,
        alma: nil,
        amazon_pay: nil,
        au_becs_debit: nil,
        bacs_debit: nil,
        bancontact: nil,
        billie: nil,
        blik: nil,
        boleto: nil,
        card: nil,
        card_present: nil,
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
        revolut_pay: nil,
        samsung_pay: nil,
        satispay: nil,
        sepa_debit: nil,
        sofort: nil,
        swish: nil,
        twint: nil,
        us_bank_account: nil,
        wechat_pay: nil,
        zip: nil
      )
        @acss_debit = acss_debit
        @affirm = affirm
        @afterpay_clearpay = afterpay_clearpay
        @alipay = alipay
        @alma = alma
        @amazon_pay = amazon_pay
        @au_becs_debit = au_becs_debit
        @bacs_debit = bacs_debit
        @bancontact = bancontact
        @billie = billie
        @blik = blik
        @boleto = boleto
        @card = card
        @card_present = card_present
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
        @revolut_pay = revolut_pay
        @samsung_pay = samsung_pay
        @satispay = satispay
        @sepa_debit = sepa_debit
        @sofort = sofort
        @swish = swish
        @twint = twint
        @us_bank_account = us_bank_account
        @wechat_pay = wechat_pay
        @zip = zip
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
      # Shipping address.
      attr_accessor :address
      # The delivery service that shipped a physical product, such as Fedex, UPS, USPS, etc.
      attr_accessor :carrier
      # Recipient name.
      attr_accessor :name
      # Recipient phone (including extension).
      attr_accessor :phone
      # The tracking number for a physical product, obtained from the delivery service. If multiple tracking numbers were generated for this purchase, please separate them with commas.
      attr_accessor :tracking_number

      def initialize(address: nil, carrier: nil, name: nil, phone: nil, tracking_number: nil)
        @address = address
        @carrier = carrier
        @name = name
        @phone = phone
        @tracking_number = tracking_number
      end
    end

    class TransferData < ::Stripe::RequestParams
      # The amount that will be transferred automatically when a charge succeeds.
      attr_accessor :amount

      def initialize(amount: nil)
        @amount = amount
      end
    end
    # Amount intended to be collected by this PaymentIntent. A positive integer representing how much to charge in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal) (e.g., 100 cents to charge $1.00 or 100 to charge ¥100, a zero-decimal currency). The minimum amount is $0.50 US or [equivalent in charge currency](https://stripe.com/docs/currencies#minimum-and-maximum-charge-amounts). The amount value supports up to eight digits (e.g., a value of 99999999 for a USD charge of $999,999.99).
    attr_accessor :amount
    # Provides industry-specific information about the amount.
    attr_accessor :amount_details
    # The amount of the application fee (if any) that will be requested to be applied to the payment and transferred to the application owner's Stripe account. The amount of the application fee collected will be capped at the total amount captured. For more information, see the PaymentIntents [use case for connected accounts](https://stripe.com/docs/payments/connected-accounts).
    attr_accessor :application_fee_amount
    # Controls when the funds will be captured from the customer's account.
    attr_accessor :capture_method
    # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
    attr_accessor :currency
    # ID of the Customer this PaymentIntent belongs to, if one exists.
    #
    # Payment methods attached to other Customers cannot be used with this PaymentIntent.
    #
    # If [setup_future_usage](https://stripe.com/docs/api#payment_intent_object-setup_future_usage) is set and this PaymentIntent's payment method is not `card_present`, then the payment method attaches to the Customer after the PaymentIntent has been confirmed and any required actions from the user are complete. If the payment method is `card_present` and isn't a digital wallet, then a [generated_card](https://docs.stripe.com/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card is created and attached to the Customer instead.
    attr_accessor :customer
    # An arbitrary string attached to the object. Often useful for displaying to users.
    attr_accessor :description
    # The list of payment method types to exclude from use with this payment.
    attr_accessor :excluded_payment_method_types
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # Automations to be run during the PaymentIntent lifecycle
    attr_accessor :hooks
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
    attr_accessor :metadata
    # Provides industry-specific information about the charge.
    attr_accessor :payment_details
    # ID of the payment method (a PaymentMethod, Card, or [compatible Source](https://stripe.com/docs/payments/payment-methods/transitioning#compatibility) object) to attach to this PaymentIntent. To unset this field to null, pass in an empty string.
    attr_accessor :payment_method
    # The ID of the [payment method configuration](https://stripe.com/docs/api/payment_method_configurations) to use with this PaymentIntent.
    attr_accessor :payment_method_configuration
    # If provided, this hash will be used to create a PaymentMethod. The new PaymentMethod will appear
    # in the [payment_method](https://stripe.com/docs/api/payment_intents/object#payment_intent_object-payment_method)
    # property on the PaymentIntent.
    attr_accessor :payment_method_data
    # Payment-method-specific configuration for this PaymentIntent.
    attr_accessor :payment_method_options
    # The list of payment method types (for example, card) that this PaymentIntent can use. Use `automatic_payment_methods` to manage payment methods from the [Stripe Dashboard](https://dashboard.stripe.com/settings/payment_methods). A list of valid payment method types can be found [here](https://docs.stripe.com/api/payment_methods/object#payment_method_object-type).
    attr_accessor :payment_method_types
    # Email address that the receipt for the resulting payment will be sent to. If `receipt_email` is specified for a payment in live mode, a receipt will be sent regardless of your [email settings](https://dashboard.stripe.com/account/emails).
    attr_accessor :receipt_email
    # Indicates that you intend to make future payments with this PaymentIntent's payment method.
    #
    # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
    #
    # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
    #
    # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
    #
    # If you've already set `setup_future_usage` and you're performing a request using a publishable key, you can only update the value from `on_session` to `off_session`.
    attr_accessor :setup_future_usage
    # Shipping information for this PaymentIntent.
    attr_accessor :shipping
    # Text that appears on the customer's statement as the statement descriptor for a non-card charge. This value overrides the account's default statement descriptor. For information about requirements, including the 22-character limit, see [the Statement Descriptor docs](https://docs.stripe.com/get-started/account/statement-descriptors).
    #
    # Setting this value for a card charge returns an error. For card charges, set the [statement_descriptor_suffix](https://docs.stripe.com/get-started/account/statement-descriptors#dynamic) instead.
    attr_accessor :statement_descriptor
    # Provides information about a card charge. Concatenated to the account's [statement descriptor prefix](https://docs.stripe.com/get-started/account/statement-descriptors#static) to form the complete statement descriptor that appears on the customer's statement.
    attr_accessor :statement_descriptor_suffix
    # Use this parameter to automatically create a Transfer when the payment succeeds. Learn more about the [use case for connected accounts](https://stripe.com/docs/payments/connected-accounts).
    attr_accessor :transfer_data
    # A string that identifies the resulting payment as part of a group. You can only provide `transfer_group` if it hasn't been set. Learn more about the [use case for connected accounts](https://stripe.com/docs/payments/connected-accounts).
    attr_accessor :transfer_group

    def initialize(
      amount: nil,
      amount_details: nil,
      application_fee_amount: nil,
      capture_method: nil,
      currency: nil,
      customer: nil,
      description: nil,
      excluded_payment_method_types: nil,
      expand: nil,
      hooks: nil,
      metadata: nil,
      payment_details: nil,
      payment_method: nil,
      payment_method_configuration: nil,
      payment_method_data: nil,
      payment_method_options: nil,
      payment_method_types: nil,
      receipt_email: nil,
      setup_future_usage: nil,
      shipping: nil,
      statement_descriptor: nil,
      statement_descriptor_suffix: nil,
      transfer_data: nil,
      transfer_group: nil
    )
      @amount = amount
      @amount_details = amount_details
      @application_fee_amount = application_fee_amount
      @capture_method = capture_method
      @currency = currency
      @customer = customer
      @description = description
      @excluded_payment_method_types = excluded_payment_method_types
      @expand = expand
      @hooks = hooks
      @metadata = metadata
      @payment_details = payment_details
      @payment_method = payment_method
      @payment_method_configuration = payment_method_configuration
      @payment_method_data = payment_method_data
      @payment_method_options = payment_method_options
      @payment_method_types = payment_method_types
      @receipt_email = receipt_email
      @setup_future_usage = setup_future_usage
      @shipping = shipping
      @statement_descriptor = statement_descriptor
      @statement_descriptor_suffix = statement_descriptor_suffix
      @transfer_data = transfer_data
      @transfer_group = transfer_group
    end
  end
end
