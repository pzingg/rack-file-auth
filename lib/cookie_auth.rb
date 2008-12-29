require 'rack/auth/abstract/handler'
require 'rack/recursive'
require 'mysql'

class CookieAuth < Rack::Auth::AbstractHandler
  attr_reader :config

  def initialize(app, cfg={})
    @app = app
    @config = {
      :auth_cookies => [],
      :login_path => nil,
      :mysql_host => 'localhost',
      :mysql_user => 'rack',
      :mysql_password => 'rack',
      :mysql_db => 'rackauth',
      :mysql_query => "SELECT login FROM users WHERE remember_token='?'" 
    }.update(cfg)
  end

  def call(env)
    req = Rack::Request.new(env)
    @config[:auth_cookies].each do |cookie_name|
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

    if @config[:login_path]
      redirect(@config[:login_path], req.url)
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
    # old-style cookie (from perl's Apache::Cookie)
    m = cookie_value.match(/user\:([^:]+)\:/)
    return m[1] if !m.nil?

    # authlogic cookie - do mysql lookup
    m = cookie_value.match(/^[a-f0-9]+$/)
    if !m.nil?
      my = Mysql::new(@config[:mysql_host], 
      	 @config[:mysql_user], 
	 @config[:mysql_password],
	 @config[:mysql_db])

      sql = @config[:mysql_query].gsub(/\?/, cookie_value)
      res = my.query(sql)
      res.each do |row|
        return row[0]
      end
    end

    # should return false, but we want to permit user in
    cookie_name
  end
end
