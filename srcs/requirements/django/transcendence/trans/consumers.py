import json
from channels.generic.websocket import AsyncWebsocketConsumer
from django.contrib.auth import get_user_model
from channels.db import database_sync_to_async


User = get_user_model()


class Consumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.user = self.scope["user"]
        if self.user.is_authenticated:
            await self.set_user_online(self.user)
        await self.accept()
        
    async def disconnect(self, close_code):
        if self.user.is_authenticated:
            await self.set_user_offline(self.user)

    async def receive(self, text_data):
        text_data_json = json.loads(text_data)
        message = text_data_json['message']

        await self.send(text_data=json.dumps({
            'message': message
        }))

@database_sync_to_async
def set_user_online(self, user):
    user.is_online = True
    user.save()

@database_sync_to_async
def set_user_offline(self, user):
    user.is_online = False
    user.save()
