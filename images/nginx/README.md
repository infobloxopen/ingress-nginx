NGINX base image using [alpine](https://www.alpinelinux.org/)

This custom image contains:

- [nginx-http-auth-digest](https://github.com/atomx/nginx-http-auth-digest)
- [ngx_http_substitutions_filter_module](https://github.com/yaoweibin/ngx_http_substitutions_filter_module)
- [nginx-opentracing](https://github.com/opentracing-contrib/nginx-opentracing)
- [opentracing-cpp](https://github.com/opentracing/opentracing-cpp)
- [zipkin-cpp-opentracing](https://github.com/rnburn/zipkin-cpp-opentracing)
- [dd-opentracing-cpp](https://github.com/DataDog/dd-opentracing-cpp)
- [ModSecurity-nginx](https://github.com/SpiderLabs/ModSecurity-nginx) (only supported in x86_64)
- [brotli](https://github.com/google/brotli)
- [geoip2](https://github.com/leev/ngx_http_geoip2_module)
- openssl 1.0.2u with FIPS mode enabled
- nginx built with openssl 1.0.2u FIPS

**How to build image**
Make image 
`make build`

Push image
`make push`

Image registry and tag can be overridden by setting `REGISTRY` `TAG` environment variables


**How to use this image:**
This image provides a default configuration file with no backend servers.

_Using docker_

```console
docker run -v /some/nginx.conf:/etc/nginx/nginx.conf:ro infoblox/nginx-fips:20200908-bcd33a8d2
```

_Creating a replication controller_

```console
kubectl create -f ./rc.yaml
```
