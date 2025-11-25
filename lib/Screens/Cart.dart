import 'package:e_commerce_app/Login_Signup/editLogin.dart';
import 'package:e_commerce_app/Screens/MakeOrder.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_commerce_app/firebase_options.dart';

Future<void> main() async{
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const CartPage(userEmail: '',));

}


class CartPage extends StatefulWidget {
  final String userEmail;
  const CartPage({super.key, required this.userEmail});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {

  String? _userId;
  Future<void> loadUser() async {
    final cartUserEmail = widget.userEmail.trim();

    final userSnapshot = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: cartUserEmail)
        .limit(1)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      setState(() {
        _userId = userSnapshot.docs.first.id;
      });
      print("✅ User ID Loaded: $_userId");
    } else {
      print("❌ No user found for email: $cartUserEmail");
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadUser();
  }

  Stream<QuerySnapshot> newStream() async*{
    final emailToSearch = widget.userEmail.trim();

    // Wait until userId is loaded
    if (_userId == null) {
      await Future.delayed(Duration(milliseconds: 200));
      // retry until loaded
      yield* Stream.empty();
      return;
    }

    final cartDoc = await FirebaseFirestore.instance.collection('carts').where('userId', isEqualTo: _userId).limit(1).get();

    if(cartDoc.docs.isNotEmpty){
      final cartId = cartDoc.docs.first.id;

      yield* FirebaseFirestore.instance.collection('carts').doc(cartId).collection('yourCart').snapshots();
    }
  }


  Future<void> deleteItem(String productId) async{
    try{
      //1. Delete from yourCart
      final cartQuery = await FirebaseFirestore.instance.collection('carts').where('userId', isEqualTo: _userId).limit(1).get();
      if (cartQuery.docs.isEmpty) {
        print('No cart found for user: ${widget.userEmail}');
        return;
      }

      final cartDocId = cartQuery.docs.first.id;

      await FirebaseFirestore.instance.collection('carts').doc(cartDocId).collection('yourCart').doc(productId).delete();


      //2. Delete from makeCartOrder
      final makeOrderQuery = await FirebaseFirestore.instance.collection('makeorder').where('userId', isEqualTo: _userId).limit(1).get();
      if (makeOrderQuery.docs.isEmpty) {
        print('No order found for user: ${widget.userEmail}');
        return;
      }

      final makeOrderDocId = makeOrderQuery.docs.first.id;

      await FirebaseFirestore.instance.collection('makeorder').doc(makeOrderDocId).collection('makeCartOrder').doc(productId).delete();

    }catch(e){}
  }


  Future<void> incrementItem(String productId) async{
      final cartUserEmail = widget.userEmail.trim();
      final cartQuery = await FirebaseFirestore.instance.collection('carts').where('userId', isEqualTo: _userId).limit(1).get();

      if (cartQuery.docs.isEmpty) {
        print('No cart found for user: $cartUserEmail');
        return;
      }

      final cartDocId = cartQuery.docs.first.id;

      await FirebaseFirestore.instance.collection('carts').doc(cartDocId).collection('yourCart').doc(productId).update({
        'quantity': FieldValue.increment(1),
      });

  }
  late String cartDocId;

  Future<void> decreaseItem(String productId) async{
      final cartUserEmail = widget.userEmail.trim();
      final cartQuery = await FirebaseFirestore.instance.collection('carts').where('userId', isEqualTo: _userId).limit(1).get();

      if (cartQuery.docs.isEmpty) {
        print('No cart found for user: $cartUserEmail');
        return;
      }

      cartDocId = cartQuery.docs.first.id;

      await FirebaseFirestore.instance.collection('carts').doc(cartDocId).collection('yourCart').doc(productId).update({
        'quantity': FieldValue.increment(-1),
      });
  }


