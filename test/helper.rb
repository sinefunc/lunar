require 'rubygems'
require 'test/unit'
require 'contest'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'lunar'

class Test::Unit::TestCase
  def setup
    Lunar.redis.flushdb
  end
end