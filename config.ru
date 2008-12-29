require 'rack'
require 'lib/cookie_auth'
require 'lib/rack/mime'
require 'lib/rack/index'

use Rack::CommonLogger
use Rack::ShowExceptions

# use Rack::Lint
use CookieAuth, :auth_cookies => ['kwebauth', 'auth_ksdwebmin'], 
    :login_path => '/mgmt/xlogin', :mysql_db => 'ksdwebmin'
run Rack::Index.new('/Library/WebServer/kentweb/teachers', '/static')
