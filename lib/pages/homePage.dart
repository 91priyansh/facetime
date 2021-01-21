import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:facetime/helpers/mlHelper.dart';
import 'package:facetime/helpers/notificationHelper.dart';
import 'package:facetime/helpers/ringtoneHelper.dart';
import 'package:facetime/helpers/videocallHelper.dart';
import 'package:facetime/models/callHistory.dart';
import 'package:facetime/models/userDetails.dart';
import 'package:facetime/providers/rootProvider.dart';
import 'package:facetime/services/database/firebaseDatabase.dart';
import 'package:facetime/utils/routes.dart';
import 'package:facetime/widgets/profilePictureContainer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  final String currentUserId;
  HomePage({Key key, this.currentUserId}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  StreamSubscription<DocumentSnapshot> _currentCallStreamSubscription;

  TabController _tabController;
  MLHelper _mlHelper = MLHelper();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    NotificationHelper.initializeFirebaseCloudMessaging();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      /// Sunbscribe current call
      _currentCallStreamSubscription =
          FirebaseDatabase.currentCall(widget.currentUserId)
              .listen(currentCallListener);
    });
  }

  //current call listener
  void currentCallListener(DocumentSnapshot documentSnapshot) {
    if (documentSnapshot.data() != null) {
      print(documentSnapshot.data());
      CallHistory currentCallDetails =
          CallHistory.fromSnapshot(documentSnapshot);

      if (currentCallDetails.callerId != widget.currentUserId) {
        //to show incomingVideoCallPage
        Navigator.of(context).pushNamed(Routes.incomingVideoCallPage,
            arguments: currentCallDetails);
      }
    } else {
      //if data is null means user do not have any current call
      //if user cuts the call from videocall and incoming video call
      if (Routes.currentRoute == Routes.videocallPage ||
          Routes.currentRoute == Routes.incomingVideoCallPage) {
        //cut the call
        Navigator.of(context).pop();
        RingtonePlayer.stopBackgroundRingtone();
        RingtonePlayer.stopRingtone();
      } else {
        print("No current call");
      }
    }
  }

  @override
  void dispose() {
    _currentCallStreamSubscription.cancel();
    _mlHelper.releaseResource();
    super.dispose();
  }

  Widget _buildDrawer(BuildContext context) {
    final UserDetails userDetails =
        Provider.of<RootProvider>(context, listen: false).userDetails;

    return Drawer(
      child: ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * (0.075),
          ),
          ProfilePictureContainer(
            imageUrl: userDetails.userImageUrl,
            size: 80,
          ),
          ListTile(
            title: Text(userDetails.username),
            subtitle: Text(userDetails.email),
          ),
          //
          SizedBox(
            height: 25.0,
          ),
          ListTile(
            title: Text("Edit Profile"),
            trailing: Icon(Icons.account_box),
          ),
          ListTile(
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(Routes.friendRequestPage);
            },
            title: Text("Friend Requests"),
            trailing: Icon(Icons.person_add),
          ),
          ListTile(
            onTap: () {
              Navigator.of(context).pop();
              Provider.of<RootProvider>(context, listen: false).signOut();
            },
            title: Text("Sign Out"),
            trailing: Icon(
              Icons.logout,
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(context),
      appBar: AppBar(
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: "Recents",
            ),
            Tab(
              text: "Friends",
            ),
          ],
        ),
        title: Text("Facetime"),
        actions: [
          IconButton(
            onPressed: () async {
              showSearch<UserDetails>(
                      context: context,
                      delegate: SearchUser(currentUserId: widget.currentUserId))
                  .then((result) {
                if (result != null) {
                  Navigator.of(context).pushNamed(Routes.userPage, arguments: {
                    "checkForFriendship": true,
                    "userDetails": result
                  });
                }
              });
            },
            icon: Icon(CupertinoIcons.search),
          ),
          /*
          IconButton(
            onPressed: () {
              //
              _mlHelper.processImage();
            },
            icon: Icon(Icons.plus_one),
          ),
          
          IconButton(
            onPressed: () {
              RingtonePlayer.stopRingtone();
            },
            icon: Icon(Icons.remove),
          ),
          */
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [CallHistoryContainer(), FriendsContainer()],
      ),
    );
  }
}

class FriendsContainer extends StatelessWidget {
  const FriendsContainer({Key key}) : super(key: key);

