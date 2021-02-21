require 'yose'
require 'date'
require 'singleton'

module Que
  module_function
  def succ(ary=[0])
    *rest, tail = ary
    rest + [tail.succ]
  end

  class SecNumber
    def initialize(ary=[0])
      @curr = ary
    end
    attr_reader :curr

    def to_s
      p @curr
      @curr.join(".")
    end

    def next
      *rest, tail = @curr
      @curr = rest + [tail.succ]
      to_s
    end

    def push(n=0)
      @curr = @curr + [n]
      to_s
    end

    def pop
      *rest, tail = @curr
      @curr = rest
      to_s
    end
  end
end