local _M = {}




-- ####################### upstream for http #######################

-- get upstream file path by upstream name
function _M.get_http_upstream_file(name)
    return dynamic_http_upstreams_dir.."/"..name..".conf"
end

-- get upstream file path by upstream name
function _M.get_stream_upstream_file(name)
    return dynamic_stream_upstreams_dir.."/"..name..".conf"
end

-- 定义upstream文件模版
_M.temp_upstream =
[[upstream %s {
    %s
}]]

function _M.http_upstream_read(name)
    local name = utils.exec(string.format([[cat %s | grep 'upstream ' | awk '{print $2}']], _M.get_http_upstream_file(name)))
    local ip_list = utils.split(utils.exec(string.format([[cat %s | grep 'server ' | awk '{print $2}' | tr -d ';']], _M.get_http_upstream_file(name))),"\n")

    local tab = {}
    tab.name = name
    tab.servers = ip_list

    return tab
end

function _M.http_upstream_save(data_table)
    local name = data_table.name
    local upstream_file = _M.get_http_upstream_file(name)

    -- 将server列表拼接为多行形式
    local servers_line = ""
    for _, item in pairs(data_table.servers) do
        if servers_line == "" then
            servers_line = "server " .. item .. ";"
        else
            servers_line = servers_line .. "\n    server " .. item .. ";"
        end
    end

    -- 生成完整文件内容
    local content = string.format(_M.temp_upstream, name, servers_line)

    -- 写入文件
    local file = io.open(upstream_file, "w+")
    file:write(content)
    file:close()
end

function _M.http_upstream_delete(name)
    local upstream_file = _M.get_http_upstream_file(name)
    return utils.shell("rm -f "..upstream_file)
end




-- ####################### upstream for stream #######################

function _M.stream_upstream_read(name)
    local name = utils.exec(string.format([[cat %s | grep 'upstream ' | awk '{print $2}']], _M.get_stream_upstream_file(name)))
    local ip_list = utils.split(utils.exec(string.format([[cat %s | grep 'server ' | awk '{print $2}' | tr -d ';']], _M.get_stream_upstream_file(name))),"\n")

    local tab = {}
    tab.name = name
    tab.servers = ip_list

    return tab
end

function _M.stream_upstream_save(data_table)
    local name = data_table.name
    local upstream_file = _M.get_stream_upstream_file(name)

    -- 将server列表拼接为多行形式
    local servers_line = ""
    for _, item in pairs(data_table.servers) do
        if servers_line == "" then
            servers_line = "server " .. item .. ";"
        else
            servers_line = servers_line .. "\n    server " .. item .. ";"
        end
    end

    -- 生成完整文件内容
    local content = string.format(_M.temp_upstream, name, servers_line)

    -- 写入文件
    local file = io.open(upstream_file, "w+")
    file:write(content)
    file:close()
end

function _M.stream_upstream_delete(name)
    local upstream_file = _M.get_stream_upstream_file(name)
    return utils.shell("rm -f "..upstream_file)
end


-- 根据server名字获取文件名
function _M.get_stream_server_file(server_name)
    return dynamic_stream_servers_dir.."/"..server_name..".conf"
end

-- 根据server名字获取文件名
function _M.get_http_server_file(server_name)
    return dynamic_http_servers_dir.."/"..server_name..".conf"
end

-- 根据server名字获取证书文件名
function _M.get_cert_filename(server_name)
    return dynamic_certs_dir.."/"..server_name..".cert"
end

-- 根据server名字获取私钥文件名
function _M.get_key_filename(server_name)
    return dynamic_certs_dir.."/"..server_name..".key"
end




-- ####################### server for http #######################

-- 定义https_server文件模版
_M.temp_tls_server =
[[server {
    listen %s;
    server_name %s;
    ssl_certificate %s;
    ssl_certificate_key %s;
    %s

    location %s {
        proxy_pass http://%s;
    }
}]]

-- 定义http_server文件模版
_M.temp_http_server =
[[server {
    listen %s;
    server_name %s;
    %s

    location %s {
        proxy_pass http://%s;
    }
}]]

