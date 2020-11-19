# -*- coding: utf-8 -*-
require 'tofu'
require 'pathname'
require 'pp'
require_relative './mail_config'

module OTofu
  class Session < Tofu::Session
    def initialize(bartender, hint='')
      super
      @base = BaseTofu.new(self)
      @user = nil
    end
    attr_reader :user
    
    def do_GET(context)
      context.res_header('cache-control', 'no-store')
      super(context)
    end

    def lookup_view(context)
      @base
    end

    def valid_email?(email)
      valid = %w(ikezawa@nasuinfo.or.jp m_seki@mac.com m_seki@mva.biglobe.ne.jp)
      valid.include?(email)
    end

    def login(email)
      @user = email
      @hint = email
    end

    def logout
      @user = nil
    end

    def normalize_string(str)
      return '' unless str
      str.force_encoding('utf-8')
      str.strip
    end
  end

  class BaseTofu < Tofu::Tofu
    set_erb(__dir__ + '/base.html')

    def initialize(session)
      super(session)
      @login = LoginTofu.new(self)
    end

    def tofu_id
      'base'
    end

    def pathname(context)
      script_name = context.req_script_name
      script_name = '/' if script_name.empty?
      Pathname.new(script_name)
    end

    def do_login(context, params)
      @session.login('test')
    end

    def do_logout(context, params)
      @session.logout
    end
  end

  class LoginTofu < Tofu::Tofu
    set_erb(__dir__ + '/login.html')
    reload_erb

    def initialize(session)
      super(session)
      @sent = false
      @confirm = nil
      @curr_hint = @session.hint
    end

    def tofu_id
      'login'
    end

    def do_send(context, params)
      email ,= params['email']
      email = @session.normalize_string(email)
      return if email.empty?

      return unless @session.valid_email?(email)

      @email = email
      @curr_hint = email

      @sent = true
      @confirm = "%06d" % rand(1000000)
      p [:confirm, @confirm]

      send_mail(email, context)
    end

    def do_login(context, params)
      password ,= params['password']
      password = @session.normalize_string(password)
      return if password.empty?
      if @confirm == password
        @session.login(@email)
        @sent = false
        @confirm = nil
      end
    end

    def do_resend(context, params)
      @sent = false
      @confirm = nil
    end

    def send_mail(addr, context)
      content = <<EOM
次の6桁の数字を入力してください。
   #{@confirm}

5分間有効です。
EOM
      mail = Mail.deliver do
        to addr
        from 'noreply@jdesign.co.jp'
        subject 'ワンタイムパスワード送付'
        text_part do
          body content
          content_type 'text/plain; charset=UTF-8'
        end
      end
    end
  end
end