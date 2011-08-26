
__author__="mark"
__date__ ="$Sep 8, 2010 8:59:08 PM$"

class LoginError(Exception):

    def __init__(self, value):
        self.value = value

    def __str__(self):
        return repr(self.value)
