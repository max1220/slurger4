#!/usr/bin/env luajit
TURBO_SSL = true
local turbo = require("turbo")
local json = require("cjson")
local template = require("resty.template")
local config = require("config")

local cinstance, app
local coupons, meta, flags, contents, products, stores, promos, tiles, prestitials


-- read file from disk, return contents
local function read_file(path)
	local file = assert(io.open(path, "rb"))
	local str = file:read("*a")
	file:close()
	return str
end


-- write a string to disk
local function write_file(path, str)
	local file = assert(io.open(path, "wb"))
	local str = file:write(str)
	file:close()
end


-- return true if the file exists
local function exists_file(path)
	local file = io.open(path)
	if file then
		file:close()
		return true
	end
end


-- download URL and return body
local function download_to_string(url)
	local httpclient = turbo.async.HTTPClient({verify_ca=false}, nil, 1024*1000 *5)
	local res = coroutine.yield(httpclient:fetch(url))
	assert(not res.error, res.error)
	return res.body
end


-- download URL, write body to file and return body
local function download_to_file(url, path)
	local file = assert(io.open(path, "wb"))
	local str = download_to_string(url)
	file:write(str)
	file:close()
	return str
end


-- add the new coupons from other_coupons to the coupons table
local function merge_new_coupons(other_coupons)
	
	-- make list of coupon id's in the original coupons
	local coupon_ids = {}
	for i, coupon in ipairs(coupons) do
		coupon_ids[coupon.id] = true
	end
	
	-- check other coupons for coupons not in that list and add them
	for i, coupon in ipairs(other_coupons) do
		if not coupon_ids[coupon.id] then
			turbo.log.success("Adding missing coupon: " .. coupon.id)
			coupon._slurger_time = os.time()
			table.insert(coupons, coupon)
		end
	end
	
	return coupons
end


-- update the data jsons on disk
local function update_data()
	local coupons_new = json.decode(download_to_string(config.burgerking_api_urls.coupons, "coupons.json"))
	merge_new_coupons(coupons_new)
	write_file("coupons.json", json.encode(coupons))
	
	meta = json.decode(download_to_file(config.burgerking_api_urls.meta, "meta.json"))
	flags = json.decode(download_to_file(config.burgerking_api_urls.flags, "flags.json"))
	contents = json.decode(download_to_file(config.burgerking_api_urls.contents, "contents.json"))
	products = json.decode(download_to_file(config.burgerking_api_urls.products, "products.json"))
	stores = json.decode(download_to_file(config.burgerking_api_urls.stores, "stores.json"))
	promos = json.decode(download_to_file(config.burgerking_api_urls.promos, "promos.json"))
	tiles = json.decode(download_to_file(config.burgerking_api_urls.tiles, "tiles.json"))
	prestitials = json.decode(download_to_file(config.burgerking_api_urls.prestitials, "prestitials.json"))
end


-- re-read the data jsons from disk into memory
local function read_data()
	coupons = json.decode(read_file("coupons.json"))
	meta = json.decode(read_file("meta.json"))
	flags = json.decode(read_file("flags.json"))
	contents = json.decode(read_file("contents.json"))
	products = json.decode(read_file("products.json"))
	stores = json.decode(read_file("stores.json"))
	promos = json.decode(read_file("promos.json"))
	tiles = json.decode(read_file("tiles.json"))
	prestitials = json.decode(read_file("prestitials.json"))
end


-- substitute all occurances of %{something} with the value at "something" in tbl
local function subst_str(str, tbl)
	return str:gsub("%%{(.-)}", function(key)
		return tbl[key] or ""
	end)
end


-- return the filename in a URL
local function filename_from_url(url)
	local filename = url:match("^.*/(.-)$")
	if filename and filename:find("?") then
		filename = filename:match("^(.-)%?")
	end
	return filename
end


-- get a URL for the image
local function url_for_image(img_path)
	return "/" .. img_path
end


-- get a local version of the url from a json
local function get_local_image_from_url(url, resolution)
	local url = turbo.escape.unescape(url)

	local filename = config.img_path .. resolution .. "_"..filename_from_url(url)
	if exists_file(filename) then
		return url_for_image(filename)
	else
		download_to_file("https://api.burgerking.de" .. url, filename)
		return url_for_image(filename)
	end
	
	-- return "https://api.burgerking.de" .. url
end


-- filter a list by a callback function
local function ifilter(tbl, func)
	local new_t = {}
	for k,v in ipairs(tbl) do
		if func(k,v) then
			table.insert(new_t, v)
		end
	end
	return new_t
end


-- recursivly copy a table
local function tcopy(t)
	local new_t = {}
	for k,v in pairs(t) do
		if type(v) == "table" then
			new_t[k] = tcopy(v)
		else
			new_t[k] = v
		end
	end
	return new_t
end


-- return the values in the csv string
local function split_csv(str)
	local t = {}
	for v in (str .. ","):gmatch("(.-),") do
		table.insert(t, v)
	end
	return t
end


-- get an image from a coupon and a resolution
local function _img(coupon, resolution)
	return get_local_image_from_url(subst_str(coupon.images.bgImage.url, {resolution=resolution}), resolution)
end


-- get a category by it's id
local function category_by_id(id)
	for i, category in ipairs(flags.productCategories) do
		if category.id == id then
			return category
		end
	end
end


local admin_panel_template = template.compile(config.templates.admin_panel_template)
local admin_panel_handler = class("admin_panel", turbo.web.RequestHandler)
function admin_panel_handler:get()
	self:write(admin_panel_template({
		title = "Admin Panel",
		coupons = coupons,
		meta = meta,
		flags = flags,
		contents = contents,
		products = products,
		stores = stores,
		promos = promos,
		tiles = tiles,
		prestitials = prestitials,
		NULL = json.null
	}))
