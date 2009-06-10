require 'rack'
require 'lib/google_analytics'
require 'lib/cookie_auth'
require 'lib/rack/mime'
require 'lib/rack/index'

use Rack::CommonLogger
use Rack::ShowExceptions

# use Rack::Lint
use GoogleAnalytics, 'UA-1439623-2'
use CookieAuth, :auth_cookies => ['kwebauth', 'auth_ksdwebmin'], 
    :login_path => '/mgmt/xlogin', :mysql_db => 'ksdwebmin',
    :except => [ '/outreach' ], :whitelist => ['10.3.0.0/16', '10.4.0.0/16']
run Rack::Index.new('/Library/WebServer/kentweb/teacherweb', '/protected')
