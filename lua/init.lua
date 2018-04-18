-- 定义全局常量
get = "GET"
post = "POST"
del = "DELETE"
update = "UPDATE"
list = "LIST"


-- 定义全局变量
dyups_api_ip = "localhost:8082"

nginx_home = os.getenv("OPENRESTY_HOME") .. "/nginx"
balances_src = nginx_home .. "/conf/balances"

dynamic_http_servers_dir = nginx_home .. "/conf/balances/dynamic_http_servers"
dynamic_stream_servers_dir = nginx_home .. "/conf/balances/dynamic_stream_servers"
dynamic_upstreams_dir = nginx_home .. "/conf/balances/dynamic_upstreams"
dynamic_certs_dir = nginx_home .. "/conf/balances/dynamic_certs"

HTTP_OK = 205
HTTP_NOT_ALLOWED = 405

-- 导入自定义的全局模块
dyups = require('ngx.dyups')
cjsonf = require('cjson.safe')
utils = require('utils')
dao = require('dao')