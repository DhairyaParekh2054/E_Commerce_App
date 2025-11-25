import 'package:e_commerce_app/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class UserService{
  final CollectionReference userCollection = FirebaseFirestore.instance.collection('users');

  Future<String?> getDocId(String uEmail) async{
    QuerySnapshot snapshot = await userCollection.where('email', isEqualTo: uEmail).get();

    if(snapshot.docs.isNotEmpty){
      return snapshot.docs.first.id;
    }else{
      return null;
    }
  }
}

UserService userService = UserService();

Future<void> main() async{
  Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );
  runApp(const EditAddressPage(userEmail: '',));
}


class EditAddressPage extends StatefulWidget {
  final String userEmail;
  const EditAddressPage({super.key, required this.userEmail});

  @override
  State<EditAddressPage> createState() => _EditAddressPageState();
}

class _EditAddressPageState extends State<EditAddressPage> {

  final oldStreetController = TextEditingController();
  final newStreetController = TextEditingController();
  final oldAreaController = TextEditingController();
  final newAreaController = TextEditingController();
  final oldCityController = TextEditingController();
  final newCityController = TextEditingController();
  final oldStateController = TextEditingController();
  final newStateController = TextEditingController();
  final oldPincodeController = TextEditingController();
  final newPincodeController = TextEditingController();


  Future<void> loadUserData() async{
    QuerySnapshot userData = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: widget.userEmail).get();

    if(userData.docs.isNotEmpty){
      final userAddressData = userData.docs.first.data() as Map<String, dynamic>;
      oldStreetController.text = userAddressData['street'] ?? '';
      oldAreaController.text = userAddressData['area'] ?? '';
      oldCityController.text = userAddressData['city'] ?? '';
      oldStateController.text = userAddressData['state'] ?? '';
      oldPincodeController.text = userAddressData['pincode'].toString();
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadUserData();
  }


  Future<void> editStreet() async{
    if(oldStreetController.text == newStreetController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enter Different Street')),
      );
      return; // stop here if same email
    }

    String? docId = await userService.getDocId(widget.userEmail);

    if(docId != null){
      await userService.userCollection.doc(docId).update({'street': newStreetController.text});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Street Updated Successfully')),
      );

