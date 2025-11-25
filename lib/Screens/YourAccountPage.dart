import 'package:e_commerce_app/Login_Signup/editLogin.dart';
import 'package:e_commerce_app/Screens/OrderPlaced.dart';
import 'package:flutter/material.dart';
// Import your service function here
// import 'path/to/your/auth_service_file.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_commerce_app/firebase_options.dart';

import '../Login_Signup/editAddress.dart';


class YourAccountPage extends StatefulWidget {
  final String userEmail;
  const YourAccountPage({super.key,required this.userEmail});

  @override
  State<YourAccountPage> createState() => _YourAccountPageState();
}

class _YourAccountPageState extends State<YourAccountPage> {

  String? username;
  String? userProfile;
  Future<void> user() async{
    final userData = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: widget.userEmail).limit(1).get();

    if(userData.docs.isNotEmpty){
      final data = userData.docs.first.data();
      setState(() {
        username = data['username'] ?? '';
        userProfile = data['imageUrl'] ?? '';
      });
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    user();
  }

  @override
  Widget build(BuildContext context) {

    final userEmail = widget.userEmail;


    final List<Map<String, dynamic>> accountItems = [
      {
        'title': 'Your Orders',
        'subtitle': 'Track, return, or buy things again',
        'onTap': OrderPlacedPage(userEmail: userEmail),
        'image' : 'https://m.media-amazon.com/images/G/31/x-locale/cs/ya/images/Box._CB485927553_.png',
      },
      {
        'title': 'Login & security',
        'subtitle': 'Edit login, name, mobile number, \nprofile pic and birthdate',
        'onTap': EditLoginPage(userEmail: userEmail),
        'image': 'https://m.media-amazon.com/images/G/31/x-locale/cs/ya/images/sign-in-lock._CB485931504_.png',
      },
      {
        'title': 'Prime',
        'subtitle': 'View benefits and payment settings',
        'onTap': PrimePage(),
        'image': 'https://m.media-amazon.com/images/G/31/x-locale/cs/ya/images/rc_prime._CB485926807_.png',
      },
      {
        'title': 'Your Addresses',
        'subtitle': 'Edit addresses for orders and gifts',
        'onTap': EditAddressPage(userEmail: widget.userEmail),
        'image': 'https://m.media-amazon.com/images/G/31/x-locale/cs/ya/images/address-map-pin._CB485934183_.png',
      },
      {
        'title': 'Payment Options',
        'subtitle': 'Edit and add payment methods',
        'onTap': PaymentOptionPage(),
        'image': 'https://m.media-amazon.com/images/G/31/x-locale/cs/ya/images/Payments._CB485926359_.png',
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Your Account')),
      body: Padding(
        padding: const EdgeInsets.only(left: 50.0,right: 50,top: 15,bottom: 15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text("Your Account",style: TextStyle(fontSize: 40,fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: Card(
                elevation: 20,
                child: Padding(
                  padding: const EdgeInsets.all(26.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Row(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            child: Image.network('https://tse2.mm.bing.net/th/id/OIP.g0qYLq0G09unEJPan_GKvwHaHw?cb=12&rs=1&pid=ImgDetMain&o=7&rm=3'),
                          ),
                          SizedBox(width: 20,),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello! $username',
                                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                              ),

                              // SizedBox(width: 20,),
                              Text(
                                'Email: $userEmail',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ],
                      ),


                      const Divider(height: 30),

                      Expanded(
                        child: GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 12.0,
                            crossAxisSpacing: 40.0,
                            childAspectRatio: 3.1,
                          ),
                          itemCount: accountItems.length,
                          itemBuilder: (context, index){
                            final item = accountItems[index];
                            return InkWell(
                              onTap: () {
                                // Handle navigation for the tile

                                Navigator.push(context, MaterialPageRoute(builder: (context)=>item['onTap']));

                              },
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.black),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Image.network(item['image'],height: 54,),
                                    const SizedBox(width: 14),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['title'] as String,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 23),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item['subtitle'] as String,
                                          style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Column(
                      //   // crossAxisAlignment: CrossAxisAlignment.end,
                      //   children: [
                      //     // --- 3. Account Actions ---
                      //     ListTile(
                      //       leading: const Icon(Icons.edit),
                      //       title: const Text('Edit Profile'),
                      //       onTap: () {
                      //       },
                      //     ),
                      //     ListTile(
                      //       leading: const Icon(Icons.lock),
                      //       title: const Text('Change Password'),
                      //       onTap: () {
                      //       },
                      //     ),
                      //   ],
                      // ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