  Future<void> goToMakeOrder(double subTotal,double CGST,double SGST,double grandTotal) async{

      final emailToSearch = widget.userEmail.trim();

    //1. check any order is exits or not
    final existingMakeOrder = await FirebaseFirestore.instance.collection('makeorder')
        .where('email', isEqualTo: emailToSearch).limit(1).get();

    String makeOrderId;

    //2. create new orderId
    if (existingMakeOrder.docs.isNotEmpty) {
      makeOrderId = existingMakeOrder.docs.first.id;
    }else{
      QuerySnapshot allMakeOrder = await FirebaseFirestore.instance.collection('makeorder')
          .orderBy(FieldPath.documentId).get();

      if(allMakeOrder.docs.isEmpty){
        makeOrderId = "MO001";
      }else{
        String lastMakeOrderId = allMakeOrder.docs.last.id;
        String numberPart = lastMakeOrderId.replaceAll(RegExp(r'[^0-9]'), '');

        int lastNumber =  int.tryParse(numberPart) ?? 0;
        int newNumber = lastNumber + 1;
        makeOrderId = 'MO${newNumber.toString().padLeft(3, '0')}';
      }
    }

    //3. Add makeOrder details to makeCartOrder(subcollection)
    final cartQuery = await FirebaseFirestore.instance
        .collection('carts')
        .where('userId', isEqualTo: _userId)
        .limit(1)
        .get();

    if (cartQuery.docs.isEmpty) {
      print('No cart found for user: ${widget.userEmail}');
      return;
    }

    final cartDocId = cartQuery.docs.first.id;
    final cartItemsSnapshot = await FirebaseFirestore.instance
        .collection('carts')
        .doc(cartDocId)
        .collection('yourCart')
        .get();

    print('cart doc id: $cartDocId');

    for (var doc in cartItemsSnapshot.docs) {
      final data = doc.data();

      await FirebaseFirestore.instance
          .collection('makeorder')
          .doc(makeOrderId)
          .collection('makeCartOrder')
          .doc(data['productId']) // ✅ use key string, not variable
          .set({
        'productId': data['productId'],          // ✅ use data from Firestore
        'productName': data['productName'],
        'price': data['price'],
        'quantity': data['quantity'],
        'imageUrl': data['imageUrl'],
        'itemTotalPrice':(data['price'] ?? 0) * (data['quantity'] ?? 0),
      }, SetOptions(merge: true));
    }

    //4. Add user details to makeOrder(collection)
    await FirebaseFirestore.instance
        .collection('makeorder')
        .doc(makeOrderId)
        .set({
          'userId': _userId,
          'email': emailToSearch,
          'subTotal': subTotal,
          'CGST': double.parse(CGST.toStringAsFixed(2)),
          'SGST': double.parse(SGST.toStringAsFixed(2)),
          'grandTotal': double.parse(grandTotal.toStringAsFixed(2))
        }, SetOptions(merge: true));


    //5. go to MakeOrder page
    Navigator.push(context, MaterialPageRoute(builder: (context)=> MakeOrderPage(userEmail: widget.userEmail)));

  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black26,
        appBar: AppBar(
          leading: IconButton(onPressed: (){Navigator.of(context).pop();}, icon: Icon(Icons.arrow_back)),
          title: Text("Cart Page"),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 20.0,left: 40,bottom: 20,right: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Padding(
                  padding: const EdgeInsets.only(bottom: 15.0),
                  child: Text("Your Cart",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 45),),
                ),


                //Cart Grid Items
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                  stream: newStream(),
                  builder: (context, snapshot) {

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
                      return Center(child: Text('No items in your cart.'));
                    }

                    final cart = snapshot.data!.docs;

                    double subTotal = 0;

                    for(var items in cart){
                      var data = items.data() as Map<String, dynamic>;
                      final pPrice = (data['price'] as num).toDouble();
                      final qty = (data['quantity'] ?? 1);

                      subTotal += pPrice * qty;
                    }

                    int gstPer = 3;
                    //3% GST on subtotal
                    double CGST = subTotal * (gstPer/100);

                    double SGST = subTotal * (gstPer/100);

                    double grandTotal = subTotal + CGST + SGST;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: GridView.builder(
                              itemCount: cart.length,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 5,
                                  childAspectRatio: 0.9
                                // mainAxisExtent: 1,
                              ),
                              itemBuilder: (context, index){
                                var cartItems = cart[index].data() as Map<String, dynamic>;

                                final int quantity = cartItems['quantity'];
                                final double price = (cartItems['price'] as num).toDouble();
                                double itemTotalPrice = price*quantity;

                                return Card(
                                    elevation: 9,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 20.0,right: 20,top: 20),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [

                                          //Item Image
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Container(
                                              color: Colors.white, // Ensure a white background for non-filling images
                                              child: AspectRatio(
                                                aspectRatio: 1.4,
                                                child: Image.network(
                                                  cartItems['imageUrl'] as String,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) =>
                                                  const Icon(Icons.broken_image, size: 60),
                                                ),
                                              ),
                                            ),
                                          ),

                                          SizedBox(
                                            height: 10,
                                          ),
                                          //Item Name
                                          Text(
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            cartItems['productName'],style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),

                                          //ItemPrice * ItemCount = TotalPrice
                                          Text("$price × $quantity = $itemTotalPrice",style: TextStyle(fontSize: 15),),

                                          //Delete , Quantity
                                          Expanded(
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                IconButton(
                                                  onPressed: () async{
                                                    showDialog(
                                                         barrierDismissible: false,
                                                        context: context,
                                                        builder: (context){
                                                          return AlertDialog(
                                                            content: Text("Remove Item From CART ?"),
                                                            actions: [
                                                              TextButton(onPressed: (){
                                                                Navigator.of(context).pop();
                                                              }, child: Text("No")),
                                                              TextButton(onPressed: () async{
                                                                deleteItem(cartItems['productId'] ?? '');
                                                                Navigator.of(context).pop();
                                                              }, child: Text("Remove")),
                                                            ],
                                                          );
                                                        }
                                                    );
                                                  },
                                                  icon: Icon(Icons.delete),
                                                  color: Colors.red,
                                                ),
                                                Container(
                                                  decoration: BoxDecoration(
                                                      color: Colors.greenAccent,
                                                      borderRadius: BorderRadius.circular(10)
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      quantity == 1 ?
                                                      FloatingActionButton(
                                                        heroTag: 'decreaseBtnOne',
                                                        onPressed: (){},
                                                        child: Icon(Icons.remove),
                                                        tooltip: 'Min 1',
                                                        backgroundColor: Colors.green,
                                                        foregroundColor: Colors.black12,
                                                        mini: true,
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                      ) :
                                                      FloatingActionButton(
                                                        heroTag: 'decreaseBtnTwo',
                                                        onPressed: (){
                                                          decreaseItem(cartItems['productId'] ?? '');
                                                        },
                                                        child: Icon(Icons.remove),
                                                        backgroundColor: Colors.green,
                                                        foregroundColor: Colors.white,
                                                        mini: true,
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                      ),

                                                      Padding(
                                                        padding: const EdgeInsets.only(left: 13.0,right: 13),
                                                        child: Text("$quantity",style: TextStyle(fontWeight: FontWeight.bold),),
                                                      ),

                                                      quantity == 5 ?
                                                      FloatingActionButton(
                                                        heroTag: 'increaseBtnOne',
                                                        onPressed: (){},
                                                        child: Icon(Icons.add),
                                                        tooltip: 'Max 5',
                                                        backgroundColor: Colors.green,
                                                        foregroundColor: Colors.black12,
                                                        mini: true,
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                      ) :
                                                      FloatingActionButton(
                                                        heroTag: 'increaseBtnTwo',
                                                        onPressed: (){
                                                          incrementItem(cartItems['productId'] ?? '');
                                                        },
                                                        child: Icon(Icons.add),
                                                        backgroundColor: Colors.green,
                                                        foregroundColor: Colors.white,
                                                        mini: true,
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                    )
                                );
                              }
                          ),
                        ),

