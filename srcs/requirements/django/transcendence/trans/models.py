from django.db import models
from django.contrib.auth.models import AbstractUser, BaseUserManager
from phonenumber_field.modelfields import PhoneNumberField
from django.core.exceptions import ValidationError
from django.utils.translation import gettext_lazy as _
from datetime import timedelta
from django.utils import timezone
from django.core.files import File
from django.conf import settings
import os

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
        with open('/app/media/users/images/default.jpg', 'rb') as f:
            user.photo.save('default.jpg', File(f), save=False)
        print("prout")
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
    phone_number = PhoneNumberField(blank=False, unique = True)
    photo = models.ImageField(upload_to='users/images/')

    nbrgames = models.IntegerField(default=0, editable=False)
    mmr = models.IntegerField(default=1000, editable=False)
    wins = models.IntegerField(default=0, editable=False)
    loses = models.IntegerField(default=0, editable=False)
    null = models.IntegerField(default=0, editable=False)
    percent_win = models.IntegerField(default=0, editable=False)

    objects = CustomUserTransManager()

    USERNAME_FIELD = 'username'
    REQUIRED_FIELDS = ['email', 'phone_number']
    
    def set_stats(self, opponent_mmr, status) :
        self.nbrgames = self.nbrgames + 1
        if self.nbrgames >= 0 and self.nbrgames <= 10 :
            k = 40
        else :
            k = 20
        E =  1 / (1 + 10 ** ((opponent_mmr - self.mmr) / 400))
        if status == 1:  # Victoire
            score = 1
            self.wins = self.wins + 1
        elif status == 0.5:  # Match nul
            score = 0.5
            self.null = self.null + 1
        else:  # Défaite
            score = 0
            self.loses = self.loses + 1
        self.percent_win = self.wins / (self.nbrgames - self.null) * 100
        # Calcul du nouveau classement
        self.mmr = self.mmr + k * (score - E)
        self.save()

    def clean(self):
        if self.nbrgames < 0 or self.wins < 0 or self.loses < 0 or self.null < 0:
            raise ValidationError(_('Number of games must be positive or equal 0.'))
        if (self.wins + self.loses + self.null) > self.nbrgames : 
            raise ValidationError(_('Error of count in games.'))
        if self.percent_win != (self.wins / (self.nbrgames - self.null) * 100) : 
            raise ValidationError(_('Invalid percentage.'))

        
    def __str__(self):
        return f"{self.username}"

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
        one_month_ago = timezone.now() - timedelta(days=30)
        if self.date_played < one_month_ago:
            raise ValidationError(_("Game has been played more than a month ago")) 
    
    def __str__(self):
        return f"Game number {self.id}"
