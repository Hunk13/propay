require "logger"

require "propay/version"
require "propay/errors"
require "propay/command"

module ProPay
  class << self
    attr_writer :logger

    def logger
      @logger ||= Logger.new(STDOUT)
    end
  end
end
