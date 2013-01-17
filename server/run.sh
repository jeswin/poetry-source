./compile.sh $1
echo Poe3 application starting...

cd app

cd api
if [ "$1" == "--trace" ]; then
    node app.js '' 1234 &
else
    forever start app.js '' 1234
fi
cd ..

cd website
if [ "$1" == "--trace" ]; then
    node app.js '' 1235 &
else
    forever start app.js '' 1235
fi
cd ..
