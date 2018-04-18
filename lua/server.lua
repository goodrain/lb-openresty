--[[实现对server的操作，并写入配置文件，server对应上层的一条规则]]

local server_name = ngx.var.src_name

local function GET()
    local str = utils.exec(string.format("ls %s|grep -e '.conf$'|awk -F '.' '{print $1}'", dynamic_http_servers_dir))
    local arr = utils.split(str, "\n")
    local json = cjsonf.encode(arr)

    ngx.log(ngx.INFO, json)
    ngx.status = HTTP_OK
    ngx.print(json)
end

-- 更新指定server
local function UPDATE()
    -- 获取请求体，数据格式如下：
    -- {"name": "voa1i9kc_gr9e98de_8088.Rule", "domain": "myapp.sycki.com", "port": 8085, "path": "/", "protocol": "https", "transferHTTP": "false", "cert": "thiscert", "key": "thiskey", "options": {}, "upstream": "5000.grb5060d.vzrd9po6"}
    -- upstream字段是一个不带后缀的域名，在这里需要拼接为一个完整域名
    ngx.req.read_body()
    local data_str = ngx.req.get_body_data()
    ngx.log(ngx.INFO, "POST server ", ngx.req.get_body_data())

    -- 转为map形式
    local data_table = cjsonf.decode(data_str)
    data_table.upstream = data_table.upstream .. "." .. http_suffix_url

    -- 如果用户添加自定义域名是http to https类型，则会有两个相同的server名字
    -- 为了区分它们，给http类型的文件名加一个前缀，删除的时候，两个一起删
    if data_table.transferHTTP == true then
        data_table.name = "transferHTTP."..server_name
    else
        data_table.name = server_name
    end

    -- 保存证书
    if data_table.protocol == "https" then
        dao.certs_save(server_name, data_table.cert, data_table.key)
        if not dao.certs_is_exists(server_name) then
            local msg = "failed save cert or key file for server "..server_name
            ngx.log(ngx.ERR, msg)

            ngx.status = 517
            ngx.print(msg)
            return
        end
    end

    -- 根据协议名称获取文件全名
    local filename = dao.get_server_file(data_table.name, data_table.protocol)

    -- 如果文件存在则备份
    local is_exists = utils.file_is_exists(filename)
    if is_exists then
        utils.file_backup(filename)
    end

    -- 更新持久层
    dao.server_save(data_table)

    -- 热加载配置
    local err = utils.shell(utils.cmd_restart_nginx, "0")

    -- 处理结果
    if err ~= nil then
        -- 合并日志信息
        ngx.log(ngx.ERR, err)
        ngx.status = HTTP_NOT_ALLOWED
        ngx.print(err)

        -- 如果配置文件错误则恢复到之前的状态
        if is_exists then
            utils.file_recover(filename)
        else
            dao.server_delete(server_name, data_table.protocol)
        end
    else
        ngx.status = HTTP_OK
        ngx.print("success")

        -- 如果配置文件正常加载则清除备份文件
        utils.file_clean_bak(filename)
    end

end

-- 创建指定server
local function POST()
    UPDATE()
end

local function DELETE()
    local protocol = ngx.req.get_uri_args()["protocol"]
    if protocol == nil or string.len(protocol) > 4 or string.match(protocol, "%a+") == nil then
        ngx.status = HTTP_NOT_ALLOWED
        ngx.print("The parameter is incorrect")
        return
    end

    -- 更新持久层
    dao.server_delete(server_name, protocol)

    -- 热加载配置
    utils.shell(utils.cmd_restart_nginx, "0")

    -- 处理结果
    ngx.status = HTTP_OK
    ngx.print("success")
end


-- 处理请求
local function main()
    local method = ngx.req.get_method()

    if method == post then
        POST()
    elseif method == del then
        DELETE()
    elseif method == update then
        UPDATE()
    elseif method == get then
        GET()
     else
        ngx.status = ngx.HTTP_NOT_FOUND
    end
end

main()
