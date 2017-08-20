require 'jsonpath'
require 'json'
module Matchers
  class JsonNodesMatcher
    def initialize(path_hash)
      @path_hash = JSON(path_hash) if path_hash.is_a?(String)
      @path_hash = path_hash if path_hash.is_a?(Hash)
    end

    def matches?(json)
      @json = json
      nodes_compare?(@json, @path_hash)
    end

    def failure_message
      res = ''
      @not_matches.each do |val_on_path, compare|
        res += "Expected the value: #{val_on_path} to match:\n#{compare}\n\n"
      end
      res
    end

    private

    def nodes_compare?(json, path_hash)
      res = true
      tmp = true
      @not_matches = {}
      path_hash.each do |path, compare|
        val_on_path = JsonPath.new(path).first(json)
        escaped = compare.split(/\s/)
        act = escaped[0]
        value = escaped[1] if escaped.size == 2

        case act
        when 'equal'
          tmp = val_on_path.eql?(value)
        when 'not_equal'
          tmp = !val_on_path.eql?(value)
        when 'include'
          tmp = val_on_path.include?(value)
        when 'null', 'nil', 'empty'
          tmp = val_on_path.empty? || val_on_path.nil?
        when 'not_null', 'not_nil', 'not_empty'
          tmp = !val_on_path.empty?
        when 'less_than'
          tmp = val_on_path.to_f <= value.to_f
        when 'more_than'
          tmp = val_on_path.to_f >= value.to_f
        when 'is_num'
          tmp = val_on_path.is_a?(Numeric)
        when 'is_array'
          tmp = val_on_path.is_a?(Array)
        when 'is_hash'
          tmp = val_on_path.is_a?(Hash)
        else
          raise 'illegal comparison'
        end

        unless tmp
          @not_matches.store(val_on_path, compare)
          res = false if res
        end
      end
      res
    end
  end
end
