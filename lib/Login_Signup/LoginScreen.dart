
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_commerce_app/firebase_options.dart';

import '../AdminScreens/Admin.dart';
import '../Screens/Home.dart';
import 'SignUpScreen.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const LoginPage(),
    );
  }
}




class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  final email = TextEditingController();
  final pass = TextEditingController();


  Future<void> login() async {
    var snap = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email.text.trim())
        .where('password', isEqualTo: pass.text.trim())
        .get();

    if (snap.docs.isNotEmpty) {
      var role = snap.docs[0]['role'];
      if (role == 'Admin') {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => AdminPanel(email: email.text)));
      } else {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => HomePage(userEmail: email.text)));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid credentials")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black12,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(80.0),
          child: SizedBox(
            height: 490,
            width: 390,
            child: Card(
              elevation: 90,
              child: Padding(
                padding: const EdgeInsets.only(left: 40,right: 40,top: 60),
                child: Column(
                  children: [
                    Text("Login",style: TextStyle(
                      fontSize: 45,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5D5FEF),
                    ),),
                    SizedBox(height: 60,),
                    TextField(
                      controller: email,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Email"
                      ),
                    ),
                    SizedBox(height: 20,),
                    TextField(
                      controller: pass,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Password"
                      ),
                    ),
                    SizedBox(height: 40,),
                    ElevatedButton(onPressed: login, child: Text("Login"),
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
                    )),
                    SizedBox(height: 20,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("You don't have an Account?"),
                        TextButton(onPressed: (){
                          Navigator.push(context, MaterialPageRoute(builder: (context) => SignUpPage()));
                        }, child: Text('Sign Up',style: TextStyle(
                          fontWeight: FontWeight.bold,fontSize: 16
                        ),))
                      ],
                    ),

                  ],
                ),
              ),
            ),
          )
        ),
      ),
    );
  }
}
