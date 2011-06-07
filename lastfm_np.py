#!/usr/bin/env python

import sys
import urllib2
from itertools import cycle
from urllib import urlencode
from time import sleep

users = "ludvigericson", "modigkrokodil"

default_format = "np: %(artist)s - %(title)s"
api_key = "b25b959554ed76058ac220b7b2e0a026"
ws_url = "http://ws.audioscrobbler.com/2.0/"

def lastfm_qs(method_name, api_key=api_key, **additional):
    return urlencode(dict(additional, method=method_name, api_key=api_key))

def lastfm_url(method_name, ws_url=ws_url, **kwds):
    return ws_url + "?" + lastfm_qs(method_name, **kwds)

def interpret_recent_minidom(fp):
    from xml.dom import minidom
    xml = minidom.parse(fp)
    for node in xml.getElementsByTagName("track"):
        if node.getAttribute("nowplaying"):
            artist = node.getElementsByTagName("artist")[0].childNodes[0].data
            name = node.getElementsByTagName("name")[0].childNodes[0].data
            return artist, name

def interpret_recent_etree(fp):
    from xml.etree import cElementTree as ElementTree
    tree = ElementTree.parse(fp)
    tracks = tree.getroot().find("recenttracks").findall("track")
    for track in tracks:
        if track.get("nowplaying", "false") == "true":
            artist = track.find("artist").text
            name = track.find("name").text
            return artist, name

def get_recent_for(user, interpreter=interpret_recent_etree):
    url = lastfm_url("user.getrecenttracks", user=user, limit=1)
    resp = urllib2.urlopen(url)
    return interpreter(resp)

if __name__ == "__main__":
    format = " ".join(sys.argv[1:]).decode("utf-8")
    if not format:
        format = default_format

    next_user = cycle(users).next
    recent = None
    backoff = 0
    while recent is None:
        user = next_user()
        recent = get_recent_for(user)
        if recent is None:
            backoff += 2
            sleep(backoff)
        else:
            artist, title = recent
            info = dict(user=user, artist=artist, title=title)
            print (format % info).encode("utf-8")
