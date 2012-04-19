class Service::TeamCity < Service
  string   :base_url, :build_type_id, :username
  password :password

  def receive_push
    # :(
    http.ssl[:verify] = false

    base_url = data['base_url'].to_s
    if base_url.empty?
      raise_config_error "No base url: #{base_url.inspect}"
    end

    http.url_prefix = base_url
    http.basic_auth data['username'].to_s, data['password'].to_s
    build_type_ids = data['build_type_id'].to_s
    build_type_ids.split(",").each do |build_type_id|
      res = http_get "httpAuth/action.html", :add2Queue => build_type_id
      case res.status
        when 200..299
        when 403, 401, 422 then raise_config_error("Invalid credentials")
        when 404, 301, 302 then raise_config_error("Invalid TeamCity URL")
        else raise_config_error("HTTP: #{res.status}")
      end
    end
  rescue SocketError => e
    raise_config_error "Invalid TeamCity host name" if e.to_s =~ /getaddrinfo: Name or service not known/
    raise
  end
end
