import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_commerce_app/firebase_options.dart';
import 'package:icons_plus/icons_plus.dart';


Future<void> main() async{
  Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ContactUsPage(userEmail: ''));
}

class ContactUsPage extends StatefulWidget {
  final String userEmail;
  const ContactUsPage({super.key, required this.userEmail});

  @override
  State<ContactUsPage> createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {


  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final messageController = TextEditingController();

  String? selectSubject;
  final List<String> subjects = [
    'Order Issue',
    'Payment Issue',
    'Refund Request',
    'Wrong / Damaged Item',
    'Billing / Invoice Request',
    'Delivery Issue',
    'App/Technical Issues',
    'Login / OTP Problem',
    'Product Inquiry',
    'Feedback & Suggestions',
  ];

  Future<void> contactUs() async{

    final emailToSearch = widget.userEmail.trim();

    // Step 1️⃣: Check if this user already has a contactus id
    final existingContact = await FirebaseFirestore.instance
        .collection('contactus')
        .where('email', isEqualTo: emailToSearch)
        .limit(1)
        .get();

    String contactId;


    // Step 2️⃣: If user already has a cart → use same cart ID
    if (existingContact.docs.isNotEmpty) {
      contactId = existingContact.docs.first.id;
    } else {
      // Step 3️⃣: If no cart → generate new ID like CU001, CU002...
      QuerySnapshot allcontact = await FirebaseFirestore.instance
          .collection('contactus')
          .orderBy(FieldPath.documentId)
          .get();

      if (allcontact.docs.isEmpty) {
        contactId = 'CU001';
      } else {
        String lastCartId = allcontact.docs.last.id;
        int lastNumber = int.tryParse(lastCartId.substring(1)) ?? 0;
        int newNumber = lastNumber + 1;
        contactId = 'CU${newNumber.toString().padLeft(3, '0')}';
      }

    }

    // Step 4️⃣: Get userId using email
    final userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: emailToSearch)
        .limit(1)
        .get();

    if (userSnapshot.docs.isEmpty) {
      print("❌ No user found with email $emailToSearch");
      return;
    }
    final userId = userSnapshot.docs.first.id;




    //Step 5: Find message Id
    final existingMessage = await FirebaseFirestore.instance
        .collection('contactus')
        .doc(contactId)
        .collection('yourMessages')
        .get();

    String messageId;

      // Step 6: If message has → then generate new id (M002) else start with M001
      QuerySnapshot allmessage = await FirebaseFirestore.instance
          .collection('contactus')
          .doc(contactId)
          .collection('yourMessages')
          .orderBy(FieldPath.documentId)
          .get();

      if (allmessage.docs.isEmpty) {
        messageId = 'M001';
      } else {
        String lastMsgId = allmessage.docs.last.id;
        int lastNumber = int.parse(lastMsgId.substring(1));
        int newNumber = lastNumber + 1;
        messageId = 'M${newNumber.toString().padLeft(3, '0')}';
      }




// Step 7 Reference to user's cart
    final contactRef = FirebaseFirestore.instance.collection('contactus').doc(contactId);

// Step 8: Add product to cart (subcollection)
    await contactRef.collection('yourMessages').doc(messageId).set({
      'name': nameController.text.trim(),
      'phone': int.parse(phoneController.text.trim()),
      'email': emailController.text.trim(),
      'subject': selectSubject,
      'message': messageController.text.trim(),
      'state': 'unread'
    }, SetOptions(merge: true));

// Step 9: Save user details in cart document (only once)
    await contactRef.set({
      'userId': userId,
      'email': emailToSearch,
    }, SetOptions(merge: true));

    print("✅ Product added to cart ($contactId) for user: $emailToSearch");
    

    nameController.clear();
    phoneController.clear();
    emailController.clear();
    messageController.clear();
    setState(() {
      selectSubject=null;
    });

  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          leading: IconButton(onPressed: (){Navigator.of(context).pop();}, icon: Icon(Icons.arrow_back)),
          title: Text("Contact us"),
        ),

