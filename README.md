Slurger4
==========



Slurger = Super + Lua + Burger
-------------------------------

Slurger is a programm, written in Lua, that grab coupons from the Burgerking Server, and presents them on a webpage.





Details
--------

This program uses the same API to query data from the Burgerking Server as the app. That is because the API endpoints were extracted from the app. The main advantage is that slurger does not delete the coupons based on the set expiry date(which is inaccurate; Coupons stay valid way after). Not beeing tracked by that app is just a nice bonus.





Installation
-------------

First, install LuaJIT, luarocks, and libssl1.0.2  via your prefered package manager.

	luarocks install cjson turbo lua-resty-template

Now you should be able to start the server via the start.sh script.	




Todo
-----

 * make page that looks like app
 * generate EAN13/QR-codes
 * use HTML5 web storage for offline support
 * better search, filters, sort



Libraries used
---------------

turbo.lua
cjson
lua-resty-template
Bootstrap
openiconic




License
--------

slurger is released under the MIT license. See LICENSE
