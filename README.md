Poe3 install instructions from new Ubuntu 12.04
==========================================
sudo apt-get install build-essential
    - To build node.js from source.
    - node.js packaged with the distro is often outdated.
    
sudo apt-get build-dep nodejs
    
Install node.js
    - Download source tarball from nodejs.org (http://nodejs.org/dist/v0.8.11/node-v0.8.11.tar.gz)
    - configure
    - make
    - sudo make install
    
sudo apt-get install nginx
- nginx configuration

```
#This redirects non-www to www urls
server {
    server_name poe3.com;
    rewrite ^(.*) http://www.poe3.com$1 permanent;
}

server {
    listen 80;
    server_name www.poe3.com;
    client_max_body_size 20M;

    location /api {
        proxy_pass http://localhost:1234;
    }

    location /user {
        alias /path/to/poetry/server/www-user;
    }

    location /css {
        alias /path/to/poetry/server/app/www/css;
    }

    location /html {
        alias /path/to/poetry/server/app/www/html;
    }

    location /images {
        alias /path/to/poetry/server/app/www/images;
    }

    location /js {
        alias /path/to/poetry/server/app/www/js;
    }

    location /lib {
        alias /path/to/poetry/server/app/www/lib;
    }

    location /templates {
        alias /path/to/poetry/server/app/www/templates;
    }

    location / {
        proxy_pass http://localhost:1235;
        #root /path/to/poetry/server/app/www;
        #try_files $uri /index.html;
        #index index.html;
    }
}                         
```            

sudo apt-get install mongodb

sudo apt-get install git

sudo apt-get install graphicsmagick

sudo npm install -g coffee-script

npm install express

npm install mongodb

npm install validator

npm install hbs

npm install fs-extra

npm install gm

npm install mongo-express

npm install node-minify

npm install oauth

npm install forever


Because the path the node modules was changed, this is also required to be run (as root):
rm /usr/local/lib/node
ln -s /usr/local/lib/node_modules /usr/local/lib/node 
Or: in .bashrc
export NODE_PATH="/usr/local/lib/node_modules"