      // Optional: refresh UI or clear field
      oldStreetController.text = newStreetController.text;
      newStreetController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not found')),
      );
    }
  }

  Future<void> editArea() async{
    if(oldAreaController.text == newAreaController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enter Different Area')),
      );
      return; // stop here if same email
    }

    String? docId = await userService.getDocId(widget.userEmail);

    if(docId != null){
      await userService.userCollection.doc(docId).update({'area': newAreaController.text});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Area Updated Successfully')),
      );

      // Optional: refresh UI or clear field
      oldAreaController.text = newAreaController.text;
      newAreaController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not found')),
      );
    }
  }

  Future<void> editCity() async{
    if(oldCityController.text == newCityController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enter Different City')),
      );
      return; // stop here if same email
    }

    String? docId = await userService.getDocId(widget.userEmail);

    if(docId != null){
      await userService.userCollection.doc(docId).update({'city': newCityController.text});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('City Updated Successfully')),
      );

      // Optional: refresh UI or clear field
      oldCityController.text = newCityController.text;
      newCityController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not found')),
      );
    }
  }

  Future<void> editState() async{
    if(oldStateController.text == newStateController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enter Different State')),
      );
      return; // stop here if same email
    }

    String? docId = await userService.getDocId(widget.userEmail);

    if(docId != null){
      await userService.userCollection.doc(docId).update({'state': newStateController.text});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('State Updated Successfully')),
      );

      // Optional: refresh UI or clear field
      oldStateController.text = newStateController.text;
      newStateController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not found')),
      );
    }
  }

  Future<void> editPincode() async{
    if(oldPincodeController.text == newPincodeController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enter Different Pincode')),
      );
      return; // stop here if same email
    }

    String? docId = await userService.getDocId(widget.userEmail);

    if(docId != null){
      await userService.userCollection.doc(docId).update({'pincode': newPincodeController.text});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pincode Updated Successfully')),
      );

      // Optional: refresh UI or clear field
      oldPincodeController.text = newPincodeController.text;
      newPincodeController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not found')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        // backgroundColor: Colors.blueGrey,
        appBar: AppBar(
          leading: IconButton(onPressed: (){Navigator.of(context).pop();}, icon: Icon(Icons.arrow_back)),
        ),
        body: Center(
            child: Padding(
              padding: const EdgeInsets.only(left: 20.0,right: 20),
              child: Column(
                children: [
                  Text("Edit Your Address Here! ${widget.userEmail}",style: TextStyle(fontSize: 50),),
                  SizedBox(height: 50,),

                  Row(
                    children: [
                      //Chage Street
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.black12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 25,right: 25,bottom: 20,top: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text("Change Your Street",style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 150),
                                    child: ElevatedButton(
                                      onPressed: editStreet,
                                      child: Text("Change"),
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor: Color(0xFF5D5FEF), // Purple button background
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10.0),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                                        textStyle: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                              SizedBox(height: 15,),
                              SizedBox(
                                width: 400,
                                child: TextFormField(
                                  controller: oldStreetController,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: 'Old Street',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              SizedBox(height: 10,),
                              SizedBox(
                                width: 400,
                                child: TextFormField(
                                  controller: newStreetController,
                                  decoration: InputDecoration(
                                    labelText: 'Enter New Street',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 30,),


                      //Change Area
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.black12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 25,right: 25,bottom: 20,top: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text("Change Your Area",style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 150),
                                    child: ElevatedButton(
                                      onPressed: editArea,
                                      child: Text("Change"),
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor: Color(0xFF5D5FEF), // Purple button background
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10.0),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                                        textStyle: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                              SizedBox(height: 15,),
                              SizedBox(
                                width: 400,
                                child: TextFormField(
                                  controller: oldAreaController,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: 'Old Area',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              SizedBox(height: 10,),
                              SizedBox(
                                width: 400,
                                child: TextFormField(
                                  controller: newAreaController,
                                  decoration: InputDecoration(
                                    labelText: 'Enter New Area',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20, width: 30,),


                      //Change City
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.black12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 25,right: 25,bottom: 20,top: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text("Change Your City",style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 160),
                                    child: ElevatedButton(
                                      onPressed: editCity,
                                      child: Text("Change"),
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor: Color(0xFF5D5FEF), // Purple button background
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10.0),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                                        textStyle: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                              SizedBox(height: 15,),
                              SizedBox(
                                width: 400,
                                child: TextFormField(
                                  controller: oldCityController,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: 'Enter Old City',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              SizedBox(height: 10,),
                              SizedBox(
                                width: 400,
                                child: TextFormField(
                                  controller: newCityController,
                                  decoration: InputDecoration(
                                    labelText: 'Enter New City',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    ],
                  ),

                  SizedBox(height: 40,),
                  Row(
                    children: [

                      //Change State
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.black12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 25,right: 25,bottom: 20,top: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text("Change Your State",style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 145),
                                    child: ElevatedButton(
                                      onPressed: editState,
                                      child: Text("Change"),
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor: Color(0xFF5D5FEF), // Purple button background
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10.0),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                                        textStyle: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                              SizedBox(height: 15,),
                              SizedBox(
                                width: 400,
                                child: TextFormField(
                                  controller: oldStateController,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: 'Old State',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              SizedBox(height: 10,),
                              SizedBox(
                                width: 400,
                                child: TextFormField(
                                  controller: newStateController,
                                  decoration: InputDecoration(
                                    labelText: 'Enter New State',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 30,),

                      //Change Pincode
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.black12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 25,right: 25,bottom: 20,top: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text("Change Your Pincode",style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 120),
                                    child: ElevatedButton(
                                      onPressed: editPincode,
                                      child: Text("Change"),
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor: Color(0xFF5D5FEF), // Purple button background
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10.0),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                                        textStyle: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                              SizedBox(height: 15,),
                              SizedBox(
                                width: 400,
                                child: TextFormField(
                                  controller: oldPincodeController,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: 'Old Pincode',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              SizedBox(height: 10,),
                              SizedBox(
                                width: 400,
                                child: TextFormField(
                                  controller: newPincodeController,
                                  decoration: InputDecoration(
                                    labelText: 'Enter New Pincode',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
        ),
      ),
    );
  }
}



