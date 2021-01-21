import 'package:facetime/helpers/userPageHelper.dart';
import 'package:facetime/models/callHistory.dart';
import 'package:facetime/models/userDetails.dart';
import 'package:facetime/providers/rootProvider.dart';
import 'package:facetime/services/database/firebaseDatabase.dart';
import 'package:facetime/utils/errors.dart';
import 'package:facetime/widgets/profilePictureContainer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserPage extends StatefulWidget {
  final UserDetails userDetails;
  final bool checkForFriendship;
  const UserPage({Key key, @required this.userDetails, this.checkForFriendship})
      : super(key: key);

  static Route<UserPage> route(RouteSettings routeSettings) {
    Map<String, dynamic> arguments =
        routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
        builder: (context) => UserPage(
              userDetails: arguments['userDetails'],
              checkForFriendship: arguments['checkForFriendship'],
            ));
  }

  @override
  _UserPageState createState() => _UserPageState();
}

enum FriendshipStatus { friend, requested, sendRequest, loading, acceptRequest }

class _UserPageState extends State<UserPage> {
  ///
  ///friendship status
  ///
  FriendshipStatus _friendshipStatus = FriendshipStatus.loading;
  //userpage Helper
  UserPageHelper _userPageHelper;

  //to change friendship status
  void changeFriendshipStatus(FriendshipStatus status) {
    setState(() {
      _friendshipStatus = status;
    });
  }

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () {
      //userPage helper

      _userPageHelper = UserPageHelper(
          context: context,
          changeFriendshipStatus: changeFriendshipStatus,
          userDetails: widget.userDetails);
      //if user comes to this page from homePage (friendsContainer)
      //then we do not need to check friendship status
      if (widget.checkForFriendship) {
        _userPageHelper.checkFriendship();
      } else {
        changeFriendshipStatus(FriendshipStatus.friend);
      }
    });
  }

  //build friendship button based on friendship status
  Widget _buildFriendshipButton() {
    switch (_friendshipStatus) {
      //if status is friend then we display freinds button
      //on tapping this button dialog will pop to unfriend the user
      case FriendshipStatus.friend:
        {
          return CustomRoundedButton(
            function: _userPageHelper.unfriendUser,
            title: "Friends",
          );
        }
      //if status is requested then we display Requested button
      //on tapping this button dialog will pop to cancel request
      case FriendshipStatus.requested:
        {
          return CustomRoundedButton(
            function: _userPageHelper.cancelFriendRequest,
            title: "Requested",
          );
        }
      //if status is sendRequest then we will display Send Request
      case FriendshipStatus.sendRequest:
        {
          return CustomRoundedButton(
            function: _userPageHelper.sendFriendRequest,
            title: "Send Request",
          );
        }
      //if status is acceptRequest then we will display Accept Request
      case FriendshipStatus.acceptRequest:
        {
          return Row(
            children: [
              CustomRoundedButton(
                function: _userPageHelper.acceptRequest,
                title: "Accept Request",
              ),
              SizedBox(
                width: 10.0,
              ),
              CustomRoundedButton(
                size: 0.2,
                function: _userPageHelper.cancelFriendRequest,
                title: "Cancel",
              ),
            ],
          );
        }
      default:
        {
          return CustomRoundedButton(
            function: () {},
            title: "Loading..",
          );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          _friendshipStatus == FriendshipStatus.friend
              ? IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.call),
                )
              : Container()
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 20.0,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20.0,
                ),
                ProfilePictureContainer(
                  size: 40.0,
                  imageUrl: widget.userDetails.userImageUrl,
                ),
                SizedBox(
                  width: 20.0,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userDetails.username,
                        style: TextStyle(fontSize: 19),
                      ),
                      SizedBox(
                        height: 10.0,
                      ),
                      _buildFriendshipButton(),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 5.0),
              child: Divider(),
            ),
            //calls between two users
            CallHistoryWithFriendContainer(
              currentUserId: Provider.of<RootProvider>(context, listen: false)
                  .currentUserId,
              friendUserId: widget.userDetails.userId,
            ),
          ],
        ),
      ),
    );
  }
}

class CallHistoryWithFriendContainer extends StatefulWidget {
  final String currentUserId;
  final String friendUserId;
  CallHistoryWithFriendContainer(
      {Key key, this.currentUserId, this.friendUserId})
      : super(key: key);

  @override
  _CallHistoryWithFriendContainerState createState() =>
      _CallHistoryWithFriendContainerState();
}

class _CallHistoryWithFriendContainerState
    extends State<CallHistoryWithFriendContainer> {
  Future<List<CallHistory>> _callHistory;
  @override
  void initState() {
    super.initState();
    _callHistory = FirebaseDatabase.callHistoryWithFriend(
        widget.currentUserId, widget.friendUserId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CallHistory>>(
      future: _callHistory,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          print("Data is null");
          return Center(
            child: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).size.height * (0.2),
              ),
              child: CircularProgressIndicator.adaptive(),
            ),
          );
        }
        if (snapshot.hasError) {
          Errors.showErrorDialog(context, snapshot.error.toString());
          return Container();
        }
        if (snapshot.data.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).size.height * (0.2)),
              child: Text("No call has been exchanged between two of you"),
            ),
          );
        }

        return Column(
          children: snapshot.data.map((callHistory) {
            DateTime dateTime = callHistory.timestamp.toDate();

            return ListTile(
              title: Text(
                  "${dateTime.day}-${dateTime.month}-${dateTime.year}, ${dateTime.hour}:${dateTime.minute}"),
              leading: Icon(
                callHistory.callerId == widget.currentUserId
                    ? Icons.arrow_upward_sharp
                    : Icons.arrow_downward_sharp,
                color: Colors.blue,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class CustomRoundedButton extends StatelessWidget {
  final String title;
  final Function function;
  final double size;
  const CustomRoundedButton(
      {Key key, this.function, this.title, this.size = 0.35})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: function,
      child: Container(
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(color: Colors.white, fontSize: 14.0),
        ),
        padding: EdgeInsets.symmetric(vertical: 5),
        width: MediaQuery.of(context).size.width * size,
        decoration: BoxDecoration(
            color: Colors.blue, borderRadius: BorderRadius.circular(5.0)),
      ),
    );
  }
}
