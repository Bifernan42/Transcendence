from django.db import models
from django.contrib.auth.models import AbstractUser, BaseUserManager
from phonenumber_field.modelfields import PhoneNumberField

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


# class History(models.Model):
#     user = models.ForeignKey(CustomUserTrans.id)
#     user_2 = models.ForeignKey(CustomUserTrans.id)
#     score = models.IntegerField()
#     score_2 = models.IntegerField()
#     status = models.CharField(max_length=30)
#     duration = models.DurationField()
#     date_played = models.DateTimeField(auto_now_add=True)
    

#     def __str__(self):
#         return f"History between {self.user.username} and {self.User_2.username}"