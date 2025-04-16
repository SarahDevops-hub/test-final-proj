ARG USER_ID=1000
ARG GROUP_ID=1000

FROM wordpress:6.2-php8.0 AS wordpress
RUN groupadd -g $GROUP_ID customuser && \
    useradd -u $USER_ID -g customuser -s /bin/bash customuser
USER customuser
WORKDIR /var/www/html

FROM wordpress:cli-2.7.1 AS wpcli
ARG USER_ID
ARG GROUP_ID
RUN groupadd -g $GROUP_ID customuser && \
    useradd -u $USER_ID -g customuser -s /bin/bash customuser
USER customuser
WORKDIR /var/www/html