  Widget _buildFriendList(
      List<DocumentSnapshot> friends, bool showMoreFriends) {
    return ListView.builder(
      padding: EdgeInsets.only(top: 10.0),
      itemCount: friends.length,
      itemBuilder: (context, index) {
        //
        UserDetails friendDetails = UserDetails.fromSnapshot(friends[index]);
        if (index == friends.length - 1) {
          if (showMoreFriends) {
            return ListTile(
              title: Center(
                child: FlatButton(
                  textColor: Colors.blue,
                  child: Text("See more"),
                  onPressed: () {
                    //to see more friends
                    Navigator.of(context)
                        .pushNamed(Routes.moreFriendsPage, arguments: friends);
                  },
                ),
              ),
            );
          }
        }
        return ListTile(
          onTap: () {
            Navigator.of(context).pushNamed(Routes.userPage, arguments: {
              "checkForFriendship": false,
              "userDetails": friendDetails
            });
          },
          trailing: IconButton(
            onPressed: () async {
              await VideoCallHelper.handleCameraAndMicPermission(
                  Permission.camera);
              await VideoCallHelper.handleCameraAndMicPermission(
                  Permission.microphone);
              String channelName = VideoCallHelper.generateChannelName(32);
              Navigator.of(context).pushNamed(Routes.videocallPage, arguments: {
                "channelName": channelName,
                "incomingCall": false,
                "userDetails": friendDetails
              });
            },
            icon: Icon(Icons.call),
          ),
          leading: ProfilePictureContainer(
            imageUrl: friendDetails.userImageUrl,
          ),
          title: Text("${friendDetails.username}"),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId =
        Provider.of<RootProvider>(context, listen: false).currentUserId;
    return StreamBuilder<List<DocumentSnapshot>>(
      stream: FirebaseDatabase.friendsStream(currentUserId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text("Error while getting your friends"),
          );
        }

        if (snapshot.data.isEmpty) {
          return Center(
            child: Text("You don't have any friends ):):"),
          );
        }
        if (snapshot.data.length < 25) {
          return _buildFriendList(snapshot.data, false);
        }
        return _buildFriendList(snapshot.data, true);
      },
    );
  }
}

class CallHistoryContainer extends StatelessWidget {
  const CallHistoryContainer({Key key}) : super(key: key);

  Widget _buildCallHistory(
      List<DocumentSnapshot> calls, String currentUserId, bool showLoadMore) {
    return ListView.builder(
      itemBuilder: (context, index) {
        CallHistory callHistory = CallHistory.fromSnapshot(calls[index]);
        DateTime dateTime = callHistory.timestamp.toDate();
        if (index == calls.length - 1) {
          if (showLoadMore) {
            return ListTile(
              title: Center(
                child: FlatButton(
                  textColor: Colors.blue,
                  child: Text("See more"),
                  onPressed: () {
                    Navigator.of(context).pushNamed(Routes.moreCallHistoryPage,
                        arguments: calls);
                  },
                ),
              ),
            );
          }
        }
        return ListTile(
          trailing: Icon(
            callHistory.callerId == currentUserId
                ? Icons.arrow_upward_sharp
                : Icons.arrow_downward_sharp,
            color: Colors.blue,
          ),
          leading: ProfilePictureContainer(
            imageUrl: callHistory.toImageUrl,
          ),
          onTap: () {},
          title: Text(callHistory.toUsername),
          subtitle: Text(
              "${dateTime.day}-${dateTime.month}-${dateTime.year}, ${dateTime.hour}:${dateTime.minute}"),
        );
      },
      itemCount: calls.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        Provider.of<RootProvider>(context, listen: false).currentUserId;
    return StreamBuilder<List<DocumentSnapshot>>(
      stream: FirebaseDatabase.callHistoryStream(currentUserId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text("Error while fetching call history"),
          );
        }
        if (snapshot.data.length < 25) {
          return _buildCallHistory(snapshot.data, currentUserId, false);
        }
        return _buildCallHistory(snapshot.data, currentUserId, true);
      },
    );
  }
}

class SearchUser extends SearchDelegate<UserDetails> {
  final String currentUserId;

  SearchUser({this.currentUserId});
  List<DocumentSnapshot> searchResult = [];

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(
          Icons.clear,
          color: Colors.black,
        ),
        onPressed: () {
          this.query = "";
        },
      )
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.arrow_back,
        color: Colors.black,
      ),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (searchResult.isEmpty) {
      return Center(
        child: Text("No suggestions"),
      );
    }
    return ListView.builder(
      itemCount: searchResult.length,
      itemBuilder: (context, index) {
        UserDetails userDetails = UserDetails.fromSnapshot(searchResult[index]);
        return Padding(
          padding: EdgeInsets.only(top: 10.0),
          child: ListTile(
            onTap: () {
              if (userDetails.userId != currentUserId) {
                close(context, userDetails);
              }
            },
            title: Text(userDetails.username),
            leading: ProfilePictureContainer(
              imageUrl: userDetails.userImageUrl,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return this.query.isEmpty
        ? Container()
        : FutureBuilder<List<DocumentSnapshot>>(
            future: FirebaseDatabase.serachUser(this.query.toLowerCase()),
            //initialData: [],
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(snapshot.error.toString()),
                );
              }
              searchResult = snapshot.data;
              if (snapshot.data.isEmpty) {
                return Center(
                  child: Text("No suggestions"),
                );
              }
              return ListView.builder(
                itemCount: snapshot.data.length,
                itemBuilder: (context, index) {
                  UserDetails userDetails =
                      UserDetails.fromSnapshot(snapshot.data[index]);
                  return Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: ListTile(
                      onTap: () {
                        if (userDetails.userId != currentUserId) {
                          close(context, userDetails);
                        }
                      },
                      title: Text(userDetails.username),
                      leading: ProfilePictureContainer(
                        imageUrl: userDetails.userImageUrl,
                      ),
                    ),
                  );
                },
              );
            },
          );
  }
}
