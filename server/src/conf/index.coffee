#Database
if process.env.NODE_ENV is 'development'
    db = { name: 'poetry-db-dev', host: '127.0.0.1', port: 27017 }

    twitter = {
        TWITTER_CONSUMER_KEY: 'YOUR_TWITTER_KEY'
        TWITTER_SECRET: 'YOUR_TWITTER_SECRET',
        TWITTER_CALLBACK: "YOUR_TWITTER_CB",
    }

else
    db = { name: 'poetry-db', host: '127.0.0.1', port: 27017 }

    twitter = {
        TWITTER_CONSUMER_KEY: 'YOUR_TWITTER_KEY'
        TWITTER_SECRET: 'YOUR_TWITTER_SECRET',
        TWITTER_CALLBACK: "YOUR_TWITTER_CB",
    }

#Auth
auth = {    
    facebook: {
        FACEBOOK_APP_ID: 'YOUR_FB_APPID'
        FACEBOOK_SECRET: 'YOUR_FB_SECRET'
    },
    twitter,
    adminkeys: { 
        default: 'RANDOM_STRING_HERE'
    }
}

admins = [
    { username: 'adminuser', domain: 'fb' }
]
    
module.exports = {
    db,
    auth,
    admins
}
