require 'rack/auth/abstract/handler'
require 'rack/recursive'

class CookieAuth < Rack::Auth::AbstractHandler
  def initialize(app, auth_cookies=[], login_path=nil)
    @app = app
    @auth_cookies = auth_cookies
    @login_path = login_path
  end

  def call(env)
    req = Rack::Request.new(env)
    @auth_cookies.each do |cookie_name|
      if req.cookies.key?(cookie_name)
        cookie_value = req.cookies[cookie_name]
        user = valid_user(cookie_name, cookie_value)
        if user
          env['REMOTE_USER'] = user
          status, headers, body = @app.call(env)
          headers['X-Cookie-Auth-Via'] = cookie_name
          return [status, headers, body]
        end
      end
    end

    if @login_path
      redirect(@login_path, req.url)
    else
      unauthorized
    end
  end
  
  private

  def redirect(loc, original_url)
    body = "Redirecting to #{loc} for authentication for #{original_url}\n"
    loc = loc + "?uri=" + Rack::Utils.escape(original_url)
    [302, {"Content-Type" => "text/plain",
           "Content-Length" => body.size.to_s,
           "Location" => loc},
     [body]]
  end
  
  def unauthorized(www_authenticate='Basic')
    return [ 401, { 'WWW-Authenticate' => www_authenticate.to_s }, [] ]
  end

  def bad_request
    [ 400, {}, [] ]
  end
  
  def valid_user(cookie_name, cookie_value)
    m = cookie_value.match(/user\:([^:]+)\:/)
    # TODO: parse the cookie using authlogic?
    m.nil? ? cookie_name : m[1]
  end

end
