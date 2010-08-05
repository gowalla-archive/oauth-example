# Gowalla OAuth API example

This little app demonstrates how to use Gowalla's OAuth API to authorize an application, fetch user info using that authorization and, if the user has granted permission, check in on behalf of that user.

## How to Get It Running

- `gem install bundler`
- `bundle install`

Open up another terminal tab and do:

    API_KEY='your_key' API_SECRET='your_secret' bundle exec shotgun -p 3001

Now open up `http://localhost:3001/` in your browser and everything should be ready to go!

## Caveats

- Check in requires a browser with HTML5 geolocation services
- Safari seems to put on its propellerhead beanie when it asks for location. Sometimes it works, sometimes it doesn't.
