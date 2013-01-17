./compile.sh $1
cd app/api
node --debug app.js "$1" "$2"
