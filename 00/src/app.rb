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
    attr_reader :base
    
    def do_GET(context)
      context.res_header('pragma', 'no-store')
      context.res_header('cache-control', 'no-store')
      context.res_header('expires', 'Thu, 01 Dec 1994 16:00:00 GMT')
      super(context)
    end

    def lookup_view(context)
      @base
    end

    def redirect_to_root(context)
      context.res.set_redirect(WEBrick::HTTPStatus::MovedPermanently,
                               context.req_script_name.to_s)
      context.done
    end

    def redirect_to(context, path)
      context.res.set_redirect(WEBrick::HTTPStatus::MovedPermanently,
                               context.req_script_name.to_s + path)
      context.done
    end

    def normalize_string(str)
      return '' unless str
      str.force_encoding('utf-8')
      str.strip
    end
  end

  class BaseTofu < Tofu::Tofu
    set_erb(__dir__ + '/base.html')
    reload_erb

    def initialize(session)
      super(session)
    end

    def tofu_id
      'base'
    end

    def pathname(context)
      Pathname.new(context.req_script_name)
    end
  end
end