require 'time'

module Rack
  # Rack::File serves files below the +root+ given, according to the
  # path info of the Rack request.
  #
  # Handlers can detect if bodies are a Rack::File, and use mechanisms
  # like sendfile on the +path+.

  class Index
    attr_accessor :root
    attr_accessor :path
    attr_accessor :uri, :app_base, :index_files

    def initialize(root, app_base='/', index_files=%w(index.html index.htm))
      @root = root
      @app_base = app_base
      @index_files = index_files
    end

    def call(env)
      dup._call(env)
    end

    F = ::File

    def _call(env)
      return forbidden if env["PATH_INFO"].match(/(^|\/)\.\.($|\/$)/)

      @uri = Utils.unescape(env["PATH_INFO"])
      @path = F.join(@root, @uri)

      begin
        if accessible?(@path)
          serving
        elsif (test = index_file_path)
          if @uri[-1,1] == '/'
            @path = test
            serving
          else
            redirect(@uri + '/')
          end
        else
          raise Errno::EPERM
        end
      rescue SystemCallError
        not_found
      end
    end

    def forbidden
      body = "Forbidden\n"
      [403, {"Content-Type" => "text/plain",
             "Content-Length" => body.size.to_s},
       [body]]
    end

    # NOTE:
    #   We check via File::size? whether this file provides size info
    #   via stat (e.g. /proc files often don't), otherwise we have to
    #   figure it out by reading the whole file into memory. And while
    #   we're at it we also use this as body then.

    def serving
      if size = F.size?(@path)
        body = self
      else
        body = [F.read(@path)]
        size = body.first.size
      end

      [200, {
        "Last-Modified"  => F.mtime(@path).httpdate,
        "Content-Type"   => Mime.mime_type(F.extname(@path), 'text/plain'),
        "Content-Length" => size.to_s
      }, body]
    end

    def not_found
      body = "File not found: #{@path}\n"
      [404, {"Content-Type" => "text/plain",
         "Content-Length" => body.size.to_s},
       [body]]
    end

    def each
      F.open(@path, "rb") { |file|
        while part = file.read(8192)
          yield part
        end
      }
    end

    def accessible?(p)
      F.file?(p) && F.readable?(p)
    end

    def index_file_path
      @index_files.each do |fname|
        test = F.join(@path, fname)
        return test if accessible?(test)
      end
      nil
    end
  
    def redirect(loc)
      loc = F.join(@app_base, loc) if @app_base != '/'
      body = "Redirecting to #{loc}\n"
      [302, {"Content-Type" => "text/plain",
           "Content-Length" => body.size.to_s,
           "Location" => loc},
        [body]]
    end
  end
end
