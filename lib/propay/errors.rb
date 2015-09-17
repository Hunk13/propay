module ProPay
  # Generic error, also used to facilitate catching all ProPay-specific errors.
  class StandardError < ::StandardError; end

  # Raised when cannot parse XML and retrieve mandatory data in the ProPay responses.
  class InvalidDataError < ProPay::StandardError; end

  # Raised when getting non-success responses from ProPay server.
  # (Not HTTP connection errors!)
  class ServerError < ProPay::StandardError; end
end
