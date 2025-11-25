import 'package:e_commerce_app/Login_Signup/LoginScreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_commerce_app/firebase_options.dart';


class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {


  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passController = TextEditingController();
  final phoneController = TextEditingController();
  final streetController = TextEditingController();
  final areaController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final pincodeController = TextEditingController();
  final profilePicController = TextEditingController();

  //For Gender
  String genGroup = 'genderGroup';
  String male = 'Male';
  String female = 'Female';
  String others = 'Others';
  bool isSelected = false;

  int? selectedDay;
  String? selectedMonth;
  int? selectedYear;

  final List<String> months = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  ];


  void clearFields() {
    usernameController.clear();
    emailController.clear();
    passController.clear();
    phoneController.clear();
    profilePicController.clear();


    streetController.clear();
    areaController.clear();
    cityController.clear();
    stateController.clear();
    pincodeController.clear();

    setState(() {
      selectedDay = null;
      selectedMonth = null;
      selectedYear = null;
      isSelected = false;
    });
  }



  Future<void> addUser() async{
    final userCollection = await FirebaseFirestore.instance.collection("users");

    //Check EmailID Exist or Not
    QuerySnapshot snapshot = await userCollection.where('email', isEqualTo: emailController.text).get();
    if(snapshot.docs.isNotEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Email already exists!')),
      );
      return;
    }

    //Generate new user id : U0..
    QuerySnapshot alluser = await userCollection.orderBy(FieldPath.documentId).get();
    String newUserId;

    if(alluser.docs.isEmpty){
      newUserId = 'U001';
    }else{
      String lastUserId = alluser.docs.last.id;
      int lastNumber = int.parse(lastUserId.substring(1));
      int newNumber = lastNumber + 1;
      newUserId = 'U${newNumber.toString().padLeft(3,'0')}';

    }

    //For BirhteDay
    if (selectedDay == null || selectedMonth == null || selectedYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Please select your Date of Birth")),
      );
      return;
    }
    // Convert month name → month index
    final monthIndex = months.indexOf(selectedMonth!) + 1;
    DateTime dob = DateTime(selectedYear!, monthIndex, selectedDay!);


    //Add new data
    await userCollection.doc(newUserId).set({
      'username': usernameController.text.trim(),
      'email': emailController.text.trim(),
      'password': passController.text.trim(),
      'phone': int.parse(phoneController.text.trim()),
      'role': 'User',
      'street': streetController.text.trim(),
      'area': areaController.text.trim(),
      'city': cityController.text.trim(),
      'state': stateController.text.trim(),
      'pincode': int.parse(pincodeController.text.trim()),
      'dateOfBirth': dob,
      'profileUrl': profilePicController.text.trim(),
      'gender': genGroup
    });

    clearFields();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: (){Navigator.of(context).pop();},icon: Icon(Icons.arrow_back)),
      ),
      body: Center(
        child: SingleChildScrollView( // Allows scrolling if keyboard appears
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Make column only take needed space
                children: [
                  Text(
                    'Sign Up!',
                    style: TextStyle(
                      fontSize: 45,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5D5FEF), // Purple color
                    ),
                  ),
                  const SizedBox(height: 40),


                  Column(
                    children: [
                      Row(
                        children: [

                          //Username
                          Expanded(child:
                          TextFormField(
                            controller: usernameController,
                            decoration: InputDecoration(
                              labelText: 'Username',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          )
                          ),
                          const SizedBox(width: 16),

                          //Street
                          Expanded(
                            child: TextFormField(
                              controller: streetController,
                              decoration: InputDecoration(
                                labelText: 'Street/Society/Banglows',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [

                          //Email
                          Expanded(
                            child: TextFormField(
                              controller: emailController,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          //Area
                          Expanded(
                            child: TextFormField(
                              controller: areaController,
                              decoration: InputDecoration(
                                labelText: 'Area',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [

                          //Password
                          Expanded(
                            child: TextFormField(
                              controller: passController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          //City
                          Expanded(
                            child: TextFormField(
                              controller: cityController,
                              decoration: InputDecoration(
                                labelText: 'City',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [

                          //Phone Number
                          Expanded(
                            child: TextFormField(
                              controller: phoneController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Phone Number',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          //State
                          Expanded(
                            child: TextFormField(
                              controller: stateController,
                              decoration: InputDecoration(
                                labelText: 'State',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [

                          //Profile Pic Url
                          Expanded(
                            child: TextFormField(
                              controller: profilePicController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Profile URL',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          //Pincode
                          Expanded(
                            child: TextFormField(
                              controller: pincodeController,
                              decoration: InputDecoration(
                                labelText: 'Pincode',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [

                          //Date Of Birth
                          Expanded(
                            child: Row(
                              children: [

                                // ---------------- DAY ---------------- //
                                Expanded(
                                  child: DropdownButtonFormField<int>(
                                    value: selectedDay,
                                    decoration: InputDecoration(
                                      labelText: "Day",
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                                    ),
                                    items: List.generate(31, (index) => index + 1)
                                        .map((day) => DropdownMenuItem(
                                      value: day,
                                      child: Text(day.toString()),
                                    ))
                                        .toList(),
                                    onChanged: (value) {
                                      setState(() => selectedDay = value);
                                    },
                                  ),
                                ),

                                SizedBox(width: 10),

                                // ---------------- MONTH ---------------- //
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: selectedMonth,
                                    decoration: InputDecoration(
                                      labelText: "Month",
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                                    ),
                                    items: months
                                        .map((m) => DropdownMenuItem(
                                      value: m,
                                      child: Text(m),
                                    ))
                                        .toList(),
                                    onChanged: (value) {
                                      setState(() => selectedMonth = value);
                                    },
                                  ),
                                ),

                                SizedBox(width: 10),

                                // ---------------- YEAR ---------------- //
                                Expanded(
                                  child: DropdownButtonFormField<int>(
                                    value: selectedYear,
                                    decoration: InputDecoration(
                                      labelText: "Year",
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                                    ),
                                    items: List.generate(
                                        100, (index) => DateTime.now().year - index) // last 100 years
                                        .map((year) => DropdownMenuItem(
                                      value: year,
                                      child: Text(year.toString()),
                                    ))
                                        .toList(),
                                    onChanged: (value) {
                                      setState(() => selectedYear = value);
                                    },
                                  ),
                                ),
                              ],
                            )



                          ),
                          const SizedBox(width: 16),

                          //Gender
                          Expanded(
                            // The Radio group will take up the remaining space on the right
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8.0, top: 4.0), // Adjust padding to align with other fields
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start, // Start layout from the left
                                children: [
                                  // 1. Gender Label
                                  const Text(
                                    "Gender: ",
                                    style: TextStyle(
                                      fontSize: 18, // Matching common label/input text size
                                      color: Colors.black54, // A slightly subdued color, like a hint text
                                    ),
                                  ),

                                  // Add a small spacer
                                  const SizedBox(width: 10),

                                  // 2. Male Radio Button
                                  Row(
                                    mainAxisSize: MainAxisSize.min, // Keep the row tight around the radio and text
                                    children: [
                                      Radio<String>(
                                        value: male,
                                        groupValue: genGroup,
                                        onChanged: (String? value) {
                                          setState(() {
                                            genGroup = value!;
                                            isSelected==true;
                                          });
                                        },
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // Makes the touch target smaller/cleaner
                                      ),
                                      Text(male),
                                    ],
                                  ),

                                  // 3. Female Radio Button
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Radio<String>(
                                        value: female,
                                        groupValue:   genGroup,
                                        onChanged: (String? value) {
                                          setState(() {
                                            genGroup = value!;
                                            isSelected==true;
                                          });
                                        },
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      Text(female),
                                    ],
                                  ),

                                  // 4. Others Radio Button
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Radio<String>(
                                        value: others,
                                        groupValue: genGroup,
                                        onChanged: (String? value) {
                                          setState(() {
                                            genGroup = value!;
                                            isSelected==true;
                                          });
                                        },
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      Text(others),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                      // You can add more rows for state, zip, etc. if needed
                    ],
                  ),


                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: addUser  ,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Color(0xFF5D5FEF), // Purple button background
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('Sign Up'),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("You have an Account?"),
                      TextButton(onPressed: (){
                        Navigator.pop(context);
                      }, child: Text('Login',style: TextStyle(
                          fontWeight: FontWeight.bold,fontSize: 16
                      ),))
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

