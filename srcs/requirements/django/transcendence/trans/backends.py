from social_core.backends.oauth import BaseOAuth2

class Intra42OAuth2(BaseOAuth2):
    name = 'intra42'
    AUTHORIZATION_URL = 'https://api.intra.42.fr/oauth/authorize'
    ACCESS_TOKEN_URL = 'https://api.intra.42.fr/oauth/token'
    USER_DATA_URL = 'https://api.intra.42.fr/v2/me'
    DEFAULT_SCOPE = ['public']
    EXTRA_DATA = [
        ('id', 'id'),
        ('login', 'username'),
        ('email', 'email'),
    ]

    def get_user_details(self, response):
        return {
            'username': response.get('login'),
            'email': response.get('email') or f"{response.get('login')}@student.42.fr",
        }