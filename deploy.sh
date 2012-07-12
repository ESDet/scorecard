#!/bin/bash

svn update
lessc public/stylesheets/style.less > public/stylesheets/style.css
lessc public/stylesheets/print.less > public/stylesheets/print.css
touch tmp/restart.txt


