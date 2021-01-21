import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:facetime/helpers/videocallHelper.dart';
import 'package:facetime/models/userDetails.dart';
import 'package:facetime/providers/rootProvider.dart';
import 'package:facetime/services/database/firebaseDatabase.dart';
import 'package:facetime/utils/routes.dart';
import 'package:facetime/widgets/profilePictureContainer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class MoreFriendsPage extends StatefulWidget {
  final List<DocumentSnapshot> documentSnapshots;

  MoreFriendsPage({Key key, this.documentSnapshots}) : super(key: key);

  @override
  _MoreFriendsPageState createState() => _MoreFriendsPageState();

  //
  static Route<MoreFriendsPage> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
        builder: (context) => MoreFriendsPage(
              documentSnapshots: routeSettings.arguments,
            ));
  }
}

class _MoreFriendsPageState extends State<MoreFriendsPage> {
  ScrollController _scrollController = ScrollController();
  List<DocumentSnapshot> _friends = [];
  bool _hasMore;
  bool _hasError;

  @override
  void initState() {
    super.initState();
    _friends = widget.documentSnapshots;
    _hasMore = true;
    _hasError = false;

    //To go at the ene of friends list
    Future.delayed(Duration(milliseconds: 250), () {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      _scrollController.addListener(() {
        if (_scrollController.offset ==
            _scrollController.position.maxScrollExtent) {
          _loadMoreFriends();
        }
      });
    });
  }

  void _loadMoreFriends() {
    String currentUserId =
        Provider.of<RootProvider>(context, listen: false).currentUserId;

    if (_hasMore) {
      FirebaseDatabase.getFriends(
              currentUserId: currentUserId, lastDocumentSnapshot: _friends.last)
          .then((result) {
        //Adding callHistory to _friends
        result.forEach((element) {
          setState(() {
            _friends.add(element);
          });
        });
        //
        if (result.length < 25) {
          _hasMore = false;
        } else {
          _hasMore = true;
        }
      }).catchError((e) {
        //setting hasError to true
        setState(() {
          _hasError = true;
        });
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Friends"),
      ),
      body: ListView.builder(
        controller: _scrollController,
        itemBuilder: (context, index) {
          UserDetails friendDetails = UserDetails.fromSnapshot(_friends[index]);
          if (index == _friends.length - 1) {
            if (_hasError) {
              return ListTile(
                title: Text(
                  "Couldn't get more friends",
                  style: TextStyle(color: Colors.blue),
                ),
              );
            }
            if (_hasMore) {
              return ListTile(
                title: Center(child: CircularProgressIndicator()),
              );
            }
          }
          return ListTile(
            trailing: IconButton(
              icon: Icon(Icons.call),
              onPressed: () async {
                await VideoCallHelper.handleCameraAndMicPermission(
                    Permission.camera);
                await VideoCallHelper.handleCameraAndMicPermission(
                    Permission.microphone);
                String channelName = VideoCallHelper.generateChannelName(32);
                Navigator.of(context).pushNamed(Routes.videocallPage,
                    arguments: {
                      "channelName": channelName,
                      "incomingCall": false,
                      "userDetails": friendDetails
                    });
              },
            ),
            leading: ProfilePictureContainer(
              imageUrl: friendDetails.userImageUrl,
            ),
            onTap: () {
              Navigator.of(context).pushNamed(Routes.userPage, arguments: {
                "checkForFriendship": false,
                "userDetails": friendDetails
              });
            },
            title: Text(friendDetails.username),
          );
        },
        itemCount: _friends.length,
      ),
    );
  }
}
