import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:facetime/models/callHistory.dart';
import 'package:facetime/providers/rootProvider.dart';
import 'package:facetime/services/database/firebaseDatabase.dart';
import 'package:facetime/widgets/profilePictureContainer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MoreCallHistoryPage extends StatefulWidget {
  final List<DocumentSnapshot> documentSnapshots;
  MoreCallHistoryPage({Key key, this.documentSnapshots}) : super(key: key);

  @override
  _MoreCallHistoryPageState createState() => _MoreCallHistoryPageState();

  static Route<MoreCallHistoryPage> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
        builder: (context) => MoreCallHistoryPage(
              documentSnapshots: routeSettings.arguments,
            ));
  }
}

class _MoreCallHistoryPageState extends State<MoreCallHistoryPage> {
  ScrollController _scrollController = ScrollController();
  List<DocumentSnapshot> _calls = [];
  bool _hasMore;
  bool _hasError;

  @override
  void initState() {
    super.initState();
    _calls = widget.documentSnapshots;
    _hasMore = true;
    _hasError = false;

    //To go at the ene of call history list
    Future.delayed(Duration(milliseconds: 250), () {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      _scrollController.addListener(() {
        if (_scrollController.offset ==
            _scrollController.position.maxScrollExtent) {
          _loadMoreCalls();
        }
      });
    });
  }

  void _loadMoreCalls() {
    String currentUserId =
        Provider.of<RootProvider>(context, listen: false).currentUserId;

    if (_hasMore) {
      FirebaseDatabase.callHistory(currentUserId, _calls.last).then((result) {
        //Adding callHistory to _calls
        result.forEach((element) {
          setState(() {
            _calls.add(element);
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
    final String currentUserId =
        Provider.of<RootProvider>(context, listen: false).currentUserId;
    return Scaffold(
      appBar: AppBar(
        title: Text("Call History"),
      ),
      body: ListView.builder(
        controller: _scrollController,
        itemBuilder: (context, index) {
          CallHistory callHistory = CallHistory.fromSnapshot(_calls[index]);
          DateTime dateTime = callHistory.timestamp.toDate();
          if (index == _calls.length - 1) {
            if (_hasError) {
              return ListTile(
                title: Text(
                  "Couldn't get call history",
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
        itemCount: _calls.length,
      ),
    );
  }
}
