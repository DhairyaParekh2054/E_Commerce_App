import 'package:e_commerce_app/AdminScreens/AddProduct.dart';
import 'package:e_commerce_app/AdminScreens/AdminDashboard.dart';
import 'package:e_commerce_app/AdminScreens/AdminOrders.dart';
import 'package:e_commerce_app/AdminScreens/AdminSettings.dart';
import 'package:e_commerce_app/AdminScreens/AdminUsers.dart';
import 'package:e_commerce_app/Login_Signup/LoginScreen.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_commerce_app/firebase_options.dart';
import 'AddProduct.dart';
import 'AdminProductList.dart';


void main() async {

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AdminPanel(email: ''));
}


class AdminPanel extends StatelessWidget {
  final String email;
  const AdminPanel({super.key, required this.email});


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AdminPage(email: email),
    );
  }
}



class AdminPage extends StatefulWidget {
  final String email;
  const AdminPage({super.key, required this.email});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {

  void goTo(){
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>AdminMainPage(email: widget.email)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Welcome! Admin",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 50),),
            SizedBox(height: 40,),
            ElevatedButton(onPressed: goTo, child: Text("Go To Admin Panel"))
          ],
        ),
      ),
    );
  }
}



class AdminMainPage extends StatefulWidget {
  final String email;
  const AdminMainPage({super.key, required this.email});

  @override
  State<AdminMainPage> createState() => _AdminMainPageState();
}

class _AdminMainPageState extends State<AdminMainPage> {

  void addBtn(){
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AddProductPage(productId: null,)));
  }

  String? username;
  Future<void> loadusername() async{
    final userData = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: widget.email).limit(1).get();

    if(userData.docs.isNotEmpty){
      final data = userData.docs.first.data();
      setState(() {
        username = data['username'] ?? '';
      });
    }
  }

  String selectedPage = 'Dashboard'; // default page

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadusername();
  }

  Widget getSelectedPage() {
    switch (selectedPage) {
      case 'Dashboard':
        return AdminDashboard();
      case 'Products':
        return AdminProductList();
      case 'Orders':
        return AdminOrders();
      case 'Users':
        return AdminUsers(email: widget.email);
      case 'Settings':
        return AdminSettingPage(email: widget.email);
      default:
        return Center(child: Text('Page not found'));
    }
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Panel"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Row(
          children: [
            Container(
              width: 220,
              color: Colors.black12,
              child: Column(
                children:  [
                  Padding(
                    padding: const EdgeInsets.only(top: 30.0,bottom: 10),
                    child: Column(
                        children: [
                          CircleAvatar(
                            radius: 48,
                          ),
                          SizedBox(height: 9,),
                          Text("$username",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20),)
                        ],
                      ),
                  ),
                  Divider(),
                  ListTile(
                    mouseCursor: SystemMouseCursors.click,
                    leading: Icon(Icons.dashboard),
                    title: Text("Dashboard"),
                    onTap: (){
                      setState(() {
                        selectedPage="Dashboard";
                      });
                    },
                  ),
                  ListTile(
                    mouseCursor: SystemMouseCursors.click,
                    leading: Icon(Icons.shopping_cart),
                    title: Text("Products"),
                    onTap: (){
                      setState(() {
                        selectedPage='Products';
                      });
                    },
                  ),
                  ListTile(
                    mouseCursor: SystemMouseCursors.click,
                    leading: Icon(Icons.add_alarm_outlined),
                    title: Text("Orders"),
                    onTap:(){
                      setState(() {
                        selectedPage='Orders';
                      });
                    },
                  ),
                  ListTile(
                    mouseCursor: SystemMouseCursors.click,
                    leading: Icon(Icons.person),
                    title: Text("Users"),
                    onTap:(){
                      setState(() {
                        selectedPage='Users';
                      });
                    },
                  ),
                  ListTile(
                    mouseCursor: SystemMouseCursors.click,
                    leading: Icon(Icons.settings),
                    title: Text("Settings"),
                    onTap:(){
                      setState(() {
                        selectedPage='Settings';
                      });
                    },
                  ),

                  Spacer(),
                  Divider(),
                  ListTile(
                    mouseCursor: SystemMouseCursors.click,
                    leading: Icon(Icons.logout),
                    title: Text("Logout"),
                    onTap:(){
                      setState(() {

                        showDialog(
                          context: context,
                          barrierDismissible: true,
                          builder: (context){
                            return AlertDialog(
                              alignment: Alignment.bottomLeft,
                              // title: Text("Logout"),
                              content: Text("You want to Logout?"),
                              actions: [
                                TextButton(onPressed: (){
                                  Navigator.of(context).pop();
                                }, child: Text("Cancel")),
                                TextButton(onPressed: (){
                                  Navigator.push(context, MaterialPageRoute(builder: (context)=>LoginPage()));
                                }, child: Text("Logout"))
                              ],
                            );
                          }
                        );
                      });
                    },
                  ),
                ],
              ),
            ),

            Expanded(
              child: Center(
                child: getSelectedPage(),
              ),
            ),
          ],
        ),
    );
  }
}