        body: Padding(
          padding: const EdgeInsets.only(top: 30.0,right: 100,left: 100,bottom: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Connect With Us",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 33),),
              SizedBox(height: 15,),
              Text("We would love to respond to you queries and help you succeed.",style: TextStyle(fontSize: 18),),
              Text("Feel free to get in touch with us.",style: TextStyle(fontSize: 18),),

              SizedBox(height: 30,),

              Expanded(
                child: SizedBox(
                  width: double.maxFinite,
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(0),
                    ),
                    elevation: 10,
                    child: Row(
                      children: [

                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 20, bottom: 20, left: 45, right: 45.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text("Send Your Request",style: TextStyle(fontSize: 24,fontWeight: FontWeight.bold,),),
                                    Spacer(),
                                    ElevatedButton(
                                        onPressed: contactUs,
                                        child: Text("Send Message"),
                                        style: ElevatedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          backgroundColor: Colors.redAccent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(0),
                                          ),
                                        ),
                                    )
                                  ],
                                ),
                                SizedBox(height: 20,),


                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [

                                          Text("Name"),
                                          SizedBox(height: 5),
                                          TextField(
                                            controller: nameController,
                                            decoration: InputDecoration(
                                              border: UnderlineInputBorder(),
                                              hintText: "Your Name",
                                            ),
                                          ),

                                          SizedBox(height: 20),

                                          Text("Email"),
                                          SizedBox(height: 5),
                                          TextField(
                                            controller: emailController,
                                            decoration: InputDecoration(
                                              border: UnderlineInputBorder(),
                                              hintText: "youremail@gmail.com",
                                            ),
                                          ),

                                        ],
                                      ),
                                    ),

                                    SizedBox(width: 40),

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [

                                          Text("Phone"),
                                          SizedBox(height: 5),
                                          TextField(
                                            controller: phoneController,
                                            decoration: InputDecoration(
                                              border: UnderlineInputBorder(),
                                              hintText: "+12 12345 67890",
                                            ),
                                          ),

                                          SizedBox(height: 20),

                                          Text("Subject"),
                                          SizedBox(height: 5),
                                          DropdownButtonFormField<String>(
                                            value: selectSubject,
                                            alignment: Alignment.centerLeft,
                                            icon: Icon(Icons.arrow_drop_down),
                                            hint: Text("Select Subject"),

                                            items: subjects.map((cat) => DropdownMenuItem(value: cat,child: Text(cat))).toList(),
                                            onChanged: (value){
                                              setState(() {
                                                selectSubject=value;
                                              });
                                            },
                                          ),

                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: 30,),

                                Text("Message"),
                                SizedBox(height: 10),
                                TextField(
                                  controller: messageController,
                                  maxLines: 4,
                                  maxLength: 200,
                                  decoration: InputDecoration(
                                      border: OutlineInputBorder()
                                  ),
                                ),

                              ],
                            ),
                          ),
                        ),

                        Expanded(
                          flex: 2,   // keep whatever ratio you want (ex: 5)
                          child: Container(
                            color: Color(0xFF38485B),
                            padding: EdgeInsets.only(top: 20,left: 40,right: 40,bottom: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              // mainAxisAlignment: MainAxisAlignment.center,
                              children: [

                                // TITLE
                                Text("Quick Support",style: TextStyle(fontSize: 24,fontWeight: FontWeight.bold,color: Colors.white),),
                                SizedBox(height: 25),


                                Expanded(
                                  child: Center(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Spacer(),
                                        // WHATSAPP BUTTON
                                        SizedBox(
                                          width: 210,
                                          child: IconButton(
                                            onPressed: (){},
                                            icon: Row(
                                              children: [
                                                Logo(Logos.whatsapp, size: 27),
                                                SizedBox(width: 15,),
                                                Text("WhatsApp Chat",style: TextStyle(color: Colors.white,fontSize: 20),),
                                              ],
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 20),

                                        // CALL BUTTON
                                        SizedBox(
                                          width: 210,
                                          child: IconButton(
                                            onPressed: (){},
                                            icon: Row(
                                              children: [
                                                Icon(Icons.call, size: 28,color: Colors.blue,),
                                                SizedBox(width: 15,),
                                                Text("Call Us",style: TextStyle(color: Colors.white,fontSize: 20),),
                                              ],
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 20),

                                        // EMAIL BUTTON
                                        SizedBox(
                                          width: 210,
                                          child: IconButton(
                                            onPressed: (){},
                                            icon: Row(
                                              children: [
                                                Logo(Logos.gmail, size: 27),
                                                SizedBox(width: 15,),
                                                Text("Email Us",style: TextStyle(color: Colors.white,fontSize: 20),),
                                              ],
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 30),


                                        Spacer(),
                                        // RESPONSE TIME NOTE
                                        Text(
                                          "We Reply Within 2-3 Working Days.",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 17,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        )

                      ],
                    ),
                  ),
                ),
              )

            ],
          ),
        ),
      ),
    );
  }
}
