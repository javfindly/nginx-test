SHELL := /bin/bash
NGINX_VER := 1.4.1

bootstrap: nginx

test: checkversions
	@echo "Running tests..."
	@test -d /data1/logs || mkdir -p /data1/logs/ 
	@cd test && ./run_tests.sh
	@#./bin/check_servers.sh
	@echo "sudo make test" > .lasttest


test-vagrant:
	@echo "sudo make test-vagrant" > .lasttest
	vagrant up
	vagrant ssh -c "cd /vagrant && (make -v 2>&1 1>/dev/null|| sudo apt-get install make -f) && sudo make nginx-vagrant && sudo make test"  

nginx-vagrant:
	@echo "Checking nginx installation in vagrant" 
	$(if $(findstring ERROR,$(shell ./bin/check_nginx.sh)),\
		sudo make nginx)

dnsmasq:
	@which dnsmasq 1>/dev/null || test -d /usr/sbin/dnsmasq || (apt-get update && apt-get -y install dnsmasq*  && update-rc.d -f dnsmasq remove && sed -ie 's/^#prepend domain-name-servers 127.0.0.1/prepend domain-name-servers 127.0.0.1/' /etc/dnsmasq.conf)
	@sleep 3

pcre: 
	@apt-get install -y libssl-dev libpcre3 libpcre3-dev libssl-dev

curl:
	@apt-get install -y curl

uuid:
	@apt-get install libossp-uuid-dev -y

lua:
	@apt-get install -y lua5.1 liblua5.1-0 liblua5.1-0-dev

base:
	sudo apt-get install -y build-essential libpcre3 libpcre3-dev libssl-dev git-core

nginx: dnsmasq pcre curl uuid lua base
	@test -d /usr/src || mkdir -p /usr/src
	@rm -rf /usr/src/nginx-$(NGINX_VER)
	@test -f /usr/src/nginx-$(NGINX_VER).tar.gz || (cd /usr/src && curl -O http://nginx.org/download/nginx-$(NGINX_VER).tar.gz)
	@test -d /usr/src/nginx-$(NGINX_VER) || (cd /usr/src && tar xf nginx-$(NGINX_VER).tar.gz)
	@mkdir -p /usr/src/nginx-$(NGINX_VER)/modules
	@cd /usr/src/nginx-$(NGINX_VER)/modules && (test -d echo-nginx-module || (git clone https://github.com/agentzh/echo-nginx-module.git && cd echo-nginx-module && git checkout v0.45))
	@cd /usr/src/nginx-$(NGINX_VER)/modules && (test -d ngx_devel_kit || (git clone https://github.com/simpl/ngx_devel_kit.git && cd ngx_devel_kit && git checkout v0.2.18))
	@cd /usr/src/nginx-$(NGINX_VER)/modules && (test -d set-misc-nginx-module || (git clone https://github.com/agentzh/set-misc-nginx-module.git && cd set-misc-nginx-module && git checkout v0.22rc8))
	@cd /usr/src/nginx-$(NGINX_VER)/modules && (test -d nginx-upstream-idempotent || (git clone https://github.com/xetorthio/nginx-upstream-idempotent.git && cd nginx-upstream-idempotent && git checkout e4f72f7ffea2d50c896c))
	@cd /usr/src/nginx-$(NGINX_VER)/modules && (test -d headers-more-nginx-module || (git clone https://github.com/agentzh/headers-more-nginx-module.git && cd headers-more-nginx-module && git checkout v0.20))
	@cd /usr/src/nginx-$(NGINX_VER)/modules && (test -d nginx-x-rid-header || git clone https://github.com/newobj/nginx-x-rid-header.git)
	@cd /usr/src/nginx-$(NGINX_VER)/modules && (test -d lua-nginx-module || (git clone https://github.com/chaoslawful/lua-nginx-module.git && cd lua-nginx-module && git checkout v0.8.3))

	cd /usr/src/nginx-$(NGINX_VER) && ./configure --with-ld-opt="-lossp-uuid" --with-cc-opt="-D NGX_HAVE_CASELESS_FILESYSTEM=0 -I/usr/include/ossp" --prefix=/opt/nginx \
	  --add-module=/usr/src/nginx-$(NGINX_VER)/modules/echo-nginx-module \
	  --add-module=/usr/src/nginx-$(NGINX_VER)/modules/ngx_devel_kit \
	  --add-module=/usr/src/nginx-$(NGINX_VER)/modules/set-misc-nginx-module \
	  --add-module=/usr/src/nginx-$(NGINX_VER)/modules/nginx-upstream-idempotent \
	  --add-module=/usr/src/nginx-$(NGINX_VER)/modules/headers-more-nginx-module \
          --add-module=/usr/src/nginx-$(NGINX_VER)/modules/nginx-x-rid-header \
	  --add-module=/usr/src/nginx-$(NGINX_VER)/modules/lua-nginx-module && make && make install

checkversions:
	@echo "Checking nginx version..."
	@./bin/check_nginx.sh
	@echo "Checking system..."
	@./bin/check_system.sh
