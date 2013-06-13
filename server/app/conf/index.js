// Generated by CoffeeScript 1.6.2
(function() {
  var admins, auth, db, twitter;

  if (process.env.NODE_ENV === 'development') {
    db = {
      name: 'poetry-db-dev',
      host: '127.0.0.1',
      port: 27017
    };
    twitter = {
      TWITTER_CONSUMER_KEY: 'YOUR_TWITTER_KEY',
      TWITTER_SECRET: 'YOUR_TWITTER_SECRET',
      TWITTER_CALLBACK: "YOUR_TWITTER_CB"
    };
  } else {
    db = {
      name: 'poetry-db',
      host: '127.0.0.1',
      port: 27017
    };
    twitter = {
      TWITTER_CONSUMER_KEY: 'YOUR_TWITTER_KEY',
      TWITTER_SECRET: 'YOUR_TWITTER_SECRET',
      TWITTER_CALLBACK: "YOUR_TWITTER_CB"
    };
  }

  auth = {
    facebook: {
      FACEBOOK_APP_ID: 'YOUR_FB_APPID',
      FACEBOOK_SECRET: 'YOUR_FB_SECRET'
    },
    twitter: twitter,
    adminkeys: {
      "default": 'RANDOM_STRING_HERE'
    }
  };

  admins = [
    {
      username: 'adminuser',
      domain: 'fb'
    }
  ];

  module.exports = {
    db: db,
    auth: auth,
    admins: admins
  };

}).call(this);
