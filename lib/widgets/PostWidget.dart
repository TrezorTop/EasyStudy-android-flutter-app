import 'dart:async';

import 'package:buddiesgram/models/user.dart';
import 'package:buddiesgram/pages/CommentsPage.dart';
import 'package:buddiesgram/pages/HomePage.dart';
import 'package:buddiesgram/pages/ProfilePage.dart';
import 'package:buddiesgram/widgets/CImageWidget.dart';
import 'package:buddiesgram/widgets/ProgressWidget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Post extends StatefulWidget {
  final String postId;
  final String ownerId;
  final dynamic likes;
  final String username;
  final String title;
  final String description;
  final String location;
  final String contact;
  final String url;

  Post({
    this.postId,
    this.ownerId,
    this.likes,
    this.username,
    this.title,
    this.description,
    this.location,
    this.contact,
    this.url,
  });

  factory Post.fromDocument(DocumentSnapshot documentSnapshot){
    return Post(
      postId: documentSnapshot["postId"],
      ownerId: documentSnapshot["ownerId"],
      likes: documentSnapshot["likes"],
      username: documentSnapshot["username"],
      title: documentSnapshot["title"],
      description: documentSnapshot["description"],
      location: documentSnapshot["location"],
      contact: documentSnapshot["contact"],
      url: documentSnapshot["url"],
    );
  }

  int getTotalNumberOfLikes(likes){
    if(likes == null) {
      return 0;
    }

    int counter = 0;
    likes.values.forEach((eachValue){
      if(eachValue == true) {
        counter = counter + 1;
      }
    });
    return counter;
  }

  @override
  _PostState createState() => _PostState(
    postId: this.postId,
    ownerId: this.ownerId,
    likes: this.likes,
    username: this.username,
    title: this.title,
    description: this.description,
    location: this.location,
    contact: this.contact,
    url: this.url,
    likeCount: getTotalNumberOfLikes(this.likes),
  );
}



class _PostState extends State<Post> {

  final String postId;
  final String ownerId;
  Map likes;
  final String username;
  final String title;
  final String description;
  final String location;
  final String contact;
  final String url;
  int likeCount;
  bool isLiked;
  bool showHeart = false;
  final String currentOnlineUserId = currentUser?.id;

  _PostState({
    this.postId,
    this.ownerId,
    this.likes,
    this.username,
    this.title,
    this.description,
    this.location,
    this.contact,
    this.url,
    this.likeCount
  });