                        //Grand Total
                        SizedBox(
                          height: 220 ,
                          width: 500,
                          child: Card(
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(15.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Sub Total",style: TextStyle(fontSize: 18),),
                                      Text("₹$subTotal",style: TextStyle(fontSize: 18),),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("CGST: ($gstPer%)",style: TextStyle(fontSize: 15),),
                                      Text("₹${CGST.toStringAsFixed(2)}",style: TextStyle(fontSize: 15,color: Colors.black45),),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("SGST: ($gstPer%)",style: TextStyle(fontSize: 15),),
                                      Text("₹${SGST.toStringAsFixed(2)}",style: TextStyle(fontSize: 15,color: Colors.black45),),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 5,right: 5),
                                    child: Divider(),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Grand Total",style: TextStyle(fontSize: 30),),
                                      Text(overflow: TextOverflow.ellipsis,maxLines: 1,
                                        "₹${grandTotal.toStringAsFixed(2)}",style: TextStyle(fontSize: 30),),
                                    ],
                                  ),
                                  SizedBox(
                                    height: 20,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      ElevatedButton(
                                        onPressed: (){
                                          setState(() {
                                            showDialog(
                                                context: context,
                                                builder: (context){
                                                  return AlertDialog(
                                                    alignment: Alignment.bottomCenter,
                                                    // title: Text("Logout"),
                                                    content: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text("Once You Make Order,",style: TextStyle(fontSize: 15),),
                                                        Text("You Don't Able To Change Quantity",style: TextStyle(fontSize: 20,color: Colors.red),),
                                                        Text("Are You Sure to Processed Make Your Order ?",style: TextStyle(fontSize: 15),),
                                                      ],
                                                    ),
                                                    actions: [
                                                      TextButton(onPressed: (){
                                                        Navigator.of(context).pop();
                                                      }, child: Text("Change Quantity")),
                                                      TextButton(onPressed: (){
                                                        goToMakeOrder(subTotal,CGST,SGST,grandTotal);
                                                        Navigator.of(context).pop();
                                                      }, child: Text("Ok"))
                                                    ],
                                                  );
                                                }
                                            );
                                          });


                                        },
                                        child: Text("Make Order"),
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
                          ),
                        ),
                      ],
                    );
                  }
                ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}






