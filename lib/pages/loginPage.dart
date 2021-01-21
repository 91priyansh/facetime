import 'package:facetime/providers/rootProvider.dart';
import 'package:facetime/services/authService.dart';
import 'package:facetime/services/database/firebaseDatabase.dart';
import 'package:facetime/utils/errors.dart';
import 'package:facetime/utils/routes.dart';
import 'package:facetime/widgets/customTextFormField.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String _email = "";
  String _password = "";
  bool _isLoading = false;

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

  void _changeIsLoading() {
    setState(() {
      _isLoading = !_isLoading;
    });
  }

  void loginUser() {
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save();
      print(_email);
      print(_password);
      _changeIsLoading();
      AuthService.loginUser(_email, _password).then((uid) {
        //Fetching current user's data
        FirebaseDatabase.fetchUserData(uid).then((userDetails) {
          //changing auth status
          Provider.of<RootProvider>(context, listen: false).changeAuthStatus(
              uid,
              email: userDetails.email,
              userImageUrl: userDetails.userImageUrl,
              username: userDetails.username);
        }).catchError((e) {
          Errors.showErrorDialog(context, e.toString());
          _changeIsLoading();
          //signing out the user
          AuthService.signOut();
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
            key: _formKey,
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
                  height: 10.0,
                ),
                _isLoading
                    ? Center(
                        child: CircularProgressIndicator(),
                      )
                    : RaisedButton(
                        onPressed: () {
                          loginUser();
                        },
                        child: Text("Log In"),
                      ),
                _isLoading
                    ? Container()
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Not have an account?"),
                          Transform.translate(
                            offset: Offset(-10.0, 0.0),
                            child: FlatButton(
                              onPressed: () {
                                Navigator.of(context)
                                    .pushNamed(Routes.signUpPage);
                              },
                              child: Text("Create Account"),
                            ),
                          )
                        ],
                      )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
