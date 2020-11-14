require 'webrick'
require 'tofu'
require_relative 'src/app'

port = Integer(ENV['PORT']) rescue 8000
server = WEBrick::HTTPServer.new({
  :Port => port,
  :FancyIndexing => false
})

tofu = Tofu::Bartender.new(OTofu::Session, 'otofu')
server.mount('/app', Tofu::Tofulet, tofu)

server.mount_proc('/') {|req, res|
  res['Pragma'] = 'no-store'
  res.set_redirect(WEBrick::HTTPStatus::MovedPermanently, '/app')
}

trap(:INT){exit!}
server.start
