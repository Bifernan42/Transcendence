from django.shortcuts import render, redirect
from django.contrib import messages
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.decorators import login_required
from django.contrib.auth.models import User
from django.db import IntegrityError
from django.db.models import Q
from rest_framework.views import APIView
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework import status
from rest_framework import serializers
from rest_framework.permissions import AllowAny
from rest_framework.exceptions import ValidationError
from rest_framework_simplejwt.authentication import JWTAuthentication
from rest_framework_simplejwt.tokens import RefreshToken
from .models import CustomUserTrans, Friendship

### USER SYSTEMS ###
class LoginSerializer(serializers.Serializer):
    username = serializers.CharField()
    password = serializers.CharField()

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
        if CustomUserTrans.objects.filter(username=username).exists():
            return Response({"detail": "Username already exists"}, status=status.HTTP_400_BAD_REQUEST)
        if CustomUserTrans.objects.filter(email=email).exists():
            return Response({"detail": "Email already in use."}, status=status.HTTP_400_BAD_REQUEST)
        else:
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



### FRIEND SYSTEMS ###
@api_view(['POST'])
@login_required
def add_friend(request):
    try:
        user = request.user
        friend = CustomUserTrans.objects.get(username=request.data.get('friend_user'))
        if user.username == friend.username:
            Response({"detail":f"You cannot send yourself a friend request"}, status=400)

        #check si deja amis
        if Friendship.objects.filter(
                Q(user=user, friend=friend, accepted=True) | 
                Q(user=friend, friend=user, accepted=True)
        ).count() == 2:
            return Response({"detail": "You are already friends."}, status=400)
        #check si deja request
        if Friendship.objects.filter(user=user, friend=friend, accepted=False).exists():
            return Response({"detail": "Friend request already sent."}, status=400)
        try:
            #si friend a deja request user, accept
            friendship = Friendship.objects.filter(user=friend, friend=user, accepted=False).get()
            friendship.accepted = True
            friendship.save()
            Friendship.objects.create(user=user, friend=friend, accepted=True)
            return Response({"detail": f"Friend request already received from {friend.username}, accepted."}, status=200)
        except Friendship.DoesNotExist:
            #si non, request friend
            Friendship.objects.create(user=user, friend=friend)
            return Response({"detail": f"Friend request successfully send to {friend.username}."}, status=200)

    except CustomUserTrans.DoesNotExist:
        return Response({"error": f"User {request.data.get('friend_user')} does not exist."}, status=400)
    except Exception as e:
        return Response({"error": str(e)}, status=400)

@api_view(['DELETE'])
@login_required
def unfriend(request):
    try:
        user = request.user
        friend = CustomUserTrans.objects.get(username=request.data.get('friend_user'))
        if user.username == friend.username:
            Response({"detail":f"You cannot unfriend yourself"}, status=400)

        friendship_1 = Friendship.objects.filter(user=user, friend=friend).first()
        friendship_2 = Friendship.objects.filter(user=friend, friend=user).first()

        if friendship_1.accepted and friendship_2.accepted:
            friendship_1.delete()
            friendship_2.delete()
            return Response({"detail": f"You have unfriended {friend.username}."}, status=200)
        return Response({"detail": f"{friend.username} is not currently your friend."}, status=400)
    except CustomUserTrans.DoesNotExist:
        return Response({"error": "User not found."}, status=400)
    except Exception as e:
        return Response({"error": str(e)}, status=400)

@api_view(['GET'])
@login_required
def view_sent_requests(request):
    try:
        user = request.user
        sent_requests = Friendship.objects.filter(user=user, accepted=False)
        sent_requests_data = [{"friend_user": req.friend.username} for req in sent_requests]
        return Response(sent_requests_data, status=200)
    except Exception as e:
        return Response({"error": str(e)}, status=400)

@api_view(['GET'])
@login_required
def view_received_requests(request):
    try:
        user = request.user
        received_requests = Friendship.objects.filter(friend=user, accepted=False)
        received_requests_data = [{"user": req.user.username} for req in received_requests]
        return Response(received_requests_data, status=200)
    except Exception as e:
        return Response({"error": str(e)}, status=400)

@api_view(['POST'])
@login_required
def accept_friend_request(request):
    try:
        user = request.user
        friend = CustomUserTrans.objects.get(username=request.data.get('friend_user'))
        friendship = Friendship.objects.get(user=friend, friend=user, accepted=False)

        friendship.accepted = True
        friendship.save()
        Friendship.objects.create(user=user, friend=friendship.user, accepted=True)
        return Response({"detail": f"You and {friend} are now friends!"}, status=200)

    except Friendship.DoesNotExist:
        return Response({"error": "Friend request not found."}, status=404)
    except Exception as e:
        return Response({"error": str(e)}, status=400)

@api_view(['POST'])
@login_required
def reject_friend_request(request):
    try:
        user = request.user
        friend = CustomUserTrans.objects.get(username=request.data.get('friend_user'))
        friendship = Friendship.objects.get(user=friend, friend=user, accepted=False)

        friendship.delete()
        return Response({"detail": f"You have rejected {friend}'s friend request."}, status=200)

    except Friendship.DoesNotExist:
        return Response({"error": "Friend request not found."}, status=404)
    except Exception as e:
        return Response({"error": str(e)}, status=400)

@api_view(['GET'])
@login_required
def view_friends_list(request):
    user = request.user
    friendships = Friendship.objects.filter(user=user, accepted=True)
    friend_usernames = [f.friend.username for f in friendships]
    return Response({"friends":friend_usernames}, status=200)

@api_view(['GET'])
@login_required
def friendship_status(request):
    try:
        user = request.user
        friend = CustomUserTrans.objects.get(username=request.data.get('friend_user'))
        if user.username == friend.username:
            Response({"detail":f"That's you!"}, status=400)

        friendship_1 = Friendship.objects.filter(user=user, friend=friend).first()
        friendship_2 = Friendship.objects.filter(user=friend, friend=user).first()
        if friendship_1:
            if friendship_1.accepted:
                return response({friend.username: "friends"}, status=200)
            else:
                return Response({friend.username: "request_sent"}, status=200)
        elif friendship_2 and not friendship_2.accepted:
                return Response({friend.username: "request_received"}, status=200)

        return Response({friend.username: "no_relationship"}, status=200)
    except CustomUserTrans.DoesNotExist:
        return Response({"error": "User not found."}, status=400)
    except Exception as e:
        return Response({"error": str(e)}, status=400)
### FRIENDS END ###

### NOTIFICATIONS ###
@api_view(['GET'])
@login_required
def view_notifications(request):
    try:
        user = request.user
        pending = Friendship.objects.filter(friend=user, accepted=False)

        friend_requests = [
            {
                "type":"friend_request",
                "message":f"{req.user.username} has sent you a friend request",
                "sender":req.user.username
            }
            for req in pending
        ]

        # CAN ADD OTHER NOTIFICATIONS HERE

        return Response({"notifications":friend_requests}, status=200)
    except Exception as e:
        return Response({"error": str(e)}, status=400)




