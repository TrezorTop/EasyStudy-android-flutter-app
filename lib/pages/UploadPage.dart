import 'dart:io';
import 'package:buddiesgram/models/user.dart';
import 'package:buddiesgram/pages/HomePage.dart';
import 'package:buddiesgram/widgets/ProgressWidget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image/image.dart' as ImD;

class UploadPage extends StatefulWidget {
  final User gCurrentUser;

  UploadPage({this.gCurrentUser});


  @override
  _UploadPageState createState() => _UploadPageState();
}


class _UploadPageState extends State<UploadPage> with AutomaticKeepAliveClientMixin<UploadPage>
{
  File file;
  bool uploading = false;
  String postId = Uuid().v4();
  TextEditingController titleTextEditingController = TextEditingController();
  TextEditingController descriptionTextEditingController = TextEditingController();
  TextEditingController locationTextEditingController = TextEditingController();
  TextEditingController contactTextEditingController = TextEditingController();


  captureImageWithCamera() async {
    Navigator.pop(context);
    File imageFile = await ImagePicker.pickImage(
      source: ImageSource.camera,
      maxHeight: 680,
      maxWidth: 970,
    );
    setState(() {
      this.file = imageFile;
    });
  }

  pickImageFromGallery() async {
    Navigator.pop(context);
    File imageFile = await ImagePicker.pickImage(
      source: ImageSource.gallery,
    );
    setState(() {
      this.file = imageFile;
    });
  }

  takeImage(mContext){
    return showDialog(
        context: mContext,
      builder: (context){
          return SimpleDialog(
            title: Text("Новый пост", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
            children: <Widget>[
              SimpleDialogOption(
                child: Text("Сделать фото", style: TextStyle(color: Colors.white,),),
                onPressed: captureImageWithCamera,
              ),
              SimpleDialogOption(
                child: Text("Выбрать фото из галереи", style: TextStyle(color: Colors.white,),),
                onPressed: pickImageFromGallery,
              ),
              SimpleDialogOption(
                child: Text("Отмена", style: TextStyle(color: Colors.white,),),
                onPressed: () => Navigator.pop(context),
           ),
          ],
        );
      }
    );
  }



  displayUploadScreen() {
    return Container(
      color: Theme.of(context).accentColor.withOpacity(0.5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.add_to_photos, color: Colors.white, size: 200.0,),
          Padding(
            padding: EdgeInsets.only(top: 20.0),
            child: RaisedButton(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9.0),),
                child: Text("Загрузить", style: TextStyle(color: Colors.white, fontSize: 20.0),),
                color: Colors.blueAccent,
                onPressed: () => takeImage(context)
            ),
          ),
        ],
      ),
    );
  }

  clearPostInfo()
  {
    titleTextEditingController.clear();
    descriptionTextEditingController.clear();
    locationTextEditingController.clear();
    contactTextEditingController.clear();

    setState(() {
      file = null;
    });
  }


