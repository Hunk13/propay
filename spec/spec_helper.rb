require "propay"
require "active_merchant"
require "active_merchant/gateways/propay"

log_dir = File.join(File.dirname(__FILE__), "..", "log")
log = File.join(log_dir, "test.log")
Dir.mkdir(log_dir) unless Dir.exists?(log_dir)
ProPay.logger = Logger.new(log)
