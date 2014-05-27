"""\
Cooperative task scheduling

Simple library for scheduling tasks and checking when to execute them, for
example::

    >>> import schedule, datetime, time
    >>> schedule.every(datetime.timedelta(seconds=1), 'laundry')
    >>> time.sleep(2)
    >>> schedule.due().next()
    'laundry'
    >>> schedule.remove('laundry')

You can schedule anything you like, typically a callable::

    >>> schedule.add(datetime.datetime.now(), lambda: 'surprise!')
    >>> for task in schedule.due():
    ...   print(task())
    ... 
    surprise!

"""

import heapq
import datetime

class Schedule(object):
    def __init__(self):
        #: a heap of (when, recur, item)
        self._upcoming = []

    def add(self, when, item, recur=None):
        heapq.heappush(self._upcoming, (when, recur, item))

    def every(self, recur, item):
        self.add(datetime.datetime.now() + recur, item, recur=recur)

    def remove(self, item):
        f = lambda (when, recur, itemf): itemf != item
        self._upcoming = filter(f, self._upcoming)

    def due(self):
        now = datetime.datetime.now()

        while self._upcoming:
            (when, recur, item) = self._upcoming[0]

            if when > now:
                break

            if recur:
                heapq.heapreplace(self._upcoming, (now + recur, recur, item))
            else:
                heapq.heappop(self._upcoming)

            yield item

_default_schedule = Schedule()
add = _default_schedule.add
every = _default_schedule.every
remove = _default_schedule.remove
due = _default_schedule.due

if __name__ == "__main__":
    import doctest
    doctest.testmod()
