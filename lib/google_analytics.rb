
class GoogleAnalytics
  def initialize(app, ga_acct_id)
    @app = app
    @end_body_re = Regexp.new('</body>', Regexp::IGNORECASE)
    @ga_acct_id = ga_acct_id
    @ga_script = <<END_SCRIPT
<script type=\"text/javascript\">
var gaJsHost = ((\"https:\" == document.location.protocol) ? \"https://ssl.\" : \"http://www.\");
document.write(unescape(\"%3Cscript src='\" + gaJsHost + \"google-analytics.com/ga.js' type='text/javascript'%3E%3C/script%3E\"));
</script>
<script type=\"text/javascript\">
var pageTracker = _gat._getTracker(\"#{@ga_acct_id}\");
pageTracker._initData();
pageTracker._trackPageview();
</script>
</body>
END_SCRIPT
  end

  def call(env)
    status, headers, body = @app.call(env)
    if status == 200 && (headers['Content-Type'] || '').index("text/") == 0
      body_s = ''
      if body.is_a?(String)
        body_s = body
      else
        body.each { |chunk| body_s << chunk }
      end
      if body_s.rindex(@ga_acct_id) == nil
        m = @end_body_re.match(body_s)
        if m
          offset = m.offset(0)
          body_s[offset[0], offset[1]-offset[0]] = @ga_script
          headers['Content-Length'] = body_s.size.to_s
          body = body_s
        end
      end
    end
    [status, headers, body]
  end

end
