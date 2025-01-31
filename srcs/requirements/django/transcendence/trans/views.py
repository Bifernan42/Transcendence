from django.shortcuts import render, redirect
from django.contrib import messages
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.decorators import login_required
from django.contrib.auth.models import User
from django.db import IntegrityError
from rest_framework.views import APIView
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework import status
from rest_framework import serializers
from rest_framework.permissions import AllowAny, IsAdminUser
from rest_framework_simplejwt.tokens import RefreshToken
from datetime import timedelta
from django.utils import timezone
from django.db.models import Q
from django.core.validators import validate_email
from django.core.exceptions import ValidationError
from .models import CustomUserTrans, Friendship, History
from phonenumber_field.validators import validate_international_phonenumber

class LoginSerializer(serializers.Serializer):
    username = serializers.CharField()
    password = serializers.CharField()

class HistorySerializer(serializers.ModelSerializer):
    class Meta:
        model = History
        fields = ['user1', 'user2', 'score1', 'score2', 'winner', 'duration', 'date_played']
    def validate_winner(self, value):
        if value < 0 or value > 2:
            raise serializers.ValidationError("Winner must be between 0 and 2.")
        return value

    def validate_date_played(self, value):
        one_month_ago = timezone.now() - timedelta(days=30)
        if value < one_month_ago:
            raise serializers.ValidationError("Game has been played more than a month ago.")
        return value
        
@api_view(['POST'])
@permission_classes([AllowAny])
def registerView(request):
    if (request.method == "POST"):
        username = request.data.get('username')
        email = request.data.get('email')
        password = request.data.get('password')
        phone_number = request.data.get('phone_number')

        if not username or not password or not email or not phone_number:
            return Response({"detail": "Username, email, phone number, and password are required"}, status=status.HTTP_400_BAD_REQUEST)
        
        try :
            validate_email(email)
        except ValidationError:
            return Response({"detail": "Email Error"}, status=status.HTTP_400_BAD_REQUEST)

        try :
            validate_international_phonenumber(phone_number)
        except ValidationError:
                return Response({"detail": "Invalid phone number"}, status=status.HTTP_400_BAD_REQUEST)
        
        if not re.match("^[a-zA-Z0-9_]*$", username):
            return Response({"detail": "Username must not contain special characters."}, status=status.HTTP_400_BAD_REQUEST)
        
        if len(username) < 4 or len(username) > 15 :
            return Response({"detail": "Username must be between 4 and 20 characters"}, status=status.HTTP_400_BAD_REQUEST)

        if CustomUserTrans.objects.filter(username=username).exists():
            return Response({"detail": "Username already exists"}, status=status.HTTP_400_BAD_REQUEST)
        
        if CustomUserTrans.objects.filter(email=email).exists():
            return Response({"detail": "Email already in use."}, status=status.HTTP_400_BAD_REQUEST)
        
        user = CustomUserTrans.objects.create_user(username=username, password=password, email=email, phone_number=phone_number)
        user.save()
        login(request, user)
        refresh = RefreshToken.for_user(user)
        return Response({
            "detail": "Successfully registered.",
            "refresh": str(refresh),
            "access": str(refresh.access_token)
        }, status=status.HTTP_200_OK)
        return Response({"detail": "Successfully registered."}, status=status.HTTP_200_OK)
    return Response({"detail": "Invalid request method"}, status=status.HTTP_400_BAD_REQUEST)

# Vue de connexion
class LoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request, **kwargs):
        # Utilisation du sérialiseur pour valider les données d'entrée
        serializer = LoginSerializer(data=request.data)
        if serializer.is_valid():
            username = serializer.validated_data['username']
            password = serializer.validated_data['password']
            user = authenticate(username=username, password=password)
            if user is not None and user.is_active:
                login(request, user)
                refresh = RefreshToken.for_user(user)
                return Response({
                    "detail": "Successfully logged in.",
                    "refresh": str(refresh),
                    "access": str(refresh.access_token)
                }, status=status.HTTP_200_OK)
                return Response({"detail": "Successfully logged in."}, status=status.HTTP_200_OK)
            return Response({"detail": "Invalid credentials or inactive user."}, status=status.HTTP_400_BAD_REQUEST)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class LogoutView(APIView):  

    def get(self, request, **kwargs):
        logout(request)
        return Response({"detail" : "Successfully logged out."}, status=status.HTTP_200_OK)

