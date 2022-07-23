######################################################
# Name: wordpress
#
# Description: install of Wordpress. This package can
# use variableized commandline on RedHat/CentOS
#
# verified OS: CentOS 6.5, 7, Ubuntu 14.04
#
# usage:
# salt <target> state.sls wordpress pillar='{wp-title: My Super Awesome Site, wp-admin: foo, wp-admin-pw: letmein, wp-admin-email: email@my.com}'
#
######################################################
# import variables from apache.sls
{% import 'apache/init.sls' as vars %}
# other variable items
{% set wp_db_user = salt['pillar.get']('wp-db-user', 'wordpressuser') %}
{% set wp_db_name = salt['pillar.get']('wp-db-name', 'wordpress') %}
{% set wp_db_pass = salt['pillar.get']('wp-db-pass', 'password') %}
{% set wp_db_host = salt['pillar.get']('wp-db-host', 'localhost') %}

######################################################
# this uses MySQL, PHP and Apche
# 
###################################################### 
include:
  - mysql
  - php
  - apache

######################################################
# This downloads wordpress from official site and
# untar's to our sync folder
# 
###################################################### 
get_wordpress:
 cmd.run:
  - name: 'wget http://wordpress.org/latest.tar.gz --no-check-certificate && tar xvzf latest.tar.gz'
  - cwd: {{ vars.apache_html }}/

######################################################
# setup the database
# 
######################################################       
{{ wp_db_name }}:
  mysql_database.present
  
######################################################
# setup the database user
# 
######################################################       
{{ wp_db_user }}:  
  mysql_user.present:
    - host: {{ wp_db_host }}
    - password: {{ wp_db_pass }}

######################################################
# setup the database user permissions
# 
###################################################### 
wordpress-db-permissions:
  mysql_grants.present:
    - grant: ALL PRIVILEGES
    - database: {{ wp_db_name }}.*
    - user: {{ wp_db_user }}
    - host: {{ wp_db_host }}


######################################################
# copy the wordpress config file into the source
###################################################### 
{{ vars.apache_html }}/wordpress/wp-config.php:
  file.managed:
    - source: salt://{{slspath}}/wp-config.php
    - template: jinja
    - makedirs: True
    - context:
      database: {{ wp_db_name }}
      username: {{ wp_db_user }}
      pass: {{ wp_db_pass }}
      host: {{ wp_db_host }}

######################################################
# setup the wordpress file permissions
# 
######################################################     
wordpress-permissions:
  cmd.run:
    - names:
      - chmod -R 755 {{ vars.apache_html }}/wordpress
      - chown -R {{ vars.apache_user }}:{{ vars.apache_group }} {{ vars.apache_html }}/wordpress/wp-content

######################################################
# setup the wordpress PHP requirements
# 
###################################################### 
wordpress-php:    
  pkg.installed:
    {% if grains['os_family'] == 'RedHat' %}
    - pkgs:
      - php-gd
    {% elif grains['os_family'] == 'Debian' %}
    - pkgs:
      - php5-gd
    {% endif %}


######################################################
#
# The following sections are not required for wordpress
# to function
#
######################################################
    
######################################################
# setup the wp-cli file (MIT License)
# Copyright (C) 2011-2013 WP-CLI Development Group 
# (https://github.com/wp-cli/wp-cli/contributors)
###################################################### 
/usr/local/bin/wp:
 file.managed:
  - source: salt://{{slspath}}/wp-cli.phar
  - mode: 744
  - user: {{ vars.apache_user }}

######################################################
# execute the Wordpress configuration and setup
# pillars to execute based on commandline
# these are the default values:
#
# wp-title: MySite,
# wp-admin: foo, 
# wp-admin-pw: letmein, 
# wp-admin-email: email@my.com}'
######################################################     
wordpress-configure:
  cmd.run:
    - name: /usr/local/bin/wp core install --url=http://{{ salt['grains.get']( 'ip_interfaces:eth1')[0] }}/wordpress --path={{ vars.apache_html }}/wordpress --title='{{ salt['pillar.get']('wp-title', 'MySite') }}' --admin_user={{ salt['pillar.get']('wp-admin', 'admin') }} --admin_password={{ salt['pillar.get']('wp-admin-pw', 'password') }} --admin_email={{ salt['pillar.get']('wp-admin-email', 'noreply@noreply.com') }}
    - cwd: {{ vars.apache_html }}/wordpress/
    - user: {{ vars.apache_user }}
