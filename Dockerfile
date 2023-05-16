FROM ubuntu:20.04

ENV TZ=Europe/Istanbul
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update
RUN apt-get install -y software-properties-common curl git nano zip unzip

#php 8.2
RUN add-apt-repository ppa:ondrej/php -y
RUN apt-get update
RUN apt-get install php8.2 php8.2-dev php8.2-curl php8.2-xml -y --allow-unauthenticated

#Install ODBC
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
RUN curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list > /etc/apt/sources.list.d/mssql-release.list
RUN apt-get update
RUN ACCEPT_EULA=Y apt-get install -y msodbcsql17
RUN ACCEPT_EULA=Y apt-get install -y mssql-tools
RUN apt-get install -y unixodbc-dev

# Install PHP Drivers for SQL Server
RUN pecl install sqlsrv
RUN pecl install pdo_sqlsrv
RUN printf "; priority=20\nextension=sqlsrv.so\n" > /etc/php/8.2/mods-available/sqlsrv.ini
RUN printf "; priority=30\nextension=pdo_sqlsrv.so\n" > /etc/php/8.2/mods-available/pdo_sqlsrv.ini
RUN phpenmod -v 8.2 sqlsrv pdo_sqlsrv

# Install PHP Driver Mysql
RUN apt-get install -y php8.2-mysql php8.2-gd

# Install locales
RUN apt-get install -y locales && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen

#Clean Apt cache (using "du -shc" to see the folders length)
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

#Apache Configurations
COPY apache2.conf /etc/apache2/
COPY default-ssl.conf /etc/apache2/sites-available/default-ssl.conf
COPY 000-default.conf /etc/apache2/sites-enabled/000-default.conf    

EXPOSE 80
EXPOSE 443

WORKDIR /var/www/html/
RUN chown -hR www-data .

CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]