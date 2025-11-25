import 'dart:ui' as html;

import 'package:e_commerce_app/Login_Signup/editAddress.dart';
import 'package:e_commerce_app/Login_Signup/editLogin.dart';
import 'package:e_commerce_app/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:js' as js;

import 'OrderPlaced.dart';

Future<void> main() async{
  Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform
  );
  runApp(const MakeOrderPage(userEmail: '',));
}

class MakeOrderPage extends StatefulWidget {
  final String userEmail;
  const MakeOrderPage({super.key, required this.userEmail});

  @override
  State<MakeOrderPage> createState() => _MakeOrderPageState();
}

class _MakeOrderPageState extends State<MakeOrderPage> {



  String? _userId;
  Future<void> loadUser() async {
    final userEmail = widget.userEmail.trim();

    final userSnapshot = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: userEmail)
        .limit(1)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      setState(() {
        _userId = userSnapshot.docs.first.id;
      });
      // print("✅ User ID Loaded: $_userId");
    } else {
      // print("❌ No user found for email: $userEmail");
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadUser();

    js.context['onPaymentSuccess'] = (js.JsObject response) {
      final paymentId = response['razorpay_payment_id'];
      final method = response['method'] ?? 'Unknown'; // may need manual input if not returned

      // 🔥 Save payment info in Firestore
      FirebaseFirestore.instance.collection('orders').doc('OR001').update({
        'email': widget.userEmail,
        'paymentMethod': method,
      });
    };
  }

  String? makeOrderId;
  //ASYNC STREAMS---------
  Stream<QuerySnapshot> streamOrderItems() async* {

    if (_userId == null) {
      await Future.delayed(Duration(milliseconds: 200));
      // retry until loaded
      yield* Stream.empty();
      return;
    }

    final makeOrderDoc = await FirebaseFirestore.instance.collection('makeorder').where('userId', isEqualTo: _userId).limit(1).get();

    if(makeOrderDoc.docs.isNotEmpty){
      makeOrderId = makeOrderDoc.docs.first.id;

      yield* FirebaseFirestore.instance.collection('makeorder').doc(makeOrderId).collection('makeCartOrder').snapshots();
    }
  }

  Stream<DocumentSnapshot?> getPaymentInfo() {
    final userEmail = widget.userEmail.trim();
    return FirebaseFirestore.instance
        .collection('makeorder')
        .where('email', isEqualTo: userEmail)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first;
      } else {
        return null;
      }
    });
  }



  Future<DocumentSnapshot?> getUserInfo() async {
    final userEmail = widget.userEmail.trim();
    QuerySnapshot userInfo = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: userEmail).limit(1).get();
    if(userInfo.docs.isNotEmpty){
      return userInfo.docs.first;
    }else{
      return null;
    }
  }


  Future<void> deleteItem(String productId) async{
    await FirebaseFirestore.instance.collection('makeorder').doc(makeOrderId).collection('makeCartOrder').doc(productId).delete();

    final OrderQuery = await FirebaseFirestore.instance.collection('orders').where('userId', isEqualTo: _userId).limit(1).get();
    if (OrderQuery.docs.isEmpty) {
      print('No order found for user: ${widget.userEmail}');
      return;
    }

    final OrderDocId = OrderQuery.docs.first.id;

    await FirebaseFirestore.instance.collection('orders').doc(OrderDocId).collection('yourOrderedItems').doc(productId).delete();
  }

  Future<void> updateTotals() async{
    final snapshot = await FirebaseFirestore.instance.collection('makeorder').doc(makeOrderId).collection('makeCartOrder').get();

    double newSubTotal = 0;

    if(snapshot.docs.isNotEmpty){
      for (var doc in snapshot.docs){
        final data = doc.data();
        newSubTotal += (data['itemTotalPrice'] ?? 0).toDouble();

        double newCGST = newSubTotal * 0.03;
        double newSGST = newSubTotal * 0.03;
        double newGrandTotal = newSubTotal + newCGST + newSGST;

        await FirebaseFirestore.instance.collection('makeorder').doc(makeOrderId).update({
          'subTotal': newSubTotal,
          'CGST': double.parse(newCGST.toStringAsFixed(2)),
          'SGST': double.parse(newSGST.toStringAsFixed(2)),
          'grandTotal': double.parse(newGrandTotal.toStringAsFixed(2))
        });
      }
    }else{
      await FirebaseFirestore.instance.collection('makeorder').doc(makeOrderId).update({
        'subTotal': 0,
        'CGST': 0,
        'SGST': 0,
        'grandTotal': 0
      });
    }

  }


  //DEMO STREAMS -----------
  Stream<QuerySnapshot> demoStream() {
    return FirebaseFirestore.instance.collection('makeorder').doc('MO001').collection('makeCartOrder').snapshots();
  }

  Future<DocumentSnapshot> demoUserInfoStream() {
    return FirebaseFirestore.instance.collection('users').doc('U006').get();
  }

  Future<DocumentSnapshot> demoPaymentTotal() {
    return FirebaseFirestore.instance.collection('makeorder').doc('MO001').get();
  }


  //Razorpay Payments
  String? name;
  String? phone;
  Future<void> openCheckout(double subTotal,double CGST,double SGST,double grandTotal) async {


    // ... (Your existing code to get user data)
    final userEmail = widget.userEmail.trim();

    final checkOrderItem = await FirebaseFirestore.instance.collection('makeorder')
        .doc(makeOrderId).collection('makeCartOrder').get();

    if(checkOrderItem.docs.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Your Make Order Is Empty")),
      );
    }else{
      // final user = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: userEmail).get();
      // if(user.docs.isNotEmpty){
      //   final data = user.docs.first.data();
      //   name = data['username'] ?? '';
      //   phone = data['phone'];
      // }

      // String testPaymentAPI = "rzp_test_RbyzzbUPyAXrJ8";
      // String StoreName = "PROductADDa";
      // int inrGrandTotal = (GrandTotal * 100).round().toInt();
      // final options = {
      //   'key': testPaymentAPI,
      //   'amount': inrGrandTotal,
      //   'currency': 'INR',
      //   'name': StoreName,
      //   'description': 'Test Transaction',
      //   'prefill': {'name': name,'contact': phone, 'email': userEmail},
      //   'theme': {'color': '#3399cc'},
      // };

      // js.context.callMethod('openRazorpayCheckout', [js.JsObject.jsify(options)]);





      // STEP 1 — Convert last recent → previous
      final oldRecent = await FirebaseFirestore.instance.collection('orders')
          .where('email', isEqualTo: userEmail)
          .where('orderStatus', isEqualTo: 'recent')
          .limit(1)
          .get();

      if (oldRecent.docs.isNotEmpty) {
        await oldRecent.docs.first.reference.update({
          'orderStatus': 'previous'
        });
      }

  // STEP 2 — Create NEW orderId every time
      String orderId;

      QuerySnapshot allOrders = await FirebaseFirestore.instance
          .collection('orders')
          .orderBy(FieldPath.documentId)
          .get();

      if (allOrders.docs.isEmpty) {
        orderId = "OR001";
      } else {
        String lastOrderId = allOrders.docs.last.id; // example: OR015
        int lastNum = int.parse(lastOrderId.substring(2)); // "015" → 15
        int newNum = lastNum + 1;
        orderId = "OR${newNum.toString().padLeft(3, '0')}";
      }

  // STEP 3 — Add ordered items
      final makeOrderQuery = await FirebaseFirestore.instance
          .collection('makeorder')
          .where('userId', isEqualTo: _userId)
          .limit(1)
          .get();

      if (makeOrderQuery.docs.isEmpty) {
        print('No cart found for user: ${widget.userEmail}');
        return;
      }

      final makeOrderDocId = makeOrderQuery.docs.first.id;

      final makeOrderItemsSnapshot = await FirebaseFirestore.instance
          .collection('makeorder')
          .doc(makeOrderDocId)
          .collection('makeCartOrder')
          .get();

  // upload items
      for (var doc in makeOrderItemsSnapshot.docs) {
        final data = doc.data();

        await FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .collection('yourOrderedItems')
            .doc(data['productId'])
            .set({
          'productId': data['productId'],
          'productName': data['productName'],
          'price': data['price'],
          'quantity': data['quantity'],
          'imageUrl': data['imageUrl'],
          'itemTotalPrice': (data['price'] ?? 0) * (data['quantity'] ?? 0),
          'itemStatus': 'Ordered'
        });
      }

  // STEP 4 — Add main order data as recent
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .set({
        'orderId': orderId,
        'userId': _userId,
        'email': userEmail,
        'subTotal': subTotal,
        'CGST': double.parse(CGST.toStringAsFixed(2)),
        'SGST': double.parse(SGST.toStringAsFixed(2)),
        'grandTotal': double.parse(grandTotal.toStringAsFixed(2)),
        'orderedDate': Timestamp.now(),
        'shippedDate': Timestamp.now(),
        'deliveredDate': Timestamp.now(),
        'inTransitDate': Timestamp.now(),
        'outDiliveredDate': Timestamp.now(),
        'paymentMethod': 'UPI',
        'shippingStatus': 'Order Confirmed',
        'orderStatus': 'recent'
      });

  // Navigate
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderPlacedPage(userEmail: userEmail),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          leading: IconButton(onPressed: (){Navigator.of(context).pop();}, icon: Icon(Icons.arrow_back)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.only(left: 30.0,right: 30.0,top: 30.0,bottom: 15.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 15.0,top: 5),
                        child: Text("Your Orders",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 45),),
                      ),
                      SizedBox(height: 10,),

                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                            stream: streamOrderItems(),
                            builder: (context, snapshot){

                              // 1️⃣ Check for errors
                              if (snapshot.hasError) {
                                return Center(child: Text('Error: ${snapshot.error}'));
                              }

                              // 2️⃣ Show loading indicator while waiting
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return Center(child: CircularProgressIndicator());
                              }

                              // 3️⃣ Check if no data or empty
                              if (!snapshot.hasData || snapshot.data == null || snapshot.data!.docs.isEmpty) {
                                return Center(child: Text('No items in your order.'));
                              }

                              final makeOrders = snapshot.data!.docs;

                              return ListView.builder(
                                itemCount: makeOrders.length,
                                itemBuilder: (context, index){

                                  var orderItems = makeOrders[index].data() as Map<String, dynamic>;

                                  final imageUrl = orderItems['imageUrl'] as String;
                                  final productName = orderItems['productName'] ?? '';
                                  final int quantity = orderItems['quantity'];
                                  final double price = (orderItems['price'] as num).toDouble();
                                  final double itemTotalPrice = price*quantity;



                                  return Container(
                                    width: 750,
                                    height: 280,
                                    margin: EdgeInsets.all(8),
                                    child: Card(
                                        elevation: 9,
                                        child: Padding(
                                          padding: const EdgeInsets.all(20.0),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: [

                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Container(
                                                  color: Colors.white, // Ensure a white background for non-filling images
                                                  child: AspectRatio(
                                                    aspectRatio: 1.3,
                                                    child: Image.network(
                                                      '$imageUrl',
                                                      fit: BoxFit.cover,
                                                      width: 100,
                                                      errorBuilder: (context, error, stackTrace) =>
                                                      const Icon(Icons.broken_image, size: 60),
                                                    ),
                                                  ),
                                                ),
                                              ),

                                              SizedBox(width: 40,),

                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      overflow: TextOverflow.ellipsis,
                                                      maxLines: 1,
                                                      "$productName",
                                                      style: TextStyle(fontSize: 26,fontWeight: FontWeight.bold),
                                                    ),
                                                    SizedBox(height: 10,),

                                                    Text("Color: Black Titanium",style: TextStyle(fontSize: 17),),
                                                    Text("RAM: 28GB",style: TextStyle(fontSize: 17),),
                                                    Text("Storage: 256GB",style: TextStyle(fontSize: 17),),

                                                    SizedBox(height: 20,),

                                                    Text("Unit Price: $price",style: TextStyle(fontSize: 18),),
                                                    Text("Quantity: $quantity",style: TextStyle(fontSize: 18)),
                                                    Row(
                                                      // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                      children: [
                                                        Text("Sub Total: $itemTotalPrice",style: TextStyle(fontSize: 18)),
                                                        SizedBox(width: 70,),
                                                        ElevatedButton(
                                                          onPressed: () async{
                                                            deleteItem(orderItems['productId']);
                                                            updateTotals();
                                                          },
                                                          child: Text("Remove Item"),
                                                          style: ElevatedButton.styleFrom(
                                                            foregroundColor: Colors.white,
                                                            backgroundColor: Colors.redAccent, // Purple button background
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(10.0),
                                                            ),
                                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                                                            textStyle: const TextStyle(
                                                              fontSize: 18,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        )
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                    ),
                                  );
                                },
                              );
                            }
                        ),
                      ),
                    ],
                  ),
                ),




                StreamBuilder<DocumentSnapshot?>(
                    stream: getPaymentInfo(),
                    builder: (context, snapshot){

                      // 1️⃣ Check for errors
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      // 2️⃣ Show loading indicator while waiting
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      // 3️⃣ Check if no data or empty
                      if (!snapshot.hasData || snapshot.data == null) {
                        return Center(child: Text('No items in your order.'));
                      }

                      final orderInfo = snapshot.data!.data() as Map<String, dynamic>;

                      return Container(
                        width: 320,
                        height: double.infinity,
                        margin: const EdgeInsets.all(8),
                        child: Card(
                            elevation: 9,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  // --- HEADER ---
                                  Text(
                                      'Order Details',
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)
                                  ),
                                  const Divider(),

                                  // --- FINANCIAL BREAKDOWN ---
                                  Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Subtotal: ',style: TextStyle(fontSize: 19),),
                                          Text('${orderInfo['subTotal']}',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('CGST (3%): ',style: TextStyle(fontSize: 14),),
                                          Text('${orderInfo['CGST']}',style: TextStyle(fontSize: 16),),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('SGST (3%): ',style: TextStyle(fontSize: 14),),
                                          Text('${orderInfo['SGST']}',style: TextStyle(fontSize: 16),),
                                        ],
                                      ),

                                    ],
                                  ),

                                  const SizedBox(height: 15),

                                  // --- GRAND TOTAL ---
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: const BoxDecoration(
                                      border: Border(top: BorderSide(color: Colors.black, width: 2)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Grand Total: ',style: TextStyle(fontSize: 19,color: Colors.redAccent),
                                        ),
                                        Text(
                                          '${orderInfo['grandTotal']}',style: TextStyle(fontSize: 24,fontWeight: FontWeight.bold,color: Colors.redAccent),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // --- PAYMENT METHOD SELECTION ---
                                  const Spacer(),

                                  Text('Pay With: Razorpay', style: Theme.of(context).textTheme.titleMedium),
                                  const SizedBox(height: 10),

                                  // // Placeholder for actual payment widgets
                                  // Container(
                                  //   height: 50,
                                  //   alignment: Alignment.center,
                                  //   decoration: BoxDecoration(
                                  //       border: Border.all(color: Colors.grey.shade300),
                                  //       borderRadius: BorderRadius.circular(8)
                                  //   ),
                                  //   child: const Text('UPI | Net Banking | COD', style: TextStyle(color: Colors.blue)),
                                  // ),

                                  const SizedBox(height: 20),

                                  // --- ACTION BUTTON ---
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: (){
                                        openCheckout(orderInfo['subTotal'],orderInfo['CGST'],orderInfo['SGST'],orderInfo['grandTotal']);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 15),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                      child: const Text('PROCEED TO PAY', style: TextStyle(fontSize: 18, color: Colors.white)),
                                    ),
                                  ),
                                ],
                              ),
                            )
                        ),
                      );
                    }
                ),




                FutureBuilder<DocumentSnapshot?>(
                    future: getUserInfo(),
                    builder: (context, snapshot){

                      // 1️⃣ Check for errors
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      // 2️⃣ Show loading indicator while waiting
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      // 3️⃣ Check if no data or empty
                      if (!snapshot.hasData || snapshot.data == null) {
                        return Center(child: Text('No items in your order.'));
                      }

                      final userInfo = snapshot.data!.data() as Map<String, dynamic>;

                      Timestamp t = userInfo['dateOfBirth'];
                      DateTime dob = t.toDate();
                      final dateOfBirth = "${dob.day.toString().padLeft(2, '0')}-${dob.month.toString().padLeft(2, '0')}-${dob.year}";

                      return Container(
                        width: 320,
                        height: double.infinity,
                        margin: EdgeInsets.all(8),
                        child: Card(
                          elevation: 9,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 15,right: 15,top: 35),
                            child: Column(
                              children: [
                                CircleAvatar(radius: 60,child: Text("${userInfo['profileUrl']}"),),


                                SizedBox(height: 15,),

                                Text("${userInfo['username']}",style: TextStyle(fontSize: 28,fontWeight: FontWeight.bold),),

                                Padding(
                                  padding: const EdgeInsets.only(left: 20,right: 20,top: 10,bottom: 8),
                                  child: Divider(),
                                ),

                                Padding(
                                  padding: const EdgeInsets.only(left: 20.0),
                                  child: Container(
                                    width: double.maxFinite,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text("Personal Info",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 19),),
                                            IconButton(onPressed: (){
                                              Navigator.push(context, MaterialPageRoute(builder: (context) => EditLoginPage(userEmail: widget.userEmail)));
                                            }, icon: Icon(Icons.edit,size: 19,color: Colors.deepPurple,))
                                          ],
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(left: 8.0,top: 8),
                                          child: Text("Email: ${userInfo['email']}",style: TextStyle(fontSize: 16),),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(left: 8.0,top: 4),
                                          child: Text("Number: ${userInfo['phone']}",style: TextStyle(fontSize: 16),),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(left: 8.0,top: 4),
                                          child: Text("Gender: ${userInfo['gender']}",style: TextStyle(fontSize: 16),),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(left: 8.0,top: 4),
                                          child: Text("DOB: $dateOfBirth",style: TextStyle(fontSize: 16),),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                Padding(
                                  padding: const EdgeInsets.only(left: 20,right: 20,top: 10,bottom: 8),
                                  child: Divider(),
                                ),

                                Padding(
                                  padding: const EdgeInsets.only(left: 20.0),
                                  child: Container(
                                    width: double.maxFinite,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text("Your Shipping Address",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 19),),
                                            IconButton(onPressed: (){
                                              Navigator.push(context, MaterialPageRoute(builder: (context) => EditAddressPage(userEmail: widget.userEmail)));
                                            }, icon: Icon(Icons.edit,size: 19,color: Colors.deepPurple,))
                                          ],
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(left: 8.0,top: 8),
                                          child: Text("${userInfo['street']},",style: TextStyle(fontSize: 16),),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(left: 8.0,top: 4),
                                          child: Text("${userInfo['area']},",style: TextStyle(fontSize: 16),),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(left: 8.0,top: 4),
                                          child: Text("${userInfo['city']},",style: TextStyle(fontSize: 16),),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(left: 8.0,top: 4),
                                          child: Text("${userInfo['state']} - ${userInfo['pincode']}",style: TextStyle(fontSize: 16),),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              ],
                            ),
                          ),
                        ),
                      );
                    }
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}




