# -*- coding: utf-8 -*-
require 'tofu'
require 'pathname'
require 'pp'

module OTofu
  class Session < Tofu::Session
    def initialize(bartender, hint='')
      super
      @base = BaseTofu.new(self)
    end
    
    def do_GET(context)
      context.res_header('cache-control', 'no-store')
      super(context)
    end

    def lookup_view(context)
      @base
    end
  end

  class BaseTofu < Tofu::Tofu
    set_erb(__dir__ + '/base.html')

    def initialize(session)
      super(session)
    end

    def tofu_id
      'base'
    end

    def pathname(context)
      script_name = context.req_script_name
      script_name = '/' if script_name.empty?
      Pathname.new(script_name)
    end
  end
end