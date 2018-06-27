require_relative 'custom_matcher/array_not_empty'

module Matchers
  def array_not_empty
    Matchers::ArrayMatchers::ArrayNotEmtpy.new
  end
end

RSpec.configure do |config|
  config.include Matchers
end