end
function admin_panel_handler:post()
	local action = self:get_argument("action")
	if action == "update_data" then
		update_data()
	elseif action == "read_data" then
		read_data()
	end

	self:redirect("/admin")
end


local coupon_template = template.compile(config.templates.coupon_template)
local coupon_handler = class("admin_panel", turbo.web.RequestHandler)
function coupon_handler:get(coupon_i)
	local coupon_i = assert(tonumber(coupon_i))
	local coupon = assert(coupons[coupon_i])
	
	local theme = self:get_argument("theme", "")
	
	local bootstrap_css = "/static/bootstrap-4.3.1/css/bootstrap.min.css"
	if theme == "cyborg" then
		bootstrap_css = "/static/cyborg/bootstrap.min.css"
	elseif theme == "flatly" then
		bootstrap_css = "/static/flatly/bootstrap.min.css"
	elseif theme == "darkly" then
		bootstrap_css = "/static/darkly/bootstrap.min.css"
	end
	
	
	for k,v in ipairs(coupon.categories) do
		local category = category_by_id(v)
		coupon.categories[k] = category
	end
	
	self:write(coupon_template({
		coupon = coupon,
		resolution = 750,
		_img = _img,
		NULL = json.null,
		bootstrap_css = bootstrap_css,
	}))
	
end


local coupons_template = template.compile(config.templates.coupons_template)
local coupons_handler = class("coupons_handler", turbo.web.RequestHandler)
function coupons_handler:get()
	local _coupons = tcopy(coupons)
	local sort = self:get_argument("sort", "")
	local filters = self:get_argument("filters", "")
	local theme = self:get_argument("theme", "")
	local search = self:get_argument("search", "")
	
	local bootstrap_css = "/static/bootstrap-4.3.1/css/bootstrap.min.css"
	if theme == "cyborg" then
		bootstrap_css = "/static/cyborg/bootstrap.min.css"
	elseif theme == "flatly" then
		bootstrap_css = "/static/flatly/bootstrap.min.css"
	elseif theme == "darkly" then
		bootstrap_css = "/static/darkly/bootstrap.min.css"
	end
	
	
	if search then
		_coupons = ifilter(_coupons, function(k, coupon)
			if coupon.title:lower():match(search:lower()) then
				return true
			elseif coupon.description ~= json.null and coupon.description:lower():match(search) then
				return true
			end
		end)
	end
	
	
	if filters ~= "" then
		filters = split_csv(filters)
		for k,v in ipairs(filters) do
			filters[v] = k
		end
	end
	
	if sort == "price_asc" then
		table.sort(_coupons, function(a,b)
			return a.price < b.price
		end)
	elseif sort == "price_desc" then
		table.sort(_coupons, function(a,b)
			return a.price > b.price
		end)
	elseif sort == "to_asc" then
		table.sort(_coupons, function(a,b)
			return a.to < b.to
		end)
	elseif sort == "to_desc" then
		table.sort(_coupons, function(a,b)
			return a.to > b.to
		end)
	end
	
	if filters.hide_invalid_date then
		_coupons = ifilter(_coupons, function(k, coupon)
			if (os.time() <= coupon.to) and (os.time() >= coupon.from) then
				return true
			end
		end)
	end
	
	if filters.show_invalid_date then
		_coupons = ifilter(_coupons, function(k, coupon)
			if (os.time() <= coupon.to) and (os.time() >= coupon.from) then
				return
			end
			return true
		end)
	end
	
	if filters.price_max then
		_coupons = ifilter(_coupons, function(k, coupon)
			local max_price = assert(tonumber(filters[filters.price_max + 1]))
			local price = tonumber((coupon.price:gsub("€", ""):gsub(",", "."))) or 0
			if price <= max_price then
				return true
			end
		end)
	end
	
	if filters.price_min then
		_coupons = ifilter(_coupons, function(k, coupon)
			local min_price = assert(tonumber(filters[filters.price_min + 1]))
			local price = tonumber((coupon.price:gsub("€", ""):gsub(",", "."))) or 0
			if price >= min_price then
				return true
			end
		end)
	end
	
	if filters.category then
		_coupons = ifilter(_coupons, function(k, coupon)
			local category_id = assert(tonumber(filters[filters.category + 1]))
			for k,v in ipairs(coupon.categories) do
				if v == category_id then
					return true
				end
			end
		end)
	end
	
	

	self:write(coupons_template({
		coupons = _coupons,
		meta = meta,
		flags = flags,
		contents = contents,
		products = products,
		stores = stores,
		promos = promos,
		tiles = tiles,
		prestitials = prestitials,
		bootstrap_css = bootstrap_css,
		resolution = 375,
		resolution_lg = 640,
		NULL = json.null,
		_img = _img
	}))
end


local function startup()
	read_data()
	turbo.log.success("Startup complete, listening on port " .. config.port)
end


app = turbo.web.Application({
	{"^/coupon/(%d+)$", coupon_handler},
	{"^/coupons/$", coupons_handler},
	{"^/$", coupons_handler},
	{"^/admin$", admin_panel_handler},
	{"^/static/(.-)$", turbo.web.StaticFileHandler, "static/"},
	{"^/img/(.-)$", turbo.web.StaticFileHandler, "img/"}
})

cinstance = turbo.ioloop.instance()
app:listen(config.port)
cinstance:add_callback(startup)
cinstance:start()

