import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {

  int? _userCount;
  int? _adminCount;
  int? _productCount;
  int? _orderCount;


  Future<void> count() async{
    try{
      QuerySnapshot countUser = await FirebaseFirestore.instance.collection("users").where('role', isEqualTo: 'User').get();
      QuerySnapshot countAdmin = await FirebaseFirestore.instance.collection("users").where('role', isEqualTo: 'Admin').get();
      QuerySnapshot countProducts = await FirebaseFirestore.instance.collection("products").get();
      QuerySnapshot countOrders = await FirebaseFirestore.instance.collection("orders").get();


      int countedUser = countUser.docs.length;
      int countedAdmin = countAdmin.docs.length;
      int countedProduct = countProducts.docs.length;
      int countedOrder = countOrders.docs.length;

      if(mounted){
        setState(() {
          _userCount = countedUser;
          _adminCount = countedAdmin;
          _productCount = countedProduct;
          _orderCount = countedOrder;
        });
      }
    }catch(e){
      print("Error: $e");
      if (mounted) {
        setState(() {
          _userCount = 0;
          _adminCount = 0;
          _productCount = 0;
          _orderCount = 0;
        });
      }
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    count();
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            // mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Admin Dashboard",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 40),),
              SizedBox(height: 40,),
              Row(
                children: [
                  SizedBox(
                    height: 230,
                    width: 200,
                    child: Card(
                      elevation: 4,
                      margin: EdgeInsets.only(
                          top: 20, bottom: 20, left: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,

                        children: [
                          Text("$_productCount",style: TextStyle(fontSize: 80),),
                          Text("Total Products",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20),),
                        ],
                      ),
                    ),

                  ),
                  SizedBox(
                    height: 230,
                    width: 200,
                    child: Card(
                      elevation: 4,
                      margin: EdgeInsets.only(
                          top: 20, bottom: 20, left: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,

                        children: [
                          Text("$_userCount",style: TextStyle(fontSize: 80),),
                          Text("Total Users",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20),),
                        ],
                      ),
                    ),

                  ),
                  SizedBox(
                    height: 230,
                    width: 200,
                    child: Card(
                      elevation: 4,
                      margin: EdgeInsets.only(
                          top: 20, bottom: 20, left: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,

                        children: [
                          Text("$_orderCount",style: TextStyle(fontSize: 80),),
                          Text("Total Orders",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20),),
                        ],
                      ),
                    ),

                  ),
                  SizedBox(
                    height: 230,
                    width: 200,
                    child: Card(
                      elevation: 8,
                      margin: EdgeInsets.only(
                          top: 20, bottom: 20, left: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,

                        children: [
                          Text("$_adminCount",style: TextStyle(fontSize: 80),),
                          Text("Total Admin",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20),),
                        ],
                      ),
                    ),

                  ),
                ],
              ),

            ],
          ),
        ),
      ),
    );
  }
}


