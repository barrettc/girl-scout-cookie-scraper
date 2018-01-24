# girl-scout-cookie-scraper

Create a `cookie-war.yaml` based on the example.

```
$ bundle install
$ ruby cookie-war.db
```

Log is created as `cookie-war.log`. Running with `TEST=1 ruby cookie-war.db` will run the `available_page_sample.html` instead of hitting the live site and will not result in a Twilio notification being sent.
