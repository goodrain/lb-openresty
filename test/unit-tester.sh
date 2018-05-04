#!/bin/bash

# You must execute build.sh before executing this script


# setup functions
tester(){
  if [[ x$3 == x ]]; then
    r=`curl -X $1 -s $ip:$port/v1/$2`
    printf "%-7s %-20s =>  $r\n" $1 $2
  else
    r=`curl -X $1 $ip:$port/v1/$2 -sd "$3"`
    printf "%-7s %-20s =>  $r\n" $1 $2
  fi
}


# setup variable
ip="localhost"
port="10002"
name=${1:-app1}


# testing
json_https='{"name": "app1", "domain": "myapp.sycki.com", "port": 8085, "path": "/", "protocol": "https", "toHTTPS": "false", "cert": "-----BEGIN CERTIFICATE-----
MIID3jCCAsagAwIBAgIUMVptyX8awjdL0KKgiRJB1lFDHGMwDQYJKoZIhvcNAQEL
BQAwZTELMAkGA1UEBhMCQ04xEDAOBgNVBAgTB0JlaUppbmcxEDAOBgNVBAcTB0Jl
aUppbmcxDDAKBgNVBAoTA2s4czEPMA0GA1UECxMGU3lzdGVtMRMwEQYDVQQDEwpr
dWJlcm5ldGVzMB4XDTE4MDQwMzA3NDcwMFoXDTI4MDMzMTA3NDcwMFowbDELMAkG
A1UEBhMCQ04xEDAOBgNVBAgTB0JlaUppbmcxEDAOBgNVBAcTB0JlaUppbmcxDDAK
BgNVBAoTA2s4czEPMA0GA1UECxMGU3lzdGVtMRowGAYDVQQDExFzeXN0ZW06a3Vi
ZS1wcm94eTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBANzNUTt5Ig4L
E0jntbouzA741ByGl+5Jqu9ufBYbVEqwfBDbV7kcpenTp70TPPfxU2dscx2L3asS
PImKBWSjEuI8lduEDoOlcJZ2s5Pd21MDFzK0XYeofZdlg9KW+LZ19CvHTNemWZ/l
v+qHl/vf9BwDzSwhNVRBvhZoYPu69pdUS0tVIV/nR/F56OIYOLPpMJe6vaBjBM3l
DYf7rASKdhwB3zmHDbslrivwHOnuN49NNAeugWhnclSYoIgY/dShdl1y271Q7PVt
sfE1vjK2d+T8uAuWlH7eJt21hDQo4U5i1tO2AM45eflcSAZ2YW49cfoxJR8XsumL
veGVtISQwF0CAwEAAaN/MH0wDgYDVR0PAQH/BAQDAgWgMB0GA1UdJQQWMBQGCCsG
AQUFBwMBBggrBgEFBQcDAjAMBgNVHRMBAf8EAjAAMB0GA1UdDgQWBBQKKzt9VU+9
6xXiX6T2mlzHKJuNVDAfBgNVHSMEGDAWgBTAr6Vp8JvQ8BtnmQNNpZv4B9fEBzAN
BgkqhkiG9w0BAQsFAAOCAQEAI1XlFKnslJpyUyr09PBBMStZr7nmwRDOeMf0yPWx
GnHTsUtHj9NMjXOe1iW9Bz8W2K6r1GYbrnVvME6HB3SmvnljvSnJt7D2dcqwEq+V
8U5B8BBawgbiBvg+VPr03CrKKiWdJ2tjQbSW33w82aPUGNQLEGAalD8jB5+GK2uE
/8zJlAAvfkQ9sK8jA++pWx/x00qTrw0IBPF3IGy63qwkI+7Hs0WrdF43Ej28XkJm
t06LjuqXkiFI+/4tFUpiGX/QM9M1CqrGbBVoND/G4wLQbQNvv0C83yiKX6OajI1M
yS3YkZVmMKjHEr4l2xTyPogMIGiYwJ6fFtKU+anXQby7uA==
-----END CERTIFICATE-----", "key": "-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA3M1RO3kiDgsTSOe1ui7MDvjUHIaX7kmq7258FhtUSrB8ENtX
uRyl6dOnvRM89/FTZ2xzHYvdqxI8iYoFZKMS4jyV24QOg6Vwlnazk93bUwMXMrRd
h6h9l2WD0pb4tnX0K8dM16ZZn+W/6oeX+9/0HAPNLCE1VEG+Fmhg+7r2l1RLS1Uh
X+dH8Xno4hg4s+kwl7q9oGMEzeUNh/usBIp2HAHfOYcNuyWuK/Ac6e43j000B66B
aGdyVJigiBj91KF2XXLbvVDs9W2x8TW+MrZ35Py4C5aUft4m3bWENCjhTmLW07YA
zjl5+VxIBnZhbj1x+jElHxey6Yu94ZW0hJDAXQIDAQABAoIBAQDcIosZa0Rrkdkx
N2oz7FIfny8CHaI9vQ6B1bo65BZevKOEvtovwQMdI5q5ZAPGAsCvfS0ryPVAiFb4
nTWRRxAdpF+X0ooR8BBWwpN5GZh/o7YuJCqXhIFqPph1jXT7nI/KUdInsj7qrslv
Dq6VPIuInrWgiJ89mKnmdzwx3Q3agiJwm19+cHIIqlHttw2vtMJL4VWCsNY4TjsA
oxRtui0Uv6szoJi+bd65UryRCleZxrS51yO+BlS8RC72cJKOW+Ss/x76NhlFGPek
zhCuYtslIxWhVLMWavH72l+mZromJF5IDOI24TPnJZh3DHDi+r+/17sEG8IFhbOl
o4ujUoWBAoGBAPfQLz+9kvpHdpZEZfj4LR46ESKybB90upyQmirRMyPV4+sNbdTh
LTLcRfAqHv0AcYn1u/XHwkucKukfzWKkx22xG6bGLTxLH2DVZRYfi5I1RRkjUqOF
zFVUUPSs5lyHCnCU22BbXaI923mFYyOi7tQEQySPS8cDXzDs0z3RP4HhAoGBAOQY
sU3SxaRop6x+04LtrxBaeYWJejh/Ahyfm+EOTDXqXpn4Y6G9qRUOyMlql744Do+8
IqUPDQnnqCQjWAK8muYNz2p/ACnYXIVMNC8trsOhhHbF9zeDPButphp2ZiqpIKDn
k0xLVgL2a6Wb9gZgPZchFLqBC8vsSYgWrF5rxAX9AoGAaPTunhN/pasQydIMUmdi
TJQRX92rt6LrypXgBdR20W2sy4fzhZ8dUpZCtNZSK5u9es3uHsnNO9LXxcbnaSkb
IhVJ/defnxK+JngbCUSxC2qualgwjvuDMHy2kPqN0pCLVmVliKkJvkZup0hcVeKT
Po7TlS9vy8lczs7vJRZzzGECgYEAxYKwPVBOvi+1SYPEyTHhjoqZgc1qnPM1s+1t
gDLuQR2B71eLhmmBuO9FZEu9vAQ0b7gcU8s1oicLjMdiFXSVuLGqsm/oh1OHwhEb
euLW2yXIW0TO7i3gZaM3GuD9VOGAlHQSM1Vk1EnnKs9i+WBq1KvblCfcPCeOAJ6J
gXVVl00CgYBqwmcF4GjckhWsNh49vK8QJBTgqCY/0VKUGOpOcLj82mjf0+QL0X2z
jm2fCQ2VMZt+Vuc6ojxKaNE1nLIZGT6dvjA+0qgun49fQssKZFUJqF/fJ+fjs6JD
sBWnz/W6pQUuvatbxdx9UEd6OKhDM2cvRJ6HKW8Pnulj+hfL1SJp6g==
-----END RSA PRIVATE KEY-----", "options": {}, "upstream": "app1"}'


