# encoding: UTF-8

require "helper"

class LunarWordsTest < Test::Unit::TestCase
  test "german words" do
    str = "Der schnelle braune Fuchs springt über den faulen Hund"
    metaphones = %w(TR SXNL BRN FXS SPRNKT BR TN FLN HNT)

    words = Lunar::Words.new(str)
    
    assert_equal metaphones, words.map { |w| Lunar.metaphone(w) }
  end
end
