#!/bin/bash

cat file-opening-staging.conf > staginginrelationto.conf
cat .htaccess_misc >> staginginrelationto.conf
cat .htaccess_bloggers >> staginginrelationto.conf
cat .htaccess_posts >> staginginrelationto.conf
cat file-closing.conf >> staginginrelationto.conf
scp staginginrelationto.conf ci.hibernate.org:~

cat file-opening-production.conf > inrelationto.conf
cat .htaccess_misc >> inrelationto.conf
cat .htaccess_bloggers >> inrelationto.conf
cat .htaccess_posts >> inrelationto.conf
cat file-closing.conf >> inrelationto.conf
scp inrelationto.conf ci.hibernate.org:~

ssh -t ci.hibernate.org "sudo cp staginginrelationto.conf /etc/httpd/conf.d/staginginrelationto.conf && sudo cp inrelationto.conf /etc/httpd/conf.d/inrelationto.conf && sudo service httpd reload"

rm inrelationto.conf
rm staginginrelationto.conf

