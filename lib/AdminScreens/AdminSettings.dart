import 'package:e_commerce_app/Login_Signup/editAddress.dart';
import 'package:e_commerce_app/Login_Signup/editLogin.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_commerce_app/firebase_options.dart';

class AdminSettingPage extends StatefulWidget {
  final String email;
  const AdminSettingPage({super.key, required this.email});

  @override
  State<AdminSettingPage> createState() => _AdminSettingPageState();
}

class _AdminSettingPageState extends State<AdminSettingPage> {

  final oldAdminEmailController = TextEditingController();
  final newAdminEmailController = TextEditingController();
  final oldAdminPassController = TextEditingController();
  final newAdminPassController = TextEditingController();


  Future<void> loadAdminData() async{
    QuerySnapshot adminData = await FirebaseFirestore.instance.collection('users')
        .where('email', isEqualTo: widget.email).get();

    if(adminData.docs.isNotEmpty){
      final adminLoginData = adminData.docs.first.data() as Map<String, dynamic>;
      oldAdminEmailController.text = adminLoginData['email'] ?? '';
      oldAdminPassController.text = adminLoginData['password'] ?? '';
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadAdminData();
  }


  //Edit Email
  Future<void> editAdminEmail() async{

    if(oldAdminEmailController.text == newAdminEmailController.text){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enter Different Email')),
      );
      return;
    }

    String? docId;
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: oldAdminEmailController.text).get();

    if(snapshot.docs.isNotEmpty){
      docId = snapshot.docs.first.id as String;
    }

    if(docId != null){

      await FirebaseFirestore.instance.collection('users').doc(docId).update({'email': newAdminEmailController.text});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email Updated Successfully')),
      );

      oldAdminEmailController.text = newAdminEmailController.text;
      newAdminEmailController.clear();
    }else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not found')),
      );
    }

  }



  //Edit Password
  Future<void> editAdminPassword() async{

    if(oldAdminPassController.text == newAdminPassController.text){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enter Different Password')),
      );
      return;
    }

    String? docId;
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('users').where('password', isEqualTo: oldAdminPassController.text).get();

    if(snapshot.docs.isNotEmpty){
      docId = snapshot.docs.first.id as String;
    }

    if(docId != null){

      await FirebaseFirestore.instance.collection('users').doc(docId).update({'password': newAdminPassController.text});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password Updated Successfully')),
      );

      oldAdminPassController.text = newAdminPassController.text;
      newAdminPassController.clear();
    }else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not found')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Text("Manage Users",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 40),),
              SizedBox(height: 40,),

              ElevatedButton(onPressed: (){
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>EditLoginPage(userEmail: widget.email)));
                }, child: Text("Edit Login")
              ),
              SizedBox(height: 10,),
              ElevatedButton(onPressed: (){
                Navigator.push(context, MaterialPageRoute(builder: (context)=>EditAddressPage(userEmail: widget.email)));
              }, child: Text("Edit Address")
              ),
              // Container(
              //   height: 210,
              //   width: 450,
              //   decoration: BoxDecoration(
              //     color: Colors.white24,
              //     borderRadius: BorderRadius.circular(8),
              //     border: Border.all(color: Colors.black12),
              //     boxShadow: [
              //       BoxShadow(
              //         color: Colors.black.withOpacity(0.05),
              //         blurRadius: 2,
              //         offset: const Offset(0, 1),
              //       ),
              //     ],
              //   ),
              //   child: Padding(
              //       padding: const EdgeInsets.all(20.0),
              //       child: Column(
              //         children: [
              //
              //           Row(
              //             children: [
              //               Spacer(),
              //               ElevatedButton(
              //                   onPressed: editAdminEmail,
              //                   child: Text("Change"),
              //                 style: ElevatedButton.styleFrom(
              //                   foregroundColor: Colors.white,
              //                   backgroundColor: Color(0xFF5D5FEF), // Purple button background
              //                   shape: RoundedRectangleBorder(
              //                     borderRadius: BorderRadius.circular(10.0),
              //                   ),
              //                   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
              //                   textStyle: const TextStyle(
              //                     fontSize: 18,
              //                     fontWeight: FontWeight.bold,
              //                   ),
              //                 ),
              //
              //               )
              //             ],
              //           ),
              //
              //           SizedBox(height: 10,),
              //
              //           //Old Admin Email
              //           TextField(
              //             controller: oldAdminEmailController,
              //             readOnly: true,
              //             decoration: InputDecoration(
              //               border: OutlineInputBorder(),
              //               labelText: 'Old Email'
              //             ),
              //           ),
              //           SizedBox(height: 10,),
              //
              //           //New Admin Email
              //           TextField(
              //             controller: newAdminEmailController,
              //             decoration: InputDecoration(
              //                 border: OutlineInputBorder(),
              //               labelText: 'Enter New Email'
              //             ),
              //           ),
              //         ],
              //       ),
              //     ),
              // ),
              //
              // SizedBox(height: 20,),
              //
              // Container(
              //   height: 210,
              //   width: 450,
              //   decoration: BoxDecoration(
              //     color: Colors.white24,
              //     borderRadius: BorderRadius.circular(8),
              //     border: Border.all(color: Colors.black12),
              //     boxShadow: [
              //       BoxShadow(
              //         color: Colors.black.withOpacity(0.05),
              //         blurRadius: 2,
              //         offset: const Offset(0, 1),
              //       ),
              //     ],
              //   ),
              //   child: Padding(
              //       padding: const EdgeInsets.all(20.0),
              //       child: Column(
              //         children: [
              //
              //           Row(
              //             children: [
              //               Spacer(),
              //               ElevatedButton(
              //                   onPressed: editAdminPassword,
              //                   child: Text("Change"),
              //                 style: ElevatedButton.styleFrom(
              //                   foregroundColor: Colors.white,
              //                   backgroundColor: Color(0xFF5D5FEF), // Purple button background
              //                   shape: RoundedRectangleBorder(
              //                     borderRadius: BorderRadius.circular(10.0),
              //                   ),
              //                   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
              //                   textStyle: const TextStyle(
              //                     fontSize: 18,
              //                     fontWeight: FontWeight.bold,
              //                   ),
              //                 ),
              //               )
              //             ],
              //           ),
              //
              //           SizedBox(height: 10,),
              //
              //           //Old Admin Email
              //           TextField(
              //             controller: oldAdminPassController,
              //             readOnly: true,
              //             decoration: InputDecoration(
              //                 border: OutlineInputBorder(),
              //                 labelText: 'Old Password'
              //             ),
              //           ),
              //           SizedBox(height: 10,),
              //
              //           //New Admin Email
              //           TextField(
              //             controller: newAdminPassController,
              //             decoration: InputDecoration(
              //                 border: OutlineInputBorder(),
              //                 labelText: 'Enter New Password'
              //             ),
              //           ),
              //         ],
              //       ),
              //     ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
