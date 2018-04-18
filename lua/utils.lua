local _M = {}

-- 定义字段
-- _M.cmd_restart_nginx = "kill -HUP `ps -ef|grep -e 'nginx: master'|grep -v grep|awk '{print $1}'|head -n 1`; echo $?"
_M.cmd_restart_nginx = nginx_home .."/sbin/nginx -s reload; echo $?"
_M.cmd_check_nginx = nginx_home .."/sbin/nginx -t; echo $?"


-- 用指定的分割符sep切分字符串str，将结果封装到一个数组中并返回
function _M.split(str, sep)
    local arr = {}
    local i = 1
    for token in string.gmatch(str, "[^"..sep.."]+") do
       arr[i] = token
       i = i + 1
    end
    return arr
end


-- 执行指定命令，如果执行日志的最后一行不是预期的断言则认为执行失败并返回错误信息，执行成功则返回nil
function _M.shell(cmd, assert)
    local f = io.popen("{ " .. cmd .. "; }" .. " 2>&1")
    local log = f:read("*a")
    f:close()

    log = string.reverse(string.gsub(string.reverse(log), "\n", "", 1))

    local lines = _M.split(log, "\n")
    local result = lines[table.getn(lines)]

    if assert ~= nil then
        if result ~= assert then
            ngx.status = 555
            ngx.log(ngx.ERR, "failed cmd ["..cmd.."] => ["..log.."] ["..result.."/"..assert.."]")
            return log
        end

        return nil
    end

    return nil
end


-- 执行指定命令，返回标准输出
function _M.exec(cmd)
    local f = io.popen(cmd)
    local log = f:read("*a")
    f:close()

    log = string.reverse(string.gsub(string.reverse(log), "\n", "", 1))

    return log
end


-- 备份与恢复
function _M.file_is_exists(filename)
    local r = _M.exec(string.format("ls %s 2>/dev/null|wc -l", filename))

    if r == "0" then
        return false
    else
        return true
    end
end

function _M.file_backup(filename)
    _M.shell(string.format("/bin/cp -f %s %s.bak", filename, filename))
end

function _M.file_recover(filename)
    _M.shell(string.format("/bin/mv -f %s.bak %s", filename, filename))
end

function _M.file_clean_bak(filename)
    _M.shell(string.format("/bin/rm -f %s.bak", filename))
end


return _M