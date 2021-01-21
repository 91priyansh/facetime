import 'package:facetime/providers/rootProvider.dart';
import 'package:facetime/services/authService.dart';
import 'package:facetime/services/database/firebaseDatabase.dart';
import 'package:facetime/utils/errors.dart';
import 'package:facetime/widgets/customTextFormField.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SignUpPage extends StatefulWidget {
  SignUpPage({Key key}) : super(key: key);

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final GlobalKey<FormState> _key = GlobalKey<FormState>();
  String _email = "";
  String _password = "";
  String _username = "";
  bool _isLoading = false;

  //_usernameAvailability will have 4 state (0 to 4)
  //0 means we did not check for uniqueness of username
  //1 means checking(in-progress) uniqueness of username
  //2 means username is unique
  //3 means username is already exist
  int _usernameAvailability = 0;
  List<String> _usernames = [];

  String _emailValidator(String value) {
    if (value.isEmpty) {
      return "Please enter email address";
    }
    return null;
  }

  String _passwordValidator(String value) {
    if (value.isEmpty) {
      return "Please enter password";
    }
    return null;
  }

  Widget getUsernameSuffixIcon() {
    if (_usernameAvailability == 0) {
      return SizedBox();
    } else if (_usernameAvailability == 1) {
      return SizedBox(
        height: 12.5,
        width: 12.5,
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      );
    } else if (_usernameAvailability == 2) {
      return Icon(
        Icons.check,
        color: Colors.green,
      );
    }
    return Icon(
      Icons.error_outline,
      color: Colors.red,
    );
  }

  void changeUsernameAvailability(int value) {
    setState(() {
      _usernameAvailability = value;
    });
  }

  void onUsernameTextFormFieldChanged(String value) {
    if (value.isEmpty) {
      //set _usernameAvailibility to 0
      setState(() {
        _usernameAvailability = 0;
        _usernames = [];
      });
    } else if (value.length == 1 && _usernameAvailability == 0) {
      print("will fetch usernames that starts with $value");
      changeUsernameAvailability(1);
      //fetching usernames
      FirebaseDatabase.fetchUsernames(value.trim()).then((usernames) {
        setState(() {
          _usernames = usernames;
          if (_usernames.contains(value.trim())) {
            //username already exist
            _usernameAvailability = 3;
          } else {
            //username is unique
            _usernameAvailability = 2;
          }
        });
      }).catchError((e) {
        changeUsernameAvailability(0);
        //Show error dialog
        Errors.showErrorDialog(context, e.toString());
      });
    } else {
      //check for username availablitity
      if (_usernames.contains(value.trim())) {
        changeUsernameAvailability(3);
      } else {
        changeUsernameAvailability(2);
      }
    }
  }

  Widget usernameTextFormField() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 30.0, vertical: 5.0),
      child: TextFormField(
        onChanged: onUsernameTextFormFieldChanged,
        enabled: !_isLoading, //_usernameAvailability != 1 && !_isLoading
        onSaved: (String value) {
          _username = value.trim().toLowerCase();
        },
        decoration: InputDecoration(
            labelText: "Enter username", suffix: getUsernameSuffixIcon()),
        validator: (String value) {
          if (value.isEmpty) {
            return "Please enter username";
          }
          return null;
        },
      ),
    );
  }

  bool _validateFormFields() {
    if (_key.currentState.validate() && _usernameAvailability == 2) {
      //If user has selected unique username then create account
      _key.currentState.save();
      return true;
    }
    return false;
  }

  void _changeIsLoading() {
    setState(() {
      _isLoading = !_isLoading;
    });
  }

  void createAccount() {
    if (_validateFormFields()) {
      _changeIsLoading();
      //create account in firebase auth
      AuthService.createAccount(_email, _password).then((uid) {
        //add user data into database
        FirebaseDatabase.addUser(email: _email, uid: uid, username: _username)
            .then((_) {
          //change authStatus in rootProvider
          Provider.of<RootProvider>(context, listen: false).changeAuthStatus(
              uid,
              email: _email,
              userImageUrl: "",
              username: _username);
          Navigator.of(context).pop();
        }).catchError((e) {
          Errors.showErrorDialog(context, e.toString());
          //show error message
          _changeIsLoading();
        });
      }).catchError((e) {
        //show error dialog
        Errors.showErrorDialog(context, e.toString());
        _changeIsLoading();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          child: SingleChildScrollView(
            child: Form(
              key: _key,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * (0.2),
                  ),
                  Text(
                    "Facetime",
                    style: TextStyle(fontSize: 25.0),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * (0.05),
                  ),
                  CustomTextFormField(
                    enabled: !_isLoading,
                    hintText: "Enter email",
                    obscureText: false,
                    onSaved: (String value) {
                      _email = value.trim();
                    },
                    textInputType: TextInputType.emailAddress,
                    validator: _emailValidator,
                  ),
                  usernameTextFormField(),
                  CustomTextFormField(
                    enabled: !_isLoading,
                    hintText: "Enter password",
                    obscureText: true,
                    onSaved: (String value) {
                      _password = value.trim();
                    },
                    textInputType: TextInputType.visiblePassword,
                    validator: _passwordValidator,
                  ),
                  SizedBox(
                    height: 15.0,
                  ),
                  _isLoading
                      ? Center(
                          child: CircularProgressIndicator(),
                        )
                      : RaisedButton(
                          onPressed: () {
                            createAccount();
                          },
                          child: Text("Create Account"),
                        ),
                ],
              ),
            ),
          )),
    );
  }
}