-- 保存server配置文件
function _M.http_server_save(server_name, data_table)
    local server_file = _M.get_http_server_file(server_name)
    -- 生成配置文件内容
    local options = ""
    for k, v in pairs(data_table.options) do
        if options == "" then
            options = string.format("%s %s;", k, v)
        else
            options = options .. string.format("    \n%s %s;", k, v)
        end
    end

    local content = ""

    if data_table.protocol == "https" then
        local cert = _M.get_cert_filename(server_name)
        local key = _M.get_key_filename(server_name)
        content = string.format(_M.temp_tls_server, data_table.port, data_table.domain, cert, key, options, data_table.path, data_table.upstream)
    else
        content = string.format(_M.temp_http_server, data_table.port, data_table.domain, options, data_table.path, data_table.upstream)
    end

    -- 写入文件
    local file = io.open(server_file, "w+")
    file:write(content)
    file.close()
end

-- 读取server配置文件，TODO 暂时不能读出options部分
function _M.http_server_read(name)
    local port = utils.exec(string.format([[cat %s | grep 'listen ' | awk '{print $2}' | tr -d ';']], _M.get_http_server_file(name)))
    local domain = utils.exec(string.format([[cat %s | grep 'server_name ' | awk '{print $2}' | tr -d ';']], _M.get_http_server_file(name)))
    local cert = utils.exec(string.format([[cat %s]], _M.get_cert_filename(name)))
    local key = utils.exec(string.format([[cat %s]], _M.get_key_filename(name)))
    local path = utils.exec(string.format([[cat %s | grep 'location ' | awk '{print $2}' | tr -d '{'|tee /dev/stderr]], _M.get_http_server_file(name)))
    local upstream = utils.exec(string.format([[cat %s | grep 'proxy_pass ' | awk -F '//' '{print $2}' | tr -d ';']], _M.get_http_server_file(name)))
    local options = {}
    local protocol = ""
    if string.len(cert) > 1 then
        protocol = "https"
    end

    local tab = {}
    tab.name = name
    tab.domain = domain
    tab.port = tonumber(port)
    tab.path = path
    tab.protocol = protocol
    tab.cert = cert
    tab.key = key
    tab.options = options
    tab.upstream = upstream

    return tab
end

-- 删除server配置文件
function _M.http_server_delete(server_name)
    utils.shell("rm -f ".._M.get_http_server_file(server_name).."; echo $?", "0")
    _M.certs_del(server_name)
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




-- ####################### upstream for stream #######################

-- 定义stream_server文件模版
_M.temp_stream_server =
[[server {
    listen %s;
    %s
    proxy_pass %s;
}]]

-- 写入配置文件
function _M.stream_server_save(data_table)
    local server_file = _M.get_stream_server_file(data_table.name)

    -- 生成配置文件内容
    local options = ""
    for k, v in pairs(data_table.options) do
        if options == "" then
            options = string.format("%s %s;", k, v)
        else
            options = options .. string.format("    \n%s %s;", k, v)
        end
    end

    local content = string.format(_M.temp_stream_server, data_table.port, options, data_table.upstream)

    -- 写入文件
    local file = io.open(server_file, "w+")
    file:write(content)
    file.close()
end

-- 读取stream server配置文件，TODO 暂时不能读出options部分
function _M.stream_server_read(name)
    local port = utils.exec(string.format([[cat %s | grep 'listen ' | awk '{print $2}' | tr -d ';']], _M.get_stream_server_file(name)))
    local cert = utils.exec(string.format([[cat %s]], _M.get_cert_filename(name)))
    local upstream = utils.exec(string.format([[cat %s | grep 'proxy_pass ' | awk -F '//' '{print $2}' | tr -d ';']], _M.get_stream_server_file(name)))
    local options = {}
    local protocol = ""
    if string.len(cert) > 1 then
        protocol = "https"
    end

    local tab = {}
    tab.name = name
    tab.port = (port + 0)
    tab.options = options
    tab.upstream = upstream

    return tab
end

function _M.stream_server_delete(name)
    utils.shell("/bin/rm -f ".._M.get_stream_server_file(name).."; echo $?", "0")
end



return _M