//Mobile View Code ---------------------------------------------------------
// Mobile View Code:
// Scaffold(
// appBar: AppBar(
// leading: IconButton(
// onPressed: () {
// // Assume context exists and navigation is possible
// Navigator.of(context).pop();
// },
// icon: const Icon(Icons.arrow_back),
// ),
// title: const Text("Checkout"),
// ),
// body: Center(
// child: LayoutBuilder(
// builder: (context, constraints) {
// // --- 1. DATA AND HELPER FUNCTIONS (Placed OUTSIDE any Widget List) ---
//
// // Financial Data
// const double subtotal = 920000.0;
// const double gstRate = 0.09;
// final double cgst = subtotal * gstRate;
// final double grandTotal = subtotal + (2 * cgst);
// String formatCurrency(double amount) => '₹ ${amount.toStringAsFixed(2)}';
//
// // Helper function for the financial breakdown rows
// Widget buildDetailRow(String label, String value, {bool isGrandTotal = false}) {
// return Padding(
// padding: const EdgeInsets.symmetric(vertical: 4.0),
// child: Row(
// mainAxisAlignment: MainAxisAlignment.spaceBetween,
// children: [
// Text(
// label,
// style: TextStyle(
// fontSize: isGrandTotal ? 18 : 16,
// fontWeight: isGrandTotal ? FontWeight.bold : FontWeight.normal,
// ),
// ),
// Text(
// value,
// style: TextStyle(
// fontSize: isGrandTotal ? 18 : 16,
// fontWeight: isGrandTotal ? FontWeight.bold : FontWeight.w600,
// color: isGrandTotal ? Colors.redAccent : Colors.black,
// ),
// ),
// ],
// ),
// );
// }
//
// // Helper function for the User Info section
// Widget buildInfoSection(String title, Map<String, dynamic> userInfo, Map<String, String> fields, {bool isAddress = false}) {
// return Column(
// crossAxisAlignment: CrossAxisAlignment.start,
// children: [
// Row(
// mainAxisAlignment: MainAxisAlignment.spaceBetween,
// children: [
// Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
// IconButton(
// onPressed: () {
// // Placeholder navigation logic, depends on context/widget.
// },
// icon: const Icon(Icons.edit, size: 18, color: Colors.deepPurple),
// ),
// ],
// ),
// const SizedBox(height: 5),
// ...fields.entries.map((entry) {
// final key = entry.key;
// final valueKey = entry.value;
// String displayValue = userInfo[valueKey]?.toString() ?? '';
//
// if (key == 'StatePin' && isAddress) {
// displayValue = "${userInfo['sta