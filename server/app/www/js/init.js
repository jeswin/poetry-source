window.Poe3 = {}


/* Check for browser. If IE, we support only v10+ */
window.Poe3.browserCheck = function() {
    var getVersion = function() {
        var rv = -1; // Return value assumes failure.
        if (navigator.appName == 'Microsoft Internet Explorer') {
            var ua = navigator.userAgent;
            var re = new RegExp("MSIE ([0-9]{1,}[\.0-9]{0,})");
            if (re.exec(ua) != null)
                rv = parseFloat(RegExp.$1);
        }
        return rv;
    }
    var ver = getVersion();
    if (ver > -1) {
        if (ver <= 9.0) {
            window.location.reload('/html/browsers.html')
        }
    }
}
window.Poe3.browserCheck();


window.Poe3.initFB = (function() {
    (function(d){
        var js, id = 'facebook-jssdk', ref = d.getElementsByTagName('script')[0];
        if (d.getElementById(id)) {return;}
        js = d.createElement('script'); js.id = id; js.async = true;
        js.src = "//connect.facebook.net/en_US/all.js";
        ref.parentNode.insertBefore(js, ref);
    }(document));

    // Init the SDK upon load
    window.fbAsyncInit = function() {
        FB.init({
            appId      : '399747530084964', // App ID
            channelUrl : '//'+window.location.hostname+'/channel', // Path to your Channel File
            frictionlessRequests : false,
            status     : true, // check login status
            cookie     : true, // enable cookies to allow the server to access the session
            xfbml      : true  // parse XFBML
        });                

        /*
        //DISABLED: This doesn't work so well when supporting login mechanisms other than FB
        FB.Event.subscribe('auth.authResponseChange', function(response) {
            app.processFBAuthResponse(response);             
        });
        */
        
        app.onFBLoad();
    } 
});

/* Template Loader */
// The Template Loader. Used to asynchronously load templates located in separate .html files
window.Poe3.templateLoader = {
    load: function(namespace, views, callback) {
        if(Poe3.debugMode) {
            var deferreds = [];

            $.each(views, function(index, view) {
                if(view.view) {
                    fn = function(_view, _name) {
                        deferreds.push($.get('/templates/' + _view.templates[_name].toLowerCase() + '.html', function(data) {
                            window[namespace][_view.view].prototype[_name] = Handlebars.compile(data);
                        }, 'html'));
                    }
                    for(name in view.templates) {                                                
                        fn(view, name);
                    }                
                } else {
                    fn = function(_view) {
                        deferreds.push($.get('/templates/' + _view.toLowerCase() + '.html', function(data) {
                            window[namespace][_view].prototype.template = Handlebars.compile(data);
                        }, 'html'));
                    }
                    fn(view);
                }
            });

            $.when.apply(null, deferreds).done(callback);
        }
        
        else {
            $.get('/templates/templates.html', function(data) {
                templates = $(data);
                $.each(views, function(index, view) {
                    if(view.view) {
                        for(name in view.templates) {                            
                            var i = 0;
                            var tmpl = null;
                            for(i = 0; i < templates.length; i++) {
                                if($(templates[i]).hasClass("template-" + view.templates[name].toLowerCase())) {
                                    tmpl = templates[i].outerHTML;
                                    break;
                                }
                            }
                            if(tmpl)
                                window[namespace][view.view].prototype[name] = Handlebars.compile(tmpl);
                            else
                                console.log("Template not found: " + view.templates[name])
                        }
                    } else {
                        var i = 0;
                        var tmpl = null;
                        for(i = 0; i < templates.length; i++) {
                            if($(templates[i]).hasClass("template-" + view.toLowerCase())) {
                                tmpl = templates[i].outerHTML;
                                break;
                            }
                        }
                        if(tmpl)
                            window[namespace][view].prototype.template = Handlebars.compile(tmpl);
                        else
                            console.log("Template not found: " + view)                        
                    }
                });
                callback();
            });
        }
    }
};

