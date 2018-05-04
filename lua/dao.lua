local _M = {}



-- ####################### upstream #######################

-- get upstream file path by upstream name
function _M.get_upstream_file(data_table)
    return string.format("%s/%s.%s.conf", dynamic_upstreams_dir, data_table.name, data_table.protocol)
end

-- 定义upstream文件模版
_M.temp_upstream =
[[upstream %s {
    %s
}]]

function _M.upstream_save(data_table)
    local name = data_table.name
    local upstream_file = _M.get_upstream_file(data_table)

    -- 将server列表拼接为多行形式
    local servers_line = ""
    for _, item in pairs(data_table.servers) do
        if servers_line == "" then
            servers_line = string.format("server %s weight=%s max_fails=3 fail_timeout=6s;", item.addr, item.weight)
        else
            servers_line = string.format("%s\n    server %s weight=%s max_fails=3 fail_timeout=6s;", servers_line, item.addr, item.weight)
        end
    end

    -- 生成完整文件内容
    local content = string.format(_M.temp_upstream, name, servers_line)

    -- 写入文件
    local file = io.open(upstream_file, "w+")
    file:write(content)
    file:close()

    -- 检查文件合法性
    return utils.shell(utils.cmd_check_nginx, "0")
end

function _M.upstream_delete(data_table)
    local upstream_file = _M.get_upstream_file(data_table)
    return utils.shell("rm -f "..upstream_file)
end




-- ####################### server #######################

-- 根据server名字获取文件名
function _M.get_server_file(data_table)
    return string.format("%s/%s.%s.conf", dynamic_servers_dir, data_table.name, data_table.protocol)
end

-- 根据server名字获取证书文件名
function _M.get_cert_filename(server_name)
    return dynamic_certs_dir.."/"..server_name..".cert"
end

-- 根据server名字获取私钥文件名
function _M.get_key_filename(server_name)
    return dynamic_certs_dir.."/"..server_name..".key"
end


-- 定义http_server配置模版
_M.temp_http_server =
[[server {
    listen %s;
    server_name %s;
    %s
    error_page 404 500 502 503 504 /waiting.html;
    location = /waiting.html {
        root html;
    }

    location %s {
        set $upstream "%s";
        proxy_set_header Host $host:$server_port;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_redirect off;

        proxy_pass http://$upstream;
    }
}]]

-- 定义http转https配置模版
_M.temp_http_to_https =
[[server {
    listen %s;
    server_name %s;
    return 301 https://$host$request_uri;
}]]

-- 定义https_server配置模版
_M.temp_tls_server =
[[server {
    listen %s ssl;
    server_name %s;
    ssl_certificate %s;
    ssl_certificate_key %s;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers HIGH:!aNULL:!MD5;
    %s
    error_page 404 500 502 503 504 /waiting.html;
    location = /waiting.html {
        root html;
    }

    location %s {
        set $upstream "%s";
        proxy_set_header Host $host:$server_port;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_redirect off;

        proxy_pass http://$upstream;
    }
}]]

-- 定义stream_server配置模版
_M.temp_stream_server =
[[server {
    listen %s so_keepalive=on;
    proxy_connect_timeout 1s;
    proxy_timeout 3s;
    %s
    proxy_pass %s;
}]]

-- 保存server配置文件
function _M.server_save(data_table)
    local server_name = data_table.name
    local protocol = data_table.protocol
    -- 生成配置文件内容
    local options = ""
    for k, v in pairs(data_table.options) do
        if options == "" then
            options = string.format("%s %s;", k, v)
        else
            options = options .. string.format("    \n%s %s;", k, v)
        end
    end

    -- 根据协议选择相应模版，生成文件
    local content = ""
    if protocol == "https" then
        local cert = _M.get_cert_filename(server_name)
        local key = _M.get_key_filename(server_name)
        content = string.format(_M.temp_tls_server, data_table.port, data_table.domain, cert, key, options, data_table.path, data_table.upstream)
    elseif protocol == "http" then
        if data_table.toHTTPS then
            content = string.format(_M.temp_http_to_https, data_table.port, data_table.domain)
        else
            content = string.format(_M.temp_http_server, data_table.port, data_table.domain, options, data_table.path, data_table.upstream)
        end
    else
        content = string.format(_M.temp_stream_server, data_table.port, options, data_table.upstream)
    end

    -- 写入文件
    local file = io.open(_M.get_server_file(data_table), "w+")
    file:write(content)
    file:close()
end

-- 删除server配置文件
function _M.server_delete(data_table)
    utils.shell("rm -f ".._M.get_server_file(data_table).."; echo $?", "0")
end

-- 如果该server对应的证书已存在，则返回true
function _M.certs_is_exists(server_name)
    local is_exists = true
    local r1 = utils.shell(string.format("ls %s | grep '^%s.cert$'", dynamic_certs_dir, server_name))
    local r2 = utils.shell(string.format("ls %s | grep '^%s.key$'", dynamic_certs_dir, server_name))

    if r1 == "0" and r2 == "0" then
        is_exists = false
    end

    return is_exists
end

-- 将证书和私钥的文件内容保存为文件
function _M.certs_save(server_name, cert_content, key_content)
    utils.shell(string.format("echo -n '%s' > %s/%s.cert", cert_content, dynamic_certs_dir, server_name))
    utils.shell(string.format("echo -n '%s' > %s/%s.key", key_content, dynamic_certs_dir, server_name))
end

-- 删除server对应的证书和私钥
function _M.certs_del(server_name)
    utils.shell(string.format("/bin/rm -f %s/%s.cert", dynamic_certs_dir, server_name))
    utils.shell(string.format("/bin/rm -f %s/%s.key", dynamic_certs_dir, server_name))
end



return _M
