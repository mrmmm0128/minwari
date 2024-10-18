import os

class Config:
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'a_random_secret_key'
    DEBUG = True