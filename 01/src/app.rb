# -*- coding: utf-8 -*-
require 'tofu'
require 'pathname'
require 'pp'

module OTofu
  class Session < Tofu::Session
    def initialize(bartender, hint='')
      super
      @base = BaseTofu.new(self)
      @history = []
    end
    attr_reader :base, :history
    
    def do_GET(context)
      @history << [Time.now, context.req.path_info]
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