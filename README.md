This is a console macOS app that allows for monitoring and sending new App Store reviews
of an app over email.

# Usage

It's convinient to schedule its running in cron:

```
@hourly /usr/local/AppReviewsMailer.app --app-id "<myAppIdInTheAppStore>" --lang-id "en-US" --recipients "first@mail.com, second@mail.com"
```

## Arguments

* `app-id` - the id of the application in the AppStore. See section "How to find iTunes store id or App id?".
* `lang-id` - the country identifier of the AppStore for your app. See section "How to find iTunes store id or App id?".
* `recipients` - a comma separated list of the email addresses the new reviews should be sent to.

## How to find iTunes store id or App id?

1. Open iTunes.
2. Search for your app.
3. Click your app’s name and copy the URL (In case of PC users, mouse right-click on App Name).
4. App store URL’s will be in the following format:
  `http://itunes.apple.com/[country]/app/[App–Name]/id[App Id or Store Id]?mt=8`

Here is an example url:

`https://itunes.apple.com/us/app/mobile-security-cloud-mdm/id567173760?mt=8`

## How does the app work?

The app queries the RSS feed of the AppStore for the app reviews. On the fresh run it sends all the reviews to the
recipients (in a single mail for all the reviews), and saves the updated date of the latest review to the file
"~/Documents/.review_latest_date_[appId]_[langId]". On the consecutive runs, the app filters out
all the recieved reviews with the updated date earlier or equal to the date from that file.

It uses the XML format of the RSS feed because it has the "updated_at" field, in contrast to the JSON representation.

# Installation

Download the project, build it with Xcode 8. Then you can archive it via Product > Archive, and export the archive as
build products. Move the AppReviewsMailer.app file from the resulting folder into /usr/local.
