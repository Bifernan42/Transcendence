"""
URL configuration for transcendence project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.1/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path
from .views import LoginView, LogoutView
from . import views

urlpatterns = [
    path('login/', views.LoginView.as_view(), name='login'),
    path('logout/', views.LogoutView.as_view(), name='logout'),
    path('register/', views.registerView, name='register'),
    path('password_change/', views.PasswordChangeView.as_view(), name='change_password'),
    path('password_reset/', views.PasswordResetRequestView.as_view(), name='request_password_change'),
    path('password_reset/<uidb64>/<token>/', views.PasswordResetConfirmView.as_view(), name='confirm_password_change'),
    path('email_update/', views.EmailUpdateView.as_view(), name='update_email'),
    path('username_update/', views.UsernameUpdateView.as_view(), name='username_update'),
    path('pictures_update/', views.PhotoUpdateView.as_view(), name='photo_update'),
   # path('phone_number_update/', views.PhoneNumberUpdateView.as_view(), name='phone_number_update'),
    path('friend_requests/add_friend/', views.add_friend, name='add_friend'),
    path('unfriend/', views.unfriend, name='unfriend'),
    path('friend_requests/sent/', views.view_sent_requests, name='view_sent_requests'),
    path('friend_requests/received/', views.view_received_requests, name='view_received_requests'),
    path('friend_requests/accept/', views.accept_friend_request, name='accept_friend_request'),
    path('friend_requests/reject/', views.reject_friend_request, name='reject_friend_request'),
    path('friendslist/', views.view_friends_list, name='view_friends_list'),
    path('friend_status/', views.friendship_status, name='friendship_status'),
    path('notifications/', views.view_notifications, name='view_notifications'),
    path('history/', views.show_history, name='history'),
    path('add_game/', views.add_game_history, name='add_game'),
]