# que des users authenitcated peuvent appeller la fonction (a tester)
@api_view(['POST'])
@permission_classes([AllowAny])
@login_required
def add_friend(request):
    # Pour la requette HTTP method="POST" dans l'HTML?
    if request.method == "POST":
        # normalement, request contient le user qui l'a envoye et name='friend_user' ou 'friend_username'
        try:
            user = request.user
            username = request.data.get('friend_user')
            friend = CustomUserTrans.objects.get(username=request.data.get('friend_user'))

            #check si deja amis
            if Friendship.objects.filter(user=user, friend=friend, accepted=True).exists() or \
                Friendship.objects.filter(user=friend, friend=user, accepted=True).exists():
                    return Response({"detail": "You are already friends."}, status=400)
            #check si deja request
            if Friendship.objects.filter(user=user, friend=friend, accepted=False).exists() or \
                Friendship.objects.filter(user=friend, friend=user, accepted=False).exists():
                    return Response({"detail": "Friend request already sent or received."}, status=400)
            # success     
            Friendship.objects.create(user=user, friend=friend)
            return Response({"detail": f"Friend request successfully send to {friend.username}"}, status=status.HTTP_200_OK)

        except CustomUserTrans.DoesNotExist:
            return Response({"error": f"User does not exist.{username}"}, status=400)
        except ValueError as e:
            return Response({"error": str(e)}, status=400)


@api_view(['GET'])
@permission_classes([AllowAny])
@login_required
def show_history(request):
    if request.method == "GET":
        try :
            user = request.user.id
            #supprimer les games de l'utilisateurs datant de plus d'un mois
            one_month_ago = timezone.now() - timedelta(days=30)
            History.objects.filter(date_played__lt=one_month_ago).filter(Q(user1=user) | Q(user2=user)).delete()
            #trier les games pour les renvoyer
            histories = History.objects.filter(user1=user) | History.objects.filter(user2=user)
            serializer = HistorySerializer(histories, many=True)
            return Response(serializer.data, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)
    return Response({"detail": "Invalid request method"}, status=status.HTTP_400_BAD_REQUEST)

#Seul le serveur peut configurer une nouvelle partie dans l'historique, faut encore configurer son "rang"
@api_view(['POST'])
@permission_classes([IsAdminUser])
def add_game_history(request):
    if (request.method == "POST"):
        try :
            user1 = request.data.get('user1')
            user2 = request.data.get('user2')
            winner = request.data.get("winner")
            serializer = HistorySerializer(data=request.data)
            if serializer.is_valid():
                serializer.save()
                user1object = CustomUserTrans.objects.get(id=user1)
                user2object = CustomUserTrans.objects.get(id=user2)
                #incrementation du nombre de partie
                if winner == 1:
                    user1object.set_stats(user2object.mmr, 1)  # user1 gagne
                    user2object.set_stats(user1object.mmr, 0)  # user2 perd
                elif winner == 2:
                    user1object.set_stats(user2object.mmr, 0)  # user1 perd
                    user2object.set_stats(user1object.mmr, 1)  # user2 gagne
                else:
                    user1object.set_stats(user2object.mmr, 0.5)  # match nul
                    user2object.set_stats(user1object.mmr, 0.5)  # match nul
                return Response(serializer.data, status=status.HTTP_201_CREATED)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)
    return Response({"detail": "Invalid request method"}, status=status.HTTP_400_BAD_REQUEST)

