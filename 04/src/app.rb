# -*- coding: utf-8 -*-
require 'tofu'
require 'pathname'
require 'pp'
require_relative './mail_config'
require_relative './questionnaire'

module Tofu
  class Tofu
    def normalize_string(str_or_param)
      str ,= str_or_param
      return '' unless str
      str.force_encoding('utf-8').strip
    end
  end
end

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
  end

  class BaseTofu < Tofu::Tofu
    set_erb(__dir__ + '/base.html')

    def initialize(session)
      super(session)
      @login = LoginTofu.new(session)
      @que = QuestionnaireTofu.new(session)
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
      @login.show = true
    end

    def do_logout(context, params)
      @session.logout
    end
  end

  class QuestionnaireTofu < Tofu::Tofu
    set_erb(__dir__ + '/questionnaire.html')
    reload_erb

    def title
      "フォームのサンプル"
    end

    def doc
      sec = Que::SecNumber.new([2, 1])
      sec.push
      [
        { 'type' => 'text', 'id' => sec.next, 'label' => '質問です。'},
        { 'type' => 'text', 'id' => sec.next, 'label' => '質問です。'},
        { 'type' => 'textarea', 'id' => sec.next, 'label' => '質問です。'},
        { 'type' => 'radio', 'id' => sec.next, 'label' => 'radio buttonです。',
          'option' => [1, 2, 3, 4, [5, '外れ値']],
          'inline' => true
        },
        { 'type' => 'radio', 'id' => sec.next, 'label' => 'radio buttonです。',
          'option' => %w(あたり はずれ),
          'inline' => false
        },
        { 'type' => 'checkbox', 'id' => sec.next, 'label' => 'checkboxです。',
          'option' => %w(那須塩原 西那須野 野崎 矢板),
          'inline' => false
        }
      ]
    end
  end

  class LoginTofu < Tofu::Tofu
    set_erb(__dir__ + '/login.html')
    reload_erb

    def initialize(session)
      super(session)
      @confirm = nil
      @curr_hint = @session.hint
      @show = false
    end
    attr_accessor :show

    def sent?
      ! @confirm.nil?
    end

    def tofu_id
      'login'
    end

    def valid_email?(email)
      @session.valid_email?(email)
    end

    def do_send(context, params)
      email = normalize_string(params['email'])
      return unless valid_email?(email)

      @email = email
      @curr_hint = email

      @confirm = "%06d" % rand(1000000)
      p [:confirm, @confirm]

      send_mail(email, context)
    end

    def do_login(context, params)
      password = normalize_string(params['password'])

      if @confirm == password
        @session.login(@email)
        @confirm = nil
        @show = false
      end
    end

    def do_resend(context, params)
      @confirm = nil
      @show = false
    end

    def send_mail(addr, context)
      content = <<EOM
次の6桁の数字を入力してください。
   #{@confirm}

5分間有効です。
EOM
      mail = Mail.deliver do
        to addr
        from 'noreply@example.com'
        subject 'ワンタイムパスワード送付'
        text_part do
          body content
          content_type 'text/plain; charset=UTF-8'
        end
      end
    end
  end
end