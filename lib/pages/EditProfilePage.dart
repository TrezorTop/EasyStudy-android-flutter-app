import 'package:buddiesgram/models/user.dart';
import 'package:buddiesgram/pages/HomePage.dart';
import 'package:buddiesgram/widgets/ProgressWidget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import "package:flutter/material.dart";


class EditProfilePage extends StatefulWidget {
  final String currentOnlineUserId;

  EditProfilePage({
    this.currentOnlineUserId
});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  TextEditingController profileNameTextEditingController = TextEditingController();
  TextEditingController bioTextEditingController = TextEditingController();
  final _scaffoldGlobalKey = GlobalKey<ScaffoldState>();
  bool loading = false;
  User user;
  bool _bioValid = true;
  bool _profileNameValid = true;


  void initState(){
    super.initState();

    getAndDisplayUserInformation();
  }

  getAndDisplayUserInformation() async {
    setState(() {
      loading = true;
    });

    DocumentSnapshot documentSnapshot = await usersReference.document(widget.currentOnlineUserId).get();
    user = User.fromDocument(documentSnapshot);

    profileNameTextEditingController.text = user.profileName;
    bioTextEditingController.text = user.bio;

    setState(() {
      loading = false;
    });
  }

  updateUserData(){
    setState(() {
      profileNameTextEditingController.text.trim().length < 3 || profileNameTextEditingController.text.isEmpty ? _profileNameValid = false : _profileNameValid = true;

      bioTextEditingController.text.trim().length > 150 ? _bioValid = false : _bioValid = true;
    });

    if(_bioValid && _profileNameValid){
      usersReference.document(widget.currentOnlineUserId).updateData({
        "profileName": profileNameTextEditingController.text,
        "bio": bioTextEditingController.text,
      });
      SnackBar successSnackBar = SnackBar(content: Text("Профиль успешно отредактирован"));
      _scaffoldGlobalKey.currentState.showSnackBar(successSnackBar);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldGlobalKey,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text("Редактирование профиля", style: TextStyle(color: Colors.white),),
        actions: <Widget>[
          IconButton(icon: Icon(Icons.done, color: Colors.white, size: 30.0,), onPressed: ()=> Navigator.pop(context),),
        ],
      ),
      body: loading ? circularProgress() : ListView(
        children: <Widget>[
          Container(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(top: 15.0, bottom: 7.0),
                  child: CircleAvatar(
                    radius: 52.0,
                    backgroundImage: CachedNetworkImageProvider(user.url),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(children: <Widget>[createProfileNameTextFormField(), createBioTextFromField()],),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 29.0, left: 50.0, right: 50.0),
                  child: RaisedButton(
                    onPressed: updateUserData,
                    child: Text(
                      "Обновить профиль",
                      style: TextStyle(color: Colors.black, fontSize: 16.0),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 10.0, left: 50.0, right: 50.0),
                  child: RaisedButton(
                    color: Colors.red,
                    onPressed: logoutUser,
                    child: Text(
                      "Выйти из аккаунта",
                      style: TextStyle(color: Colors.white, fontSize: 14.0),
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  logoutUser() async{
    await gSignIn.signOut();
    Navigator.push(context, MaterialPageRoute(builder: (context) =>HomePage()));
  }

  Column createProfileNameTextFormField(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 13.0),
          child: Text(
            "Имя профиля", style: TextStyle(color: Colors.blueAccent),
          ),
        ),
        TextField(
          style: TextStyle(color: Colors.black),

          controller: profileNameTextEditingController,
          decoration: InputDecoration(
            hintText: "Введите имя профиля здесь",
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blueAccent),
            ),
            hintStyle: TextStyle(color: Colors.grey),
            errorText: _profileNameValid ? null : "Данное поле обязательно к заполнению",
          ),
        ),
      ],
    );
  }

  Column createBioTextFromField(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 13.0),
          child: Text(
            "Описание профиля", style: TextStyle(color: Colors.blueAccent),
          ),
        ),
        TextField(
          style: TextStyle(color: Colors.white),

          controller: bioTextEditingController,
          decoration: InputDecoration(
            hintText: "Расскажите немного о себе",
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blueAccent),
            ),
            hintStyle: TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }
}
