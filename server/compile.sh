if [ $NODE_ENV == "development" ]
then
    if [ "$1" != "--nodel" ]; then
	    echo Deleting ./app 
	    rm -rf app
	    mkdir app
    else
	    echo Not deleting ./app
    fi

    echo Copying src to app
    cp -r src _temp
    find _temp -name '*.coffee' | xargs rm -rf
    find _temp -name '*.*~' | xargs rm -rf
    cp -r _temp/* app
    rm -rf _temp

    # echo Compiling coffee to js
    coffee -o app/ -c src/
    
    if [ "$1" == "--debug" ] || [ "$1" == "--trace" ]; then
	    echo Skipped packaging script.
	    cp src/website/views/layouts/default-debug.hbs app/website/views/layouts/default.hbs
    else
        echo Running packaging script...
	    node app/scripts/deploy/package.js $1
	    
	    echo Merging templates...
	    cat app/www/templates/edituserview.html app/www/templates/newpostview.html app/www/templates/postcomments.html app/www/templates/postlistview.html \
	        app/www/templates/postlistviewitem.html app/www/templates/postsview.html app/www/templates/postview.html app/www/templates/taglistview.html \
	        app/www/templates/taglistviewitem.html app/www/templates/userinfo.html app/www/templates/userlistview.html app/www/templates/userview.html \
	        > app/www/templates/templates.html
	        
    fi
    
else
    echo "compile.sh can only be run in development."
fi