//  getUserCurrentLocation() async {
//    Position position = await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
//    List<Placemark> placeMarks = await Geolocator().placemarkFromCoordinates(position.latitude, position.longitude);
//    Placemark mPlaceMark = placeMarks[0];
//    String completeAddressInfo = '${mPlaceMark.subThoroughfare}, ${mPlaceMark.thoroughfare}, ${mPlaceMark.subLocality}, ${mPlaceMark.locality}, ${mPlaceMark.subAdministrativeArea}, ${mPlaceMark.administrativeArea}, ${mPlaceMark.postalCode}, ${mPlaceMark.country}';
//    String specificAddress = '${mPlaceMark.locality}, ${mPlaceMark.country}';
//    locationTextEditingController.text = specificAddress;
//  }

  compressingPhoto() async {
    final tDirectory = await getTemporaryDirectory();
    final path = tDirectory.path;
    ImD.Image mImageFile = ImD.decodeImage(file.readAsBytesSync());
    final compressedImageFile = File('$path/img_$postId.jpg')..writeAsBytesSync(ImD.encodeJpg(mImageFile, quality: 60));
    setState(() {
      file = compressedImageFile;
    });
  }

  controlUploadAndSave() async {
    setState(() {
      uploading = true;
    });

    await compressingPhoto();

    String downloadUrl = await uploadPhoto(file);

    savePostInfoToFireStorm(url: downloadUrl, title: titleTextEditingController.text, description: descriptionTextEditingController.text, location: locationTextEditingController.text, contact: contactTextEditingController.text);

    titleTextEditingController.clear();
    descriptionTextEditingController.clear();
    locationTextEditingController.clear();
    contactTextEditingController.clear();

    setState(() {
      file = null;
      uploading = false;
      postId = Uuid().v4();
    });
  }


  savePostInfoToFireStorm({String url, String title, String description, String location, String contact})
  {
    postsReference.document(widget.gCurrentUser.id).collection("usersPosts").document(postId).setData({
      "postId": postId,
      "ownerId": widget.gCurrentUser.id,
      "timestamp": DateTime.now(),
      "likes": {},
      "username": widget.gCurrentUser.username,
      "title": title,
      "description": description,
      "location": location,
      "contact": contact,
      "url": url,
    });
  }

  Future<String> uploadPhoto(mImageFile) async {
    StorageUploadTask mStorageUploadTask = storageReference.child("post_$postId.jpg").putFile(mImageFile);
    StorageTaskSnapshot storageTaskSnapshot = await mStorageUploadTask.onComplete;
    String downloadUrl = await storageTaskSnapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  displayUploadFormScreen() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: Colors.white,), onPressed: clearPostInfo),
        title: Text("Новый пост", style: TextStyle(fontSize: 24.0, color: Colors.white, fontWeight: FontWeight.bold),),
        actions: <Widget>[
          FlatButton(
            onPressed: uploading ? null : () => controlUploadAndSave(),
            child: Text("Опубликовать", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.0),),
          )
        ],
      ),
      body: ListView(
        children: <Widget>[
          uploading ? linearProgress() : Text(""),
          Container(
            height: 230.0,
            width: MediaQuery.of(context).size.width * 0.8,
            child: Center(
              child: AspectRatio(
                aspectRatio: 16/9,
                child: Container(
                  decoration: BoxDecoration(image: DecorationImage(image: FileImage(file), fit: BoxFit.cover,)),
                ),
              ),
            ),
          ),
          Padding(padding: EdgeInsets.only(top: 12.0),),
          ListTile(
            leading: CircleAvatar(backgroundImage: CachedNetworkImageProvider(widget.gCurrentUser.url),),
            title: Container(
              width: 250.0,
              child: TextField(
                style: TextStyle(color: Colors.black),
                controller: titleTextEditingController,
                decoration: InputDecoration(
                  hintText: "Заголовок",
                  hintStyle: TextStyle(color: Colors.blueGrey),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Divider(
            color: Colors.blue,
            thickness: 2,
          ),
          ListTile(
            leading: Icon(Icons.description, color: Colors.blueAccent, size: 36.0,),
            title: Container(
              width: 250.0,
              child: TextField(
                style: TextStyle(color: Colors.black),
                controller: descriptionTextEditingController,
                decoration: InputDecoration(
                  hintText: "Описание.",
                  hintStyle: TextStyle(color: Colors.blueGrey),
                  border: InputBorder.none,

                ),
              ),
            ),
          ),
          Divider(
            color: Colors.blue,
            thickness: 2,
          ),
          ListTile(
            leading: Icon(Icons.place, color: Colors.blueAccent, size: 36.0,),
            title: Container(
              width: 250.0,
              child: TextField(
                style: TextStyle(color: Colors.black),
                controller: locationTextEditingController,
                decoration: InputDecoration(
                  hintText: "Место проведения/площадка.",
                  hintStyle: TextStyle(color: Colors.blueGrey),
                  border: InputBorder.none,

                ),
              ),
            ),
          ),
          Divider(
            color: Colors.blue,
            thickness: 2,
          ),
          ListTile(
            leading: Icon(Icons.contact_mail, color: Colors.blueAccent, size: 36.0,),
            title: Container(
              width: 250.0,
              child: TextField(
                style: TextStyle(color: Colors.black),
                controller: contactTextEditingController,
                decoration: InputDecoration(
                  hintText: "Ваши контакты для связи.",
                  hintStyle: TextStyle(color: Colors.blueGrey),
                  border: InputBorder.none,

                ),
              ),
            ),
          ),
//          Container(
//            width: 220.0,
//            height: 110.0,
//            alignment: Alignment.center,
//            child: RaisedButton.icon(
//              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35.0)),
//              color: Colors.blueAccent,
//              icon: Icon(Icons.location_on, color: Colors.white,),
//              label: Text("Get my Current Location", style: TextStyle(color: Colors.white),),
//              onPressed: getUserCurrentLocation,
//            ),
//          ),
        ],
      ),
    );
  }


  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    return file == null ? displayUploadScreen() : displayUploadFormScreen();
  }
}
