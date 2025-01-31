from django.db import models
from django.contrib.auth.models import AbstractUser, BaseUserManager
from phonenumber_field.modelfields import PhoneNumberField
from django.core.exceptions import ValidationError
from django.utils.translation import gettext_lazy as _

class CustomUserTransManager(BaseUserManager):
    def _create_user(self, username, email, password, **extra_fields):
        if not username:
            raise ValueError("The username field must be set")
        if not password:
            raise ValueError("The password field must be set")
        if not extra_fields.get('phone_number'):
            raise ValueError("The phone number field must be set")
        if not email:
            raise ValueError("The Email field must be set")
        
        email = self.normalize_email(email)
        user = self.model(username=username, email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_user(self, username, email=None, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', False)
        extra_fields.setdefault('is_superuser', False)
        return self._create_user(username, email, password, **extra_fields)

    def create_superuser(self, username, email=None, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)

        if extra_fields.get('is_staff') is not True:
            raise ValueError('Superuser must have is_staff=True.')
        if extra_fields.get('is_superuser') is not True:
            raise ValueError('Superuser must have is_superuser=True.')

        return self._create_user(username, email, password, **extra_fields)

class CustomUserTrans(AbstractUser):
    email = models.EmailField(unique=True)
    phone_number = PhoneNumberField(blank=True, null=True)

    objects = CustomUserTransManager()

    USERNAME_FIELD = 'username'
    REQUIRED_FIELDS = ['email', 'phone_number']

    def __str__(self):
        return self.username

class Friendship(models.Model):
    user = models.ForeignKey(CustomUserTrans, related_name="friendship_requests_sent", on_delete=models.CASCADE)
    friend = models.ForeignKey(CustomUserTrans, related_name="friendship_requests_received", on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
    accepted = models.BooleanField(default=False)
    
    def __str__(self):
        return f"{self.user.username} status with  {self.friend.username} = {self.accepted}"


class History(models.Model):
    user1 = models.ForeignKey(CustomUserTrans, related_name="player1", on_delete=models.CASCADE)
    user2 = models.ForeignKey(CustomUserTrans, related_name="player2",  on_delete=models.CASCADE)
    score1 = models.IntegerField()
    score2 = models.IntegerField()
    winner = models.IntegerField(default=0)
    duration = models.DurationField()
    date_played = models.DateTimeField()
    
    def clean(self):
        if self.winner < 0 or self.winner > 2:
            raise ValidationError(_('Winner must be between 0 and 2.'))
    
    def __str__(self):
        return f"History of games"
