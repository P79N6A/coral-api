module Matchers
  module ArrayMatchers
    class ArrayNotEmtpy

      def initialize
      end

      def matches?(array)
        raise 'params error,should be array' unless Array === array
        if array.empty?
          false
        else
          true
        end
      end

      def failure_message
        "expected that #{actual} would not be empty array!"
      end
    end
  end
end