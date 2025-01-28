from django.contrib import admin
from .models import CustomUserTrans, Friendship

# Register your models here.

admin.site.register(CustomUserTrans)
admin.site.register(Friendship)