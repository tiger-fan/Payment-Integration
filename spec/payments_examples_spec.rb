require 'spec_helper'

describe "Payments" do

  PaymentAttributes = {
        "intent" =>  "sale",
        "payer" =>  {
          "payment_method" =>  "credit_card",
          "funding_instruments" =>  [ {
            "credit_card" =>  {
              "type" =>  "visa",
              "number" =>  "4567516310777851",
              "expire_month" =>  "11", "expire_year" =>  "2018",
              "cvv2" =>  "874",
              "first_name" =>  "Joe", "last_name" =>  "Shopper",
              "billing_address" =>  {
                "line1" =>  "52 N Main ST",
                "city" =>  "Johnstown",
                "state" =>  "OH",
                "postal_code" =>  "43210", "country_code" =>  "US" } } } ] },
        "transactions" =>  [ {
          "amount" =>  {
            "total" =>  "1.00",
            "currency" =>  "USD" },
          "description" =>  "This is the payment transaction description." } ] }

  FuturePaymentAttributes = {
        "intent" =>  "authorize",
        "payer" =>  {
          "payment_method" =>  "paypal" },
        "transactions" =>  [ {
          "amount" =>  {
            "total" =>  "1.00",
            "currency" =>  "USD" },
          "description" =>  "This is the payment transaction description." } ] }

  it "Validate user-agent", :unit => true do
    PayPal::SDK::REST::API.user_agent.should match "PayPalSDK/PayPal-Ruby-SDK"
  end

  describe "Examples" do
    describe "REST", :unit => true do
      it "Modifiy global configuration" do
        backup_config = PayPal::SDK::REST.api.config
        PayPal::SDK::REST.set_config( :client_id => "XYZ" )
        PayPal::SDK::REST.api.config.client_id.should eql "XYZ"
        PayPal::SDK::REST.set_config(backup_config)
        PayPal::SDK::REST.api.config.client_id.should_not eql "XYZ"
      end
    end

    describe "Payment", :integration => true do
      it "Create" do
        payment = Payment.new(PaymentAttributes)
        # Create
        payment.create
        payment.error.should be_nil
        payment.id.should_not be_nil
      end

      it "Create with request_id" do
        payment = Payment.new(PaymentAttributes)
        payment.create
        payment.error.should be_nil

        request_id = payment.request_id

        new_payment = Payment.new(PaymentAttributes.merge( :request_id => request_id ))
        new_payment.create
        new_payment.error.should be_nil

        payment.id.should eql new_payment.id

      end

      it "Create with token" do
        api = API.new
        payment = Payment.new(PaymentAttributes.merge( :token => api.token ))
        Payment.api.should_not eql payment.api
        payment.create
        payment.error.should be_nil
        payment.id.should_not be_nil
      end

      it "Create with client_id and client_secret" do
        api = API.new
        payment = Payment.new(PaymentAttributes.merge( :client_id => api.config.client_id, :client_secret => api.config.client_secret))
        Payment.api.should_not eql payment.api
        payment.create
        payment.error.should be_nil
        payment.id.should_not be_nil
      end

      it "List" do
        payment_history = Payment.all( "count" => 5 )
        payment_history.error.should be_nil
        payment_history.count.should eql 5
      end

      it "Find" do
        payment_history = Payment.all( "count" => 1 )
        payment = Payment.find(payment_history.payments[0].id)
        payment.error.should be_nil
      end

      describe "Validation", :integration => true do

        it "Create with empty values" do
          payment = Payment.new
          expect(payment.create).to be_falsey
        end

        it "Find with invalid ID" do
          lambda {
            payment = Payment.find("Invalid")
          }.should raise_error PayPal::SDK::Core::Exceptions::ResourceNotFound
        end

        it "Find with nil" do
          lambda{
            payment = Payment.find(nil)
          }.should raise_error ArgumentError
        end

        it "Find with empty string" do
          lambda{
            payment = Payment.find("")
          }.should raise_error ArgumentError
        end

        it "Find record with expired token" do
          lambda {
            Payment.api.token
            Payment.api.token.sub!(/^/, "Expired")
            Payment.all(:count => 1)
          }.should_not raise_error
        end
      end

      # describe "instance method" do

      #   it "Execute" do
      #     pending "Test with capybara"
      #   end
      # end

    end

    describe "Future Payment", :disabled => true do
      access_token = nil

      it "Exchange Authorization Code for Refresh / Access Tokens" do

        # put your authorization code for testing here
        auth_code = ''

        if auth_code != ''
          tokeninfo  = FuturePayment.exch_token(auth_code)
          tokeninfo.access_token.should_not be_nil
          tokeninfo.refresh_token.should_not be_nil
        end
      end

      it "Create a payment" do
        # put your PAYPAL-CLIENT-METADATA-ID
        correlation_id = '' 
        @future_payment = FuturePayment.new(FuturePaymentAttributes.merge( :token => access_token ))
        @future_payment.create(correlation_id)
        @future_payment.error.should be_nil
        @future_payment.id.should_not be_nil
      end

    end

    describe "Sale", :integration => true do
      before :each do
        @payment = Payment.new(PaymentAttributes)
        @payment.create
        @payment.should be_success
      end

      it "Find" do
        sale = Sale.find(@payment.transactions[0].related_resources[0].sale.id)
        sale.error.should be_nil
        sale.should be_a Sale
      end

      describe "instance method" do
        it "Refund" do
          sale   = @payment.transactions[0].related_resources[0].sale
          refund = sale.refund( :amount => { :total => "1.00", :currency => "USD" } )
          refund.error.should be_nil

          refund = Refund.find(refund.id)
          refund.error.should be_nil
          refund.should be_a Refund
        end
      end
    end

    describe "Order", :integration => true do
      it "Find" do
        order   = Order.find("O-2HT09787H36911800")
        expect(order.error).to be_nil
        expect(order).to_not be_nil
      end

      # The following Order tests must be ignored when run in an automated environment because executing an order
      # will require approval via the executed payment's approval_url.

      before :each, :disabled => true do
        @payment = Payment.new(PaymentAttributes.merge( "intent" => "order" ))
        payer_id = "" # replace with the actual payer_id
        @payment.create
        @payment.execute( :payer_id => payer_id )
        expect(@payment.error).to be_nil
      end

      it "Authorize", :disabled => true do
        auth = order.authorize
        expect(auth.state).to eq("Pending")
      end

      it "Capture", :disabled => true do
        capture = Capture.new({
            "amount" => {
              "currency" => "USD",
              "total" => "1.00"
            },
            "is_final_capture" => true
          })
        order = order.capture(@capture)
        expect(order.state).to eq("completed")
      end

      it "Void", :disabled => true do
        order = order.void()
        expect(order.state).to eq("voided")
      end

    end

    describe "Authorize", :integration => true do
      before :each do
        @payment = Payment.new(PaymentAttributes.merge( "intent" => "authorize" ))
        @payment.create
        @payment.error.should be_nil
      end

      it "Find" do
        authorize = Authorization.find(@payment.transactions[0].related_resources[0].authorization.id)
        authorize.error.should be_nil
        authorize.should be_a Authorization
      end

      it "Capture" do
        authorize = @payment.transactions[0].related_resources[0].authorization
        capture   = authorize.capture({:amount => { :currency => "USD", :total => "1.00" } })
        capture.error.should be_nil
      end

      it "Void" do
        authorize = @payment.transactions[0].related_resources[0].authorization
        authorize.void()
        authorize.error.should be_nil
      end

     it "Reauthorization" do
        authorize = Authorization.find("7GH53639GA425732B");
        authorize.amount = { :currency => "USD", :total => "1.00" }
        authorize.reauthorize
        authorize.error.should_not be_nil
      end
    end

    describe "Capture", :integration => true do
      before :each do
        @payment = Payment.new(PaymentAttributes.merge( "intent" => "authorize" ))
        @payment.create
        @payment.error.should be_nil
        authorize = @payment.transactions[0].related_resources[0].authorization
        @capture = authorize.capture({:amount => { :currency => "USD", :total => "1.00" } })
        @capture.error.should be_nil
      end

      it "Find" do
        capture = Capture.find(@capture.id)
        capture.error.should be_nil
        capture.should be_a Capture
      end

      it "Refund" do
        refund = @capture.refund({})
        refund.error.should be_nil
      end
    end

    describe "CreditCard", :integration => true do
      it "Create" do
        credit_card = CreditCard.new({
          "type" =>  "visa",
          "number" =>  "4567516310777851",
          "expire_month" =>  "11", "expire_year" =>  "2018",
          "cvv2" =>  "874",
          "first_name" =>  "Joe", "last_name" =>  "Shopper",
          "billing_address" =>  {
            "line1" =>  "52 N Main ST",
            "city" =>  "Johnstown",
            "state" =>  "OH",
            "postal_code" =>  "43210", "country_code" =>  "US" }})
        credit_card.create
        credit_card.error.should be_nil
        credit_card.id.should_not be_nil

        credit_card = CreditCard.find(credit_card.id)
        credit_card.should be_a CreditCard
        credit_card.error.should be_nil
      end

      it "Delete" do
        credit_card = CreditCard.new({
          "type" =>  "visa",
          "number" =>  "4567516310777851",
          "expire_month" =>  "11", "expire_year" =>  "2018" })
        expect(credit_card.create).to be_truthy
        expect(credit_card.delete).to be_truthy
      end

      describe "Validation", :integration => true do
        it "Create" do
          credit_card = CreditCard.new({
            "type" =>  "visa",
            "number" =>  "4111111111111111" })
          credit_card.create
          credit_card.error.should_not be_nil

          credit_card.error.name.should eql "VALIDATION_ERROR"
          credit_card.error["name"].should eql "VALIDATION_ERROR"

          credit_card.error.details[0].field.should eql "expire_year"
          credit_card.error.details[0].issue.should eql "Required field missing"
          credit_card.error.details[1].field.should eql "expire_month"
          credit_card.error.details[1].issue.should eql "Required field missing"

          credit_card.error["details"][0]["issue"].should eql "Required field missing"
        end
      end
    end

    describe 'CreditCardList', :integration => true do

      it "List" do
        options = { :create_time => "2015-03-28T15:33:43Z" }
        credit_card_list = CreditCardList.list()
        expect(credit_card_list.total_items).to be > 0
      end

    end

  end
end
