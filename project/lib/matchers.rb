require_relative 'custom_matcher/json_nodes_matcher'

module Matchers
  def json_nodes_matcher(path_hash)
    Matchers::JsonNodesMatcher.new(path_hash)
  end
end

RSpec.configure do |config|
  config.include Matchers
end