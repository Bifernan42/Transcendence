from django.contrib import admin
from .models import CustomUserTrans, Friendship, History

# Register your models here.

admin.site.register(CustomUserTrans)
admin.site.register(Friendship)
admin.site.register(History)
