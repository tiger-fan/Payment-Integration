# webhook validation (see https://developer.paypal.com/docs/integration/direct/rest-webhooks-overview/#event-signature )

require 'paypal-sdk-rest'
include PayPal::SDK::REST
include PayPal::SDK::Core::Logging

# webhook headers required for event verification
# PAYPAL-TRANSMISSION-SIG header
actual_signature = "thy4/U002quzxFavHPwbfJGcc46E8rc5jzgyeafWm5mICTBdY/8rl7WJpn8JA0GKA+oDTPsSruqusw+XXg5RLAP7ip53Euh9Xu3UbUhQFX7UgwzE2FeYoY6lyRMiiiQLzy9BvHfIzNIVhPad4KnC339dr6y2l+mN8ALgI4GCdIh3/SoJO5wE64Bh/ueWtt8EVuvsvXfda2Le5a2TrOI9vLEzsm9GS79hAR/5oLexNz8UiZr045Mr5ObroH4w4oNfmkTaDk9Rj0G19uvISs5QzgmBpauKr7Nw++JI0pr/v5mFctQkoWJSGfBGzPRXawrvIIVHQ9Wer48GR2g9ZiApWg=="
# PAYPAL-AUTH-ALGO header
auth_algo = "sha256"
# PAYPAL-CERT-URL header
cert_url = "https://api.sandbox.paypal.com/v1/notifications/certs/CERT-360caa42-fca2a594-a5cafa77"

# other required items for event verification
transmission_id = "dfb3be50-fd74-11e4-8bf3-77339302725b"
timestamp = "2015-05-18T15:45:13Z"
webhook_id = "4JH86294D6297924G"
event_body = '{"id":"WH-0G2756385H040842W-5Y612302CV158622M","create_time":"2015-05-18T15:45:13Z","resource_type":"sale","event_type":"PAYMENT.SALE.COMPLETED","summary":"Payment completed for $ 20.0 USD","resource":{"id":"4EU7004268015634R","create_time":"2015-05-18T15:44:02Z","update_time":"2015-05-18T15:44:21Z","amount":{"total":"20.00","currency":"USD"},"payment_mode":"INSTANT_TRANSFER","state":"completed","protection_eligibility":"ELIGIBLE","protection_eligibility_type":"ITEM_NOT_RECEIVED_ELIGIBLE,UNAUTHORIZED_PAYMENT_ELIGIBLE","parent_payment":"PAY-86C81811X5228590KKVNARQQ","transaction_fee":{"value":"0.88","currency":"USD"},"links":[{"href":"https://api.sandbox.paypal.com/v1/payments/sale/4EU7004268015634R","rel":"self","method":"GET"},{"href":"https://api.sandbox.paypal.com/v1/payments/sale/4EU7004268015634R/refund","rel":"refund","method":"POST"},{"href":"https://api.sandbox.paypal.com/v1/payments/payment/PAY-86C81811X5228590KKVNARQQ","rel":"parent_payment","method":"GET"}]},"links":[{"href":"https://api.sandbox.paypal.com/v1/notifications/webhooks-events/WH-0G2756385H040842W-5Y612302CV158622M","rel":"self","method":"GET"},{"href":"https://api.sandbox.paypal.com/v1/notifications/webhooks-events/WH-0G2756385H040842W-5Y612302CV158622M/resend","rel":"resend","method":"POST"}]}'

# pass all the field to `WebhookEvent.verify()` method which returns true or false based on validation
cert = WebhookEvent.get_cert(cert_url)
valid = WebhookEvent.verify(transmission_id, timestamp, webhook_id, event_body, cert_url, actual_signature, auth_algo)

if valid
  logger.info "webhook event #{webhook_id} has been verified"
else
  logger.info "webhook event #{webhook_id} validation failed"
end
