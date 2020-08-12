# twilio-ivr-tester

This small Ruby/Sinatra application is meant for developer use in testing a [Twilio](https://twilio.com) IVR API endpoint ("incoming call") from the browser without having to incur charges that would be incurred by dialing its Twilio Number. Besides, it's faster, and you don't have to change your endpoint settings in the Twilio console!

Please feel free to submit a PR if you have a bugfix or improvement.

## Requirements

- Ruby v2.6+
- Bundler v2
- A backend Twilio IVR application that is intended to interact with (accept incoming requests from and output TwiML responses to) the Twilio API accessible from your local machine

If needed:

1. Install [rbenv](https://github.com/rbenv/rbenv)

2. Install Ruby using rbenv:

```
rbenv install 2.7.1
rbenv local 2.7.1
# or:
# rbenv global 2.7.1
gem install bundler
```

## Setup & Run

1. Customize the `IVR_BASE_URL` and `IVR_DEFAULT_PATH` environment variables in your environment or in app.rb according to your setup.

2. Launch your Twilio IVR API app in another Terminal window.

3. Launch this app:

```
bundle install
bundle exec rackup
```

The app will launch in your browser at http://localhost:9292. See the [Sinatra](https://github.com/sinatra/sinatra) documentation for more info.

## Troubleshooting

This app is not meant to work by itself. It attempts to connect immediately to your backend app, just as a Twilio incoming call would. If you see an error such as `Errno::ECONNREFUSED at /`, please customize the `IVR_BASE_URL` and `IVR_DEFAULT_PATH` environment variables and make sure your backend app is running and responding to requests.
