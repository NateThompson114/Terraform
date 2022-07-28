# web_server_location = ["westus","eastus"]
# web_server_rg = ["ae1-web-rg","aw1-web-rg"]

resource_prefix             = "web-server"
web_server_address_space    = "1.0.0.0/22"
web_server_address_prefix   = "1.0.1.0/24"
web_server_name             = "web-01"
web_server = [ 
    {
      "ResourceGroup" : "East Us",
      "location" : "eastus",
      "prefix" : "ae1"
    }
 ]
 environment = "development"