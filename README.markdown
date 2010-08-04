## How to Get It Running

- <tt>gem install bundler thin</tt>
- <tt>bundle install</tt>
- <tt>sass --watch public/css/elite.scss</tt>

Open up another terminal tab. If you are touching anything other than the view or CSS, do:
<tt>thin start -R config.ru -p 3000</tt>

Otherwise, you'll want the server to reload when changes are made, so instead do:
<tt>shotgun config.ru -s thin -p 3000</tt>
  
Now open up <tt>http://localhost:3000/</tt> in your browser and everything should be ready to go!
