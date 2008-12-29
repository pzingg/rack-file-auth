require 'rack'
require 'lib/cookie_auth'
require 'lib/rack/mime'
require 'lib/rack/index'

use Rack::CommonLogger
use Rack::ShowExceptions

# use Rack::Lint
use CookieAuth, ['kwebauth', 'auth_ksdwebmin'], '/mgmt/xlogin'
run Rack::Index.new('/Library/WebServer/kentweb/teachers', '/static')
