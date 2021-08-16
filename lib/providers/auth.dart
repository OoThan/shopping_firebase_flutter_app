import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/http_exception.dart';

class Auth with ChangeNotifier {
  late String _token;
  DateTime? _expiryDate;
  late String _userId;
  Timer? _authTimer;

  bool get isAuth {
    print(token != '');
    return token != '';
  }

  String get token {
    if (_expiryDate != null &&
        _expiryDate!.isAfter(DateTime.now()) &&
        _token != null) {
      // print('still');
      return _token;
    }
    return '';
  }

  String get userId {
    return _userId;
  }

  Future<void> _authenticate(
      String email, String password, String urlSegment) async {
    var url =
        'https://identitytoolkit.googleapis.com/v1/accounts:$urlSegment?key=AIzaSyDH4Y330EaoxrUy-ZHtNtcyXEwTgrPaMcE';
    try {
      final response = await http.post(
        Uri.parse(url),
        body: json.encode({
          'email': email,
          'password': password,
          'returnSecureToken': true,
        }),
      );
      final responseData = json.decode(response.body);
      if (responseData['error'] != null) {
        throw HttpException(responseData['error']['message']);
      }
      _token = responseData['idToken'];
      _userId = responseData['localId'];
      _expiryDate = DateTime.now().add(
        Duration(
          seconds: int.parse(responseData['expiresIn']),
        ),
      );
      _autoLogout();
      notifyListeners();
      // print(json.decode(response.body));

      final prefs = await SharedPreferences.getInstance();
      final userData = json.encode(
        {
          'token': _token,
          'userId': _userId,
          'expiryDate': _expiryDate!.toIso8601String(),
        },
      );
      // addToken();
      // addUserId();
      // addExpiryDate();
      // notifyListeners();
      prefs.setString('token', _token);
      prefs.setString('expiryDate', _expiryDate!.toIso8601String());
      prefs.setString('userId', _userId);
      notifyListeners();
    } catch (error) {
      throw error;
    }
    // print(json.decode(response.body));
  }

  Future<void> signup(String email, String password) async {
    return _authenticate(email, password, 'signUp');
  }

  Future<void> login(String email, String password) async {
    return _authenticate(email, password, 'signInWithPassword');
  }

  void logout() {
    _token = '';
    _expiryDate = null;
    _userId = '';
    if (_authTimer != null) {
      _authTimer!.cancel();
      _authTimer = null;
    }
    notifyListeners();
  }

  void _autoLogout() {
    if (_authTimer != null) {
      _authTimer!.cancel();
    }
    // final timeToExpiry = _expiryDate?.difference(DateTime.now()).inSeconds;
    // _authTimer = Timer(Duration(seconds: timeToExpiry!), logout);
    notifyListeners();
  }

  // addToken() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   prefs.setString('token', _token);
  // }

  // getToken() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   String stringToken = prefs.getString('token').toString();
  //   return stringToken;
  // }

  // addUserId() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   prefs.setString('userId', _userId);
  // }

  // getUserId() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   String stringUserId = prefs.getString('userId').toString();
  //   return stringUserId;
  // }

  // addExpiryDate() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   prefs.setString('expiryDate', _token);
  // }

  // getExpiryDate() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   String stringExpiryDate = prefs.getString('expiryDate').toString();
  //   return stringExpiryDate;
  // }

  Future<bool?> tryAutoLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    print('trying');
    if (!prefs.containsKey('token')) {
      return false;
    }
    // final extractedUserData = json.decode(data) as Map<String, Object>;
    // final expiryDate = DateTime.parse(getExpiryDate());
    // final token = getToken();
    // final userId = getUserId();
    final expiryDate = DateTime.parse(prefs.getString('expiryDate').toString());
    final token = prefs.getString('token');
    final userId = prefs.getString('userId');
    print(expiryDate);
    print(token);
    print(userId);
    if (expiryDate.isBefore(DateTime.now())) {
      print('tryingyyyy');
      return false;
    }
    notifyListeners();
    _autoLogout();
    print('tryingyyyy');
    return true;
    // notifyListeners();
  }
}
