import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

//Profile picture container

class ProfilePictureContainer extends StatelessWidget {
  final double size;
  final String imageUrl;
  const ProfilePictureContainer({Key key, this.size = 25, this.imageUrl})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size,
      backgroundImage: imageUrl.isEmpty
          ? AssetImage(
              "assets/profile.png",
            )
          : CachedNetworkImageProvider(imageUrl),
    );
  }
}
