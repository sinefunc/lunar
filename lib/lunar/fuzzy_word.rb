module Lunar
  # @private A helper for producing all the characters of a word.
  #
  # @example
  #   
  #   expected = %w(a ab abr abra abrah abraha abraham)
  #   FuzzyWord.new("Abraham").partials == expected
  #   # => true
  #
  class FuzzyWord < String
    def partials
      (1..length).map { |i| self[0, i].downcase }
    end
  end
end