  @override
  Widget build(BuildContext context) {
    isLiked = (likes[currentOnlineUserId] == true);

    return Padding(
      padding: EdgeInsets.only(bottom: 12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          createPostHead(),
          createPostPicture(),
          createPostFooter(),
        ],
      ),
    );
  }

  createPostHead(){
    return FutureBuilder(
      future: usersReference.document(ownerId).get(),
      builder: (context, dataSnapshot){
        if(dataSnapshot.data == null){
          return circularProgress();
        }
        User user = User.fromDocument(dataSnapshot.data);
        bool isPostOwner = currentOnlineUserId == ownerId;

        return ListTile(
          leading: CircleAvatar(backgroundImage: CachedNetworkImageProvider(user.url), backgroundColor: Colors.grey,),
          title: GestureDetector(
            onTap: ()=> displayUserProfile(context, userProfileId: user.id),
            child: Text(
              user.username,
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
          subtitle: Text(title, style: TextStyle(color: Colors.black),),
          trailing: isPostOwner ? IconButton(
            icon: Icon(Icons.more_vert, color: Colors.black,),
            onPressed: () => controlPostDelete(context),
          ) : Text(""),
        );
      },
    );
  }

  controlPostDelete(BuildContext mContext){
    return showDialog(
      context: mContext,
      builder: (context){
        return SimpleDialog(
          title: Text("Что вы хотите сделать?", style: TextStyle(color: Colors.white),),
          children: <Widget>[
            SimpleDialogOption(
              child: Text("Удалить", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
              onPressed: (){
                Navigator.pop(context);
                removeUserPost();
              },
            ),
            SimpleDialogOption(
              child: Text("Отменить", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      }
    );
  }

  removeUserPost() async{
    postsReference.document(ownerId).collection("usersPosts").document(postId).get().then((document){
      if(document.exists){
        document.reference.delete();
      }
    });

    storageReference.child("post_$postId.jpg").delete();

    QuerySnapshot querySnapshot = await activityFeedReference.document(ownerId).collection("feed").where("postId", isEqualTo: postId).getDocuments();

    querySnapshot.documents.forEach((document) {
      if(document.exists){
        document.reference.delete();
      }
    });

    QuerySnapshot commentsQuerySnapshot = await commentsReference.document(postId).collection("comments").getDocuments();

    commentsQuerySnapshot.documents.forEach((document) {
      if(document.exists){
        document.reference.delete();
      }
    });
  }

  displayUserProfile(BuildContext context, {String userProfileId}){
    Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage(userProfileId: userProfileId,)));
  }


//  removeLike(){
//    bool isNotPostOwner = currentOnlineUserId != ownerId;
//
//    if(isNotPostOwner){
//      activityFeedReference.document(ownerId).collection("feedItems").document(postId).get().then((document){
//        if(document.exists){
//          document.reference.delete();
//        }
//      });
//    }
//  }

  addLike(){
    bool isNotPostOwner = currentOnlineUserId != ownerId;

//    if(isNotPostOwner){
//      activityFeedReference.document(ownerId).collection("feedItems").document(postId).setData({
//        "type": "like",
//        "username": currentUser.username,
//        "userId": currentUser.id,
//        "timestamp": DateTime.now(),
//        "url": url,
//        "postId": postId,
//        "userProfileImage": currentUser.url,
//      });
//    }
  }

  controlUserLikePost(){
   bool _liked = likes[currentOnlineUserId] == true;
   
   if(_liked){
     postsReference.document(ownerId).collection("usersPosts").document(postId).updateData({"likes.$currentOnlineUserId": false});

//     removeLike();

     setState(() {
       likeCount = likeCount - 1;
       isLiked = false;
       likes[currentOnlineUserId] = false;
     });
   }
   else if(!_liked){
     postsReference.document(ownerId).collection("usersPosts").document(postId).updateData({"likes.$currentOnlineUserId": true});

     addLike();

     setState(() {
       likeCount = likeCount + 1;
       isLiked = true;
       likes[currentOnlineUserId] = true;
       showHeart = true;
     });
     Timer(Duration(milliseconds: 800), (){
       setState(() {
         showHeart = false;
       });
     });
   }
  }
  
  createPostPicture(){
    return GestureDetector(
      onDoubleTap: ()=> controlUserLikePost,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Image.network(url),
          showHeart ? Icon(Icons.favorite, size: 140.0, color: Colors.blueAccent,) : Text(""),
        ],
      ),
    );
  }

  createPostFooter(){
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(padding: EdgeInsets.only(top: 40.0, left: 20.0),),
            GestureDetector(
              onTap: ()=> controlUserLikePost(),
              child: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                size: 28.0,
                color: Colors.blueAccent,
              ),
            ),
            Padding(padding: EdgeInsets.only(right: 20.0),),
            GestureDetector(
              onTap: ()=> displayComments(context, postId: postId, ownerId: ownerId, url: url),
              child: Icon(Icons.chat_bubble_outline, size: 28.0, color: Colors.blueAccent,),
            ),
          ],
        ),
        Row(
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20.0),
              child: Text(
                "$likeCount likes",
                style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20.0),
              child: Text(description, style: TextStyle(color: Colors.black ),),
            ),
//            Expanded(
//              child: Text(description, style: TextStyle(color: Colors.black ),),
//            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20.0),
              child: Text(location, style: TextStyle(color: Colors.black ),),
            ),
//            Expanded(
//              child: Text(description, style: TextStyle(color: Colors.black ),),
//            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20.0),
              child: Text(contact, style: TextStyle(color: Colors.black ),),
            ),
//            Expanded(
//              child: Text(description, style: TextStyle(color: Colors.black ),),
//            ),
          ],
        ),
      ],
    );
  }

  displayComments(BuildContext, {String postId, String ownerId, String url}){
    Navigator.push(context, MaterialPageRoute(builder: (context){
      return CommentsPage(postId: postId, postOwnerId: ownerId, postImageUrl: url);
    }
    ));
  }

}
