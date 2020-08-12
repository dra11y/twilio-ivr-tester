# twilio-ivr-tester

This small Ruby/Sinatra application is meant for developer use in testing a Twilio IVR API endpoint from the browser without having to incur charges by dialing its Twilio Number.

Please feel free to submit a PR if you have a bugfix or improvement.

## Requirements

- Ruby v2.6+
- Bundler v2
- A backend Twilio IVR application that is intended to interact with the Twilio API accessible from your local machine

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