# 创建一个upstream，在创建server时，相应的upstream必须是已存在的
json='{"name": "app1", "servers": [{"addr":"127.0.0.1:8088", "weight": 5}, {"addr":"127.0.0.1:8089", "weight": 5}], "protocol": "http"}'
tester UPDATE upstreams/$name "$json"
tester GET upstreams '{"protocol": "http"}'


# 为tcp类型的server创建一个upstream，在创建server时，相应的upstream必须是已存在的
json='{"name": "app2", "servers": [{"addr":"127.0.0.1:8088", "weight": 5}, {"addr":"127.0.0.1:8089", "weight": 5}], "protocol": "tcp"}'
tester UPDATE upstreams/app2 "$json"
tester GET upstreams '{"protocol": "tcp"}'

# https类型的服务，证书会与服务同时保存和删除
tester UPDATE servers/$name "$json_https"
tester GET servers '{"protocol": "https"}'
tester DELETE servers/$name '{"protocol": "https"}'


# http类型的服务，如果toHTTPS字段为true，将会把http://myapp.sycki.com所有请求重定向到https://myapp.sycki.com
json='{"name": "app1", "domain": "myapp.sycki.com", "port": 8085, "path": "/", "protocol": "http", "toHTTPS": "true", "cert": "thiscert", "key": "thiskey", "options": {}, "upstream": "app1"}'
tester UPDATE servers/$name "$json"
tester GET servers '{"protocol": "http"}'
tester DELETE servers/$name '{"protocol": "http"}'


# tcp类型的服务
json='{"name": "app1", "domain": "myapp.sycki.com", "port": 8085, "path": "/", "protocol": "tcp", "toHTTPS": "true", "cert": "thiscert", "key": "thiskey", "options": {}, "upstream": "app2"}'
tester UPDATE servers/$name "$json"
tester GET servers '{"protocol": "tcp"}'
tester DELETE servers/$name '{"protocol": "tcp"}'


# udp类型的服务
json='{"name": "app1", "domain": "myapp.sycki.com", "port": 8085, "path": "/", "protocol": "udp", "toHTTPS": "true", "cert": "thiscert", "key": "thiskey", "options": {}, "upstream": "app2"}'
tester UPDATE servers/$name "$json"
tester GET servers '{"protocol": "udp"}'
tester DELETE servers/$name '{"protocol": "udp"}'


tester DELETE upstreams/$name '{"protocol": "http"}'
exit
tester DELETE upstreams/app2 '{"protocol": "tcp"}'


