#!/bin/bash -e
export TERM=xterm

if [ ! -f "/etc/nginx/nginx.conf" ]; then cp -R -f /etc-start/nginx/* /etc/nginx; fi

if [ -z "`ls /etc/php5`" ] 
then
	cp -R /etc-start/php5/* /etc/php5
fi

    # Set environments
    TIMEZONE1=${TIMEZONE:-Asia/Ho_Chi_Minh}
    PHP_MEMORY_LIMIT1=${PHP_MEMORY_LIMIT:-512M}
    MAX_UPLOAD1=${MAX_UPLOAD:-520M}
    PHP_MAX_FILE_UPLOAD1=${PHP_MAX_FILE_UPLOAD:-200}
    PHP_MAX_POST1=${PHP_MAX_POST:-520M}
    MAX_INPUT_TIME1=${MAX_INPUT_TIME:-3600}
    MAX_EXECUTION_TIME1=${MAX_EXECUTION_TIME:-3600}
	
	sed -i -E \
	-e "s|;*date.timezone =.*|date.timezone = ${TIMEZONE1}|i" \
	-e "s|;*memory_limit =.*|memory_limit = ${PHP_MEMORY_LIMIT1}|i" \
 	-e "s|;*upload_max_filesize =.*|upload_max_filesize = ${MAX_UPLOAD1}|i" \
    	-e "s|;*max_file_uploads =.*|max_file_uploads = ${PHP_MAX_FILE_UPLOAD1}|i" \
    	-e "s|;*post_max_size =.*|post_max_size = ${PHP_MAX_POST1}|i" \
    	-e "s/max_input_time = 60/max_input_time = ${MAX_INPUT_TIME1}/" \
	-e "s/max_execution_time = 30/max_execution_time = ${MAX_EXECUTION_TIME1}/" \
	-e "s/;opcache.enable=0/opcache.enable=0/" \
	-e "s/error_reporting = .*/error_reporting = E_ALL/" \
	-e "s/display_errors = .*/display_errors = On/" \
	/etc/php5/php.ini

    sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php5/php-fpm.conf
    #sed -i '/^listen = /clisten = 9000' /etc/php5/fpm.d/www.conf && \
    #sed -i '/^listen.allowed_clients/c;listen.allowed_clients =' /etc/php5/fpm.d/www.conf && \
    #sed -i '/^;catch_workers_output/ccatch_workers_output = yes' /etc/php5/fpm.d/www.conf && \
    #sed -i '/^;env\[TEMP\] = .*/aenv[DB_PORT_3306_TCP_ADDR] = $DB_PORT_3306_TCP_ADDR' /etc/php5/fpm.d/www.conf

# set ID docker run
agid=${agid:-$auid}
auser=${auser:-apache}

if [[ -z "${auid}" ]]; then
  echo "start"
elif [[ "$auid" = "0" ]] || [[ "$aguid" == "0" ]]; then
	echo "run in user root"
	auser=root
	sed -i -e "/^user = .*/cuser = $auser" /etc/php5/php-fpm.conf
	sed -i -e "/^group = .*/cgroup = $auser" /etc/php5/php-fpm.conf
	sed -i -e "/^user .*/cuser  $auser;" /etc/nginx/nginx.conf
	sed -i -e "/^#user .*/cuser  $auser;" /etc/nginx/nginx.conf
elif id $auid >/dev/null 2>&1; then
        echo "UID exists. Please change UID"
else
if id $auser >/dev/null 2>&1; then
        echo "user exists"
	sed -i -e "/^user = .*/cuser = $auser" /etc/php5/php-fpm.conf
	sed -i -e "/^group = .*/cgroup = $auser" /etc/php5/php-fpm.conf
	sed -i -e "/^user .*/cuser  $auser;" /etc/nginx/nginx.conf
	sed -i -e "/^#user .*/cuser  $auser;" /etc/nginx/nginx.conf
	# usermod alpine
		deluser $auser && delgroup $auser
		addgroup -g $agid $auser && adduser -D -H -G $auser -s /bin/false -u $auid $auser
	# usermod ubuntu/debian
		#usermod -u $auid $auser
		#groupmod -g $agid $auser
else
        echo "user does not exist"
	# create user alpine
	addgroup -g $agid $auser && adduser -D -H -G $auser -s /bin/false -u $auid $auser
	# create user ubuntu/debian
	#groupadd -g $agid $auser && useradd --system --uid $auid --shell /usr/sbin/nologin -g $auser $auser
	sed -i -e "/^user = .*/cuser = $auser" /etc/php5/php-fpm.conf
	sed -i -e "/^group = .*/cgroup = $auser" /etc/php5/php-fpm.conf
	sed -i -e "/^user .*/cuser  $auser;" /etc/nginx/nginx.conf
	sed -i -e "/^#user .*/cuser  $auser;" /etc/nginx/nginx.conf
fi

fi

# option with entrypoint
if [ -f "/option.sh" ]; then /option.sh; fi

# run PHP-fpm
if [ -f "/usr/bin/php-fpm" ]; then php-fpm -D; fi

exec "$@"
