#!/bin/bash

/usr/local/bin/vnc.sh
set -x 
rake db:create RAILS_ENV=test
rake db:migrate RAILS_ENV=test
rake
