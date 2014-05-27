"get a page, fill in a form and post it, or click a link. whatever."

import os
import sys
import time
import cookielib
from urlparse import urljoin

import requests
import BeautifulSoup
from requests.cookies import cookiejar_from_dict

class Context(object):
    user_agent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/33.0.1750.117 Safari/537.36'
    cookie_file = os.path.expanduser('~/.webinteract-cookies.lwp')

    def __init__(self, url, delay=30):
        self.session = requests.Session()
        self.session.cookies = cookielib.LWPCookieJar()
        if os.path.exists(self.cookie_file):
            self.session.cookies.load(self.cookie_file)
        self.session.headers['User-Agent'] = self.user_agent
        self.info('Interact with %s', url)
        self.request_delay = delay
        self.request('GET', url)

    def info(self, text, *args):
        print >>sys.stderr, time.ctime(), text % args

    def request(self, method, url, **kwargs):
        timeout = kwargs.pop('timeout', 10)
        req = self.session.prepare_request(requests.Request(method, url, **kwargs))
        resp = self.session.send(req, timeout=timeout)
        self.response = resp
        # check for html?
        self.soup = BeautifulSoup.BeautifulSoup(resp.text, convertEntities=BeautifulSoup.BeautifulSoup.HTML_ENTITIES)
        self.session.cookies.save(self.cookie_file)
        time.sleep(self.request_delay)

    def open_link(self, url):
        url = urljoin(self.response.url, url)
        self.info('Open link %s', url)
        self.request('GET', url, timeout=5)

    def submit_form(self, form=None, **items):
        if not form:
            form = self.soup('form')[0]

        url = urljoin(self.response.url, form['action'])
        method = form.get('method', 'GET').upper()
        #enctype = form.get('enctype', 'application/x-www-form-urlencoded')

        data = {}
        for inp in form('input'):
            if 'value' in inp:
                data[inp['name']] = inp['value']
        #for inp in form('select'):
        #for inp in form('textarea'):

        for name, value in items.iteritems():
            data[name] = value

        # We take no heed of enctype because the requests library does that by
        # itself and is actually kind of robust about it. Makes for a much
        # better API.
        self.info('Submit form %s %s %s', method, url, data)
        if method == 'GET':
            return self.request(method, url, params=data, timeout=2)
        elif method == 'POST':
            return self.request(method, url, data=data, timeout=5)
        else:
            raise ValueError(method)

start = Context
