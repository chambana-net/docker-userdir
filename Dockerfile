FROM chambana/jekyll-github:latest

MAINTAINER Josh King <jking@chambana.net>

RUN apt-get -qq update && \
	apt-get install -y --no-install-recommends apache2 apache2-utils openssh-server openssh-client supervisor && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/*

EXPOSE 80

VOLUME ["/home"]

RUN mkdir /etc/skel/public_html

ADD files/etc/ssh/sshd_config /etc/ssh/sshd_config
RUN mkdir /etc/ssh/auth

ADD bin/authcommand.sh /etc/ssh/auth/authcommand.sh
RUN chmod +x /etc/ssh/auth/authcommand.sh

ADD files/supervisor/supervisord.conf /etc/supervisor/supervisord.conf

ADD bin/init.sh /opt/chambana/bin/init.sh
RUN chmod +x /opt/chambana/bin/init.sh

CMD ["/opt/chambana/bin/init.sh"]
