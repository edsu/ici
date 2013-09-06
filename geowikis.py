#!/usr/bin/env python

# a bit of scrapey scrapey to see which wikipedias support geosearch
# should ouptut some html to include selector in index.html

import re
import json
import requests

# first get a list of wikipedias and their language codes

wikipedias = {}
wikipedia_list = 'http://meta.wikimedia.org/wiki/List_of_Wikipedias'
html = requests.get(wikipedia_list, headers={"User-Agent": "ici : http://github.com/edsu/ici"}).content

for m in re.findall(r'<a class="external text" href="//(.+?)\..+?">([^<].+?)</a>', html):
    wikipedias[m[1]] = m[0]

# look to see which wikipedias support geosearch in their api

geo_enabled = {}
geo_search = "http://%s.wikipedia.org/w/api.php?action=query&prop=info%%7Ccoordinates&generator=geosearch&ggsradius=5000&ggscoord=52.516667%%7C13.383333&ggslimit=250&format=json"

for name, code in wikipedias.items():
    if code == "meta":
        continue
    url = geo_search % code
    try:
        geo = requests.get(url, headers={"User-Agent": "ici : http://github.com/edsu/ici"}).json()
        if type(geo) == dict:
            print "y"
            geo_enabled[name] = code
        else: 
            print "n"
    except: 
        pass # m'eh

import sys; sys.exit()

# output some html

names = geo_enabled.keys()
names.sort()

for name in names:
    print '<option value="%s">%s</option>' % (geo_enabled[name], name)
