return {
	-- port the webserver listens on
	port = 8080,
	
	-- where to store the images
	img_path = "img/",
	
	-- burgerking API json endpoints
	burgerking_api_urls = {
		coupons = "https://api.burgerking.de/api/o2uvrPdUY57J5WwYs6NtzZ2Knk7TnAUY/v4/de/de/coupons/",
		meta = "https://api.burgerking.de/api/o2uvrPdUY57J5WwYs6NtzZ2Knk7TnAUY/v2/de/de/meta",
		flags = "https://api.burgerking.de/api/o2uvrPdUY57J5WwYs6NtzZ2Knk7TnAUY/v2/de/de/flags/",
		contents = "https://api.burgerking.de/api/o2uvrPdUY57J5WwYs6NtzZ2Knk7TnAUY/v2/de/de/contents/",
		products = "https://api.burgerking.de/api/o2uvrPdUY57J5WwYs6NtzZ2Knk7TnAUY/v2/de/de/products/",
		stores = "https://api.burgerking.de/api/o2uvrPdUY57J5WwYs6NtzZ2Knk7TnAUY/v2/de/de/stores/",
		promos = "https://api.burgerking.de/api/o2uvrPdUY57J5WwYs6NtzZ2Knk7TnAUY/v2/de/de/promos/",
		tiles = "https://api.burgerking.de/api/o2uvrPdUY57J5WwYs6NtzZ2Knk7TnAUY/v3/de/de/tiles/",
		prestitials = "https://api.burgerking.de/api/o2uvrPdUY57J5WwYs6NtzZ2Knk7TnAUY/v2/de/de/prestitials/"
	},
	
	-- template paths
	templates = {
		coupons_template = "templates/coupons.lua.html",
		coupon_template = "templates/coupon.lua.html",
		admin_panel_template = "templates/admin.lua.html"
	}
}
